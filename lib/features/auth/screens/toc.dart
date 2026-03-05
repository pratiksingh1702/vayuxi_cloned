import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter/services.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  State<TermsAndConditionsScreen> createState() =>
      _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen>
    with SingleTickerProviderStateMixin {
  String markdownData = "";
  bool _isLoading = true;
  late ScrollController _scrollController;
  double _scrollProgress = 0.0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _scrollController.addListener(_onScroll);
    loadMarkdown();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final max = _scrollController.position.maxScrollExtent;
      final current = _scrollController.offset;
      setState(() {
        _scrollProgress = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
      });
    }
  }

  Future<void> loadMarkdown() async {
    final data = await rootBundle.loadString('assets/terms.md');
    setState(() {
      markdownData = data;
      _isLoading = false;
    });
    _fadeController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primaryColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF4F8EF7);
    const surfaceColor = Color(0xFFF7F8FC);
    const cardColor = Colors.white;

    return Scaffold(
      backgroundColor: surfaceColor,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Column(
          children: [
            // Custom AppBar
            Container(
              decoration: const BoxDecoration(
                color: cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          // Back button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 18,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "Terms & Conditions",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Please read carefully",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF8A94A6),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Document icon badge
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.description_outlined,
                              size: 20,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Reading progress bar
                    Container(
                      height: 3,
                      child: LinearProgressIndicator(
                        value: _scrollProgress,
                        backgroundColor: const Color(0xFFEEF0F5),
                        valueColor:
                        const AlwaysStoppedAnimation<Color>(accentColor),
                        minHeight: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Body
            Expanded(
              child: _isLoading
                  ? _buildLoadingState(accentColor)
                  : FadeTransition(
                opacity: _fadeAnimation,
                child: _buildContent(cardColor, primaryColor, accentColor),
              ),
            ),
          ],
        ),
      ),

      // Accept button
      bottomNavigationBar: _isLoading
          ? null
          : _buildBottomBar(accentColor, primaryColor),
    );
  }

  Widget _buildLoadingState(Color accentColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Loading document...",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8A94A6),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Color cardColor, Color primaryColor, Color accentColor) {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A1A2E).withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.gavel_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Legal Agreement",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Last updated: March 2025",
                        style: TextStyle(
                          color: Color(0xFF8A99C4),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F8EF7).withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "v2.1",
                    style: TextStyle(
                      color: Color(0xFF90B4FF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Markdown content card
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Markdown(
                data: markdownData,
                selectable: true,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                styleSheet: MarkdownStyleSheet(
                  h1: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -0.5,
                    height: 1.3,
                  ),
                  h2: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -0.3,
                    height: 1.4,
                  ),
                  h3: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3A5C),
                    height: 1.4,
                  ),
                  p: const TextStyle(
                    fontSize: 14.5,
                    color: Color(0xFF4A5568),
                    height: 1.7,
                    fontWeight: FontWeight.w400,
                  ),
                  strong: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                  em: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF4A5568),
                  ),
                  listBullet: const TextStyle(
                    fontSize: 14.5,
                    color: Color(0xFF4F8EF7),
                    height: 1.7,
                  ),
                  blockquote: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7A99),
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                  ),
                  blockquoteDecoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(8),
                    border: const Border(
                      left: BorderSide(
                        color: Color(0xFF4F8EF7),
                        width: 3,
                      ),
                    ),
                  ),
                  code: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF3B5BDB),
                    fontFamily: 'monospace',
                    backgroundColor: Color(0xFFF0F4FF),
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: const Color(0xFFF7F8FC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  horizontalRuleDecoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Color(0xFFEEF0F5),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Color accentColor, Color primaryColor) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress indicator text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _scrollProgress >= 0.95
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    size: 14,
                    color: _scrollProgress >= 0.95
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF8A94A6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _scrollProgress >= 0.95
                        ? "You've read all the terms"
                        : "Scroll to read all terms (${(_scrollProgress * 100).toInt()}%)",
                    style: TextStyle(
                      fontSize: 12,
                      color: _scrollProgress >= 0.95
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF8A94A6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Accept button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle accept
                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Accept & Continue",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Decline link
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  "Decline",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8A94A6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}