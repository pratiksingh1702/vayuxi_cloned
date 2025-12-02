import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';

import '../model/ai_analyze_model.dart';
import '../service/audio_analyze_service.dart';
import 'single_page_ui.dart';

class AudioUploadScreen extends ConsumerStatefulWidget {
  const AudioUploadScreen({super.key});

  @override
  ConsumerState<AudioUploadScreen> createState() => _AudioUploadScreenState();
}

class _AudioUploadScreenState extends ConsumerState<AudioUploadScreen> {
  bool isLoading = false;
  bool isRecording = false;
  int recordingSeconds = 0;
  final recorder = AudioRecorder();
  String? recordedPath;
  late Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _recordingTimer = null;
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    recorder.dispose();
    super.dispose();
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

      setState(() => isLoading = true);

      AudioAnalysis analysis = await AudioAnalyzeService.uploadAudio(file);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisReviewScreen(data: analysis),
        ),
      );
    } catch (e) {
      if (mounted) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // -----------------------------------------
  // START RECORDING
  // -----------------------------------------
  Future<void> startRecording() async {
    if (!await recorder.hasPermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Microphone permission denied."),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    recordedPath = "${dir.path}/user_recording_${DateTime.now().millisecondsSinceEpoch}.m4a";

    await recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: recordedPath!,
    );

    setState(() {
      isRecording = true;
    });
    _startTimer();
  }

  // -----------------------------------------
  // STOP RECORDING + UPLOAD
  // -----------------------------------------
  Future<void> stopAndUpload() async {
    _stopTimer();
    final path = await recorder.stop();
    setState(() => isRecording = false);

    if (path == null) return;

    setState(() => isLoading = true);

    try {
      AudioAnalysis analysis = await AudioAnalyzeService.uploadAudio(File(path));

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisReviewScreen(data: analysis),
        ),
      );
    } catch (e) {
      print(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // -----------------------------------------
  // BEAUTIFUL UI
  // -----------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "AI Audio"),
      backgroundColor: AppColors.lightBlue,
      body: CornerClippedScreenSimple(
        child: SingleChildScrollView(
          child: SafeArea(
            child: Center(
              child: isLoading
                  ? _buildLoadingState()
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
        
                  const SizedBox(height: 50),
          
                  // Pick File Button
                  _buildFilePickerButton(),
                  const SizedBox(height: 40),
          
                  // Or Divider
                  _buildOrDivider(),
                  const SizedBox(height: 40),
          
                  // Record Section
                  _buildRecordSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
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
              Text(
                isRecording ? "Processing Recording..." : "Processing Audio...",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Please wait while we analyze your audio",
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

  Widget _buildHeader() {
    return const Column(
      children: [
        Icon(
          Icons.audio_file_rounded,
          size: 64,
          color: Colors.white,
        ),
        SizedBox(height: 20),
        Text(
          "Choose Your Audio Source",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "Upload an existing audio file or record a new one for analysis",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildFilePickerButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.deepPurple,
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: pickAndUploadAudio,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.upload_file_rounded,
              size: 24,
              color: Colors.deepPurple,
            ),
            const SizedBox(width: 12),
            const Text(
              "Choose Audio File",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.black,
            thickness: 1,
            indent: 40,
            endIndent: 20,
          ),
        ),
        Text(
          "OR",
          style: TextStyle(
            color:Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.black,
            thickness: 1,
            indent: 20,
            endIndent: 40,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated Mic Icon
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isRecording ? Colors.red.withOpacity(0.1) : Colors.deepPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.mic_rounded,
                  size: 48,
                  color: isRecording ? Colors.red : Colors.deepPurple,
                ),
                if (isRecording)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fiber_manual_record_rounded,
                        color: Colors.white,
                        size: 8,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Recording Status
          Text(
            isRecording ? "Recording..." : "Record New Audio",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isRecording ? Colors.red : Colors.deepPurple,
            ),
          ),

          if (isRecording) ...[
            const SizedBox(height: 8),
            Text(
              _formattedTime,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red,
                fontFamily: 'monospace',
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Record/Stop Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isRecording ? Colors.red : Colors.deepPurple,
              foregroundColor: Colors.white,
              elevation: 6,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              if (isRecording) {
                stopAndUpload();
              } else {
                startRecording();
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isRecording ? "Stop & Analyze" : "Start Recording",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          if (!isRecording) ...[
            const SizedBox(height: 12),
            Text(
              "Record high-quality audio for analysis",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}