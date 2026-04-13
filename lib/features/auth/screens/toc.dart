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
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.onSurface;
    final accentColor = colorScheme.primary;
    final surfaceColor = colorScheme.surface;
    final cardColor = colorScheme.surfaceContainerLow;

    return Scaffold(
      backgroundColor: surfaceColor,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: theme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Column(
          children: [
            // Custom AppBar
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
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
                                child: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 18,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
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
                                const SizedBox(height: 2),
                                Text(
                                  "Please read carefully",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
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
                            child: Icon(
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
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
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
                      child:
                          _buildContent(cardColor, primaryColor, accentColor),
                    ),
            ),
          ],
        ),
      ),

      // Accept button
      bottomNavigationBar:
          _isLoading ? null : _buildBottomBar(accentColor, primaryColor),
    );
  }

  Widget _buildLoadingState(Color accentColor) {
    final colorScheme = Theme.of(context).colorScheme;
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
          Text(
            "Loading document...",
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Color cardColor, Color primaryColor, Color accentColor) {
    final colorScheme = Theme.of(context).colorScheme;
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
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.secondaryContainer
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.16),
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
                    color: colorScheme.surface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.gavel_rounded,
                    color: colorScheme.onPrimaryContainer,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Legal Agreement",
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Last updated: March 2025",
                        style: TextStyle(
                          color:
                              colorScheme.onPrimaryContainer.withOpacity(0.75),
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
                    color: accentColor.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "v2.1",
                    style: TextStyle(
                      color: accentColor,
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
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
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
                  h1: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                    height: 1.3,
                  ),
                  h2: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.3,
                    height: 1.4,
                  ),
                  h3: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    height: 1.4,
                  ),
                  p: TextStyle(
                    fontSize: 14.5,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.7,
                    fontWeight: FontWeight.w400,
                  ),
                  strong: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  em: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  listBullet: TextStyle(
                    fontSize: 14.5,
                    color: accentColor,
                    height: 1.7,
                  ),
                  blockquote: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                  ),
                  blockquoteDecoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(
                        color: accentColor,
                        width: 3,
                      ),
                    ),
                  ),
                  code: TextStyle(
                    fontSize: 13,
                    color: accentColor,
                    fontFamily: 'monospace',
                    backgroundColor:
                        colorScheme.secondaryContainer.withOpacity(0.45),
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  horizontalRuleDecoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(
                            color: colorScheme.outlineVariant, width: 1.5)),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
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
                          ? colorScheme.tertiary
                          : colorScheme.onSurfaceVariant,
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
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded,
                          size: 20, color: colorScheme.onPrimary),
                      const SizedBox(width: 8),
                      Text(
                        "Accept & Continue",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: colorScheme.onPrimary,
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
                    color: Colors.grey,
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
