// import 'package:flutter/material.dart';
// import 'package:showcaseview/showcaseview.dart';
// import '../widgets/disease_slider.dart';
// import '../widgets/inspection_card.dart';
// import '../widgets/notification_icon.dart';
// import '../../notifications/views/notification_screen.dart';

// class HomeContent extends StatelessWidget {
//   final GlobalKey<ScaffoldState> scaffoldKey;
//   final GlobalKey profileKey;
//   final GlobalKey catalogKey;
//   final GlobalKey scannerKey;
//   final bool showWeatherTip;
//   final VoidCallback onWeatherTipToggle;
//   final List<Map<String, dynamic>> diseaseData;
//   final Function(Map<String, dynamic>) onDiseaseDetailsTap;

//   const HomeContent({
//     super.key,
//     required this.scaffoldKey,
//     required this.profileKey,
//     required this.catalogKey,
//     required this.scannerKey,
//     required this.showWeatherTip,
//     required this.onWeatherTipToggle,
//     required this.diseaseData,
//     required this.onDiseaseDetailsTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     // Showcase(
//                     //   key: profileKey,
//                     //   title: 'Your Profile',
//                     //   description: 'Manage your farm settings and account details here.',
//                     //   child: GestureDetector(
//                     //     onTap: () => scaffoldKey.currentState?.openDrawer(),
//                     //     child: Container(
//                     //       decoration: BoxDecoration(
//                     //         shape: BoxShape.circle,
//                     //         border: Border.all(
//                     //           color: Colors.green.withAlpha((0.2 * 255).toInt()),
//                     //           width: 2,
//                     //         ),
//                     //       ),
//                     //       child: const CircleAvatar(
//                     //         radius: 24,
//                     //         backgroundColor: Color(0xFFF1F1F1),
//                     //         child: Icon(Icons.person_outline, color: Colors.green),
//                     //       ),
//                     //     ),
//                     //   ),
//                     // ),
//                     const SizedBox(width: 12),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text("Good Morning,", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
//                         const Text("Farmer John!", 
//                           style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
//                       ],
//                     ),
//                     const Spacer(),
//                     GestureDetector(
//                       behavior: HitTestBehavior.opaque,
//                       onTap: () {
//                         Navigator.of(context, rootNavigator: true).push(
//                           MaterialPageRoute(builder: (context) => const NotificationScreen()),
//                         );
//                       },
//                       child: const Padding(
//                         padding: EdgeInsets.all(8.0),
//                         child: NotificationIcon(),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
              
//                 Showcase(
//                   key: catalogKey,
//                   title: 'Disease Catalog',
//                   description: 'Tap or swipe to see symptoms of common cacao diseases.',
//                   child: DiseaseSlider(
//                     diseaseData: diseaseData,
//                     onDiseaseTap: (index) {
//                       // Pass the selected data back to the parent
//                       onDiseaseDetailsTap(diseaseData[index]);
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Scrollable Bottom Part
//           Expanded(
//             child: SingleChildScrollView(
//               physics: const BouncingScrollPhysics(),
//               padding: const EdgeInsets.symmetric(horizontal: 20.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const SizedBox(height: 15),
//                   const Text("Quick Inspection", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 15),
//                   Showcase(
//                     key: scannerKey,
//                     title: 'AI Scanner',
//                     description: 'Use your camera to identify diseases in the field.',
//                     child: const InspectionCard(),
//                   ),
//                   const SizedBox(height: 25),
//                   const Text("Recent Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 12),
//                   const TotalScannedCard(),
//                   const SizedBox(height: 40),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class TotalScannedCard extends StatelessWidget {
//   const TotalScannedCard({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10)],
//       ),
//       child: const Text('Recent Activity details will appear here.'),
//     );
//   }
// }