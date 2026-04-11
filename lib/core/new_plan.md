# planout.md — Unified Import Flow System
### Flutter + Riverpod | Production Architecture Document

---

## 1. 🧩 Problem Breakdown

### Current System Inefficiencies

The current system forces users through three **separate, disconnected import screens**:

- `SiteImportCsvScreen` — uploads site file, navigates to `SiteDetailScreen`
- `ImportCsvScreen` (Rate) — uploads rate file, navigates to `/site-list/rate`
- `ManImportCsvScreen` — uploads manpower file, includes analysis step, navigates to `/manpower`

**Identified Inefficiencies:**

1. **No shared state between modules** — `selectedSiteIdProvider` is read independently in each screen, with no coordination layer.
2. **Duplicated upload logic** — File picking, error handling, loading states, and FormData construction are copy-pasted across all three screens (~90% identical code).
3. **Inconsistent UX patterns** — Rate screen skips analysis; Manpower screen does analysis but Rate does not. No parity.
4. **Sequential UX with no concurrency benefit** — Rate and Manpower uploads could run in parallel after site is available, but the current flow forces a serial user journey.
5. **No dependency management** — The system has no concept of "wait for Site upload, then trigger Rate + Manpower." This logic doesn't exist anywhere.
6. **`siteId` null-safety gaps** — Both `ImportCsvScreen` and `ManImportCsvScreen` call `ref.read(selectedSiteIdProvider)` without asserting non-null before passing to `UploadJob.create`. A null siteId silently produces a bad job.
7. **Navigation is fragile** — Each screen does manual `Navigator.push` or `context.go`. There's no unified post-import navigation strategy.

### Core Technical Challenge: siteId Dependency Tree

```
Case 1: Existing site selected
  ├── siteId known immediately
  └── Rate job + Manpower job → enqueue in PARALLEL ✅

Case 2: New site from Step 1
  ├── Site upload must complete FIRST
  ├── Extract siteId from UploadJob.response
  └── Then enqueue Rate job + Manpower job (parallel) ✅

Case 3: Rate and Manpower use different sites
  ├── Rate: uses siteId_A (existing or new)
  ├── Manpower: uses siteId_B (existing or new)
  └── Each resolves its own dependency independently ✅
```

---

## 2. 🏗️ System Architecture

### High-Level Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                    UnifiedImportScreen                         │
│                                                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐ │
│  │  Step 1:     │  │  Step 2:     │  │  Step 3:             │ │
│  │  Site File   │→ │  Rate File   │→ │  Manpower File       │ │
│  │  + Source    │  │  + Source    │  │  + Source            │ │
│  └──────────────┘  └──────────────┘  └──────────────────────┘ │
│                                                                │
│              UnifiedImportController (Riverpod)                │
│         ┌──────────────────────────────────────────┐          │
│         │  UnifiedImportState                      │          │
│         │   steps: List<StepConfig>                │          │
│         │   currentStep: int                       │          │
│         │   siteSelection: SiteSelectionMode       │          │
│         │   resolvedSiteIds: Map<module, siteId>   │          │
│         │   uploadJobs: Map<module, jobId>         │          │
│         └────────────────┬─────────────────────────┘          │
│                          │                                     │
│              ImportOrchestrator                                │
│         ┌────────────────▼─────────────────────────┐          │
│         │  Dependency Resolver                      │          │
│         │  ├── resolveSiteId(module) → Future<id>  │          │
│         │  ├── waitForSiteJob(jobId) → siteId      │          │
│         │  └── parallelEnqueue(jobs) → void        │          │
│         └────────────────┬─────────────────────────┘          │
│                          │                                     │
│              UploadManager (existing)                          │
│         ┌────────────────▼─────────────────────────┐          │
│         │  enqueue(UploadJob)                      │          │
│         │  waitForCompletion(jobId)                │          │
│         │  retry / cancel / removeJob              │          │
│         └──────────────────────────────────────────┘          │
└────────────────────────────────────────────────────────────────┘
```

### Data Flow Diagram

```
User fills Step 1, 2, 3
          │
          ▼
[UnifiedImportController.submit()]
          │
          ├─── For each module step:
          │         determine siteId source
          │              │
          │    ┌─────────▼──────────┐
          │    │ SiteSelectionMode  │
          │    │ .existing(id)      │──→ siteId resolved immediately
          │    │ .newFromStep1      │──→ wait for site job to complete
          │    └────────────────────┘
          │
          ├─── [ImportOrchestrator.orchestrate()]
          │         │
          │    Has pending site job?
          │         │
          │    YES ─┤
          │         │  enqueue site job
          │         │  await UploadManager.waitForCompletion(siteJobId)
          │         │  extract siteId from response
          │         │
          │    NO ──┤
          │         │  siteId already known
          │         │
          │         └─→ enqueue(rateJob) + enqueue(manpowerJob) [PARALLEL]
          │
          ▼
[UnifiedImportState.phase = .uploading]
          │
          ▼
[UploadManager processes queue]
          │
          ▼
[UnifiedImportController listens to job completions]
          │
          ▼
[Navigate to summary screen]
```

---

## 3. 🧠 State Management Design (Riverpod)

### Provider Structure

```dart
// ── Domain Models ──────────────────────────────────────────────

enum SiteSelectionMode {
  existingSite,     // user picked from dropdown
  newFromStep1,     // use site uploaded in this very flow
}

enum ImportPhase {
  configuring,   // user is filling steps
  validating,    // pre-upload analysis running
  uploading,     // jobs submitted to UploadManager
  done,          // all terminal
  failed,        // unrecoverable error
}

class StepConfig {
  final String moduleId;       // 'site' | 'rate' | 'manpower'
  final PlatformFile? file;
  final SiteSelectionMode siteMode;
  final String? selectedSiteId;    // if mode == existingSite
  final bool analysisRequired;     // true for manpower
  final String? jobId;             // assigned after enqueue
}

class UnifiedImportState {
  final List<StepConfig> steps;
  final int currentStep;
  final ImportPhase phase;
  final String? error;
  final Map<String, String> resolvedSiteIds; // moduleId → siteId
}

// ── Providers ──────────────────────────────────────────────────

// Existing sites list (for dropdown)
final sitesListProvider = FutureProvider<List<SiteModel>>(...);

// Core controller
final unifiedImportControllerProvider =
    NotifierProvider<UnifiedImportController, UnifiedImportState>(
        UnifiedImportController.new);

// Derived: is submit enabled?
final canSubmitImportProvider = Provider<bool>((ref) {
  final state = ref.watch(unifiedImportControllerProvider);
  return state.steps.every((s) => s.file != null) &&
      state.phase == ImportPhase.configuring;
});

// Upload progress per module
final moduleUploadProgressProvider =
    Provider.family<double, String>((ref, moduleId) {
  final jobs = ref.watch(uploadManagerProvider);
  final step = ref.watch(unifiedImportControllerProvider)
      .steps
      .firstWhereOrNull((s) => s.moduleId == moduleId);
  if (step?.jobId == null) return 0.0;
  return jobs.firstWhereOrNull((j) => j.jobId == step!.jobId)?.progress ?? 0.0;
});
```

### State Separation

| Layer | Provider | Responsibility |
|---|---|---|
| UI State | `unifiedImportControllerProvider` | current step, file selections, phase |
| Async Jobs | `uploadManagerProvider` | job queue, progress, retries |
| Domain Data | `sitesListProvider` | existing sites for dropdown |
| Derived | `canSubmitImportProvider` | submit button enabled/disabled |
| Per-module progress | `moduleUploadProgressProvider.family` | individual progress bars |

### Avoiding Race Conditions

- **Site job completion** is awaited via the existing `UploadManager.waitForCompletion()` — this is already implemented and safe.
- **State transitions** (`ImportPhase`) act as a guard: the submit button is disabled once `phase != configuring`, preventing double submissions.
- **Job IDs are stored in StepConfig** after enqueue. Any listener checking job status always works off the canonical job ID, not a module name.
- **`_processingModules` map** in `UploadManager` already serializes per-module to prevent duplicate concurrent processing.

---

## 4. ⚙️ Upload Orchestration Logic

### ImportOrchestrator

```dart
class ImportOrchestrator {
  final Ref ref;
  ImportOrchestrator(this.ref);

  Future<void> orchestrate(List<StepConfig> steps) async {
    final siteStep = steps.firstWhereOrNull((s) => s.moduleId == 'site');
    final dependentSteps = steps.where((s) => s.moduleId != 'site').toList();

    // 1. Handle site resolution
    String? resolvedSiteId;

    if (siteStep != null && siteStep.file != null) {
      // Enqueue site job and WAIT for it
      final siteJobId = ref.read(uploadManagerProvider.notifier).enqueue(
        UploadJob.create(
          moduleId: 'site',
          filePath: siteStep.file!.path!,
          metadata: {'type': ref.read(typeProvider)},
          targetRoute: null, // orchestrator handles navigation
          maxRetries: 2,
        ),
      );

      // Update state: site job in progress
      ref.read(unifiedImportControllerProvider.notifier)
          .setJobId('site', siteJobId);

      try {
        final completedJob = await ref
            .read(uploadManagerProvider.notifier)
            .waitForCompletion(siteJobId);

        if (completedJob.status != UploadStatus.success) {
          throw Exception("Site upload failed: ${completedJob.message}");
        }

        // Extract siteId from response
        resolvedSiteId = _extractSiteId(completedJob.response);
      } catch (e) {
        throw SiteUploadFailedException(e.toString());
      }
    }

    // 2. Now enqueue dependent jobs in PARALLEL
    final futures = dependentSteps.map((step) async {
      final effectiveSiteId = step.siteMode == SiteSelectionMode.newFromStep1
          ? resolvedSiteId
          : step.selectedSiteId;

      if (effectiveSiteId == null) {
        throw Exception("Cannot resolve siteId for module: ${step.moduleId}");
      }

      final jobId = ref.read(uploadManagerProvider.notifier).enqueue(
        UploadJob.create(
          moduleId: step.moduleId,
          filePath: step.file!.path!,
          metadata: {
            'siteId': effectiveSiteId,
            'type': ref.read(typeProvider),
          },
          targetRoute: null,
          maxRetries: 2,
        ),
      );

      ref.read(unifiedImportControllerProvider.notifier)
          .setJobId(step.moduleId, jobId);
    });

    // Fire all parallel jobs simultaneously
    await Future.wait(futures);
  }

  String _extractSiteId(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response['site']?['_id'] ??
             response['siteId'] ??
             (throw Exception("siteId not found in response"));
    }
    throw Exception("Invalid site upload response format");
  }
}
```

### Sequential vs Parallel Summary

```
Site upload (if new)     → SEQUENTIAL (must complete first)
     ↓
