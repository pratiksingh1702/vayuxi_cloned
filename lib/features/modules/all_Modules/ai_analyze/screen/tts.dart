import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsTestPage extends StatefulWidget {
  @override
  _TtsTestPageState createState() => _TtsTestPageState();
}

class _TtsTestPageState extends State<TtsTestPage> {
  final FlutterTts flutterTts = FlutterTts();

  List<dynamic> languages = [];
  List<dynamic> voices = [];
  String? selectedLanguage;
  String? selectedVoice;

  double pitch = 1.0;
  double rate = 0.5;
  double volume = 1.0;

  TextEditingController textController =
  TextEditingController(text: "Hello! This is a TTS test.");

  @override
  void initState() {
    super.initState();
    initTts();
  }

  Future<void> initTts() async {
    languages = await flutterTts.getLanguages;
    voices = await flutterTts.getVoices;

    print("LANGUAGES: $languages");
    print("VOICES: $voices");

    setState(() {});
  }

  Future<void> speak() async {
    await flutterTts.setLanguage(selectedLanguage ?? "en-US");
    await flutterTts.setPitch(pitch);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setVolume(volume);

    if (selectedVoice != null) {
      await flutterTts.setVoice({"name": selectedVoice!, "locale": selectedLanguage!});
    }

    await flutterTts.speak(textController.text);
  }

  Future<void> stop() async {
    await flutterTts.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("TTS Full Test UI")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TEXT INPUT
            TextField(
              controller: textController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Text to Speak",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            /// LANGUAGE DROPDOWN
            Text("Language", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              isExpanded: true,
              value: selectedLanguage,
              hint: Text("Select Language"),
              items: languages
                  .cast<String>()            // 👈 FIX (forces String type)
                  .map((lang) => DropdownMenuItem<String>(
                value: lang,
                child: Text(lang),
              ))
                  .toList(),
              onChanged: (val) {
                setState(() => selectedLanguage = val);
              },
            ),

            const SizedBox(height: 20),

            /// VOICE DROPDOWN
            Text("Voice", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              isExpanded: true,
              value: selectedVoice,
              hint: Text("Select Voice"),
              items: voices.map((v) {
                final name = v["name"]?.toString();
                final locale = v["locale"]?.toString();

                return DropdownMenuItem<String>(
                  value: name,
                  child: Text("$name ($locale)"),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => selectedVoice = val);
              },
            ),

            const SizedBox(height: 20),

            /// PITCH SLIDER
            Text("Pitch (${pitch.toStringAsFixed(1)})"),
            Slider(
              value: pitch,
              min: 0.5,
              max: 2.0,
              onChanged: (val) => setState(() => pitch = val),
            ),

            /// RATE SLIDER
            Text("Rate (${rate.toStringAsFixed(2)})"),
            Slider(
              value: rate,
              min: 0.1,
              max: 1.0,
              onChanged: (val) => setState(() => rate = val),
            ),

            /// VOLUME SLIDER
            Text("Volume (${volume.toStringAsFixed(1)})"),
            Slider(
              value: volume,
              min: 0.0,
              max: 1.0,
              onChanged: (val) => setState(() => volume = val),
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: speak,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Text("Speak"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: stop,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text("Stop"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            /// QUICK TEST BUTTONS FOR LANGUAGES
            Text("Quick Test", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Wrap(
              spacing: 10,
              children: [
                ElevatedButton(
                    onPressed: () async {
                      selectedLanguage = "en-US";
                      textController.text = "This is English.";
                      speak();
                    },
                    child: Text("English")),
                ElevatedButton(
                    onPressed: () async {
                      selectedLanguage = "hi-IN";
                      textController.text = "यह हिंदी भाषा है।";
                      speak();
                    },
                    child: Text("Hindi")),
                ElevatedButton(
                    onPressed: () async {
                      selectedLanguage = "gu-IN";
                      textController.text = "આ ગુજરતી ભાષા છે.";
                      speak();
                    },
                    child: Text("Gujarati")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
