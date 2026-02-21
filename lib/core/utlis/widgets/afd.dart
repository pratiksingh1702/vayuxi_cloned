// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
//
// class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
//   final String title;
//   final bool showDrawer; // Option to hide drawer on certain screens
//
//   const CustomAppBar({
//     super.key,
//     required this.title,
//     this.showDrawer = true,
//   });
//
//   @override
//   Size get preferredSize => const Size.fromHeight(100);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         image: DecorationImage(
//           image: AssetImage(
//             "assets/images/Firefly_A seamless pattern on a white background, featuring various simple, breathable, blue  303856.webp",
//           ),
//           fit: BoxFit.cover,
//         ),
//       ),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.7),
//         ),
//         padding: EdgeInsets.only(
//           top: MediaQuery
//               .of(context)
//               .padding
//               .top,
//           left: showDrawer ? 4 : 16,
//           right: 16,
//           bottom: 10,
//         ),
//         child: Row(
//           children: [
//             // 🔹 HAMBURGER MENU BUTTON
//             if (showDrawer)
//               IconButton(
//                 icon: Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.shade600,
//                     borderRadius: BorderRadius.circular(10),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.blue.withOpacity(0.3),
//                         blurRadius: 8,
//                         spreadRadius: 1,
//                       ),
//                     ],
//                   ),
//                   child: const Icon(
//                     Icons.menu_rounded,
//                     color: Colors.white,
//                     size: 24,
//                   ),
//                 ),
//                 onPressed: () {
//                   _showCustomDrawer(context);
//                 },
//               ),
//
//             // 🔹 TITLE
//             Expanded(
//               child: Center(
//                 child: Padding(
//                   padding: EdgeInsets.only(left: showDrawer ? 0 : 0),
//                   child: Text(
//                     title,
//                     maxLines: 1,
//                     textAlign: TextAlign.center,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//
//             // 🔹 SPACER TO BALANCE HAMBURGER MENU
//             if (showDrawer)
//               const SizedBox(width: 48), // Same width as IconButton
//           ],
//         ),
//       ),
//     );
//   }
//
//   // 🔹 CUSTOM DRAWER FUNCTION
//   void _showCustomDrawer(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) =>
//           DraggableScrollableSheet(
//             initialChildSize: 0.9,
//             minChildSize: 0.5,
//             maxChildSize: 0.95,
//             builder: (context, scrollController) {
//               return Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: [Colors.blue.shade50, Colors.white],
//                   ),
//                   borderRadius: const BorderRadius.vertical(
//                       top: Radius.circular(25)),
//                 ),
//                 child: Column(
//                   children: [
//                     // 🔹 DRAG HANDLE
//                     Container(
//                       margin: const EdgeInsets.symmetric(vertical: 12),
//                       width: 40,
//                       height: 4,
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade300,
//                         borderRadius: BorderRadius.circular(2),
//                       ),
//                     ),
//
//                     // 🔹 HEADER
//                     _buildDrawerHeader(context),
//                     const Divider(height: 1),
//
//                     // 🔹 NAVIGATION ITEMS
//                     Expanded(
//                       child: ListView(
//                         controller: scrollController,
//                         padding: const EdgeInsets.symmetric(vertical: 8),
//                         children: [
//                           _buildSectionTitle('MAIN'),
//                           _buildNavItem(context, icon: Icons.dashboard_outlined,
//                               title: 'Dashboard',
//                               route: '/work-category',
//                               gradient: [
//                                 Colors.blue.shade400,
//                                 Colors.blue.shade600
//                               ]),
//                           _buildNavItem(context, icon: Icons.grid_view_outlined,
//                               title: 'Modules',
//                               route: '/select-module',
//                               gradient: [
//                                 Colors.purple.shade400,
//                                 Colors.purple.shade600
//                               ]),
//
//                           const SizedBox(height: 12),
//                           _buildSectionTitle('DAILY OPERATIONS'),
//                           _buildNavItem(
//                               context, icon: Icons.check_circle_outline,
//                               title: 'Attendance',
//                               route: '/site-list/attendance',
//                               gradient: [
//                                 Colors.red.shade400,
//                                 Colors.red.shade600
//                               ]),
//                           _buildNavItem(context, icon: Icons.note_alt_outlined,
//                               title: 'Daily Progress',
//                               route: '/site-list/dpr',
//                               gradient: [
//                                 Colors.indigo.shade400,
//                                 Colors.indigo.shade600
//                               ]),
//                           _buildNavItem(
//                               context, icon: Icons.receipt_long_outlined,
//                               title: 'Expense Entry',
//                               route: '/site-list/add-exp',
//                               gradient: [
//                                 Colors.orange.shade400,
//                                 Colors.orange.shade600
//                               ]),
//                           _buildNavItem(
//                               context, icon: Icons.inventory_2_outlined,
//                               title: 'Inventory Entry',
//                               route: '/site-list/inv-entry',
//                               gradient: [
//                                 Colors.teal.shade400,
//                                 Colors.teal.shade600
//                               ]),
//
//                           const SizedBox(height: 12),
//                           _buildSectionTitle('SETUP & CONFIGURATION'),
//                           _buildNavItem(
//                               context, icon: Icons.location_city_outlined,
//                               title: 'Site Details',
//                               route: '/site',
//                               gradient: [
//                                 Colors.cyan.shade400,
//                                 Colors.cyan.shade600
//                               ]),
//                           _buildNavItem(
//                               context, icon: Icons.currency_rupee_outlined,
//                               title: 'Rate Management',
//                               route: '/site-list/rate',
//                               gradient: [
//                                 Colors.green.shade400,
//                                 Colors.green.shade600
//                               ]),
//                           _buildNavItem(context, icon: Icons.groups_outlined,
//                               title: 'Manpower Details',
//                               route: '/manpower',
//                               gradient: [
//                                 Colors.amber.shade400,
//                                 Colors.amber.shade600
//                               ]),
//                           _buildNavItem(context, icon: Icons.group_add_outlined,
//                               title: 'Team Management',
//                               route: '/site-list/team',
//                               gradient: [
//                                 Colors.lightBlue.shade400,
//                                 Colors.lightBlue.shade600
//                               ]),
//                           _buildNavItem(context, icon: Icons.settings_outlined,
//                               title: 'DPR Setup',
//                               route: '/site-list/addMoc',
//                               gradient: [
//                                 Colors.deepPurple.shade400,
//                                 Colors.deepPurple.shade600
//                               ]),
//                           _buildNavItem(context, icon: Icons.inventory_outlined,
//                               title: 'Inventory Setup',
//                               route: '/site-list/inv-setup',
//                               gradient: [
//                                 Colors.teal.shade400,
//                                 Colors.teal.shade600
//                               ]),
//
//                           const SizedBox(height: 12),
//                           _buildSectionTitle('REPORTS & ANALYSIS'),
//                           _buildNavItem(context, icon: Icons.analytics_outlined,
//                               title: 'Summary & Analysis',
//                               route: '/summary',
//                               gradient: [
//                                 Colors.deepOrange.shade400,
//                                 Colors.deepOrange.shade600
//                               ]),
//                           _buildNavItem(context, icon: Icons.smart_toy_outlined,
//                               title: 'AI Analysis',
//                               route: '/analysis',
//                               gradient: [
//                                 Colors.pink.shade400,
//                                 Colors.pink.shade600
//                               ]),
//                           _buildNavItem(context, icon: Icons.payments_outlined,
//                               title: 'Salary Reports',
//                               route: '/salary',
//                               gradient: [
//                                 Colors.brown.shade400,
//                                 Colors.brown.shade600
//                               ]),
//                           _buildNavItem(
//                               context, icon: Icons.table_chart_outlined,
//                               title: 'DPR Sheets',
//                               route: '/site-list/dprReport',
//                               gradient: [
//                                 Colors.indigo.shade400,
//                                 Colors.indigo.shade600
//                               ]),
//                           _buildNavItem(
//                               context, icon: Icons.assessment_outlined,
//                               title: 'Expense Report',
//                               route: '/site-list/expense',
//                               gradient: [
//                                 Colors.orange.shade400,
//                                 Colors.orange.shade600
//                               ]),
//                           _buildNavItem(
//                               context, icon: Icons.table_view_outlined,
//                               title: 'Attendance Sheet',
//                               route: '/site-list/att-sheet',
//                               gradient: [
//                                 Colors.red.shade400,
//                                 Colors.red.shade600
//                               ]),
//                           _buildNavItem(context, icon: Icons.bar_chart_outlined,
//                               title: 'Inventory Report',
//                               route: '/site-list/inv-Report',
//                               gradient: [
//                                 Colors.teal.shade400,
//                                 Colors.teal.shade600
//                               ]),
//
//                           const SizedBox(height: 12),
//                           _buildSectionTitle('SETTINGS'),
//                           _buildNavItem(context, icon: Icons.person_outline,
//                               title: 'Profile',
//                               route: '/profile',
//                               gradient: [
//                                 Colors.blue.shade400,
//                                 Colors.blue.shade600
//                               ]),
//                           _buildNavItem(
//                               context, icon: Icons.workspace_premium_outlined,
//                               title: 'Subscription',
//                               route: '/subscription',
//                               gradient: [
//                                 Colors.amber.shade400,
//                                 Colors.amber.shade600
//                               ]),
//                           _buildNavItem(context, icon: Icons.palette_outlined,
//                               title: 'Theme',
//                               route: '/theme',
//                               gradient: [
//                                 Colors.purple.shade400,
//                                 Colors.purple.shade600
//                               ]),
//                           _buildNavItem(context, icon: Icons.language_outlined,
//                               title: 'Language',
//                               route: '/language',
//                               gradient: [
//                                 Colors.green.shade400,
//                                 Colors.green.shade600
//                               ]),
//                           _buildNavItem(
//                               context, icon: Icons.new_releases_outlined,
//                               title: 'What\'s New',
//                               route: '/upcoming-update',
//                               gradient: [
//                                 Colors.lightGreen.shade400,
//                                 Colors.lightGreen.shade600
//                               ]),
//                           _buildNavItem(context, icon: Icons.help_outline,
//                               title: 'Help & Support',
//                               route: '/help',
//                               gradient: [
//                                 Colors.blueGrey.shade400,
//                                 Colors.blueGrey.shade600
//                               ]),
//                         ],
//                       ),
//                     ),
//
//                     // 🔹 FOOTER
//                     _buildDrawerFooter(context),
//                   ],
//                 ),
//               );
//             },
//           ),
//     );
//   }
//
//   Widget _buildDrawerHeader(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Colors.blue.shade600, Colors.blue.shade800],
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.1),
//                   blurRadius: 8,
//                   spreadRadius: 1,
//                 ),
//               ],
//             ),
//             child: Icon(
//                 Icons.construction_outlined, color: Colors.blue.shade600,
//                 size: 32),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text('Site Manager', style: TextStyle(color: Colors.white,
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold)),
//                 Text('Pro Edition', style: TextStyle(
//                     color: Colors.white.withOpacity(0.8), fontSize: 12)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
//       child: Text(title, style: TextStyle(fontSize: 11,
//           fontWeight: FontWeight.bold,
//           color: Colors.grey.shade600,
//           letterSpacing: 1.2)),
//     );
//   }
//
//   Widget _buildNavItem(BuildContext context,
//       {required IconData icon, required String title, required String route, required List<
//           Color> gradient}) {
//     String currentRoute = '';
//     bool isActive = false;
//
//     final router = GoRouter.maybeOf(context);
//
//     if (router != null) {
//       currentRoute = router.routeInformationProvider.value.uri.path;
//       isActive =
//           currentRoute == route || currentRoute.startsWith(route);
//     }
//
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//       decoration: BoxDecoration(
//         gradient: isActive ? LinearGradient(begin: Alignment.centerLeft,
//             end: Alignment.centerRight,
//             colors: gradient) : null,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: ListTile(
//         leading: Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: isActive ? Colors.white.withOpacity(0.2) : Colors
//                 .transparent,
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(icon, color: isActive ? Colors.white : Colors.grey
//               .shade700, size: 22),
//         ),
//         title: Text(title, style: TextStyle(fontSize: 14,
//             fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
//             color: isActive ? Colors.white : Colors.grey.shade800)),
//         trailing: isActive ? const Icon(
//             Icons.chevron_right, color: Colors.white, size: 20) : null,
//         contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         onTap: () {
//           Navigator.pop(context);
//           context.go(route);
//         },
//       ),
//     );
//   }
//
//   Widget _buildDrawerFooter(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade100,
//         border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text('Version 1.0.0',
//               style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
//           TextButton.icon(
//             onPressed: () {
//               Navigator.pop(context);
//               context.go('/login');
//             },
//             icon: Icon(Icons.logout, size: 16, color: Colors.red.shade600),
//             label: Text('Logout', style: TextStyle(fontSize: 12,
//                 color: Colors.red.shade600,
//                 fontWeight: FontWeight.w600)),
//             style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(
//                 horizontal: 12, vertical: 8)),
//           ),
//         ],
//       ),
//     );
//   }
//
// }