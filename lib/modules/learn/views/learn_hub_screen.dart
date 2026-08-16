import 'package:flutter/material.dart';
import '../widgets/guide_card.dart';
import '../widgets/prevention_tip_card.dart';
import '../widgets/management_sheet.dart';
import '../widgets/mastery_detail_screen.dart';
import '../widgets/tip_complete_dialog.dart';
import '../models/guide_model.dart';
import '../../../theme/app_theme.dart';

class _GuideCategory {
  final IconData icon;
  final String label;
  final String lookupKey;
  final Color bg;

  const _GuideCategory({
    required this.icon,
    required this.label,
    required this.lookupKey,
    required this.bg,
  });
}

// Represents one Mastery Course card.
class _MasteryCourse {
  final String title;
  final String duration;
  final Color themeColor;
  final String imageUrl;
  final String rating;
  final String enrollment;

  const _MasteryCourse({
    required this.title,
    required this.duration,
    required this.themeColor,
    required this.imageUrl,
    required this.rating,
    required this.enrollment,
  });
}

class LearnHubScreen extends StatefulWidget {
  const LearnHubScreen({super.key});

  @override
  State<LearnHubScreen> createState() => _LearnHubScreenState();
}

class _LearnHubScreenState extends State<LearnHubScreen> {
  static const List<_GuideCategory> _allCategories = [
    _GuideCategory(
      icon: Icons.agriculture_rounded,
      label: "Shade Mgmt",
      lookupKey: "Optimizing Shade",
      bg: Color(0xFFDCEDE1),
    ),
    _GuideCategory(
      icon: Icons.water_drop_outlined,
      label: "Irrigation",
      lookupKey: "Smart Irrigation",
      bg: Color(0xFFDCEAF7),
    ),
    _GuideCategory(
      icon: Icons.handyman_outlined,
      label: "Tool Care",
      lookupKey: "Tool Maintenance",
      bg: Color(0xFFFBE6D4),
    ),
    _GuideCategory(
      icon: Icons.inventory_2_outlined,
      label: "Storage",
      lookupKey: "Storage Basics",
      bg: Color(0xFFF3E5F5),
    ),
    _GuideCategory(
      icon: Icons.bug_report_outlined,
      label: "Pest Control",
      lookupKey: "Pest Control",
      bg: Color(0xFFFDE8E8),
    ),
  ];

  // Full set of Mastery Courses. Image keywords are chosen to match each
  // title (e.g. rain/crops for "Rainy Season Care") using LoremFlickr's
  // tag-based photo endpoint: https://loremflickr.com/{w}/{h}/{tags}
  static const List<_MasteryCourse> _allCourses = [
    _MasteryCourse(
      title: "Soil Fertility Secrets",
      duration: "8 min",
      themeColor: Colors.brown,
      imageUrl: "https://loremflickr.com/400/300/soil,fertility,farm?lock=101",
      rating: "4.8",
      enrollment: "65",
    ),
    _MasteryCourse(
      title: "Rainy Season Care",
      duration: "5 min",
      themeColor: Colors.blue,
      imageUrl: "https://loremflickr.com/400/300/rain,crops,field?lock=102",
      rating: "4.7",
      enrollment: "40",
    ),
    _MasteryCourse(
      title: "Organic Compost",
      duration: "12 min",
      themeColor: Colors.green,
      imageUrl: "https://loremflickr.com/400/300/compost,organic,farm?lock=103",
      rating: "4.9",
      enrollment: "112",
    ),
  ];

  final ScrollController _courseScrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  double _courseScrollProgress = 0;
  double _categoryScrollProgress = 0;

  bool _tipCompletedToday = false;

  void _handleGotIt() {
    setState(() => _tipCompletedToday = true);
    showTipCompletedDialog(context);
  }

  @override
  void initState() {
    super.initState();
    _courseScrollController.addListener(_onCourseScroll);
    _categoryScrollController.addListener(_onCategoryScroll);
  }

  @override
  void dispose() {
    _courseScrollController.removeListener(_onCourseScroll);
    _courseScrollController.dispose();
    _categoryScrollController.removeListener(_onCategoryScroll);
    _categoryScrollController.dispose();
    super.dispose();
  }

  void _onCourseScroll() {
    final maxExtent = _courseScrollController.position.maxScrollExtent;
    setState(() {
      _courseScrollProgress = maxExtent > 0
          ? (_courseScrollController.offset / maxExtent).clamp(0.0, 1.0)
          : 0;
    });
  }

