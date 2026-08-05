import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/model/user.model.dart';
import '../../../theme/app_theme.dart';
class ProfileHeroCard extends StatelessWidget {
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final LocalUser? currentUser;
  final File? profileImage;

  const ProfileHeroCard({
    super.key,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.currentUser,
    this.profileImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.forestMid.withAlpha(60),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.forestMid.withAlpha(38),
              backgroundImage:
                  profileImage != null ? FileImage(profileImage!) : null,
              child: profileImage == null
                  ? Icon(Icons.person_rounded,
                      color: textPrimary.withAlpha(180), size: 42)
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            currentUser?.name ?? "Loading...",
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currentUser?.address ?? "",
            style: TextStyle(
              color: textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
     
        ],
      ),
    );
  }
}