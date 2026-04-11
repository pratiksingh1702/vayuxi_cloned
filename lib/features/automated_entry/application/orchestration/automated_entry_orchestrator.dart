import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/upload/models/upload_status.dart';

import '../../../../core/upload/manager/upload_manager.dart';
import '../../../../core/upload/models/upload_job.dart';
import '../../../modules/all_Modules/site_Details/repository/siteModel.dart';
import '../../../../typeProvider/type_provider.dart';
import '../../domain/models/automated_entry_models.dart';

class AutomatedEntryExecutionResult {
  final String? createdSiteId;
  final Map<AutomatedEntryModule, bool> moduleSuccess;
  final Map<AutomatedEntryModule, String> errors;

  const AutomatedEntryExecutionResult({
    required this.createdSiteId,
    required this.moduleSuccess,
    required this.errors,
  });

  bool get isAllSuccess => moduleSuccess.values.every((success) => success);
  bool get hasPartialSuccess =>
      moduleSuccess.values.any((success) => success) && !isAllSuccess;
}

final automatedEntryOrchestratorProvider = Provider<AutomatedEntryOrchestrator>(
    (ref) => AutomatedEntryOrchestrator(ref));

class AutomatedEntryOrchestrator {
  AutomatedEntryOrchestrator(this.ref);

  final Ref ref;

  Future<AutomatedEntryExecutionResult> execute(
      AutomatedEntryState state) async {
    final type = ref.read(typeProvider);
    if (type == null || type.isEmpty) {
      return AutomatedEntryExecutionResult(
        createdSiteId: null,
        moduleSuccess: const {
          AutomatedEntryModule.site: false,
          AutomatedEntryModule.rate: false,
          AutomatedEntryModule.manpower: false,
        },
        errors: const {
          AutomatedEntryModule.site: 'Work type is not selected',
          AutomatedEntryModule.rate: 'Work type is not selected',
          AutomatedEntryModule.manpower: 'Work type is not selected',
        },
      );
    }

    final moduleSuccess = <AutomatedEntryModule, bool>{
      for (final module in AutomatedEntryModule.values) module: false,
    };
    final errors = <AutomatedEntryModule, String>{};

    final siteDraft = state.draftOf(AutomatedEntryModule.site);
    final uploadManager = ref.read(uploadManagerProvider.notifier);

    String? createdSiteId;
    if (!siteDraft.enabled || !siteDraft.hasFile) {
      moduleSuccess[AutomatedEntryModule.site] = true;
    } else {
      try {
        final siteJobId = uploadManager.enqueue(
          UploadJob.create(
            moduleId: AutomatedEntryModule.site.moduleId,
            filePath: siteDraft.filePath!,
            metadata: {
              'type': type,
            },
            maxRetries: 2,
          ),
        );

        final siteFinalState = await uploadManager.waitForCompletion(siteJobId);
        if (siteFinalState.status == UploadStatus.success) {
          moduleSuccess[AutomatedEntryModule.site] = true;
          final response = siteFinalState.response;
          if (response is Map<String, dynamic>) {
            createdSiteId = _extractCreatedSiteId(response);
          } else {
            errors[AutomatedEntryModule.site] =
                'Site uploaded but response format is invalid.';
            moduleSuccess[AutomatedEntryModule.site] = false;
          }
        } else {
          moduleSuccess[AutomatedEntryModule.site] = false;
          errors[AutomatedEntryModule.site] = siteFinalState.message;
        }
      } catch (e) {
        errors[AutomatedEntryModule.site] = e.toString();
        moduleSuccess[AutomatedEntryModule.site] = false;
      }
    }

    Future<void> enqueueAndTrack(AutomatedEntryModule module) async {
      final draft = state.draftOf(module);
      if (!draft.enabled || !draft.hasFile) {
        moduleSuccess[module] = true;
        return;
      }
      final resolvedSiteId = _resolveSiteIdForModule(
        draft: draft,
        createdSiteId: createdSiteId,
      );

      if (resolvedSiteId == null || resolvedSiteId.isEmpty) {
        errors[module] =
            'No resolved site id for ${module.title}. Select existing site or upload site first.';
        moduleSuccess[module] = false;
        return;
      }

      final targetRoute =
          module == AutomatedEntryModule.rate ? '/site-list/rate' : '/manpower';

      final metadata = <String, dynamic>{
        'type': type,
        'siteId': resolvedSiteId,
      };

      if (module == AutomatedEntryModule.manpower) {
        if (draft.selectedManpowerConfigId != null &&
            draft.selectedManpowerConfigId!.isNotEmpty) {
          metadata['configId'] = draft.selectedManpowerConfigId;
        } else {
          final mappings = draft.confirmedManpowerMappings;
          if (mappings.isEmpty || !draft.isFullNameMapped) {
            errors[module] =
                'Manpower mapping is incomplete. Map Full Name before upload.';
            moduleSuccess[module] = false;
            return;
          }
          metadata['mappings'] = jsonEncode(
              mappings.map((e) => e.toJson()).toList(growable: false));
        }
      }

      final jobId = uploadManager.enqueue(
        UploadJob.create(
          moduleId: module.moduleId,
          filePath: draft.filePath!,
          metadata: metadata,
          targetRoute: targetRoute,
          maxRetries: 2,
        ),
      );

      try {
        final finalState = await uploadManager.waitForCompletion(jobId);
        final isSuccess = finalState.status.name == 'success';
        moduleSuccess[module] = isSuccess;
        if (!isSuccess) {
          errors[module] = finalState.message;
        }
      } catch (e) {
        moduleSuccess[module] = false;
        errors[module] = e.toString();
      }
    }

    final rateDependsOnNew =
        state.draftOf(AutomatedEntryModule.rate).siteBindingMode ==
            SiteBindingMode.uploadedInThisFlow;
    final manpowerDependsOnNew =
        state.draftOf(AutomatedEntryModule.manpower).siteBindingMode ==
            SiteBindingMode.uploadedInThisFlow;

    if ((rateDependsOnNew || manpowerDependsOnNew) &&
        !moduleSuccess[AutomatedEntryModule.site]!) {
      if (rateDependsOnNew) {
        errors[AutomatedEntryModule.rate] =
            'Blocked because site upload failed or no site id was returned.';
      }
      if (manpowerDependsOnNew) {
        errors[AutomatedEntryModule.manpower] =
            'Blocked because site upload failed or no site id was returned.';
      }
    }

    final tasks = <Future<void>>[];

    if (!rateDependsOnNew || moduleSuccess[AutomatedEntryModule.site] == true) {
      tasks.add(enqueueAndTrack(AutomatedEntryModule.rate));
    }

    if (!manpowerDependsOnNew ||
        moduleSuccess[AutomatedEntryModule.site] == true) {
      tasks.add(enqueueAndTrack(AutomatedEntryModule.manpower));
    }

    await Future.wait(tasks);

    return AutomatedEntryExecutionResult(
      createdSiteId: createdSiteId,
      moduleSuccess: moduleSuccess,
      errors: errors,
    );
  }

  String? _extractCreatedSiteId(Map<String, dynamic> response) {
    final siteJson = response['site'];
    if (siteJson is Map<String, dynamic>) {
      try {
        return SiteModel.fromJson(siteJson).id;
      } catch (_) {
        final dynamic id = siteJson['id'];
        return id?.toString();
      }
    }

    final dynamic idFromRoot = response['siteId'] ?? response['id'];
    return idFromRoot?.toString();
  }

  String? _resolveSiteIdForModule({
    required ModuleDraft draft,
    required String? createdSiteId,
  }) {
    if (draft.siteBindingMode == SiteBindingMode.existingSite) {
      return draft.selectedExistingSiteId;
    }
    return createdSiteId;
  }
}