Rate + Manpower          → PARALLEL (enqueued simultaneously)
```

### Retry & Failure Handling

- `UploadManager` already has `maxRetries` + `retry(jobId)` — reuse this.
- `UnifiedImportController` listens to `uploadManagerProvider` changes. If a job reaches `UploadStatus.failed` and retries are exhausted, it surfaces a per-module error without blocking other modules.
- A `PartialSuccessState` is supported: e.g., Rate succeeded but Manpower failed — user sees which modules completed and which need attention.

---

## 5. 🧱 File Structure

```
lib/
├── core/
│   ├── upload/
│   │   ├── manager/
│   │   │   └── upload_manager.dart          ← EXISTING (no changes needed)
│   │   ├── models/
│   │   │   ├── upload_job.dart              ← EXISTING
│   │   │   └── upload_status.dart           ← EXISTING
│   │   ├── registry/
│   │   │   └── upload_handler_registry.dart ← EXISTING
│   │   └── orchestration/
│   │       ├── import_orchestrator.dart     ← NEW
│   │       └── dependency_resolver.dart     ← NEW
│   └── utils/
│       └── ...                              ← EXISTING
│
└── features/
    └── modules/
        ├── unified_import/                  ← NEW FEATURE MODULE
        │   ├── domain/
        │   │   ├── step_config.dart
        │   │   ├── unified_import_state.dart
        │   │   ├── site_selection_mode.dart
        │   │   └── import_phase.dart
        │   ├── application/
        │   │   ├── unified_import_controller.dart
        │   │   └── unified_import_providers.dart
        │   ├── presentation/
        │   │   ├── unified_import_screen.dart
        │   │   ├── widgets/
        │   │   │   ├── import_step_card.dart
        │   │   │   ├── site_source_selector.dart
        │   │   │   ├── module_progress_tile.dart
        │   │   │   └── import_summary_sheet.dart
        │   │   └── screens/
        │   │       └── import_result_screen.dart
        │   └── config/
        │       └── import_step_registry.dart  ← config-driven steps
        │
        └── all_Modules/
            ├── site_Details/                  ← EXISTING (unchanged)
            ├── rate/                          ← EXISTING (unchanged)
            └── Manpower Details/              ← EXISTING (unchanged)
