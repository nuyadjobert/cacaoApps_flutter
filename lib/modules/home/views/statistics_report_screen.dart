import 'package:flutter/material.dart';
import '../Controller/home_controller.dart';
import '../models/disease_counts_model.dart';
import '../../../theme/app_theme.dart';

class StatisticsReportScreen extends StatefulWidget {
  final HomeController controller;

  const StatisticsReportScreen({
    required this.controller,
    super.key,
  });

  @override
  State<StatisticsReportScreen> createState() => _StatisticsReportScreenState();
}

class _StatisticsReportScreenState extends State<StatisticsReportScreen> {
  @override
  void initState() {
    super.initState();
    // Load statistics if not already loaded
    if (widget.controller.statsLoadState == StatisticsLoadState.initial) {
      widget.controller.loadStatistics();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scaffoldBg = isDark ? AppColors.nightBg : const Color(0xFFF5FAF3);
    final cardBg = isDark ? AppColors.nightCard : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white60 : Colors.grey[600];
    final accent = isDark ? AppColors.forestLight : const Color(0xFF2D6A4F);
    final dividerColor =
        isDark ? Colors.white24 : Colors.grey.withValues(alpha: 0.5);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Scan Statistics Report',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([]),
        builder: (context, _) {
          final state = widget.controller.statsLoadState;
          final counts = widget.controller.diseaseCounts;
          final year = widget.controller.selectedYear;

          return RefreshIndicator(
            onRefresh: () => widget.controller.retryLoadStatistics(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Year Selector
                  _buildYearSelector(
                    year,
                    cardBg,
                    textPrimary,
                    accent,
                    isDark,
                  ),
                  const SizedBox(height: 20),

                  // Content based on state
                  if (state == StatisticsLoadState.loading)
                    _buildLoadingState(cardBg, accent)
                  else if (state == StatisticsLoadState.offline)
                    _buildOfflineState(cardBg, textPrimary, textSecondary)
                  else if (state == StatisticsLoadState.serverUnreachable)
                    _buildServerUnreachableState(
                        cardBg, textPrimary, textSecondary)
                  else if (state == StatisticsLoadState.authError)
                    _buildAuthErrorState(cardBg, textPrimary, textSecondary)
                  else if (state == StatisticsLoadState.error)
                    _buildErrorState(
                        cardBg, textPrimary, textSecondary, widget.controller.statsError)
                  else if (state == StatisticsLoadState.empty)
                    _buildEmptyState(cardBg, textPrimary, textSecondary, year)
                  else if (state == StatisticsLoadState.success && counts != null)
                    _buildSuccessState(
                      counts,
                      cardBg,
                      textPrimary,
                      textSecondary,
                      accent,
                      dividerColor,
                      year,
                    )
                  else
                    _buildInitialState(cardBg, textPrimary, textSecondary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildYearSelector(
    int? selectedYear,
    Color cardBg,
    Color textPrimary,
    Color accent,
    bool isDark,
  ) {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => currentYear - index);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Period',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildYearChip('All Time', null, selectedYear, accent, isDark),
              ...years.map((year) =>
                  _buildYearChip(year.toString(), year, selectedYear, accent, isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYearChip(
      String label, int? year, int? selectedYear, Color accent, bool isDark) {
    final isSelected = year == selectedYear;

    return GestureDetector(
      onTap: () => widget.controller.changeYear(year),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? accent
                : isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : isDark
                    ? Colors.white70
                    : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(Color cardBg, Color accent) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: accent),
            const SizedBox(height: 16),
            Text(
              'Loading statistics...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineState(
      Color cardBg, Color textPrimary, Color? textSecondary) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.wifi_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Scan report unavailable',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect to the internet to load your\nlatest disease scan statistics.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: textSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => widget.controller.retryLoadStatistics(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D6A4F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerUnreachableState(
      Color cardBg, Color textPrimary, Color? textSecondary) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off, size: 64, color: Colors.orange[400]),
          const SizedBox(height: 16),
          Text(
            'Server unavailable',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unable to reach the server.\nPlease try again in a moment.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: textSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => widget.controller.retryLoadStatistics(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D6A4F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthErrorState(
      Color cardBg, Color textPrimary, Color? textSecondary) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Authentication failed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please log in again to view your statistics.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
      Color cardBg, Color textPrimary, Color? textSecondary, String? error) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Error loading statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error ?? 'An unexpected error occurred',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: textSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => widget.controller.retryLoadStatistics(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D6A4F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      Color cardBg, Color textPrimary, Color? textSecondary, int? year) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            year != null ? 'No scans in $year' : 'No scans yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            year != null
                ? 'You haven\'t scanned any cacao pods in $year.'
                : 'Your scan statistics will appear here\nafter you scan a cacao pod.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState(
      Color cardBg, Color textPrimary, Color? textSecondary) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Select a period above',
            style: TextStyle(
              fontSize: 16,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(
    DiseaseCountsModel counts,
    Color cardBg,
    Color textPrimary,
    Color? textSecondary,
    Color accent,
    Color dividerColor,
    int? year,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                year != null ? 'Scans in $year' : 'All-Time Scans',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                counts.totalScans.toString(),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: accent,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total Scans',
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Statistics Grid
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Healthy',
                counts.healthy,
                Icons.check_circle_outline,
                accent,
                cardBg,
                textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Diseased',
                counts.totalDiseased,
                Icons.warning_amber_outlined,
                Colors.redAccent,
                cardBg,
                textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Disease Breakdown
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Disease Breakdown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildDiseaseRow(
                'Black Pod Disease',
                counts.blackPodDisease,
                Colors.brown,
                textPrimary,
                textSecondary,
              ),
              Divider(height: 24, color: dividerColor),
              _buildDiseaseRow(
                'Mealybug',
                counts.mealybug,
                Colors.purple,
                textPrimary,
                textSecondary,
              ),
              Divider(height: 24, color: dividerColor),
              _buildDiseaseRow(
                'Cacao Pod Borer',
                counts.cacaoPodBorer,
                Colors.orange,
                textPrimary,
                textSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    int value,
    IconData icon,
    Color color,
    Color cardBg,
    Color textPrimary,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseRow(
    String name,
    int count,
    Color color,
    Color textPrimary,
    Color? textSecondary,
  ) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}
