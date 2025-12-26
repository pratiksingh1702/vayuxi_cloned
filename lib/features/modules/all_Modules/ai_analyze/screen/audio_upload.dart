import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';

import '../model/ai_analyze_model.dart';
import '../service/audio_analyze_service.dart';
import 'package:untitled2/features/modules/all_Modules/expense/service/expense_service.dart';
import 'package:untitled2/features/modules/all_Modules/team/provider/teamProvider.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import 'package:untitled2/features/modules/all_Modules/attendance/provider/AttendanceProvider.dart';
import 'package:untitled2/features/modules/all_Modules/attendance/provider/AttendanceService.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/providers/dprService.dart';
import 'package:untitled2/features/modules/all_Modules/inventory/service/inventory_service.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import '../service/utils/attendance_util.dart';

class AudioUploadAnalysisScreen extends ConsumerStatefulWidget {
  const AudioUploadAnalysisScreen({super.key});

  @override
  ConsumerState<AudioUploadAnalysisScreen> createState() =>
      _AudioUploadAnalysisScreenState();
}

class _AudioUploadAnalysisScreenState
    extends ConsumerState<AudioUploadAnalysisScreen> {
  // Recording state
  bool isLoading = false;
  bool isRecording = false;
  bool isPlayingBack = false;
  int recordingSeconds = 0;
  final recorder = AudioRecorder();
  String? recordedPath;
  File? audioFile;
  late Timer? _recordingTimer;

  // Audio Waveforms
  late RecorderController recorderController;
  late PlayerController playerController;

  // Analysis data state
  AudioAnalysis? _analysisData;
  bool _isSubmitting = false;
  bool _hasData = false;
  bool _audioReadyForAnalysis = false; // New flag to track if audio is ready for analysis

  // Controllers
  late TextEditingController _transcriptCtrl;
  late TextEditingController _remarksCtrl;
  final List<TextEditingController> _attendanceControllers = [];
  late TextEditingController _dprMaterialCtrl;
  late TextEditingController _dprLineSizeCtrl;
  late TextEditingController _dprLengthCtrl;
  final List<_DprItemRow> _dprItems = [];
  late TextEditingController _expenseTotalCtrl;
  final List<_ExpenseItemRow> _expenseItems = [];
  final List<_InventoryItemRow> _inventoryItems = [];

  @override
  void initState() {
    super.initState();
    _recordingTimer = null;

    // Initialize audio waveforms controllers
    recorderController = RecorderController();
    playerController = PlayerController();

    _initializeEmptyControllers();
  }

  void _initializeEmptyControllers() {
    _transcriptCtrl = TextEditingController();
    _remarksCtrl = TextEditingController();
    _attendanceControllers.add(TextEditingController());
    _dprMaterialCtrl = TextEditingController();
    _dprLineSizeCtrl = TextEditingController();
    _dprLengthCtrl = TextEditingController();
    _dprItems.add(_DprItemRow(
      itemNameCtrl: TextEditingController(),
      qtyCtrl: TextEditingController(),
      unitCtrl: TextEditingController(),
    ));
    _expenseTotalCtrl = TextEditingController();
    _expenseItems.add(_ExpenseItemRow(
      nameCtrl: TextEditingController(),
      qtyCtrl: TextEditingController(),
      unitCtrl: TextEditingController(),
    ));
    _inventoryItems.add(_InventoryItemRow(
      nameCtrl: TextEditingController(),
      qtyCtrl: TextEditingController(),
      unitCtrl: TextEditingController(),
    ));
  }

  void _initializeControllersFromData(AudioAnalysis data) {
    _transcriptCtrl = TextEditingController(text: data.metadata.transcript);
    _remarksCtrl = TextEditingController(text: data.metadata.siteRemarks);

    // attendance initialization
    final attendance = data.modules.attendance;
    _attendanceControllers.clear();
    if (attendance.absentNames.isNotEmpty) {
      for (final name in attendance.absentNames) {
        _attendanceControllers.add(TextEditingController(text: name));
      }
    } else {
      _attendanceControllers.add(TextEditingController());
    }

    // DPR
    final dpr = data.modules.dpr;
    _dprMaterialCtrl = TextEditingController(text: dpr.material ?? "");
    _dprLineSizeCtrl = TextEditingController(text: dpr.lineSize ?? "");
    _dprLengthCtrl = TextEditingController(text: dpr.length.toString() ?? "");
    _dprItems.clear();
    if (dpr.items.isNotEmpty) {
      for (final it in dpr.items) {
        _dprItems.add(_DprItemRow(
          itemNameCtrl: TextEditingController(text: it.itemName),
          qtyCtrl: TextEditingController(text: it.quantity?.toString() ?? ""),
          unitCtrl: TextEditingController(text: it.unit ?? ""),
        ));
      }
    } else {
      _dprItems.add(_DprItemRow(
        itemNameCtrl: TextEditingController(),
        qtyCtrl: TextEditingController(),
        unitCtrl: TextEditingController(),
      ));
    }

    // Expense
    final expense = data.modules.expense;
    _expenseTotalCtrl =
        TextEditingController(text: expense.totalAmount?.toString() ?? "");
    _expenseItems.clear();
    if (expense.items.isNotEmpty) {
      for (final it in expense.items) {
        _expenseItems.add(_ExpenseItemRow(
          nameCtrl: TextEditingController(text: it.name),
          qtyCtrl: TextEditingController(text: it.qty?.toString() ?? ""),
          unitCtrl: TextEditingController(text: it.unit ?? ""),
        ));
      }
    } else {
      _expenseItems.add(_ExpenseItemRow(
        nameCtrl: TextEditingController(),
        qtyCtrl: TextEditingController(),
        unitCtrl: TextEditingController(),
      ));
    }

    // Inventory
    final inv = data.modules.inventory;
    _inventoryItems.clear();
    if (inv.items.isNotEmpty) {
      for (final it in inv.items) {
        _inventoryItems.add(_InventoryItemRow(
          nameCtrl: TextEditingController(text: it.name),
          qtyCtrl: TextEditingController(text: it.qty?.toString() ?? ""),
          unitCtrl: TextEditingController(text: it.unit ?? ""),
        ));
      }
    } else {
      _inventoryItems.add(_InventoryItemRow(
        nameCtrl: TextEditingController(),
        qtyCtrl: TextEditingController(),
        unitCtrl: TextEditingController(),
      ));
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    _recordingTimer?.cancel();
    recorder.dispose();
    recorderController.dispose();
    playerController.dispose();
    super.dispose();
  }

  void _disposeControllers() {
    _transcriptCtrl.dispose();
    _remarksCtrl.dispose();
    for (final c in _attendanceControllers) {
      c.dispose();
    }
    _dprMaterialCtrl.dispose();
    _dprLineSizeCtrl.dispose();
    _dprLengthCtrl.dispose();
    for (final r in _dprItems) {
      r.dispose();
    }
    _expenseTotalCtrl.dispose();
    for (final r in _expenseItems) {
      r.dispose();
    }
    for (final r in _inventoryItems) {
      r.dispose();
    }
  }

  void _startTimer() {
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        recordingSeconds++;
      });
    });
  }

  void _stopTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    setState(() {
      recordingSeconds = 0;
    });
  }

  String get _formattedTime {
    final minutes = (recordingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (recordingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // -----------------------------------------
  // PICK FILE
  // -----------------------------------------
  Future<void> pickAndUploadAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ["mp3", "m4a", "wav", "aac"],
        dialogTitle: 'Select Audio File',
        allowCompression: true,
      );

      if (result == null) return;

      File file = File(result.files.single.path!);
      setState(() {
        audioFile = file;
        recordedPath = file.path;
        _hasData = false;
        _analysisData = null;
        _audioReadyForAnalysis = true;
      });
    } catch (e) {
      _showErrorSnackbar("Error: $e");
    }
  }

  // -----------------------------------------
  // START RECORDING
  // -----------------------------------------
  Future<void> startRecording() async {
    if (!await recorder.hasPermission()) {
      _showErrorSnackbar("Microphone permission denied.");
      return;
    }

    // Get temporary directory for recording
    final dir = await getTemporaryDirectory();
    recordedPath =
    "${dir.path}/user_recording_${DateTime.now().millisecondsSinceEpoch}.m4a";

    // Start recording with audio_waveforms
    await recorderController.record(
        path: recordedPath!,
        recorderSettings: RecorderSettings(
          androidEncoderSettings: AndroidEncoderSettings(
            androidEncoder: AndroidEncoder.wav,
          ),
          bitRate: 128000,
        )
    );

    setState(() {
      isRecording = true;
      _audioReadyForAnalysis = false;
    });
    _startTimer();
  }

  // -----------------------------------------
  // STOP RECORDING
  // -----------------------------------------
  Future<void> stopAndProcess() async {
    _stopTimer();

    // Stop recording
    final path = await recorderController.stop();

    setState(() => isRecording = false);

    if (path == null || path.isEmpty) return;

    File file = File(path);
    setState(() {
      audioFile = file;
      _audioReadyForAnalysis = true;
    });
  }

  // -----------------------------------------
  // SEND AUDIO FOR ANALYSIS (Manual Trigger)
  // -----------------------------------------
  Future<void> _sendAudioForAnalysis() async {
    if (audioFile == null || !audioFile!.existsSync()) {
      _showErrorSnackbar("No audio file available to analyze");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      AudioAnalysis analysis = await AudioAnalyzeService.uploadAudio(audioFile!);
      setState(() {
        _analysisData = analysis;
        _hasData = true;
        _audioReadyForAnalysis = false;
      });
      _initializeControllersFromData(analysis);
      _showSuccessSnackbar("Audio analysis completed successfully!");
    } catch (e) {
      _showErrorSnackbar("Error analyzing audio: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // -----------------------------------------
  // PLAY AUDIO
  // -----------------------------------------
  Future<void> playRecordedAudio() async {
    if (recordedPath == null || !File(recordedPath!).existsSync()) return;

    try {
      setState(() {
        isPlayingBack = true;
      });

      await playerController.preparePlayer(
        path: recordedPath!,
        shouldExtractWaveform: true,
        noOfSamples: 100,
      );

      await playerController.startPlayer();

      // Listen for playback completion
      playerController.onCompletion.listen((_) {
        setState(() {
          isPlayingBack = false;
        });
      });
    } catch (e) {
      setState(() {
        isPlayingBack = false;
      });
      _showErrorSnackbar("Failed to play audio: $e");
    }
  }

  // -----------------------------------------
  // STOP PLAYBACK
  // -----------------------------------------
  Future<void> stopPlayback() async {
    await playerController.stopPlayer();
    setState(() {
      isPlayingBack = false;
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // -----------------------------------------
  // SUBMIT TO BACKEND
  // -----------------------------------------
  Future<void> _submitToBackend() async {
    if (_analysisData == null) return;

    final siteId = ref.read(selectedSiteIdProvider);
    final teamId = ref.read(selectedTeamIdProvider);
    final type = ref.read(typeProvider);

    if (siteId == null || type == null) {
      _showErrorSnackbar("Site ID or Type is missing");
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // build edited data
    final editedAbsentNames = _attendanceControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final editedDprItems = _dprItems
        .map((r) => {
      "item_name": r.itemNameCtrl.text.trim(),
      "qty": double.tryParse(r.qtyCtrl.text.trim()) ?? 0,
      "unit": r.unitCtrl.text.trim(),
    })
        .where((m) => (m["item_name"] as String).isNotEmpty)
        .toList();

    final editedExpenseItems = _expenseItems
        .map((r) => {
      "item": r.nameCtrl.text.trim(),
      "qty": double.tryParse(r.qtyCtrl.text.trim()) ?? 0,
      "unit": r.unitCtrl.text.trim(),
    })
        .where((m) => (m["item"] as String).isNotEmpty)
        .toList();

    final editedInventoryItems = _inventoryItems
        .map((r) => {
      "name": r.nameCtrl.text.trim(),
      "qty": double.tryParse(r.qtyCtrl.text.trim()) ?? 0,
      "unit": r.unitCtrl.text.trim(),
    })
        .where((m) => (m["name"] as String).isNotEmpty)
        .toList();

    // Update analysis data locally
    _analysisData!.metadata.transcript = _transcriptCtrl.text.trim();
    _analysisData!.metadata.siteRemarks = _remarksCtrl.text.trim();
    _analysisData!.modules.attendance.absentNames = editedAbsentNames;

    try {
      // ----- VALIDATE AND SUBMIT ATTENDANCE -----
      await _submitAttendance(
        absentNames: editedAbsentNames,
        siteId: siteId,
        type: type,
        date: DateTime.now(),
      );

      // ----- DPR -----
      await DprApi.postDprWork(
        siteId: siteId,
        teamId: teamId!,
        data: {
          "material": _dprMaterialCtrl.text.trim(),
          "line_size": _dprLineSizeCtrl.text.trim(),
          "length": double.tryParse(_dprLengthCtrl.text.trim()) ?? 0,
          "items": editedDprItems,
        },
      );

      // ----- EXPENSE -----
      await ExpenseAPI.createExpense(
        siteId: siteId,
        type: type,
        data: {
          "total": double.tryParse(_expenseTotalCtrl.text.trim()) ?? 0,
          "items": editedExpenseItems,
        },
      );

      _showSuccessSnackbar("Data submitted successfully!");
    } catch (e) {
      _showErrorSnackbar("Error: $e");
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _submitAttendance({
    required List<String> absentNames,
    required String siteId,
    required String type,
    required DateTime date,
  }) async {
    try {
      // Validate manpower names
      final invalidNames = await ManpowerUtils.validateManpowerNames(
        names: absentNames,
        type: type,
        ref: ref,
      );

      if (invalidNames.isNotEmpty) {
        throw Exception("Invalid manpower names: ${invalidNames.join(", ")}");
      }

      // Create payload
      final payload = await ManpowerUtils.createAttendancePayload(
        absentNames: absentNames,
        siteId: siteId,
        type: type,
        date: date,
        ref: ref,
      );

      final shouldUpdate = await ManpowerUtils.shouldUpdateAttendance(
        siteId: siteId,
        type: type,
        date: date,
      );

      if (shouldUpdate) {
        await ref
            .read(attendanceNotifierProvider.notifier)
            .updateMultipleAttendance(
          payload: payload,
          type: type,
          siteId: siteId,
          date: ManpowerUtils.formatDateForDisplay(date),
        );
      } else {
        await ref
            .read(attendanceNotifierProvider.notifier)
            .postMultipleAttendance(
          payload: payload,
          type: type,
          siteId: siteId,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  void _resetToOriginal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text("Reset Confirmation"),
          ],
        ),
        content: const Text(
          "Are you sure you want to reset all changes? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (_analysisData != null) {
                setState(() {
                  _disposeControllers();
                  _initializeControllersFromData(_analysisData!);
                });
              }
              _showSuccessSnackbar("All data reset to original");
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("Reset", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------
  // BEAUTIFUL UI
  // -----------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "AI Audio Analysis",
      ),
      backgroundColor: AppColors.lightBlue,
      body: CornerClippedScreenSimple(
        child: Column(
          children: [
            // Main Content Area
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: isLoading
                      ? _buildLoadingState()
                      : _hasData
                      ? _buildAnalysisContent()
                      : _buildUpperEmptyState(),
                ),
              ),
            ),

            // Bottom Recording Bar
            _buildRecordingBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildUpperEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        // Audio Player Section if audio is ready
        if (_audioReadyForAnalysis) ...[
          _buildAudioPreviewSection(),
          const SizedBox(height: 30),
        ],

        // Main empty state
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _audioReadyForAnalysis ? Icons.audio_file : Icons.audio_file_rounded,
                size: 64,
                color: _audioReadyForAnalysis ? Colors.blue : Colors.deepPurple.withOpacity(0.7),
              ),
              const SizedBox(height: 20),
              Text(
                _audioReadyForAnalysis ? "Audio Ready for Analysis" : "No Audio Analyzed Yet",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _audioReadyForAnalysis ? Colors.blue : Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _audioReadyForAnalysis
                    ? "Preview your audio, then send it for AI analysis"
                    : "Record audio using the bar below or upload a file",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              if (_audioReadyForAnalysis) ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _sendAudioForAnalysis,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.send_rounded),
                      SizedBox(width: 8),
                      Text("Send for AI Analysis"),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      audioFile = null;
                      recordedPath = null;
                      _audioReadyForAnalysis = false;
                    });
                  },
                  child: const Text(
                    "Choose Different Audio",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ] else ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: pickAndUploadAudio,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.upload_file_rounded),
                      SizedBox(width: 8),
                      Text("Upload Audio File"),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAudioPreviewSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.audiotrack_rounded, color: Colors.blue.shade700),
              const SizedBox(width: 10),
              const Text(
                "Audio Preview",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  audioFile != null ? "Uploaded" : "Recorded",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Waveform Preview
          Container(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: AudioWaveforms(
                      size: Size(MediaQuery.of(context).size.width - 120, 50),
                      recorderController:recorderController,
                      waveStyle: WaveStyle(
                        showDurationLabel: true,
                        spacing: 8,
                        showBottom: false,
                        extendWaveform: true,
                        showMiddleLine: false,
                        waveColor: Colors.blue,
                        durationLinesColor: Colors.grey.shade300,
                        durationStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 10,
                        ),
                        waveThickness: 2.5,
                      ),
                      enableGesture: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Playback Control
                  _buildAudioPlaybackControl(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlaybackControl() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isPlayingBack ? stopPlayback : playRecordedAudio,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isPlayingBack ? Colors.red.shade100 : Colors.blue.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isPlayingBack ? Icons.stop_rounded : Icons.play_arrow_rounded,
            color: isPlayingBack ? Colors.red.shade700 : Colors.blue.shade700,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 100),
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              const Text(
                "Analyzing Audio...",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Please wait while we analyze your audio content",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisContent() {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        _buildTranscriptSection(),
        const SizedBox(height: 20),
        _buildRemarksSection(),
        const SizedBox(height: 20),
        _buildAttendanceEditor(),
        const SizedBox(height: 20),
        _buildDprEditor(),
        const SizedBox(height: 20),
        _buildExpenseEditor(),
        const SizedBox(height: 20),
        _buildInventoryEditor(),
        const SizedBox(height: 28),
        _buildSubmitButton(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRecordingBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, -3),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Waveform Section
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isRecording || recordedPath != null
                ? Container(
              key: ValueKey(isRecording ? 'recording' : 'recorded'),
              height: 70,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Status Indicator
                  Container(
                    width: 4,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: isRecording
                          ? Colors.red
                          : recordedPath != null
                          ? Colors.green
                          : Colors.blue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Waveform
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRecording ? "Recording..." :
                          _audioReadyForAnalysis ? "Ready to Analyze" : "Audio Available",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: AudioWaveforms(
                            size: Size(
                              MediaQuery.of(context).size.width - 140,
                              35,
                            ),
                            recorderController: recorderController,
                            waveStyle: WaveStyle(
                              showDurationLabel: true,
                              spacing: 6,
                              showBottom: false,
                              extendWaveform: true,
                              showMiddleLine: false,
                              waveColor: isRecording
                                  ? Colors.red.shade400
                                  : _audioReadyForAnalysis ? Colors.blue : Colors.deepPurple,
                              durationLinesColor: Colors.grey.shade300,
                              durationStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 10,
                              ),
                              waveThickness: 2.5,
                            ),
                            enableGesture: true,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Playback Controls
                  if (recordedPath != null && !isRecording) ...[
                    const SizedBox(width: 8),
                    _buildPlaybackControl(),
                  ],
                ],
              ),
            )
                : const SizedBox.shrink(),
          ),

          // Control Bar
          Row(
            children: [
              // Upload File Button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLoading ? Colors.grey.shade200 : Colors.deepPurple.shade50,
                ),
                child: IconButton(
                  onPressed: isLoading ? null : pickAndUploadAudio,
                  icon: Icon(
                    Icons.upload_rounded,
                    color: isLoading ? Colors.grey.shade400 : Colors.deepPurple,
                    size: 24,
                  ),
                  tooltip: "Upload Audio File",
                  splashRadius: 20,
                ),
              ),

              // Status Display
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: isRecording
                            ? Row(
                          key: const ValueKey('recording'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red,
                              ),
                              margin: const EdgeInsets.only(right: 8),
                            ),
                            Text(
                              _formattedTime,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.red.shade700,
                                fontFamily: 'SFMono',
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        )
                            : _hasData
                            ? Row(
                          key: const ValueKey('analyzed'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green.shade600,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Analysis Complete",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        )
                            : _audioReadyForAnalysis
                            ? Column(
                          key: const ValueKey('ready'),
                          children: [
                            Text(
                              "Audio Ready",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Tap send to analyze",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue.shade500,
                              ),
                            ),
                          ],
                        )
                            : Column(
                          key: const ValueKey('initial'),
                          children: [
                            Text(
                              "Ready to Record",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Tap mic or upload file",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Recording Progress (optional)
                      if (isRecording)
                        LinearProgressIndicator(
                          value: recorderController.currentScrolledDuration.value.toDouble() ?? 0.0,
                          backgroundColor: Colors.grey.shade200,
                          color: Colors.red,
                          minHeight: 2,
                          borderRadius: BorderRadius.circular(1),
                        ),
                    ],
                  ),
                ),
              ),

              // Record/Stop Button
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: isRecording
                      ? [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ]
                      : null,
                ),
                child: Material(
                  type: MaterialType.transparency,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () {
                      if (isRecording) {
                        stopAndProcess();
                      } else {
                        startRecording();
                      }
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isRecording
                            ? Colors.red
                            : Colors.deepPurple.withOpacity(0.1),
                        gradient: isRecording
                            ? RadialGradient(
                          center: Alignment.center,
                          radius: 1.2,
                          colors: [
                            Colors.red.shade300,
                            Colors.red.shade600,
                          ],
                        )
                            : null,
                        border: Border.all(
                          color: isRecording
                              ? Colors.red.shade300
                              : Colors.deepPurple.withOpacity(0.3),
                          width: isRecording ? 2 : 1.5,
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: isRecording
                            ? Icon(
                          Icons.stop_rounded,
                          key: const ValueKey('stop'),
                          color: Colors.white,
                          size: 26,
                        )
                            : Icon(
                          Icons.mic_rounded,
                          key: const ValueKey('mic'),
                          color: Colors.deepPurple,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isPlayingBack ? stopPlayback : playRecordedAudio,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isPlayingBack ? Colors.red.shade50 : Colors.green.shade50,
              border: Border.all(
                color: isPlayingBack ? Colors.red.shade100 : Colors.green.shade100,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPlayingBack ? Icons.stop : Icons.play_arrow_rounded,
                  color: isPlayingBack ? Colors.red.shade600 : Colors.green.shade700,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  isPlayingBack ? "Stop" : "Play",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPlayingBack ? Colors.red.shade600 : Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.analytics, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                "AI Analysis Review",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.refresh, size: 20, color: Colors.orange),
                ),
                tooltip: "Reset to original",
                onPressed: _resetToOriginal,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Review and edit the extracted data before submitting to the system.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptSection() {
    return _buildSection(
      title: "Transcript",
      icon: Icons.transcribe,
      iconColor: Colors.blue,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
        ),
        child: TextField(
          controller: _transcriptCtrl,
          maxLines: 6,
          style: const TextStyle(fontSize: 14),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.all(16),
            border: InputBorder.none,
            hintText: "Enter transcript text...",
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildRemarksSection() {
    return _buildSection(
      title: "Site Remarks",
      icon: Icons.comment,
      iconColor: Colors.green,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
        ),
        child: TextField(
          controller: _remarksCtrl,
          maxLines: 3,
          style: const TextStyle(fontSize: 14),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.all(16),
            border: InputBorder.none,
            hintText: "Enter site remarks...",
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildAttendanceEditor() {
    return _buildSection(
      title: "Attendance - Absent Team Members",
      icon: Icons.people_alt,
      iconColor: Colors.purple,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Absent Names", Icons.person_off),
              const SizedBox(height: 16),
              ..._attendanceControllers.asMap().entries.map((entry) {
                final i = entry.key;
                final ctrl = entry.value;
                return _buildAttendanceRow(i, ctrl);
              }).toList(),
              if (_attendanceControllers.isEmpty)
                _buildEmptyState("No absent names added", Icons.people_outline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceRow(int index, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "Enter absent team member name",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              _buildRowActions(
                onRemove: _attendanceControllers.length == 1
                    ? null
                    : () {
                  setState(() {
                    controller.dispose();
                    _attendanceControllers.removeAt(index);
                  });
                },
                onAdd: () {
                  setState(() {
                    _attendanceControllers.insert(
                        index + 1, TextEditingController());
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDprEditor() {
    return _buildSection(
      title: "DPR - Daily Progress Report",
      icon: Icons.construction,
      iconColor: Colors.orange,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Work Details", Icons.work),
              const SizedBox(height: 16),
              _buildDprFormFields(),
              const SizedBox(height: 20),
              _buildSectionHeader("Materials & Items", Icons.inventory_2),
              const SizedBox(height: 12),
              ..._dprItems.asMap().entries.map((entry) {
                final i = entry.key;
                final row = entry.value;
                return _buildDprItemRow(i, row);
              }).toList(),
              if (_dprItems.isEmpty)
                _buildEmptyState("No DPR items added", Icons.list_alt),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDprFormFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildLabeledTextField(
                controller: _dprMaterialCtrl,
                label: "Material",
                hintText: "e.g., PVC, Steel",
                icon: Icons.architecture,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLabeledTextField(
                controller: _dprLineSizeCtrl,
                label: "Line Size",
                hintText: "e.g., 2 inch",
                icon: Icons.straighten,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildLabeledTextField(
          controller: _dprLengthCtrl,
          label: "Length (meters)",
          hintText: "0.0",
          icon: Icons.square_foot,
          isNumber: true,
        ),
      ],
    );
  }

  Widget _buildDprItemRow(int index, _DprItemRow row) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Item",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  _buildRowActions(
                    onRemove: _dprItems.length == 1
                        ? null
                        : () {
                      setState(() {
                        row.dispose();
                        _dprItems.removeAt(index);
                      });
                    },
                    onAdd: () {
                      setState(() {
                        _dprItems.insert(
                          index + 1,
                          _DprItemRow(
                            itemNameCtrl: TextEditingController(),
                            qtyCtrl: TextEditingController(),
                            unitCtrl: TextEditingController(),
                          ),
                        );
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: row.itemNameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Item Name",
                        border: OutlineInputBorder(),
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: row.qtyCtrl,
                      keyboardType:
                      TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: "Quantity",
                        border: OutlineInputBorder(),
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: row.unitCtrl,
                      decoration: const InputDecoration(
                        labelText: "Unit",
                        border: OutlineInputBorder(),
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseEditor() {
    return _buildSection(
      title: "Expenses",
      icon: Icons.attach_money,
      iconColor: Colors.green,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Total Expense", Icons.calculate),
              const SizedBox(height: 12),
              _buildLabeledTextField(
                controller: _expenseTotalCtrl,
                label: "Total Amount (₹)",
                hintText: "0.00",
                icon: Icons.currency_rupee,
                isNumber: true,
              ),
              const SizedBox(height: 20),
              _buildSectionHeader("Expense Items", Icons.receipt),
              const SizedBox(height: 12),
              ..._expenseItems.asMap().entries.map((entry) {
                final i = entry.key;
                final r = entry.value;
                return _buildExpenseItemRow(i, r);
              }).toList(),
              if (_expenseItems.isEmpty)
                _buildEmptyState("No expense items added", Icons.money_off),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseItemRow(int index, _ExpenseItemRow r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Expense Item",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  _buildRowActions(
                    onRemove: _expenseItems.length == 1
                        ? null
                        : () {
                      setState(() {
                        r.dispose();
                        _expenseItems.removeAt(index);
                      });
                    },
                    onAdd: () {
                      setState(() {
                        _expenseItems.insert(
                          index + 1,
                          _ExpenseItemRow(
                            nameCtrl: TextEditingController(),
                            qtyCtrl: TextEditingController(),
                            unitCtrl: TextEditingController(),
                          ),
                        );
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: r.nameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Item Name",
                        border: OutlineInputBorder(),
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: r.qtyCtrl,
                      keyboardType:
                      TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: "Quantity",
                        border: OutlineInputBorder(),
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: r.unitCtrl,
                      decoration: const InputDecoration(
                        labelText: "Unit",
                        border: OutlineInputBorder(),
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryEditor() {
    return _buildSection(
      title: "Inventory",
      icon: Icons.inventory,
      iconColor: Colors.blue,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Inventory Items", Icons.palette),
              const SizedBox(height: 12),
              ..._inventoryItems.asMap().entries.map((entry) {
                final i = entry.key;
                final r = entry.value;
                return _buildInventoryItemRow(i, r);
              }).toList(),
              if (_inventoryItems.isEmpty)
                _buildEmptyState(
                    "No inventory items added", Icons.inventory_2_outlined),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryItemRow(int index, _InventoryItemRow r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Inventory Item",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  _buildRowActions(
                    onRemove: _inventoryItems.length == 1
                        ? null
                        : () {
                      setState(() {
                        r.dispose();
                        _inventoryItems.removeAt(index);
                      });
                    },
                    onAdd: () {
                      setState(() {
                        _inventoryItems.insert(
                          index + 1,
                          _InventoryItemRow(
                            nameCtrl: TextEditingController(),
                            qtyCtrl: TextEditingController(),
                            unitCtrl: TextEditingController(),
                          ),
                        );
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: r.nameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Item Name",
                        border: OutlineInputBorder(),
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: r.qtyCtrl,
                      keyboardType:
                      TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: "Quantity",
                        border: OutlineInputBorder(),
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: r.unitCtrl,
                      decoration: const InputDecoration(
                        labelText: "Unit",
                        border: OutlineInputBorder(),
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumber
              ? TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            prefixIcon: Icon(icon, size: 20),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildRowActions({
    required VoidCallback? onRemove,
    required VoidCallback onAdd,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color:
              onRemove == null ? Colors.grey.shade300 : Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.remove,
              size: 16,
              color: onRemove == null ? Colors.grey.shade500 : Colors.red,
            ),
          ),
          onPressed: onRemove,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, size: 16, color: Colors.green),
          ),
          onPressed: onAdd,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border:
        Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting || !_hasData ? null : _submitToBackend,
        style: ElevatedButton.styleFrom(
          backgroundColor: _hasData
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade400,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSubmitting)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              const Icon(Icons.cloud_upload, size: 20),
            const SizedBox(width: 8),
            Text(
              _isSubmitting
                  ? "Submitting..."
                  : _hasData
                  ? "Submit All Data to API"
                  : "No Data to Submit",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Helper Row Classes ----------------

class _DprItemRow {
  final TextEditingController itemNameCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController unitCtrl;
  _DprItemRow({
    required this.itemNameCtrl,
    required this.qtyCtrl,
    required this.unitCtrl,
  });

  void dispose() {
    itemNameCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
  }
}

class _ExpenseItemRow {
  final TextEditingController nameCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController unitCtrl;
  _ExpenseItemRow({
    required this.nameCtrl,
    required this.qtyCtrl,
    required this.unitCtrl,
  });
  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
  }
}

class _InventoryItemRow {
  final TextEditingController nameCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController unitCtrl;
  _InventoryItemRow({
    required this.nameCtrl,
    required this.qtyCtrl,
    required this.unitCtrl,
  });
  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
  }
}