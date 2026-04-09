# Interactive Voice-Assisted Task-Driven Onboarding Plan

This plan outlines the upgrade of the existing `Tour` system into a high-engagement, voice-guided, and task-driven assistant similar to Duolingo or premium SaaS onboarding flows.

## User Review Required

> [!IMPORTANT]
> The system shifts from a "Click Next" model to an "Action Detection" model. Users must complete specified tasks (e.g., creating a site) to advance. We will use an internal event bus to track these actions.

## User Interaction Flow

1.  **Trigger**: User opens a module (e.g., "Site") for the first time or clicks "Help/Tutorial".
2.  **Navigation**: `TourController` checks if the user is on the correct screen. If not, it navigates automatically.
3.  **Instruction**: `BuddyOverlay` appears with a bounce animation. `VoiceAssistantService` reads the `buddyMessage` aloud.
4.  **Task**: The user is instructed to perform an action (e.g., "Tap the + button"). The "Next" button is disabled; completion is event-driven.
5.  **Real-time Guidance**: 
    *   **Timeout**: If no action is detected after 7s, a hint appears (e.g., "Look for the + button at the bottom!").
    *   **Highlight**: The target UI element (Showcase) can pulse or shake to draw attention.
6.  **Validation**: When the user performs the task, the app emits a `TourEvent`. The `TourController` validates and auto-advances.
7.  **Celebration**: On module completion, a gamified success screen is shown.

> [!TIP]
> Each module (Site, Rate, Manpower, DPR) will have its own progress tracking, allowing users to restart or complete flows independently.

## Proposed Changes

### 1. Domain Models Upgrade

#### [MODIFY] [tour_step_model.dart](file:///c:/Users/Dell/Downloads/untitled2/untitled2/lib/features/tour/domain/tour_step_model.dart)
- Expand `TourActionType` to include `create`, `input`, `select`, `navigate`.
- Add `requiredEvent` (the `TourEvent` that triggers completion).
- Add `hint` (message shown after timeout).
- Add `moduleId` to associate steps with specific tours.

#### [NEW] [tour_event.dart](file:///c:/Users/Dell/Downloads/untitled2/untitled2/lib/features/tour/domain/tour_event.dart)
- Define `TourEvent` enum: `siteCreated`, `manpowerAdded`, `moduleOpened`, etc.
- This will be the glue between the app features and the tour engine.

#### [NEW] [tour_module.dart](file:///c:/Users/Dell/Downloads/untitled2/untitled2/lib/features/tour/domain/tour_module.dart)
- Define `TourModule` model: `id`, `name`, `description`, `steps`.

---

### 2. Services & Controllers

#### [NEW] [voice_assistant_service.dart](file:///c:/Users/Dell/Downloads/untitled2/untitled2/lib/features/tour/domain/voice_assistant_service.dart)
- Initialize `FlutterTts`.
- Methods: `speak(text)`, `stop()`, `toggleMute()`.
- Riverpod provider for global access.

#### [MODIFY] [tour_controller.dart](file:///c:/Users/Dell/Downloads/untitled2/untitled2/lib/features/tour/domain/tour_controller.dart)
- Enhance `TourState` to include `currentModuleId`, `isMuted`, `showHint`.
- Implement `onEvent(TourEvent event)`: if event matches `currentStep.requiredEvent`, move to next step.
- Implement Timer-based hint logic (show `step.hint` after 7 seconds of inactivity).
- Integration with `VoiceAssistantService` (auto-speak on step change).
- Smart navigation: only trigger `router.go` if the user isn't already on the correct route.

---

### 3. UI/UX Redesign

#### [MODIFY] [buddy_overlay.dart](file:///c:/Users/Dell/Downloads/untitled2/untitled2/lib/features/tour/screen/buddy_overlay.dart)
- **Visuals**: Chat bubble with tail, animated avatar (pulse animation).
- **Controls**:
    - [⏮ Prev] [⏭ Next] (Next is disabled if task is not complete).
    - [🔊/🔇 Mute] [🔁 Replay Voice].
- **Progress**: "Step 2/5" indicator and linear progress bar.
- **Animations**: Entrance bounce, pulse glow when waiting for action.

#### [NEW] [module_completion_overlay.dart](file:///c:/Users/Dell/Downloads/untitled2/untitled2/lib/features/tour/screen/module_completion_overlay.dart)
- Premium success screen with "Module Complete!" badge and "Continue" button.

---

### 4. Registry & Integration

#### [MODIFY] [tour_registery.dart](file:///c:/Users/Dell/Downloads/untitled2/untitled2/lib/features/tour/domain/tour_registery.dart)
- Reorganize `onboarding` into `TourModules` (SiteModule, RateModule, etc.).

#### [MODIFY] Feature Screens (Examples)
- In `SiteCreationScreen`, call `ref.read(tourControllerProvider.notifier).emitEvent(TourEvent.siteCreated)` upon success.

## Open Questions

- Should the voice assistant be enabled by default? (Recommendation: Yes, but with an easy mute button).
- Do we want to support speech recognition ("Next", "Repeat") in this phase? (Recommendation: Keep it optional/v2 to avoid voice noise issues in field construction environments).

## Verification Plan

### Automated Tests
- Unit tests for `TourController` event matching logic.
- Mock TTS service to verify `speak` is called on step transitions.

### Manual Verification
- Start "Site Tour".
- Verify Buddy speaks instructions.
- Ensure "Next" is disabled until a Site is created.
- Verify "Next" becomes enabled/auto-triggers after Site creation event.
- Test "Replay Voice" button.
- Test "Mute" persistence.
