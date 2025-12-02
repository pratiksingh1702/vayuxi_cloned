// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
// import 'package:untitled2/core/utlis/colors/colors.dart';
// import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
// import 'package:untitled2/features/modules/all_Modules/ai_analyze/screen/single_page_ui.dart';
// import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/moc_selection_page.dart';
// import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
// import '../../../../../core/utlis/widgets/buttons.dart';
// import '../../../../../core/utlis/widgets/custom.dart';
// import '../../../../../core/utlis/widgets/image_clipped.dart';
// import '../../../../../typeProvider/type_provider.dart';
// import '../../site_Details/repository/siteModel.dart';
//
// import '../../team/provider/teamProvider.dart';
// import '../../team/screens/teamsList.dart';
// import 'audio_upload.dart';
//
//
// class SeletTeamScreen extends ConsumerStatefulWidget {
//
//
//   const SelectTeamScreen({super.key});
//
//   @override
//   ConsumerState<SelectTeamScreen> createState() => _SelectTeamScreenState();
// }
//
// class _SelectTeamScreenState extends ConsumerState<SelectTeamScreen> {
//   Future<void> _refreshTeams() async {
//     final type = ref.read(typeProvider);
//     final siteId=ref.read(selectedSiteIdProvider);
//     await ref.read(teamProvider.notifier).getTeams(type!, siteId!);
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _refreshTeams();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final teamState = ref.watch(teamProvider);
//     final siteId=ref.read(selectedSiteIdProvider);
//
//     return Scaffold(
//       backgroundColor: AppColors.lightBlue,
//
//       body: NestedScrollView(
//         headerSliverBuilder: (context, innerBoxIsScrolled) {
//           return [
//             CustomSliverAppBar(title: "Employee List"),
//           ];
//         },
//
//         body: CornerClippedScreenSimple(
//           child: teamState.when(
//             data: (teams) => Column(
//               children: [
//                 // Teams grid with expanded to take available space
//                 Expanded(
//                   child: LiquidPullToRefresh(
//                     onRefresh: _refreshTeams,
//                     height: 200,
//                     backgroundColor: Colors.blue,
//                     color: Colors.white,
//                     animSpeedFactor: 2.0,
//                     showChildOpacityTransition: true,
//                     child: GridView.builder(
//                       padding: const EdgeInsets.all(12),
//                       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                         crossAxisCount: 2,
//                         crossAxisSpacing: 12,
//                         mainAxisSpacing: 12,
//                         childAspectRatio: 1.2,
//                       ),
//                       itemCount: teams.length,
//                       itemBuilder: (context, index) {
//                         final team = teams[index];
//                         return InkWell(
//                           onTap: () {
//                             ref.read(selectedTeamIdProvider.notifier).state = team.id;
//                             // Navigator.push(
//                             //   context,
//                             //   MaterialPageRoute(
//                             //     builder: (context) => AddDescriptionScreen(
//                             //       siteId: widget.site.id,
//                             //       teamId: team.id,
//                             //       teamName: team.teamName,
//                             //     ),
//                             //   ),
//                             // );
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => AudioUploadScreen(),
//                               ),
//                             );
//
//                           },
//                           child: Card(
//                             color: Colors.white,
//                             elevation: 0,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Padding(
//                               padding: const EdgeInsets.all(12),
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Text(
//                                     team.teamName,
//                                     textAlign: TextAlign.center,
//                                     style: const TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 8),
//                                   Text(
//                                     "Members: ${team.teamMemberIds.length}",
//                                     style: const TextStyle(fontSize: 12),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//                 // Back button at the bottom
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(16),
//                   child: RoundedButton(
//                     text: "Back",
//                     color: Colors.white,
//                     textColor: Colors.black,
//                     onPressed: () {
//                       context.pop();
//                     },
//                     width: double.infinity,
//                   ),
//                 ),
//               ],
//             ),
//             loading: () => const Center(child: CircularProgressIndicator()),
//             error: (err, _) => Column(
//               children: [
//                 Expanded(
//                   child: Center(child: Text("Error: $err")),
//                 ),
//                 // Back button at the bottom even in error state
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(16),
//                   child: RoundedButton(
//                     text: "Back",
//                     color: Colors.white,
//                     textColor: Colors.black,
//                     onPressed: () {
//                       context.pop();
//                     },
//                     width: double.infinity,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }