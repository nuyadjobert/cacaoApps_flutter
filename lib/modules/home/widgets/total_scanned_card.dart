import 'package:flutter/material.dart';
import '../Controller/home_controller.dart';
import '../models/disease_counts_model.dart';
import '../views/statistics_report_screen.dart';
import '../../../theme/app_theme.dart';

class TotalScannedCard extends StatelessWidget {
  final HomeController controller;

  const TotalScannedCard({
    required this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const Color brandGreen = Color(0xFF2D6A4F);
    final Color accentGreen = isDark ? AppColors.forestLight : brandGreen;
    final Color iconColor = isDark ? AppColors.forestLight : const Color(0xFF1B4332);

    final Color cardBg = isDark ? AppColors.nightCard : Colors.white;
    final Color titleColor = isDark ? Colors.white : const Color(0xFF1B4332);
    final Color subtitleColor = isDark ? Colors.white60 : Colors.grey;
    final Color chevronColor = isDark ? Colors.white38 : Colors.grey;
    final Color dividerColor = isDark ? Colors.white24 : Colors.grey.withValues(alpha: 0.5);
    final Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : brandGreen.withValues(alpha: 0.08);
    final Color shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.55)
        : Colors.black.withValues(alpha: 0.3);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final state = controller.statsLoadState;
        final counts = controller.diseaseCounts;

        // Show error/offline states with a different layout
        if (state == StatisticsLoadState.offline ||
            state == StatisticsLoadState.serverUnreachable ||
            state == StatisticsLoadState.authError ||
            state == StatisticsLoadState.error) {
          return _buildErrorStateCard(
            state,
            cardBg,
            titleColor,
            subtitleColor,
            borderColor,
            shadowColor,
            accentGreen,
            isDark,
          );
        }

        // Normal interactive card for loading, success, empty, and initial states
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StatisticsReportScreen(controller: controller),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildIcon(state, counts, accentGreen, iconColor, isDark),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildHeader(
                        state,
                        counts,
                        titleColor,
                        subtitleColor,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: chevronColor),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Divider(height: 1, thickness: 0.5, color: dividerColor),
                ),
                _buildStatistics(state, counts, accentGreen, subtitleColor),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorStateCard(
    StatisticsLoadState state,
    Color cardBg,
    Color titleColor,
    Color subtitleColor,
    Color borderColor,
    Color shadowColor,
    Color accentGreen,
    bool isDark,
  ) {
    IconData icon;
    Color iconColor;
    String title;
    String message;

    switch (state) {
      case StatisticsLoadState.offline:
        icon = Icons.wifi_off;
        iconColor = Colors.grey;
        title = "Unable to load statistics";
        message = "Connect to the internet to view your latest scan statistics.";
        break;
      case StatisticsLoadState.serverUnreachable:
        icon = Icons.cloud_off;
        iconColor = Colors.orange;
        title = "Server unavailable";
        message = "Unable to reach the server. Please try again in a moment.";
        break;
      case StatisticsLoadState.authError:
        icon = Icons.lock_outline;
        iconColor = Colors.red;
        title = "Authentication failed";
        message = "Please log in again to view your statistics.";
        break;
      case StatisticsLoadState.error:
      default:
        icon = Icons.error_outline;
        iconColor = Colors.red;
        title = "Error loading statistics";
        message = controller.statsError ?? "An unexpected error occurred";
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: iconColor),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: subtitleColor,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => controller.retryLoadStatistics(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(
    StatisticsLoadState state,
    DiseaseCountsModel? counts,
    Color accentGreen,
    Color iconColor,
    bool isDark,
  ) {
    if (state == StatisticsLoadState.loading) {
      return SizedBox(
        height: 50,
        width: 50,
        child: CircularProgressIndicator(
          strokeWidth: 4,
          valueColor: AlwaysStoppedAnimation<Color>(accentGreen),
        ),
      );
    }

    if (state == StatisticsLoadState.success && counts != null) {
      final totalScans = counts.totalScans;
      final healthyScans = counts.healthy;
      final progress = totalScans > 0 ? healthyScans / totalScans : 0.0;

      return Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 50,
            width: 50,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(accentGreen),
              strokeCap: StrokeCap.round,
            ),
          ),
          Icon(Icons.analytics_outlined, size: 20, color: iconColor),
        ],
      );
    }

    // Default icon for other states
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.1),
      ),
      child: Icon(Icons.analytics_outlined, size: 20, color: iconColor),
    );
  }

  Widget _buildHeader(
    StatisticsLoadState state,
    DiseaseCountsModel? counts,
    Color titleColor,
    Color subtitleColor,
  ) {
    String title = "Farm Health Summary";
    String subtitle = "Tap to view detailed report";

    if (state == StatisticsLoadState.loading) {
      subtitle = "Loading statistics...";
    } else if (state == StatisticsLoadState.offline) {
      subtitle = "Offline - Tap to retry";
    } else if (state == StatisticsLoadState.serverUnreachable) {
      subtitle = "Server unavailable - Tap to retry";
    } else if (state == StatisticsLoadState.empty) {
      subtitle = "No scans yet";
    } else if (state == StatisticsLoadState.success && counts != null) {
      final totalScans = counts.totalScans;
      subtitle = totalScans == 1
          ? "Based on your last scan"
          : "Based on your last $totalScans scans";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: subtitleColor),
        ),
      ],
    );
  }

  Widget _buildStatistics(
    StatisticsLoadState state,
    DiseaseCountsModel? counts,
    Color accentGreen,
    Color subtitleColor,
  ) {
    if (state == StatisticsLoadState.loading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSkeletonStat(subtitleColor),
          _buildSkeletonStat(subtitleColor),
          _buildSkeletonStat(subtitleColor),
        ],
      );
    }

    if (state == StatisticsLoadState.success && counts != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildEnhancedStatItem(
            counts.totalScans.toString(),
            "Total Scans",
            Colors.blueGrey,
            subtitleColor,
          ),
          _buildEnhancedStatItem(
            counts.healthy.toString(),
            "Healthy",
            accentGreen,
            subtitleColor,
          ),
          _buildEnhancedStatItem(
            counts.totalDiseased.toString(),
            "Diseased",
            Colors.redAccent,
            subtitleColor,
          ),
        ],
      );
    }

    // Empty/Error/Offline states
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildEnhancedStatItem("--", "Total Scans", Colors.blueGrey, subtitleColor),
        _buildEnhancedStatItem("--", "Healthy", accentGreen, subtitleColor),
        _buildEnhancedStatItem("--", "Diseased", Colors.redAccent, subtitleColor),
      ],
    );
  }

  Widget _buildSkeletonStat(Color subtitleColor) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 3,
          width: 20,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 50,
          height: 11,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedStatItem(
    String value,
    String label,
    Color color,
    Color labelColor,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 3,
          width: 20,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: labelColor,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
