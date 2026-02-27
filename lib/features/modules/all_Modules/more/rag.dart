// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:mobile_rag_engine/mobile_rag_engine.dart';
// import 'package:syncfusion_flutter_pdf/pdf.dart';
//
// // ─────────────────────────────────────────────
// //  Data models
// // ─────────────────────────────────────────────
//
// enum IndexStatus { idle, indexing, ready, error }
//
// class IndexedFile {
//   final String name;
//   final String type;
//   final int chunkCount;
//   final DateTime indexedAt;
//
//   IndexedFile({
//     required this.name,
//     required this.type,
//     required this.chunkCount,
//     required this.indexedAt,
//   });
// }
//
// // ─────────────────────────────────────────────
// //  Screen
// // ─────────────────────────────────────────────
//
// class RagScreen extends StatefulWidget {
//   const RagScreen({super.key});
//
//   @override
//   State<RagScreen> createState() => _RagScreenState();
// }
//
// class _RagScreenState extends State<RagScreen>
//     with SingleTickerProviderStateMixin {
//   // Controllers
//   final TextEditingController _docController = TextEditingController();
//   final TextEditingController _questionController = TextEditingController();
//   final ScrollController _resultScrollController = ScrollController();
//
//   // State
//   IndexStatus _status = IndexStatus.idle;
//   String _result = '';
//   String _statusMessage = '';
//   double _indexProgress = 0;
//   int _processedChunks = 0;
//   int _totalChunks = 0;
//   bool _isSearching = false;
//   List<IndexedFile> _indexedFiles = [];
//
//   late TabController _tabController;
//
//   // ── Theme colours ──────────────────────────
//   static const _bg = Color(0xFF0F1117);
//   static const _surface = Color(0xFF1A1D27);
//   static const _surfaceHigh = Color(0xFF242736);
//   static const _accent = Color(0xFF6C63FF);
//   static const _accentSoft = Color(0xFF9B93FF);
//   static const _success = Color(0xFF3DD68C);
//   static const _warning = Color(0xFFF5A623);
//   static const _danger = Color(0xFFFF5C5C);
//   static const _textPrimary = Color(0xFFF0F0F8);
//   static const _textSecondary = Color(0xFF8B8FA8);
//   static const _border = Color(0xFF2E3146);
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     _docController.dispose();
//     _questionController.dispose();
//     _resultScrollController.dispose();
//     super.dispose();
//   }
//
//   // ─────────────────────────────────────────
//   //  Helpers
//   // ─────────────────────────────────────────
//
//   Future<void> _ensureIndexReady() async {
//     if (!MobileRag.instance.isIndexReady) {
//       await MobileRag.instance.warmupFuture;
//     }
//   }
//
//   void _setStatus(IndexStatus s, String message) {
//     setState(() {
//       _status = s;
//       _statusMessage = message;
//     });
//   }
//
//   void _updateProgress(int processed, int total) {
//     setState(() {
//       _processedChunks = processed;
//       _totalChunks = total;
//       _indexProgress = total > 0 ? processed / total : 0;
//     });
//   }
//
//   // ─────────────────────────────────────────
//   //  PDF extraction  (page-streamed for large files)
//   // ─────────────────────────────────────────
//
//   /// Extracts and indexes PDF page-by-page to avoid loading the whole
//   /// document text into memory at once. Each page becomes its own chunk
//   /// so the RAG engine gets fine-grained metadata.
//   Future<int> _indexPdfStreaming(File file, String fileName) async {
//     await _ensureIndexReady();
//
//     _setStatus(IndexStatus.indexing, 'Extracting text...');
//
//     final bytes = await file.readAsBytes();
//     final document = PdfDocument(inputBytes: bytes);
//     final extractor = PdfTextExtractor(document);
//
//     final buffer = StringBuffer();
//
//     final totalPages = document.pages.count;
//
//     for (int i = 0; i < totalPages; i++) {
//       final pageText = extractor.extractText(
//         startPageIndex: i,
//         endPageIndex: i,
//       );
//
//       if (pageText.trim().isNotEmpty) {
//         buffer.writeln(pageText);
//       }
//
//       // show extraction progress
//       _updateProgress(i + 1, totalPages);
//     }
//
//     document.dispose();
//
//     final fullText = buffer.toString();
//
//     if (fullText.trim().isEmpty) {
//       throw Exception('No extractable text found. This PDF may be image-based.');
//     }
//
//     _setStatus(IndexStatus.indexing, 'Indexing & embedding...');
//
//     int chunkCount = 0;
//
//     await MobileRag.instance.addDocument(
//       fullText,
//       name: fileName,
//
//       strategy: ChunkingStrategy.recursive,
//       onProgress: (processed, total) {
//         chunkCount = total;
//         _updateProgress(processed, total);
//       },
//     );
//
//     return chunkCount;
//   }
//
//   // ─────────────────────────────────────────
//   //  Large text / DOCX / MD file indexing
//   // ─────────────────────────────────────────
//
//   /// Reads plain-text files and indexes them with chunking strategy +
//   /// live progress callback. Uses `addDocument` once so the engine
//   /// handles optimal chunk sizing.
//   Future<int> _indexTextFile(File file, String fileName,
//       {ChunkingStrategy strategy = ChunkingStrategy.markdown}) async {
//     await _ensureIndexReady();
//     // Stream-read in chunks to avoid OOM on huge files
//     final content = await file
//         .openRead()
//         .transform(utf8.decoder)
//         .join();
//     int chunkCount = 0;
//
//     await MobileRag.instance.addDocument(
//       content,
//       name: fileName,
//       filePath: file.path,
//       metadata: 'file_${fileName.hashCode}',
//       strategy: strategy,
//       onProgress: (processed, total) {
//         chunkCount = total;
//         _updateProgress(processed, total);
//       },
//     );
//
//     return chunkCount > 0 ? chunkCount : 1;
//   }
//
//   // ─────────────────────────────────────────
//   //  Actions
//   // ─────────────────────────────────────────
//
//   Future<void> _addText() async {
//     final text = _docController.text.trim();
//     if (text.isEmpty) return;
//
//     _setStatus(IndexStatus.indexing, 'Indexing text…');
//     setState(() => _indexProgress = 0);
//
//     try {
//       await MobileRag.instance.addDocument(
//         text,
//         strategy: ChunkingStrategy.recursive,
//         onProgress: (p, t) => _updateProgress(p, t),
//       );
//       await _ensureIndexReady();
//
//       _indexedFiles.add(IndexedFile(
//         name: 'Manual text (${text.length} chars)',
//         type: 'txt',
//         chunkCount: _totalChunks > 0 ? _totalChunks : 1,
//         indexedAt: DateTime.now(),
//       ));
//
//       _docController.clear();
//       _setStatus(IndexStatus.ready, 'Text indexed successfully');
//       _tabController.animateTo(1); // jump to files tab
//     } catch (e) {
//       _setStatus(IndexStatus.error, 'Error: $e');
//     }
//   }
//
//   Future<void> _uploadFile() async {
//     final picked = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['pdf', 'docx', 'txt', 'md'],
//       allowMultiple: true,
//     );
//     if (picked == null || picked.files.isEmpty) return;
//
//     for (final pf in picked.files) {
//       if (pf.path == null) continue;
//       final file = File(pf.path!);
//       final ext = pf.extension?.toLowerCase() ?? 'txt';
//       final name = pf.name;
//
//       _setStatus(IndexStatus.indexing, 'Indexing $name…');
//       setState(() {
//         _indexProgress = 0;
//         _processedChunks = 0;
//         _totalChunks = 0;
//       });
//
//       try {
//         int chunks;
//         if (ext == 'pdf') {
//           chunks = await _indexPdfStreaming(file, name);
//         } else {
//           final strategy = ext == 'md'
//               ? ChunkingStrategy.markdown
//               : ChunkingStrategy.recursive;
//           chunks = await _indexTextFile(file, name, strategy: strategy);
//         }
//
//         await _ensureIndexReady();
//
//         setState(() {
//           _indexedFiles.add(IndexedFile(
//             name: name,
//             type: ext,
//             chunkCount: chunks,
//             indexedAt: DateTime.now(),
//           ));
//         });
//
//         _setStatus(IndexStatus.ready, '$name indexed ($chunks chunks)');
//         print('$name indexed ($chunks chunks)');
//       } catch (e) {
//         _setStatus(IndexStatus.error, 'Error indexing $name: $e');
//       }
//     }
//   }
//
//   Future<void> _askQuestion() async {
//     final q = _questionController.text.trim();
//     if (q.isEmpty) return;
//
//     setState(() {
//       _isSearching = true;
//       _result = '';
//     });
//
//     try {
//       await _ensureIndexReady();
//
//       final res = await MobileRag.instance.search(
//         q,
//         tokenBudget: 800,
//         topK: 5, // reduce noise
//       );
//
//       // 1️⃣ Deduplicate chunks
//       final uniqueChunks = {
//         for (var chunk in res.chunks) chunk.chunkId: chunk
//       }.values.toList();
//
//       final chunks = uniqueChunks.map((c) => c.content).toList();
//
//       // 2️⃣ Prepare query words
//       final queryWords =
//       q.toLowerCase().split(RegExp(r'\W+')).toSet();
//
//       // 3️⃣ Filter chunks containing query words
//       final filtered = chunks.where((c) =>
//           queryWords.any((w) => c.toLowerCase().contains(w))
//       ).toList();
//
//       // 4️⃣ Extract best answer
//       final answer = extractBestAnswer(
//         q,
//         filtered.isNotEmpty ? filtered : chunks,
//       );
//
//       setState(() => _result = answer);
//
//     } catch (e) {
//       setState(() => _result = 'Search error: $e');
//     } finally {
//       setState(() => _isSearching = false);
//     }
//   }
//   String extractBestAnswer(String query, List<String> chunks) {
//     final queryWords = query.toLowerCase().split(RegExp(r'\W+')).toSet();
//
//     final scoredSentences = <MapEntry<String, int>>[];
//
//     for (final chunk in chunks) {
//       final sentences = chunk.split(RegExp(r'(?<=[.!?])\s+'));
//
//       for (final sentence in sentences) {
//         final words = sentence.toLowerCase().split(RegExp(r'\W+'));
//         int score = 0;
//
//         for (final word in words) {
//           if (queryWords.contains(word)) {
//             score++;
//           }
//         }
//
//         if (score > 0) {
//           scoredSentences.add(MapEntry(sentence.trim(), score));
//         }
//       }
//     }
//
//     scoredSentences.sort((a, b) => b.value.compareTo(a.value));
//
//     return scoredSentences.take(5).map((e) => e.key).join(' ');
//   }
//   Future<void> _clearIndex() async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         backgroundColor: _surface,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: const Text('Clear all data?',
//             style: TextStyle(color: _textPrimary)),
//         content: const Text(
//           'This will permanently remove all indexed documents.',
//           style: TextStyle(color: _textSecondary),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel', style: TextStyle(color: _textSecondary)),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Clear', style: TextStyle(color: _danger)),
//           ),
//         ],
//       ),
//     );
//
//     if (confirmed != true) return;
//
//     await MobileRag.instance.clearAllData();
//     setState(() {
//       _result = '';
//       _indexedFiles.clear();
//       _status = IndexStatus.idle;
//       _statusMessage = '';
//     });
//
//     if (mounted) {
//       _showToast('Index cleared');
//     }
//   }
//
//   void _showToast(String msg) {
//     ScaffoldMessenger.of(context).clearSnackBars();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg, style: const TextStyle(color: _textPrimary)),
//         backgroundColor: _surfaceHigh,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         margin: const EdgeInsets.all(16),
//       ),
//     );
//   }
//
//   // ─────────────────────────────────────────
//   //  UI helpers
//   // ─────────────────────────────────────────
//
//   Color get _statusColor {
//     switch (_status) {
//       case IndexStatus.indexing:
//         return _warning;
//       case IndexStatus.ready:
//         return _success;
//       case IndexStatus.error:
//         return _danger;
//       default:
//         return _textSecondary;
//     }
//   }
//
//   IconData get _statusIcon {
//     switch (_status) {
//       case IndexStatus.indexing:
//         return Icons.sync_rounded;
//       case IndexStatus.ready:
//         return Icons.check_circle_rounded;
//       case IndexStatus.error:
//         return Icons.error_rounded;
//       default:
//         return Icons.circle_outlined;
//     }
//   }
//
//   String _fileTypeIcon(String ext) {
//     switch (ext) {
//       case 'pdf':
//         return '📄';
//       case 'docx':
//         return '📝';
//       case 'md':
//         return '🗒️';
//       default:
//         return '📃';
//     }
//   }
//
//   // ─────────────────────────────────────────
//   //  Build
//   // ─────────────────────────────────────────
//
//   @override
//   Widget build(BuildContext context) {
//     return Theme(
//       data: ThemeData.dark().copyWith(
//         scaffoldBackgroundColor: _bg,
//         colorScheme: const ColorScheme.dark(
//           primary: _accent,
//           secondary: _accentSoft,
//           surface: _surface,
//         ),
//       ),
//       child: Scaffold(
//         backgroundColor: _bg,
//         appBar: _buildAppBar(),
//         body: Column(
//           children: [
//             _buildStatusBanner(),
//             if (_status == IndexStatus.indexing) _buildProgressBar(),
//             _buildTabBar(),
//             Expanded(
//               child: TabBarView(
//                 controller: _tabController,
//                 children: [
//                   _buildAddTab(),
//                   _buildFilesTab(),
//                   _buildSearchTab(),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       backgroundColor: _bg,
//       elevation: 0,
//       titleSpacing: 20,
//       title: Row(
//         children: [
//           Container(
//             width: 36,
//             height: 36,
//             decoration: BoxDecoration(
//               gradient: const LinearGradient(
//                 colors: [_accent, Color(0xFF9B63FF)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: const Icon(Icons.memory_rounded, color: Colors.white, size: 20),
//           ),
//           const SizedBox(width: 12),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'RAG Engine',
//                 style: TextStyle(
//                   color: _textPrimary,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w700,
//                   letterSpacing: 0.3,
//                 ),
//               ),
//               Text(
//                 '${_indexedFiles.length} doc${_indexedFiles.length == 1 ? '' : 's'} indexed',
//                 style: const TextStyle(color: _textSecondary, fontSize: 11),
//               ),
//             ],
//           ),
//         ],
//       ),
//       actions: [
//         IconButton(
//           icon: const Icon(Icons.delete_sweep_rounded, color: _textSecondary),
//           tooltip: 'Clear index',
//           onPressed: _indexedFiles.isEmpty ? null : _clearIndex,
//         ),
//         const SizedBox(width: 8),
//       ],
//     );
//   }
//
//   Widget _buildStatusBanner() {
//     if (_status == IndexStatus.idle) return const SizedBox.shrink();
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//       decoration: BoxDecoration(
//         color: _statusColor.withOpacity(0.1),
//         border: Border.all(color: _statusColor.withOpacity(0.3)),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Row(
//         children: [
//           Icon(_statusIcon, color: _statusColor, size: 16),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               _statusMessage,
//               style: TextStyle(color: _statusColor, fontSize: 13),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildProgressBar() {
//     print(   '$_processedChunks / $_totalChunks chunks');
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           ClipRRect(
//             borderRadius: BorderRadius.circular(4),
//             child: LinearProgressIndicator(
//               value: _indexProgress > 0 ? _indexProgress : null,
//               backgroundColor: _border,
//               valueColor: const AlwaysStoppedAnimation<Color>(_accent),
//               minHeight: 5,
//             ),
//           ),
//           if (_totalChunks > 0) ...[
//             const SizedBox(height: 4),
//             Text(
//               '$_processedChunks / $_totalChunks chunks',
//               style: const TextStyle(color: _textSecondary, fontSize: 11),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTabBar() {
//     return Container(
//       margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
//       decoration: BoxDecoration(
//         color: _surface,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: _border),
//       ),
//       child: TabBar(
//         controller: _tabController,
//         indicator: BoxDecoration(
//           color: _accent,
//           borderRadius: BorderRadius.circular(10),
//         ),
//         indicatorSize: TabBarIndicatorSize.tab,
//         labelColor: Colors.white,
//         unselectedLabelColor: _textSecondary,
//         labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
//         dividerColor: Colors.transparent,
//         tabs: const [
//           Tab(text: 'Add'),
//           Tab(text: 'Files'),
//           Tab(text: 'Search'),
//         ],
//       ),
//     );
//   }
//
//   // ── Tab: Add ──────────────────────────────
//
//   Widget _buildAddTab() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Upload card
//           _card(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _sectionLabel('Upload Files', Icons.upload_file_rounded),
//                 const SizedBox(height: 8),
//                 const Text(
//                   'Supports PDF (streamed page-by-page), DOCX, TXT, and Markdown. Multiple files can be selected at once.',
//                   style: TextStyle(color: _textSecondary, fontSize: 13, height: 1.5),
//                 ),
//                 const SizedBox(height: 16),
//                 SizedBox(
//                   width: double.infinity,
//                   child: _accentButton(
//                     label: 'Choose Files',
//                     icon: Icons.folder_open_rounded,
//                     onTap: _status == IndexStatus.indexing ? null : _uploadFile,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),
//
//           // Text card
//           _card(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _sectionLabel('Paste Text', Icons.text_snippet_rounded),
//                 const SizedBox(height: 12),
//                 TextField(
//                   controller: _docController,
//                   maxLines: 7,
//                   style: const TextStyle(
//                     color: _textPrimary,
//                     fontSize: 13,
//                     height: 1.6,
//                     fontFamily: 'monospace',
//                   ),
//                   decoration: InputDecoration(
//                     hintText: 'Paste your document content here…',
//                     hintStyle: const TextStyle(color: _textSecondary, fontSize: 13),
//                     filled: true,
//                     fillColor: _bg,
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                       borderSide: const BorderSide(color: _border),
//                     ),
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                       borderSide: const BorderSide(color: _border),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                       borderSide: const BorderSide(color: _accent, width: 1.5),
//                     ),
//                     contentPadding: const EdgeInsets.all(14),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 SizedBox(
//                   width: double.infinity,
//                   child: _accentButton(
//                     label: 'Index Text',
//                     icon: Icons.add_circle_outline_rounded,
//                     onTap: _status == IndexStatus.indexing ? null : _addText,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ── Tab: Files ────────────────────────────
//
//   Widget _buildFilesTab() {
//     if (_indexedFiles.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(Icons.folder_off_rounded, color: _textSecondary.withOpacity(0.4), size: 52),
//             const SizedBox(height: 12),
//             const Text('No files indexed yet',
//                 style: TextStyle(color: _textSecondary, fontSize: 14)),
//             const SizedBox(height: 6),
//             const Text('Go to the Add tab to get started.',
//                 style: TextStyle(color: _textSecondary, fontSize: 12)),
//           ],
//         ),
//       );
//     }
//
//     return ListView.separated(
//       padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
//       itemCount: _indexedFiles.length,
//       separatorBuilder: (_, __) => const SizedBox(height: 8),
//       itemBuilder: (_, i) {
//         final f = _indexedFiles[i];
//         return _card(
//           child: Row(
//             children: [
//               Container(
//                 width: 44,
//                 height: 44,
//                 decoration: BoxDecoration(
//                   color: _bg,
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(color: _border),
//                 ),
//                 child: Center(
//                   child: Text(_fileTypeIcon(f.type), style: const TextStyle(fontSize: 22)),
//                 ),
//               ),
//               const SizedBox(width: 14),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       f.name,
//                       style: const TextStyle(
//                         color: _textPrimary,
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 3),
//                     Text(
//                       '${f.chunkCount} chunks  ·  ${_timeAgo(f.indexedAt)}',
//                       style: const TextStyle(color: _textSecondary, fontSize: 12),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: _success.withOpacity(0.12),
//                   borderRadius: BorderRadius.circular(6),
//                   border: Border.all(color: _success.withOpacity(0.3)),
//                 ),
//                 child: Text(
//                   f.type.toUpperCase(),
//                   style: const TextStyle(color: _success, fontSize: 10, fontWeight: FontWeight.w700),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   String _timeAgo(DateTime dt) {
//     final diff = DateTime.now().difference(dt);
//     if (diff.inSeconds < 60) return 'just now';
//     if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
//     return '${diff.inHours}h ago';
//   }
//
//   // ── Tab: Search ───────────────────────────
//
//   Widget _buildSearchTab() {
//     print(_result);
//     return SingleChildScrollView(
//       controller: _resultScrollController,
//       padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _card(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _sectionLabel('Semantic Search', Icons.search_rounded),
//                 const SizedBox(height: 12),
//                 TextField(
//                   controller: _questionController,
//                   style: const TextStyle(color: _textPrimary, fontSize: 14),
//                   decoration: InputDecoration(
//                     hintText: 'Ask a question about your documents…',
//                     hintStyle: const TextStyle(color: _textSecondary, fontSize: 13),
//                     filled: true,
//                     fillColor: _bg,
//                     prefixIcon: const Icon(Icons.lightbulb_outline_rounded,
//                         color: _textSecondary, size: 20),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                       borderSide: const BorderSide(color: _border),
//                     ),
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                       borderSide: const BorderSide(color: _border),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                       borderSide: const BorderSide(color: _accent, width: 1.5),
//                     ),
//                     contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//                   ),
//                   onSubmitted: (_) => _askQuestion(),
//                 ),
//                 const SizedBox(height: 12),
//                 SizedBox(
//                   width: double.infinity,
//                   child: _accentButton(
//                     label: _isSearching ? 'Searching…' : 'Search',
//                     icon: Icons.travel_explore_rounded,
//                     onTap: _isSearching || _indexedFiles.isEmpty ? null : _askQuestion,
//                   ),
//                 ),
//                 if (_indexedFiles.isEmpty) ...[
//                   const SizedBox(height: 10),
//                   const Center(
//                     child: Text(
//                       'Index at least one document to enable search',
//                       style: TextStyle(color: _textSecondary, fontSize: 12),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),
//           if (_isSearching)
//             const Center(
//               child: Padding(
//                 padding: EdgeInsets.symmetric(vertical: 32),
//                 child: CircularProgressIndicator(
//                   valueColor: AlwaysStoppedAnimation<Color>(_accent),
//                   strokeWidth: 2.5,
//                 ),
//               ),
//             ),
//           if (_result.isNotEmpty && !_isSearching) ...[
//             Row(
//               children: const [
//                 Icon(Icons.format_quote_rounded, color: _accentSoft, size: 18),
//                 SizedBox(width: 6),
//                 Text('Retrieved Context',
//                     style: TextStyle(
//                       color: _accentSoft,
//                       fontSize: 13,
//                       fontWeight: FontWeight.w600,
//                     )),
//               ],
//             ),
//             const SizedBox(height: 10),
//             _card(
//               accentBorder: true,
//               child: SelectableText(
//                 _result,
//                 style: const TextStyle(
//                   color: _textPrimary,
//                   fontSize: 14,
//                   height: 1.7,
//                 ),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   // ─────────────────────────────────────────
//   //  Reusable widgets
//   // ─────────────────────────────────────────
//
//   Widget _card({required Widget child, bool accentBorder = false}) {
//     debugPrint("Result $_result", wrapWidth: 1024);
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: _surface,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//           color: accentBorder ? _accent.withOpacity(0.4) : _border,
//         ),
//       ),
//       child: child,
//     );
//   }
//
//   Widget _sectionLabel(String title, IconData icon) {
//     return Row(
//       children: [
//         Icon(icon, color: _accentSoft, size: 18),
//         const SizedBox(width: 8),
//         Text(
//           title,
//           style: const TextStyle(
//             color: _textPrimary,
//             fontSize: 15,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _accentButton({
//     required String label,
//     required IconData icon,
//     VoidCallback? onTap,
//   }) {
//     final disabled = onTap == null;
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 150),
//         height: 48,
//         decoration: BoxDecoration(
//           gradient: disabled
//               ? null
//               : const LinearGradient(
//             colors: [_accent, Color(0xFF9B63FF)],
//             begin: Alignment.centerLeft,
//             end: Alignment.centerRight,
//           ),
//           color: disabled ? _surfaceHigh : null,
//           borderRadius: BorderRadius.circular(12),
//           border: disabled ? Border.all(color: _border) : null,
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon,
//                 color: disabled ? _textSecondary : Colors.white, size: 18),
//             const SizedBox(width: 8),
//             Text(
//               label,
//               style: TextStyle(
//                 color: disabled ? _textSecondary : Colors.white,
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }