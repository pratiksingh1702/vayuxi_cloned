import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../language/model/language_storage.dart';
import '../../../language/service/lang_providers.dart';
import '../../../profile_page/provider/userProvider.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  String searchText = "";
  String? selectedLanguage;
  bool isLoading = false;
  List<LanguageItem> availableLanguages = [];

  @override
  void initState() {
    super.initState();
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    setState(() => isLoading = true);

    final storage = LanguageStorage();
    final downloadedCodes = storage.getDownloadedLanguages();
    final activeLanguage = storage.getActiveLanguage();

    try {
      final user = ref.read(userNotifierProvider).user;

      final response = await ref.read(languageApiProvider).listLanguages(
        userId: user?.id,
      );

      final List<dynamic> languageList = response.data['data'];

      setState(() {
        availableLanguages = languageList.map((lang) {
          final code = lang['languageCode'];

          return LanguageItem(
            code: code,
            name: lang['languageName'],
            nativeName: lang['nativeName'],
            version: lang['version'],
            isDownloaded: downloadedCodes.contains(code),
          );
        }).toList();

        selectedLanguage = activeLanguage;
      });
    } catch (_) {
      // 🔥 OFFLINE FALLBACK
      if (downloadedCodes.isEmpty) {
        setState(() {
          availableLanguages = [];
          selectedLanguage = activeLanguage;
        });
      } else {
        setState(() {
          availableLanguages = downloadedCodes.map((code) {
            return LanguageItem(
              code: code,
              name: code, // fallback label
              nativeName: '',
              version: '',
              isDownloaded: true,
            );
          }).toList();

          selectedLanguage = activeLanguage;
        });
      }
    } finally {
      setState(() => isLoading = false);
    }
  }


  Future<void> _downloadLanguage(String languageCode) async {
    final user = ref.read(userNotifierProvider).user;
    if (user == null) return;

    setState(() => isLoading = true);

    try {
      await ref
          .read(languageRepositoryProvider)
          .downloadAndStoreLanguage(user.id, languageCode);

      setState(() {
        final index =
        availableLanguages.indexWhere((l) => l.code == languageCode);
        if (index != -1) {
          availableLanguages[index] =
              availableLanguages[index].copyWith(isDownloaded: true);
        }
      });
    } finally {
      setState(() => isLoading = false);
    }
  }


  Future<void> _saveLanguageSelection() async {
    if (selectedLanguage == null) return;

    final userState = ref.read(userNotifierProvider);
    final user = userState.user;

    if (user == null) return;

    setState(() => isLoading = true);

    try {
      final repo = ref.read(languageRepositoryProvider);
      await repo.changeLanguage(user.id, selectedLanguage!);
      ref.invalidate(languageModuleProvider);
      final selected = availableLanguages
          .firstWhere((l) => l.code == selectedLanguage);

      if (!selected.isDownloaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please download the language first'),
          ),
        );
        return;
      }



      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Language updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating language: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredLanguages = availableLanguages
        .where((lang) =>
        lang.name.toLowerCase().contains(searchText.toLowerCase().trim()))
        .toList();

    final selectedLang = availableLanguages.firstWhere(
          (lang) => lang.code == selectedLanguage,
      orElse: () => LanguageItem(
        code: '',
        name: 'None',
        nativeName: '',
        version: '',
        isDownloaded: false,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        title: const Text(
          "Choose the language",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select your preferred language below. This helps us serve you better.",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 25),

            // YOU SELECTED
            const Text(
              "You Selected",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),

            _buildSelectedLanguageCard(selectedLang),

            const SizedBox(height: 25),

            // ALL LANGUAGES
            const Text(
              "All Languages",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            _buildSearchBox(),

            const SizedBox(height: 10),

            Expanded(
              child: ListView(
                children: filteredLanguages
                    .map((lang) => _buildLanguageTile(lang))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Back"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: isLoading ? null : _saveLanguageSelection,
                child: const Text(
                  "Save & Submit",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedLanguageCard(LanguageItem lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue, width: 1.3),
        borderRadius: BorderRadius.circular(12),
        color: Colors.blue.withOpacity(0.05),
      ),
      child: Row(
        children: [
          Text(
            lang.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 18, color: Colors.white),
          )
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      onChanged: (value) => setState(() => searchText = value),
      decoration: InputDecoration(
        hintText: "Search",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildLanguageTile(LanguageItem lang) {
    final bool isSelected = selectedLanguage == lang.code;

    return GestureDetector(
      onTap: () {
        if (!lang.isDownloaded) {
          _showDownloadDialog(lang);
        } else {
          setState(() => selectedLanguage = lang.code);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lang.nativeName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (!lang.isDownloaded)
              const Icon(Icons.download, color: Colors.grey, size: 20)
            else
              Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
          ],
        ),
      ),
    );
  }

  void _showDownloadDialog(LanguageItem lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Language'),
        content: Text(
          'The ${lang.name} language pack is not downloaded. Would you like to download it now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadLanguage(lang.code);
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }
}

// Model class for language items
class LanguageItem {
  final String code;
  final String name;
  final String nativeName;
  final String version;
  final bool isDownloaded;

  LanguageItem({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.version,
    required this.isDownloaded,
  });

  LanguageItem copyWith({
    String? code,
    String? name,
    String? nativeName,
    String? version,
    bool? isDownloaded,
  }) {
    return LanguageItem(
      code: code ?? this.code,
      name: name ?? this.name,
      nativeName: nativeName ?? this.nativeName,
      version: version ?? this.version,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}