```

**Decisions:**
- **Feature-based structure** for `unified_import` — it's a standalone feature with its own domain, application, and presentation layers.
- Individual module folders remain untouched. The unified flow is purely additive.
- `import_step_registry.dart` drives the stepper config — adding a new module (e.g., Materials) requires only a new entry in the registry, zero UI changes.

---

## 6. 🎨 UI/UX Design

### Challenging the Stepper Assumption

A linear stepper UI has a fundamental problem: **it forces serial mental processing**. Users must context-switch three times. For power users uploading the same files weekly, this is friction.

**Recommended: Parallel Card Layout (not a stepper)**

```
┌─────────────────────────────────────────────────────┐
│  📦 Batch Import                            [?] Help │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌────────────────────┐  ┌────────────────────────┐ │
│  │  🏗 Site           │  │  💰 Rate               │ │
│  │                    │  │                        │ │
│  │  [Drop file here]  │  │  [Drop file here]      │ │
│  │                    │  │  Site: [dropdown ▼]    │ │
│  │  ● New site        │  │                        │ │
│  │  ○ Existing        │  │  ✅ site-2024.xlsx     │ │
│  └────────────────────┘  └────────────────────────┘ │
│                                                     │
│  ┌────────────────────┐                             │
│  │  👷 Manpower       │                             │
│  │                    │                             │
│  │  [Drop file here]  │                             │
│  │  Site: [dropdown ▼]│                             │
│  └────────────────────┘                             │
│                                                     │
│  [  🚀 Import All  ]   ← enabled when all filled   │
└─────────────────────────────────────────────────────┘
```

**Why this is better than a stepper:**
- All three modules are visible at once — user can see completion status at a glance.
- Files can be dropped/selected in any order.
- Power users can fill all three in under 10 seconds.
- Site dependency is shown contextually (Rate and Manpower cards show the site dropdown only when site is not being uploaded as new).

**When stepper makes sense:** First-time user onboarding. Offer a "Guided Mode" toggle that activates stepper with explanations. Default to the card layout for returning users.

### Progress State (Post-Submit)

```
┌─────────────────────────────────────────────────────┐
│  Importing...                                       │
│                                                     │
│  🏗 Site      ████████████████ 100% ✅ Done         │
│  💰 Rate      ████████░░░░░░░░  52% ⏳ Uploading   │
│  👷 Manpower  ████████░░░░░░░░  48% ⏳ Uploading   │
│                                                     │
│  Rate and Manpower are running in parallel.         │
└─────────────────────────────────────────────────────┘
```

### Error States

- **Per-card validation errors**: shown inline on the card before submit (e.g., "Select a site source").
- **Upload failure**: card turns red with retry button. Other cards remain green.
- **Site failure blocks dependents**: Rate + Manpower cards show "⏸ Waiting for site" and then "❌ Site failed — fix to continue".

### UX for Power Users

- **Drag-and-drop file zones** on each card (faster than file picker dialog).
- **Remember last site selection** via shared preferences — pre-fill dropdown on next open.
- **Keyboard shortcuts**: Tab through cards, Enter to open file picker.
- **Bulk paste from clipboard**: detect clipboard file path and auto-fill (mobile: share sheet integration).

---

## 7. 🔥 Edge Cases

### Site upload fails
- `ImportOrchestrator` catches `SiteUploadFailedException`.
- State transitions to `ImportPhase.failed` with `failedModules: ['site']`.
- Rate and Manpower jobs are **never enqueued** (they depended on site).
- UI shows: "Site upload failed. Fix the file and retry. Rate + Manpower are on hold."
- Retry button re-runs only the site step, then auto-proceeds to dependents.

### Rate upload fails but Manpower succeeds
- Both are enqueued in parallel. They fail independently.
- `UnifiedImportController` tracks each `jobId` separately.
- Final state: `partialSuccess: { 'rate': failed, 'manpower': success }`.
- Summary screen shows green/red per module with individual retry buttons.
- Navigation: go to manpower list (for the success), show rate error inline.

### User changes site selection mid-flow
- If a job has already been enqueued (`step.jobId != null`), changing site selection:
  1. Cancels the existing job via `UploadManager.cancel(jobId)`.
  2. Resets `step.jobId = null`.
  3. Re-validates the form.
- Guard: site selection is **locked** once `ImportPhase.uploading` starts. Show tooltip: "Upload in progress — cannot change site."

### Duplicate uploads
- Before enqueuing, check `UploadManager.state` for an existing queued/uploading job with the same `moduleId` + same `filePath`.
- If found: show dialog "A job for this module is already running. Cancel it first?"
- Hash-based deduplication: compute `sha256` of file bytes before upload, compare against a local cache of recently uploaded hashes (`SharedPreferences`). If match: "This file was imported 2 hours ago. Import again?"

### Network interruptions
- `UploadManager` already has retry logic. On network failure, job goes to `failed`.
- `ImportOrchestrator.waitForCompletion()` will throw, surfacing the error.
- Connectivity provider (e.g., `connectivity_plus`) can show a banner: "No internet. Uploads will resume when connected."
- For background queue: jobs remain in `UploadStatus.queued` until connectivity returns (requires a `connectivityWatcher` in `UploadManager` — see Phase 2).

### Background job killed (app goes to background)
- `UploadManager` state lives in Riverpod memory — it does not persist across app kills.
- **Mitigation**: On `enqueue`, write job metadata to `SharedPreferences` / `Hive`. On app startup, `UploadManager.build()` loads persisted pending jobs and re-enqueues them.
- Jobs that were `uploading` when killed are reset to `queued` on reload (server-side idempotency assumed via file hash).

### App restart during process
- Same as above. Persistent job store is the key.
- Add `persistedJobsProvider` using `Hive` or `drift` for durability.
- After restart, show "You have 2 pending uploads from your last session. Resume?"

---

## 8. 🚀 Scalability & Future Expansion

### Config-Driven Step Registry

```dart
// lib/features/modules/unified_import/config/import_step_registry.dart

class ImportStepDefinition {
  final String moduleId;
  final String displayName;
  final IconData icon;
  final bool requiresSiteId;
  final bool requiresAnalysis;
  final List<String> allowedExtensions;
  final String targetRoute;
  final String sampleAsset;
}

