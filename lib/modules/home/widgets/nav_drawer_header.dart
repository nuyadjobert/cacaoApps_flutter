// import 'package:cacao_apps/core/db/user_repository.dart';
// import 'package:flutter/material.dart';
// import 'package:cacao_apps/core/model/user.model.dart';

// class NavDrawerHeader extends StatelessWidget {
//   const NavDrawerHeader({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final UserRepository userRepository =UserRepository();
//     return FutureBuilder<LocalUser?>(
//       future: userRepository.getCurrentUser(),
//       builder: (context, snapshot) {
//         // 1. Get the user data or use fallbacks
//         final user = snapshot.data;
//         final String displayName = user?.name ?? "Farmer";
//         final String displayEmail = user?.email ?? "No email found";

//         return Container(
//           width: double.infinity,
//           padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
//           decoration: const BoxDecoration(
//             color: Color(0xFF2D6A4F),
//             image: DecorationImage(
//               image: AssetImage('assets/images/pattern_bg.png'),
//               opacity: 0.1,
//               fit: BoxFit.cover,
//             ),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const CircleAvatar(
//                 radius: 35,
//                 backgroundColor: Colors.white,
//                 child: Icon(Icons.person, size: 40, color: Color(0xFF2D6A4F)),
//               ),
//               const SizedBox(height: 16),
              
//               // Handle loading state slightly for smoother UI
//               if (snapshot.connectionState == ConnectionState.waiting)
//                 const SizedBox(
//                   height: 20,
//                   width: 20,
//                   child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
//                 )
//               else ...[
//                 Row(
//                   children: [
//                     Text(
//                       displayName,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Icon(Icons.verified, color: Colors.blue[300], size: 18),
//                   ],
//                 ),
//                 Text(
//                   displayEmail,
//                   style: const TextStyle(color: Colors.white70, fontSize: 14),
//                 ),
//               ],
//             ],
//           ),
//         );
//       },
//     );
//   }
// }