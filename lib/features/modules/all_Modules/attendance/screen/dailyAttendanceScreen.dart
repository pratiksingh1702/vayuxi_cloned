// import 'dart:convert';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
// import 'package:table_calendar/table_calendar.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
// import 'package:file_picker/file_picker.dart';
// import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
// import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
// import '../../../../../core/utlis/widgets/buttons.dart';
// import '../../../../../core/utlis/widgets/image_clipped.dart';
// import '../../../../../typeProvider/type_provider.dart';
// import '../provider/AttendanceService.dart';
// import 'attendanceScreen.dart';
//
// class DailyAttendanceScreen extends ConsumerStatefulWidget {
//   final String siteId;
//   final String siteName;
//
//   const DailyAttendanceScreen({
//     super.key,
//     required this.siteId,
//     required this.siteName,
//   });
//
//   @override
//   ConsumerState<DailyAttendanceScreen> createState() => _DailyAttendanceScreenState();
// }
//
// class _DailyAttendanceScreenState extends ConsumerState<DailyAttendanceScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFEEF7FF),
//       appBar: CustomAppBar(title: "Daily Attendance"),
//       body: CornerClippedScreenSimple(
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: _buildOptionCard(
//                 title: "Select Date",
//                 subtitle: "Mark attendance for a specific day",
//                 icon: Icons.calendar_month_rounded,
//                 color: Colors.blue.shade600,
//                 onTap: () async {
//                   final picked = await showDatePicker(
//                     context: context,
//                     initialDate: DateTime.now(),
//                     firstDate: DateTime(2020),
//                     lastDate: DateTime(2100),
//                   );
//                   if (picked != null) {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => AttendanceScreen(
//                           siteId: widget.siteId,
//                           siteName: widget.siteName,
//                           selectedDate: picked,
//                         ),
//                       ),
//                     );
//                   }
//                 },
//               ),
//             ),
//             // Back Button at bottom
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: RoundedButton(
//                 text: "Back",
//                 color: Colors.white,
//                 textColor: Colors.black,
//                 onPressed: () {
//                   context.pop();
//                 },
//                 width:double.infinity,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//   Widget _buildOptionCard({
//     required String title,
//     required String subtitle,
//     required IconData icon,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(16),
//       child: Container(
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//
//         ),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(14),
//               decoration: BoxDecoration(
//                 color: color.withOpacity(0.15),
//                 borderRadius: BorderRadius.circular(14),
//               ),
//               child: Icon(icon, size: 32, color: color),
//             ),
//             const SizedBox(width: 20),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(title,
//                       style: const TextStyle(
//                         fontSize: 17,
//                         fontWeight: FontWeight.w600,
//                       )),
//                   const SizedBox(height: 4),
//                   Text(
//                     subtitle,
//                     style: TextStyle(color: Colors.grey.shade700),
//                   ),
//                 ],
//               ),
//             ),
//             const Icon(Icons.arrow_forward_ios_rounded, size: 18),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
//
//
// // Date Range Picker Dialog
// // Date Range Picker Dialog
// //