final importStepRegistry = [
  ImportStepDefinition(
    moduleId: 'site',
    displayName: 'Site',
    icon: Icons.business,
    requiresSiteId: false,
    requiresAnalysis: false,
    allowedExtensions: ['csv', 'xlsx'],
    targetRoute: '/site-list',
    sampleAsset: 'assets/images/site-temp.png',
  ),
  ImportStepDefinition(
    moduleId: 'rate',
    displayName: 'Rate',
    icon: Icons.attach_money,
    requiresSiteId: true,
    requiresAnalysis: false,
    allowedExtensions: ['csv', 'xlsx'],
    targetRoute: '/site-list/rate',
    sampleAsset: 'assets/images/rate-temp.webp',
  ),
  ImportStepDefinition(
    moduleId: 'manpower',
    displayName: 'Manpower',
    icon: Icons.people,
    requiresSiteId: true,
    requiresAnalysis: true,
    allowedExtensions: ['xlsx'],
    targetRoute: '/manpower',
    sampleAsset: 'assets/images/man-temp.webp',
  ),
  // Future addition — zero UI code changes required:
  // ImportStepDefinition(moduleId: 'materials', ...),
  // ImportStepDefinition(moduleId: 'vendors', ...),
];
```

### Plug-and-Play Handler Registration

Each module registers its own upload handler in `UploadHandlerRegistry`. New modules add a single handler file + one line in the registry. No changes to `ImportOrchestrator` or UI.

### Multi-project / multi-type support

The `type` value from `typeProvider` is already passed as metadata. The orchestrator is type-agnostic.

---

## 9. 🧪 Testing Strategy

### Unit Tests

```
test/features/unified_import/
├── domain/
│   ├── step_config_test.dart               — StepConfig.copyWith, validation
│   └── unified_import_state_test.dart      — state transitions
├── application/
│   ├── unified_import_controller_test.dart — submit flow, phase transitions
│   └── import_orchestrator_test.dart       — dependency resolution logic
└── core/upload/
    └── upload_manager_test.dart            — enqueue, waitForCompletion (existing)
```

**Key unit test cases for `ImportOrchestrator`:**
- Site job completes → siteId extracted → dependents enqueued
- Site job fails → dependents never enqueued
- Existing siteId provided → skip site job, go straight to parallel enqueue
- `waitForCompletion` timeout → `TimeoutException` propagated correctly

### Integration Tests

```
integration_test/
└── unified_import_flow_test.dart
    ├── full happy path (new site → rate + manpower)
    ├── existing site path (skip site upload)
    ├── partial failure (rate fails, manpower succeeds)
    └── duplicate file guard
```

Use `mockito` or `mocktail` to mock `SiteAPI`, `ManpowerAPI`, `RateApiClient`. Mock `UploadHandlerRegistry` to return controlled success/failure responses.

### Async Job Testing

```dart
test('orchestrator waits for site before enqueueing dependents', () async {
  final container = ProviderContainer(overrides: [
    uploadManagerProvider.overrideWith(() => MockUploadManager()),
  ]);

  // Simulate site job that takes 500ms
  mockUploadManager.delayForModule('site', const Duration(milliseconds: 500));

  final orchestrator = ImportOrchestrator(container.read);
  final stopwatch = Stopwatch()..start();

  await orchestrator.orchestrate(testStepsWithNewSite);

  expect(stopwatch.elapsedMilliseconds, greaterThan(450));
  // Rate and manpower enqueued AFTER site
  verify(mockUploadManager.enqueue(argThat(hasModuleId('rate')))).called(1);
});
```

### Failure Simulations

```dart
test('site upload failure blocks dependents and surfaces error', () async {
  mockUploadManager.failForModule('site');

  expect(
    () => orchestrator.orchestrate(testSteps),
    throwsA(isA<SiteUploadFailedException>()),
  );

  verifyNever(mockUploadManager.enqueue(argThat(hasModuleId('rate'))));
  verifyNever(mockUploadManager.enqueue(argThat(hasModuleId('manpower'))));
});
```

---

## 10. 📋 Implementation Plan

### Phase 1: Core Flow (Days 1–4)

**Goal:** Unified screen with all three cards, manual site selection, sequential submission.

| Task | Details |
|---|---|
| 1.1 | Create domain models: `StepConfig`, `UnifiedImportState`, `ImportPhase`, `SiteSelectionMode` |
| 1.2 | Create `UnifiedImportController` with `updateStep()`, `setFile()`, `setSiteMode()`, `setSiteId()` |
| 1.3 | Build `UnifiedImportScreen` with parallel card layout |
| 1.4 | Build `ImportStepCard` widget (file drop zone, site dropdown conditional on `requiresSiteId`) |
| 1.5 | Build `SiteSourceSelector` widget (toggle: existing / new from step 1) |
| 1.6 | Wire `canSubmitImportProvider` to submit button |
| 1.7 | Add route to Go Router: `/unified-import` |
| 1.8 | Basic submit: enqueue all jobs with resolved siteIds (existing only) |

### Phase 2: Background Jobs Integration (Days 5–8)

**Goal:** Full orchestration with site dependency resolution and parallel execution.

| Task | Details |
|---|---|
| 2.1 | Build `ImportOrchestrator` with `orchestrate()` method |
| 2.2 | Wire `UploadManager.waitForCompletion()` into orchestrator site-wait logic |
| 2.3 | Implement `_extractSiteId()` from upload response |
| 2.4 | Add per-module progress bars using `moduleUploadProgressProvider.family` |
| 2.5 | Build `ImportResultScreen` showing per-module success/failure |
| 2.6 | Add job ID tracking to `UnifiedImportState` |
| 2.7 | Implement `ImportPhase` transitions and UI locking |

### Phase 3: Edge Cases & Optimization (Days 9–12)

**Goal:** Production-hardened, handles all failure scenarios.

| Task | Details |
|---|---|
| 3.1 | Persistent job store (Hive or SharedPreferences) in `UploadManager.build()` |
| 3.2 | Duplicate upload detection (hash-based) |
| 3.3 | Mid-flow site selection change: cancel + reset logic |
| 3.4 | Connectivity watcher: pause queue on offline, resume on reconnect |
| 3.5 | Retry UI: per-module retry button on `ImportResultScreen` |
| 3.6 | Analysis step integration for manpower (reuse existing dialog logic) |
| 3.7 | "Guided mode" stepper for first-time users |

### Phase 4: Scaling Support (Days 13–15)

**Goal:** Any new module can be added with one config entry.

| Task | Details |
|---|---|
| 4.1 | Finalize `ImportStepRegistry` as the single source of truth |
| 4.2 | Refactor `UnifiedImportScreen` to render purely from registry (no hardcoded module names) |
| 4.3 | Write unit + integration tests for all 3 modules + orchestrator |
| 4.4 | Document handler registration process for future module developers |
| 4.5 | Performance audit: measure enqueue-to-completion time, optimize if needed |

---

## Appendix: Key Design Decisions

| Decision | Rationale |
|---|---|
| Card layout over stepper | Parallel mental model matches parallel execution; faster for returning users |
| Orchestrator as separate class | Keeps controller thin; orchestrator is independently testable |
| Config-driven registry | Adding Materials module = 1 file + 1 registry entry, no UI changes |
| `waitForCompletion()` already exists | Minimal invasive changes to `UploadManager` (it's already production-ready) |
| Per-module failure, not all-or-nothing | Rate success shouldn't be lost because Manpower failed |
| Guided mode as opt-in | Stepper is better for onboarding; card layout is better for power use |