  void _onCategoryScroll() {
    final maxExtent = _categoryScrollController.position.maxScrollExtent;
    setState(() {
      _categoryScrollProgress = maxExtent > 0
          ? (_categoryScrollController.offset / maxExtent).clamp(0.0, 1.0)
          : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : AppColors.creamBg;
    final cardBg = isDark ? AppColors.nightCard : AppColors.creamCard;
    final textPrimary = isDark ? Colors.white : AppColors.forestDark;
    final textSecondary = isDark ? Colors.white60 : Colors.grey.shade600;
    final divider = isDark ? AppColors.nightDivider : Colors.grey.shade200;
    final accent = isDark ? AppColors.forestLight : AppColors.forestMid;
    final muted = isDark ? AppColors.forestLight.withAlpha(200) : const Color(0xFF6B8F71);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            backgroundColor: bg,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text("Knowledge Hub",
                  style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  // --> Sterilize Pruning Tools ----
                  PreventionTipCard(
                    label: "TODAY'S ACTION",
                    message:
                        "Sterilize your pruning tools before moving between trees.",
                    icon: _tipCompletedToday
                        ? Icons.check_circle_rounded
                        : Icons.sanitizer_rounded,
                    buttonLabel: _tipCompletedToday ? "Done for today" : "Got it",
                    onTap: _tipCompletedToday ? null : _handleGotIt,
                  ),
                  const SizedBox(height: 32),

                  //  -> "Management Guides" ----
                  _buildSectionHeader(
                    context,
                    title: "Management Guides",
                    textPrimary: textPrimary,
                    muted: muted,
                    onViewAll: () => _showAllCategories(context, cardBg, textPrimary, divider, accent, muted),
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryRow(context, cardBg, divider, accent, textPrimary),
                  const SizedBox(height: 12),
                  _buildScrollIndicator(
                    itemCount: _allCategories.length,
                    progress: _categoryScrollProgress,
                    accent: accent,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 32),

                  // "Mastery Courses" ----
                  _buildSectionHeader(
                    context,
                    title: "Mastery Courses",
                    textPrimary: textPrimary,
                    muted: muted,
                    onViewAll: () => _showAllCourses(context, cardBg, textPrimary),
                  ),
                  const SizedBox(height: 16),
                  _buildHorizontalGuides(context),
                  const SizedBox(height: 12),
                  _buildScrollIndicator(
                    itemCount: _allCourses.length,
                    progress: _courseScrollProgress,
                    accent: accent,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${_allCourses.length} courses available",
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // "View all" for Mastery Courses -> bottom sheet with a scrollable grid
  void _showAllCourses(BuildContext context, Color cardBg, Color textPrimary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "All Mastery Courses (${_allCourses.length})",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: Icon(Icons.close, color: textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.55,
                  child: GridView.builder(
                    itemCount: _allCourses.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.78,
                    ),
                    itemBuilder: (context, index) {
                      final course = _allCourses[index];
                      return GuideCard(
                        title: course.title,
                        duration: course.duration,
                        themeColor: course.themeColor,
                        imageUrl: course.imageUrl,
                        rating: course.rating,
                        enrollment: course.enrollment,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MasteryDetailScreen(
                                title: course.title,
                                themeColor: course.themeColor,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // "View all" for Management Guide categories -> bottom sheet grid
  void _showAllCategories(
    BuildContext context,
    Color cardBg,
    Color textPrimary,
    Color divider,
    Color accent,
    Color muted,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "All Management Guides (${_allCategories.length})",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: Icon(Icons.close, color: textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: ListView.separated(
                    itemCount: _allCategories.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: divider,
                    ),
                    itemBuilder: (context, index) {
                      final category = _allCategories[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _openGuideSheet(context, category, cardBg, textPrimary);
                        },
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: divider,
                              width: 1,
                            ),
                          ),
                          child: Icon(category.icon, color: accent, size: 24),
                        ),
                        title: Text(
                          category.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: muted,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openGuideSheet(
    BuildContext context,
    _GuideCategory category,
    Color cardBg,
    Color textPrimary,
  ) {
    final steps = ManagementData.content[category.lookupKey] ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ManagementSheet(
        title: category.lookupKey,
        steps: steps,
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required Color textPrimary,
    required Color muted,
    VoidCallback? onViewAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: textPrimary,
          ),
        ),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Row(
              children: [
                Text(
                  "View all",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: muted,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 16, color: muted),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryRow(
    BuildContext context,
    Color cardBg,
    Color divider,
    Color accent,
    Color textPrimary,
  ) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        controller: _categoryScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _allCategories.length,
        itemBuilder: (context, index) {
          final category = _allCategories[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index == _allCategories.length - 1 ? 0 : 16,
            ),
            child: GestureDetector(
              onTap: () => _openGuideSheet(context, category, cardBg, textPrimary),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: divider,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(category.icon, color: accent, size: 32),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    category.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Mastery Courses -> horizontal scroll using your real GuideCard
  Widget _buildHorizontalGuides(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        controller: _courseScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _allCourses.length,
        itemBuilder: (context, index) {
          final course = _allCourses[index];
          return GuideCard(
            title: course.title,
            duration: course.duration,
            themeColor: course.themeColor,
            imageUrl: course.imageUrl,
            rating: course.rating,
            enrollment: course.enrollment,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MasteryDetailScreen(
                  title: course.title,
                  themeColor: course.themeColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScrollIndicator({
    required int itemCount,
    required double progress,
    required Color accent,
    required bool isDark,
  }) {
    final dotCount = itemCount;
    final activeIndex =
        (progress * (dotCount - 1)).round().clamp(0, dotCount - 1);
    final inactiveColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(dotCount, (i) {
        final isActive = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? accent : inactiveColor,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}