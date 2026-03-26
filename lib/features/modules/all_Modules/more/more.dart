// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
//
// import 'more.dart' as _nameController;
//
//
// // ==============================
// // DATA MODELS
// // ==============================
//
// enum ConstructionStatus { pending, active, completed }
//
// class ConstructionZone {
//   final String id;
//   String name;
//   String task;
//   int manpower;
//   ConstructionStatus status;
//   Offset position;
//   bool isPin;
//
//   ConstructionZone({
//     required this.name,
//     required this.task,
//     required this.manpower,
//     required this.status,
//     required this.position,
//     this.isPin = false,
//   }) : id = DateTime.now().microsecondsSinceEpoch.toString();
//
//   Color get color {
//     switch (status) {
//       case ConstructionStatus.pending:
//         return Colors.orange;
//       case ConstructionStatus.active:
//         return Colors.blue;
//       case ConstructionStatus.completed:
//         return Colors.green;
//     }
//   }
//
//   // Copy with method for updating
//   ConstructionZone copyWith({
//     String? name,
//     String? task,
//     int? manpower,
//     ConstructionStatus? status,
//     Offset? position,
//     bool? isPin,
//   }) {
//     return ConstructionZone(
//       name: name ?? this.name,
//       task: task ?? this.task,
//       manpower: manpower ?? this.manpower,
//       status: status ?? this.status,
//       position: position ?? this.position,
//       isPin: isPin ?? this.isPin,
//     );
//   }
// }
//
// class ConstructionSite {
//   final List<ConstructionZone> zones = [];
//   double zoom = 1.0;
//   Offset panOffset = Offset.zero;
// }
//
// // ==============================
// // RIVERPOD PROVIDERS
// // ==============================
//
// final siteProvider = StateNotifierProvider<SiteNotifier, ConstructionSite>(
//       (ref) => SiteNotifier(),
// );
//
// class SiteNotifier extends StateNotifier<ConstructionSite> {
//   SiteNotifier() : super(ConstructionSite());
//
//   void addZone(ConstructionZone zone) {
//     final newSite = ConstructionSite()
//       ..zones.addAll(state.zones)
//       ..zones.add(zone)
//       ..zoom = state.zoom
//       ..panOffset = state.panOffset;
//     state = newSite;
//   }
//
//   void updateZone(String id, ConstructionZone updatedZone) {
//     final newZones = state.zones.map((zone) {
//       if (zone.id == id) {
//         return updatedZone;
//       }
//       return zone;
//     }).toList();
//
//     final newSite = ConstructionSite()
//       ..zones.addAll(newZones)
//       ..zoom = state.zoom
//       ..panOffset = state.panOffset;
//     state = newSite;
//   }
//
//   void removeZone(String id) {
//     final newSite = ConstructionSite()
//       ..zones.addAll(state.zones.where((zone) => zone.id != id))
//       ..zoom = state.zoom
//       ..panOffset = state.panOffset;
//     state = newSite;
//   }
//
//   void updateZoom(double zoom) {
//     final newSite = ConstructionSite()
//       ..zones.addAll(state.zones)
//       ..zoom = zoom
//       ..panOffset = state.panOffset;
//     state = newSite;
//   }
//
//   void updatePan(Offset offset) {
//     final newSite = ConstructionSite()
//       ..zones.addAll(state.zones)
//       ..zoom = state.zoom
//       ..panOffset = offset;
//     state = newSite;
//   }
// }
//
// // ==============================
// // MAIN APP
// // ==============================
//
//
//
// // ==============================
// // MAIN SCREEN
// // ==============================
//
// class ConstructionSiteScreen extends ConsumerWidget {
//   const ConstructionSiteScreen({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final site = ref.watch(siteProvider);
//     final notifier = ref.read(siteProvider.notifier);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Construction Canvas Demo'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add),
//             onPressed: () => _addSampleZone(notifier),
//             tooltip: 'Add Sample Zone',
//           ),
//           IconButton(
//             icon: const Icon(Icons.delete_sweep),
//             onPressed: () => notifier.state = ConstructionSite(),
//             tooltip: 'Clear All',
//           ),
//         ],
//       ),
//       body: ConstructionCanvas(site: site, notifier: notifier),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showAddZoneDialog(context, notifier),
//         child: const Icon(Icons.add_location),
//       ),
//     );
//   }
//
//   void _addSampleZone(SiteNotifier notifier) {
//     final zone = ConstructionZone(
//       name: 'Zone ${DateTime.now().second}',
//       task: 'Sample Task',
//       manpower: 3 + DateTime.now().second % 5,
//       status: ConstructionStatus.values[DateTime.now().second % 3],
//       position: Offset(
//         100 + (DateTime.now().second % 10) * 50.0,
//         100 + (DateTime.now().second % 10) * 50.0,
//       ),
//       isPin: DateTime.now().second % 2 == 0,
//     );
//     notifier.addZone(zone);
//   }
//
//   void _showAddZoneDialog(BuildContext context, SiteNotifier notifier) {
//     showDialog(
//       context: context,
//       builder: (context) => AddZoneDialog(onAdd: notifier.addZone),
//     );
//   }
// }
//
// // ==============================
// // CONSTRUCTION CANVAS
// // ==============================
//
// class ConstructionCanvas extends StatefulWidget {
//   final ConstructionSite site;
//   final SiteNotifier notifier;
//
//   const ConstructionCanvas({super.key, required this.site, required this.notifier});
//
//   @override
//   State<ConstructionCanvas> createState() => _ConstructionCanvasState();
// }
//
// class _ConstructionCanvasState extends State<ConstructionCanvas> {
//   double _previousScale = 1.0;
//   Offset _previousOffset = Offset.zero;
//   Offset _startingFocalPoint = Offset.zero;
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onScaleStart: (details) {
//         _previousScale = widget.site.zoom;
//         _previousOffset = widget.site.panOffset;
//         _startingFocalPoint = details.focalPoint;
//       },
//       onScaleUpdate: (details) {
//         // Handle zoom
//         final newScale = _previousScale * details.scale;
//
//         // Handle pan (translation)
//         final offsetDelta = details.focalPoint - _startingFocalPoint;
//         final newOffset = _previousOffset + offsetDelta;
//
//         widget.notifier.updateZoom(newScale);
//         widget.notifier.updatePan(newOffset);
//       },
//       onTapUp: (details) {
//         // Convert screen coordinates to canvas coordinates
//         final canvasPosition = _convertToCanvasCoordinates(details.localPosition);
//
//         // Check if tapped on a zone
//         for (final zone in widget.site.zones) {
//           final zoneRect = Rect.fromCircle(
//             center: zone.position,
//             radius: zone.isPin ? 20 : 30,
//           );
//
//           if (zoneRect.contains(canvasPosition)) {
//             _showZoneDetails(context, zone);
//             return;
//           }
//         }
//
//         // If not tapped on a zone, add a new pin at tap location
//         _showAddZoneAtPosition(context, canvasPosition);
//       },
//       onLongPressStart: (details) {
//         // Long press to drag zones
//         final canvasPosition = _convertToCanvasCoordinates(details.localPosition);
//
//         for (final zone in widget.site.zones) {
//           final zoneRect = Rect.fromCircle(
//             center: zone.position,
//             radius: 30,
//           );
//
//           if (zoneRect.contains(canvasPosition)) {
//             _startDraggingZone(zone, canvasPosition);
//             return;
//           }
//         }
//       },
//       onLongPressMoveUpdate: (details) {
//         if (_draggingZone != null) {
//           final canvasPosition = _convertToCanvasCoordinates(details.localPosition);
//           _updateDraggingZone(canvasPosition);
//         }
//       },
//       onLongPressEnd: (details) {
//         _stopDraggingZone();
//       },
//       child: Container(
//         color: Colors.grey[100],
//         child: CustomPaint(
//           painter: ConstructionPainter(
//             site: widget.site,
//             draggingZone: _draggingZone,
//             draggingPosition: _draggingPosition,
//           ),
//           size: MediaQuery.of(context).size,
//         ),
//       ),
//     );
//   }
//
//   ConstructionZone? _draggingZone;
//   Offset? _draggingPosition;
//
//   void _startDraggingZone(ConstructionZone zone, Offset position) {
//     setState(() {
//       _draggingZone = zone;
//       _draggingPosition = position;
//     });
//   }
//
//   void _updateDraggingZone(Offset position) {
//     setState(() {
//       _draggingPosition = position;
//     });
//   }
//
//   void _stopDraggingZone() {
//     if (_draggingZone != null && _draggingPosition != null) {
//       final updatedZone = _draggingZone!.copyWith(position: _draggingPosition!);
//       widget.notifier.updateZone(_draggingZone!.id, updatedZone);
//     }
//
//     setState(() {
//       _draggingZone = null;
//       _draggingPosition = null;
//     });
//   }
//
//   Offset _convertToCanvasCoordinates(Offset screenPosition) {
//     // Convert screen coordinates to canvas coordinates considering zoom and pan
//     final scaledX = (screenPosition.dx - widget.site.panOffset.dx) / widget.site.zoom;
//     final scaledY = (screenPosition.dy - widget.site.panOffset.dy) / widget.site.zoom;
//     return Offset(scaledX, scaledY);
//   }
//
//   void _showZoneDetails(BuildContext context, ConstructionZone zone) {
//     showDialog(
//       context: context,
//       builder: (context) => ZoneDetailsDialog(
//         zone: zone,
//         onUpdate: (updatedZone) => widget.notifier.updateZone(zone.id, updatedZone),
//         onDelete: () => widget.notifier.removeZone(zone.id),
//       ),
//     );
//   }
//
//   void _showAddZoneAtPosition(BuildContext context, Offset position) {
//     showDialog(
//       context: context,
//       builder: (context) => AddZoneAtPositionDialog(
//         position: position,
//         onAdd: widget.notifier.addZone,
//       ),
//     );
//   }
// }
//
// // ==============================
// // CANVAS PAINTER
// // ==============================
//
// class ConstructionPainter extends CustomPainter {
//   final ConstructionSite site;
//   final ConstructionZone? draggingZone;
//   final Offset? draggingPosition;
//
//   ConstructionPainter({
//     required this.site,
//     this.draggingZone,
//     this.draggingPosition,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     // Draw grid background
//     _drawGrid(canvas, size);
//
//     // Draw all zones (except the one being dragged)
//     for (final zone in site.zones) {
//       if (zone != draggingZone) {
//         _drawZone(canvas, zone, isDragging: false);
//       }
//     }
//
//     // Draw dragging zone on top
//     if (draggingZone != null && draggingPosition != null) {
//       _drawZone(canvas, draggingZone!,
//           position: draggingPosition!,
//           isDragging: true
//       );
//     }
//
//     // Draw stats
//     _drawStats(canvas, size);
//   }
//
//   void _drawGrid(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.grey[300]!
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0;
//
//     const gridSize = 50.0;
//
//     // Apply pan/zoom transformation
//     canvas.save();
//     canvas.translate(site.panOffset.dx, site.panOffset.dy);
//     canvas.scale(site.zoom);
//
//     // Draw vertical lines
//     for (double x = 0; x < size.width * 2; x += gridSize) {
//       canvas.drawLine(Offset(x, 0), Offset(x, size.height * 2), paint);
//     }
//
//     // Draw horizontal lines
//     for (double y = 0; y < size.height * 2; y += gridSize) {
//       canvas.drawLine(Offset(0, y), Offset(size.width * 2, y), paint);
//     }
//
//     canvas.restore();
//   }
//
//   void _drawZone(Canvas canvas, ConstructionZone zone, {
//     Offset? position,
//     bool isDragging = false,
//   }) {
//     final zonePosition = position ?? zone.position;
//
//     canvas.save();
//     canvas.translate(site.panOffset.dx, site.panOffset.dy);
//     canvas.scale(site.zoom);
//
//     if (zone.isPin) {
//       _drawPin(canvas, zone, zonePosition, isDragging: isDragging);
//     } else {
//       _drawRectZone(canvas, zone, zonePosition, isDragging: isDragging);
//     }
//
//     canvas.restore();
//   }
//
//   void _drawPin(Canvas canvas, ConstructionZone zone, Offset position, {bool isDragging = false}) {
//     // Draw pin circle
//     final paint = Paint()
//       ..color = isDragging ? zone.color.withOpacity(0.5) : zone.color
//       ..style = PaintingStyle.fill;
//
//     canvas.drawCircle(position, 15, paint);
//
//     // Draw pin outline
//     final outlinePaint = Paint()
//       ..color = Colors.black
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2.0;
//
//     canvas.drawCircle(position, 15, outlinePaint);
//
//     if (isDragging) {
//       final shadowPaint = Paint()
//         ..color = Colors.black.withOpacity(0.3)
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 3.0
//         ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
//
//       canvas.drawCircle(position, 18, shadowPaint);
//     }
//
//     // Draw pin icon
//     final textPainter = TextPainter(
//       text: const TextSpan(text: '📍', style: TextStyle(fontSize: 10)),
//       textDirection: TextDirection.ltr,
//     );
//     textPainter.layout();
//     textPainter.paint(canvas, position - const Offset(5, 5));
//
//     // Draw zone name
//     final namePainter = TextPainter(
//       text: TextSpan(
//         text: zone.name,
//         style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     namePainter.layout();
//     namePainter.paint(canvas, position + const Offset(20, -10));
//   }
//
//   void _drawRectZone(Canvas canvas, ConstructionZone zone, Offset position, {bool isDragging = false}) {
//     final rect = Rect.fromCenter(
//       center: position,
//       width: 50,
//       height: 40,
//     );
//
//     // Draw zone rectangle
//     final paint = Paint()
//       ..color = isDragging ? zone.color.withOpacity(0.5) : zone.color.withOpacity(0.3)
//       ..style = PaintingStyle.fill;
//
//     canvas.drawRect(rect, paint);
//
//     // Draw border
//     final borderPaint = Paint()
//       ..color = zone.color
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2.0;
//
//     canvas.drawRect(rect, borderPaint);
//
//     if (isDragging) {
//       final shadowPaint = Paint()
//         ..color = Colors.black.withOpacity(0.3)
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 3.0
//         ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
//
//       canvas.drawRect(rect.inflate(2), shadowPaint);
//     }
//
//     // Draw zone info
//     final text = '${zone.name}\n${zone.manpower}👷';
//     final textPainter = TextPainter(
//       text: TextSpan(
//         text: text,
//         style: const TextStyle(color: Colors.black, fontSize: 10),
//       ),
//       textDirection: TextDirection.ltr,
//       textAlign: TextAlign.center,
//     );
//     textPainter.layout(maxWidth: 50);
//     textPainter.paint(
//       canvas,
//       rect.center - Offset(textPainter.width / 2, textPainter.height / 2),
//     );
//   }
//
//   void _drawStats(Canvas canvas, Size size) {
//     final totalManpower = site.zones.fold(0, (sum, zone) => sum + zone.manpower);
//     final completedZones = site.zones.where((z) => z.status == ConstructionStatus.completed).length;
//     final progress = site.zones.isEmpty ? 0 : (completedZones / site.zones.length) * 100;
//
//     final text = 'Zones: ${site.zones.length} | '
//         'Manpower: $totalManpower | '
//         'Progress: ${progress.toStringAsFixed(1)}% | '
//         'Zoom: ${site.zoom.toStringAsFixed(2)}x';
//
//     final textPainter = TextPainter(
//       text: TextSpan(
//         text: text,
//         style: const TextStyle(
//             color: Colors.black,
//             fontSize: 14,
//             backgroundColor: Colors.white70
//         ),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     textPainter.layout();
//     textPainter.paint(canvas, const Offset(10, 10));
//
//     // Draw progress bar
//     final progressBarRect = Rect.fromLTWH(10, 35, size.width - 20, 10);
//     final progressBarBackground = Paint()
//       ..color = Colors.grey[300]!
//       ..style = PaintingStyle.fill;
//
//     canvas.drawRect(progressBarRect, progressBarBackground);
//
//     final progressBarFill = Rect.fromLTWH(
//         10,
//         35,
//         (size.width - 20) * (progress / 100),
//         10
//     );
//
//     final gradient = LinearGradient(
//       colors: [Colors.red, Colors.orange, Colors.green],
//     ).createShader(progressBarFill);
//
//     final progressPaint = Paint()..shader = gradient;
//     canvas.drawRect(progressBarFill, progressPaint);
//   }
//
//   @override
//   bool shouldRepaint(covariant ConstructionPainter oldDelegate) {
//     return site != oldDelegate.site ||
//         draggingZone != oldDelegate.draggingZone ||
//         draggingPosition != oldDelegate.draggingPosition;
//   }
// }
//
// // ==============================
// // DIALOGS
// // ==============================
//
// class AddZoneDialog extends StatefulWidget {
//   final Function(ConstructionZone) onAdd;
//   const AddZoneDialog({super.key, required this.onAdd});
//
//   @override
//   State<AddZoneDialog> createState() => _AddZoneDialogState();
// }
//
// class AddZoneAtPositionDialog extends StatefulWidget {
//   final Offset position;
//   final Function(ConstructionZone) onAdd;
//
//   const AddZoneAtPositionDialog({
//     super.key,
//     required this.position,
//     required this.onAdd,
//   });
//
//   @override
//   State<AddZoneAtPositionDialog> createState() => _AddZoneAtPositionDialogState();
// }
//
// class _AddZoneAtPositionDialogState extends State<AddZoneAtPositionDialog> {
//   final _nameController = TextEditingController(text: 'New Zone');
//   final _taskController = TextEditingController(text: 'Construction Task');
//   final _manpowerController = TextEditingController(text: '5');
//   ConstructionStatus _status = ConstructionStatus.pending;
//   bool _isPin = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('Add New Zone/Pin'),
//       content: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text('Position: (${widget.position.dx.toStringAsFixed(0)}, '
//                 '${widget.position.dy.toStringAsFixed(0)})'),
//             const SizedBox(height: 10),
//             TextField(
//               controller: _nameController,
//               decoration: const InputDecoration(labelText: 'Name'),
//             ),
//             TextField(
//               controller: _taskController,
//               decoration: const InputDecoration(labelText: 'Task'),
//             ),
//             TextField(
//               controller: _manpowerController,
//               decoration: const InputDecoration(labelText: 'Manpower'),
//               keyboardType: TextInputType.number,
//             ),
//             const SizedBox(height: 16),
//             // Status Selection
//             DropdownButtonFormField<ConstructionStatus>(
//               value: _status,
//               onChanged: (value) => setState(() => _status = value!),
//               items: ConstructionStatus.values.map((status) {
//                 return DropdownMenuItem(
//                   value: status,
//                   child: Text(status.toString().split('.').last),
//                 );
//               }).toList(),
//               decoration: const InputDecoration(labelText: 'Status'),
//             ),
//             const SizedBox(height: 16),
//             // Pin or Zone
//             SwitchListTile(
//               title: const Text('Pin Marker'),
//               subtitle: Text(_isPin ? 'Pin' : 'Zone'),
//               value: _isPin,
//               onChanged: (value) => setState(() => _isPin = value),
//             ),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => context.pop(),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: _addZone,
//           child: const Text('Add'),
//         ),
//       ],
//     );
//   }
//
//   void _addZone() {
//     final zone = ConstructionZone(
//       name: _nameController.text,
//       task: _taskController.text,
//       manpower: int.tryParse(_manpowerController.text) ?? 5,
//       status: _status,
//       position: widget.position,
//       isPin: _isPin,
//     );
//     widget.onAdd(zone);
//     context.pop();
//   }
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _taskController.dispose();
//     _manpowerController.dispose();
//     super.dispose();
//   }
// }
//
// class _AddZoneDialogState extends State<AddZoneDialog> {
//   final _nameController = TextEditingController(text: 'New Zone');
//   final _taskController = TextEditingController(text: 'Construction Task');
//   final _manpowerController = TextEditingController(text: '5');
//   ConstructionStatus _status = ConstructionStatus.pending;
//   bool _isPin = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('Add New Zone/Pin'),
//       content: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               controller: _nameController,
//               decoration: const InputDecoration(labelText: 'Name'),
//             ),
//             TextField(
//               controller: _taskController,
//               decoration: const InputDecoration(labelText: 'Task'),
//             ),
//             TextField(
//               controller: _manpowerController,
//               decoration: const InputDecoration(labelText: 'Manpower'),
//               keyboardType: TextInputType.number,
//             ),
//             const SizedBox(height: 16),
//             // Status Selection
//             DropdownButtonFormField<ConstructionStatus>(
//               value: _status,
//               onChanged: (value) => setState(() => _status = value!),
//               items: ConstructionStatus.values.map((status) {
//                 return DropdownMenuItem(
//                   value: status,
//                   child: Text(status.toString().split('.').last),
//                 );
//               }).toList(),
//               decoration: const InputDecoration(labelText: 'Status'),
//             ),
//             const SizedBox(height: 16),
//             // Pin or Zone
//             SwitchListTile(
//               title: const Text('Pin Marker'),
//               subtitle: Text(_isPin ? 'Pin' : 'Zone'),
//               value: _isPin,
//               onChanged: (value) => setState(() => _isPin = value),
//             ),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => context.pop(),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: _addZone,
//           child: const Text('Add'),
//         ),
//       ]
//     );
//   }
//
//   void _addZone() {
//     final zone = ConstructionZone(
//       name: _nameController.text,
//       task: _taskController.text,
//       manpower: int.tryParse(_manpowerController.text) ?? 5,
//       status: _status,
//       position: const Offset(200, 200), // Default position
//       isPin: _isPin,
//     );
//     widget.onAdd(zone);
//       context.pop();
//     }
//   }
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _taskController.dispose();
//     _nameController.dispose();
//     super.dispose();
//   }
// }
//
// class ZoneDetailsDialog extends StatefulWidget {
//   final ConstructionZone zone;
//   final Function(ConstructionZone) onUpdate;
//   final VoidCallback onDelete;
//
//   const ZoneDetailsDialog({
//     super.key,
//     required this.zone,
//     required this.onUpdate,
//     required this.onDelete,
//   });
//
//   @override
//   State<ZoneDetailsDialog> createState() => _ZoneDetailsDialogState();
// }
//
// class _ZoneDetailsDialogState extends State<ZoneDetailsDialog> {
//   late TextEditingController _nameController;
//   late TextEditingController _taskController;
//   late TextEditingController _manpowerController;
//   late ConstructionStatus _status;
//
//   @override
//   void initState() {
//     super.initState();
//     _nameController = TextEditingController(text: widget.zone.name);
//     _taskController = TextEditingController(text: widget.zone.task);
//     _manpowerController = TextEditingController(text: widget.zone.manpower.toString());
//     _status = widget.zone.status;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: Row(
//         children: [
//           Container(
//             width: 20,
//             height: 20,
//             color: widget.zone.color,
//           ),
//           const SizedBox(width: 10),
//           Text(widget.zone.name),
//         ],
//       ),
//       content: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               controller: _nameController,
//               decoration: const InputDecoration(labelText: 'Name'),
//             ),
//             TextField(
//               controller: _taskController,
//               decoration: const InputDecoration(labelText: 'Task'),
//             ),
//             TextField(
//               controller: _manpowerController,
//               decoration: const InputDecoration(labelText: 'Manpower'),
//               keyboardType: TextInputType.number,
//             ),
//             const SizedBox(height: 16),
//             // Status Selection
//             DropdownButtonFormField<ConstructionStatus>(
//               value: _status,
//               onChanged: (value) => setState(() => _status = value!),
//               items: ConstructionStatus.values.map((status) {
//                 return DropdownMenuItem(
//                   value: status,
//                   child: Text(status.toString().split('.').last),
//                 );
//               }).toList(),
//               decoration: const InputDecoration(labelText: 'Status'),
//             ),
//             const SizedBox(height: 16),
//             // Zone info
//             ListTile(
//               leading: const Icon(Icons.location_on),
//               title: Text('Position: (${widget.zone.position.dx.toStringAsFixed(0)}, '
//                   '${widget.zone.position.dy.toStringAsFixed(0)})'),
//             ),
//             ListTile(
//               leading: Icon(widget.zone.isPin ? Icons.push_pin : Icons.rectangle),
//               title: Text('Type: ${widget.zone.isPin ? 'Pin' : 'Zone'}'),
//             ),
//           ],
//         ),
//       ),
//       actions: [
//         // Delete Button
//         TextButton.icon(
//           onPressed: () {
//             widget.onDelete();
//             Navigator.pop(context);
//           },
//           icon: const Icon(Icons.delete_outline, color: Colors.red),
//           label: const Text('Delete', style: TextStyle(color: Colors.red)),
//         ),
//         TextButton(
//           onPressed: () => context.pop(),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: _updateZone,
//           child: const Text('Update'),
//         ),
//       ],
//     );
//   }
//
//   void _updateZone() {
//     final updatedZone = ConstructionZone(
//       name: _nameController.text,
//       task: _taskController.text,
//       manpower: int.tryParse(_manpowerController.text) ?? widget.zone.manpower,
//       status: _status,
//       position: widget.zone.position,
//       isPin: widget.zone.isPin,
//     );
//     widget.onUpdate(updatedZone);
//     context.pop();
//   }
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _taskController.dispose();
//     _manpowerController.dispose();
//     super.dispose();
//   }
// }