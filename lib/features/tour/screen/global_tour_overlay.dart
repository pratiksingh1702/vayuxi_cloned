import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/upload/ui/upload_banner.dart';
import '../../../core/router/app_access.dart';
import '../core/tour_engine.dart';
import '../core/tour_models.dart';
import '../domain/voice_assistant_service.dart';
import '../providers/tour_providers.dart';
import '../widgets/tour_tooltip_card.dart';

class GlobalTourOverlay extends ConsumerStatefulWidget {
  final Widget child;
  const GlobalTourOverlay({super.key, required this.child});

  @override
  ConsumerState<GlobalTourOverlay> createState() => _GlobalTourOverlayState();
}

class _GlobalTourOverlayState extends ConsumerState<GlobalTourOverlay> {
  String? _lastSpokenStepKey;

  Future<void> _stopTourVoice() async {
    _lastSpokenStepKey = null;
    await ref.read(voiceAssistantProvider).stop();
  }

  void _syncTourVoice({
    required bool showTour,
    required AppTourDefinition? tour,
    required AppTourStep? step,
    required int stepIndex,
  }) {
    if (!showTour || tour == null || step == null || !step.autoSpeak) {
      if (_lastSpokenStepKey != null) {
        _stopTourVoice();
      }
      return;
    }

    final voiceText = _voiceTextForStep(step)?.trim();
    if (voiceText == null || voiceText.isEmpty) {
      if (_lastSpokenStepKey != null) {
        _stopTourVoice();
      }
      return;
    }

    final stepKey = '${tour.id}:$stepIndex:${step.id}:$voiceText';
    if (_lastSpokenStepKey == stepKey) return;
    _lastSpokenStepKey = stepKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _lastSpokenStepKey != stepKey) return;
      ref.read(voiceAssistantProvider).speakHindi(voiceText);
    });
  }

  String? _voiceTextForStep(AppTourStep step) {
    final explicit = step.voiceText?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    return _moduleHindiVoiceText(step.id);
  }

  String? _moduleHindiVoiceText(String stepId) {
    if (!stepId.startsWith('pm_')) {
      return _generalHindiVoiceText(stepId);
    }
    switch (stepId) {
      case 'pm_setup_intro':
        return 'यह पी एंड एम सेटअप है। यहां पहले मशीन और पी एंड एम का नाम जोड़ते हैं। बाद में रोज की एंट्री आसान हो जाती है।';
      case 'pm_setup_site':
        return 'यह चुनी हुई साइट है। पी एंड एम की जानकारी इसी साइट में सेव होगी।';
      case 'pm_setup_categories':
        return 'यहां कैटेगरी चुनिए। जिस कैटेगरी में मशीन या काम जोड़ना है, उस पर टैप कीजिए।';
      case 'pm_setup_add_work':
        return 'नया पी एंड एम आइटम जोड़ने के लिए इस बटन पर टैप कीजिए।';
      case 'pm_setup_work_list':
        return 'यहां पहले से जोड़े हुए पी एंड एम आइटम दिखते हैं। बदलना हो तो आइटम पर टैप कीजिए।';
      case 'pm_setup_action_intro':
        return 'इस स्क्रीन पर आप चुनते हैं कि पुराने आइटम देखने हैं या नया आइटम जोड़ना है।';
      case 'pm_setup_action_buttons':
        return 'पुराने आइटम देखने के लिए व्यू वर्क्स दबाइए। नया आइटम जोड़ने के लिए ऐड वर्क दबाइए।';
      case 'pm_work_add_intro':
        return 'यह नया पी एंड एम आइटम जोड़ने का फॉर्म है। धीरे धीरे खाली जगह भरिए।';
      case 'pm_work_add_category':
        return 'यह कैटेगरी है। नया आइटम इसी कैटेगरी में सेव होगा।';
      case 'pm_work_add_name':
        return 'यहां मशीन या पी एंड एम आइटम का नाम लिखिए।';
      case 'pm_work_add_capacity':
        return 'अगर क्षमता पता है तो यहां लिखिए। जैसे दस टन, एक नंबर, या पांच एच पी।';
      case 'pm_work_add_image':
        return 'अगर फोटो है तो यहां जोड़िए। फोटो से बाद में पहचान आसान होती है।';
      case 'pm_work_add_save':
        return 'सब सही भरने के बाद सेव वर्क बटन दबाइए।';
      case 'pm_work_edit_intro':
        return 'यह पुराने पी एंड एम आइटम को देखने या बदलने की स्क्रीन है।';
      case 'pm_work_edit_header':
        return 'यह ऊपर चुना हुआ पी एंड एम आइटम और उसकी कैटेगरी दिख रही है।';
      case 'pm_work_edit_name':
        return 'नाम गलत है या बदलना है, तो यहां सही नाम लिखिए।';
      case 'pm_work_edit_capacity':
        return 'क्षमता या यूनिट बदलनी हो तो यहां बदलिए।';
      case 'pm_work_edit_image':
        return 'फोटो बदलनी हो तो यहां नई फोटो लगाइए।';
      case 'pm_work_edit_save':
        return 'बदलाव सही हों तो सेव वर्क बटन दबाइए।';
      case 'pm_entry_select_intro':
        return 'पी एंड एम एंट्री शुरू करने से पहले मशीन या आइटम चुनिए।';
      case 'pm_entry_select_work':
        return 'जिस मशीन या आइटम की आज की एंट्री भरनी है, उस कार्ड पर टैप कीजिए।';
      case 'pm_entry_form_intro':
        return 'यह रोज की पी एंड एम एंट्री का फॉर्म है। यहां आज की जानकारी भरते हैं।';
      case 'pm_entry_date':
        return 'यह एंट्री की तारीख है। दूसरी तारीख चाहिए तो यहां टैप कीजिए।';
      case 'pm_entry_work':
        return 'यह चुनी हुई मशीन या पी एंड एम आइटम है। एंट्री इसी के लिए सेव होगी।';
      case 'pm_entry_machine':
        return 'यहां मशीन नंबर, क्षमता, मालिक, और वेंडर की जानकारी भर सकते हैं।';
      case 'pm_entry_time':
        return 'मशीन कब शुरू हुई और कब बंद हुई, वह समय यहां लिखिए।';
      case 'pm_entry_hours':
        return 'कितने घंटे चली, कितने घंटे बंद रही, और कितने घंटे खाली रही, यह यहां लिखिए।';
      case 'pm_entry_fuel':
        return 'ऑपरेटर, ड्राइवर, और फ्यूल की जानकारी हो तो यहां भरिए।';
      case 'pm_entry_progress':
        return 'आज कितना हुआ, जगह कौन सी थी, और छोटा विवरण यहां लिखिए।';
      case 'pm_entry_status':
        return 'मशीन चली, खाली रही, खराब थी, या मेंटेनेंस में थी, यह यहां चुनिए।';
      case 'pm_entry_save':
        return 'सब जानकारी सही हो जाए तो सेव पी एंड एम एंट्री दबाइए।';
      case 'pm_reports_intro':
        return 'यह पी एंड एम रिपोर्ट है। यहां तारीख के हिसाब से जानकारी दिखती है।';
      case 'pm_reports_date':
        return 'जिस दिन की रिपोर्ट देखनी है, वह तारीख यहां चुनिए।';
      case 'pm_reports_summary':
        return 'इन डिब्बों में कुल मशीन, कुल एंट्री, घंटे, और फ्यूल का हिसाब दिखता है।';
      case 'pm_reports_entries':
        return 'नीचे उस तारीख की सेव की हुई एंट्री दिखती है। अगर एंट्री नहीं है, तो खाली संदेश दिखेगा।';
      default:
        return 'इस हिस्से को ध्यान से देखिए। यहां पी एंड एम की जानकारी भरनी या देखनी होती है।';
    }
  }

  String? _generalHindiVoiceText(String stepId) {
    if (stepId.startsWith('attendance_')) {
      if (stepId.contains('intro')) {
        return 'यह हाजिरी की स्क्रीन है। यहां लिखते हैं कि आज कौन आया और कौन नहीं आया।';
      }
      if (stepId.contains('save')) {
        return 'सबकी हाजिरी सही भरने के बाद सेव बटन दबाइए।';
      }
      return 'इस हिस्से में हाजिरी की जानकारी भरिए या जांचिए।';
    }
    if (stepId.startsWith('rate_')) {
      if (stepId.contains('selector')) {
        return 'रेट सेटअप में रेट देखने या नया रेट जोड़ने का रास्ता चुनिए।';
      }
      if (stepId.contains('save') || stepId.contains('submit')) {
        return 'रेट की जानकारी सही हो जाए तो सेव बटन दबाइए।';
      }
      if (stepId.contains('import') || stepId.contains('upload')) {
        return 'रेट की शीट अपलोड करने के लिए इस हिस्से का इस्तेमाल कीजिए।';
      }
      return 'यहां काम या सामान का रेट भरिए या देखिए।';
    }
    if (stepId.startsWith('team_')) {
      if (stepId.contains('save') || stepId.contains('submit')) {
        return 'टीम की जानकारी सही हो जाए तो सेव बटन दबाइए।';
      }
      return 'यहां मजदूरों की टीम बनाइए या टीम की जानकारी देखिए।';
    }
    if (stepId.startsWith('manpower_') || stepId.startsWith('man_')) {
      if (stepId.contains('save') || stepId.contains('submit')) {
        return 'मजदूर की जानकारी सही हो जाए तो सेव बटन दबाइए।';
      }
      if (stepId.contains('upload') || stepId.contains('mapping')) {
        return 'मजदूरों की शीट अपलोड करके कॉलम मिलाइए और जांचिए।';
      }
      return 'यहां मजदूर का नाम और बाकी जानकारी भरिए या देखिए।';
    }
    if (stepId.startsWith('site_') || stepId.contains('_site')) {
      return 'यहां साइट की जानकारी देखिए या सही साइट चुनिए।';
    }
    return null;
  }

  @override
  void dispose() {
    ref.read(voiceAssistantProvider).stop();
    super.dispose();
  }

  Widget _withBanners(Widget child) {
    return Stack(
      children: [
        child,
        const Positioned.fill(child: GlobalUploadBanner()),
        // const Positioned(top: 0, left: 0, right: 0, child: GlobalSyncBanner()),
      ],
    );
  }

  Rect? _targetRect(AppTourStep? step) {
    final targetContext = step?.targetKey?.currentContext;
    final renderObject = targetContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    final topLeft = renderObject.localToGlobal(Offset.zero);
    return topLeft & renderObject.size;
  }

  Widget _buildTooltip({
    required BuildContext context,
    required AppTourDefinition tour,
    required AppTourStep step,
    required AppTourState tourState,
    required AppTourController controller,
    required Rect? targetRect,
  }) {
    const horizontalInset = 12.0;
    const targetGap = 18.0;
    const estimatedTooltipHeight = 236.0;
    final media = MediaQuery.of(context);

    final pointerX = targetRect == null
        ? null
        : targetRect.center.dx - horizontalInset;

    if (targetRect == null && step.targetKey != null) {
      return const SizedBox.shrink();
    }

    if (targetRect == null) {
      return Positioned(
        left: horizontalInset,
        right: horizontalInset,
        bottom: media.padding.bottom + (step.tooltipBottomOffset ?? 14),
        child: TourTooltipCard(
          tour: tour,
          step: step,
          stepIndex: tourState.stepIndex,
          pointerX: pointerX,
          onBack: () async {
            await _stopTourVoice();
            await controller.back();
          },
          onNext: () async {
            await _stopTourVoice();
            await controller.next();
          },
          onSkip: () async {
            await _stopTourVoice();
            await controller.skip();
          },
        ),
      );
    }

    final minTop = media.padding.top + 10;
    final maxTop =
        media.size.height - media.padding.bottom - estimatedTooltipHeight - 10;
    final safeMaxTop = maxTop < minTop ? minTop : maxTop;
    final belowTop = targetRect.bottom + targetGap;
    final aboveTop = targetRect.top - estimatedTooltipHeight - targetGap;
    final hasRoomBelow = belowTop <= safeMaxTop;
    final hasRoomAbove = aboveTop >= minTop;
    final placeBelow = hasRoomBelow || !hasRoomAbove;
    final rawTop = placeBelow ? belowTop : aboveTop;
    final top = rawTop.clamp(minTop, safeMaxTop).toDouble();

    return Positioned(
      left: horizontalInset,
      right: horizontalInset,
      top: top,
      child: TourTooltipCard(
        tour: tour,
        step: step,
        stepIndex: tourState.stepIndex,
        pointerX: pointerX,
        pointerOnTop: placeBelow,
        onBack: () async {
          await _stopTourVoice();
          await controller.back();
        },
        onNext: () async {
          await _stopTourVoice();
          await controller.next();
        },
        onSkip: () async {
          await _stopTourVoice();
          await controller.skip();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(appAccessProvider);
    final isInsideApp = !access.isBooting && access.loggedIn;

    if (!isInsideApp) return _withBanners(widget.child);

    ref.watch(voiceAssistantProvider).prepareHindi();

    final tourState = ref.watch(appTourControllerProvider);
    final controller = ref.read(appTourControllerProvider.notifier);
    final tour = controller.activeTour;
    final step = controller.currentStep;
    final showTour = tourState.status == AppTourStatus.running &&
        tour != null &&
        step != null;
    final targetRect = showTour ? _targetRect(step) : null;
    final tooltipReady = showTour &&
        (step?.showTooltip ?? false) &&
        (step?.targetKey == null || targetRect != null);
    _syncTourVoice(
      showTour: tooltipReady,
      tour: tour,
      step: step,
      stepIndex: tourState.stepIndex,
    );

    return Stack(
      children: [
        widget.child,
        const Positioned.fill(child: GlobalUploadBanner()),
        // const Positioned(top: 0, left: 0, right: 0, child: GlobalSyncBanner()),
        if (showTour && !(step?.useSpotlight ?? true))
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: ColoredBox(
                color: Colors.black.withOpacity(0.68),
              ),
            ),
          ),
        if (showTour && (step?.showTooltip ?? false))
          _buildTooltip(
            context: context,
            tour: tour!,
            step: step!,
            tourState: tourState,
            controller: controller,
            targetRect: targetRect,
          ),
      ],
    );
  }
}
