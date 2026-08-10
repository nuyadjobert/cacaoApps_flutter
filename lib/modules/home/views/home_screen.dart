import 'dart:ui';
import 'package:cacao_apps/modules/settings/views/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../disease/views/disease_detail_sheet.dart';

import '../widgets/total_scanned_card.dart';
import '../widgets/disease_slider.dart';
import '../widgets/inspection_card.dart';
import '../widgets/notification_icon.dart';
import '../../learn/views/learn_hub_screen.dart';
import '../../history/views/history_screen.dart';
import '../../notifications/views/notification_screen.dart';
import '../../scan/views/scanner_screen.dart';
import '../../components/loading-state/loading_screen.dart';
import '../Controller/home_controller.dart';
import '../../components/skeletons-state/skeleton_loading.dart';
import '../../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey _profileKey = GlobalKey();
  final GlobalKey _catalogKey = GlobalKey();
  final GlobalKey _scannerKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final HomeController _controller = HomeController();

  int _bottomNavIndex = 0;
  int _targetIndex = 0;
  late PageController _pageController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _controller.startBackgroundServices().then((_) {
      if (mounted) setState(() {});
    });

    // Using controller methods instead of handling it directly in view
    _controller.startSync();
    _controller.checkPendingScans();
    _controller.syncGuideData();

    // Load scan statistics
    _controller.loadStatistics();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ShowcaseView.get().startShowCase([_profileKey, _catalogKey, _scannerKey]);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controller.stopSync(); // Delegate to controller
    super.dispose();
  }

  void _showDiseaseDetails(Map<String, dynamic> disease) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DiseaseDetailSheet(disease: disease),
    );
  }

  void _handleNavigation(int index) async {
    if (index == _bottomNavIndex) return;

    setState(() {
      _targetIndex = index;
      _isLoading = true;
    });

    try {
      await _controller.fetchData(index);
    } catch (e) {
      debugPrint("Navigation Error: $e");
    } finally {
      if (mounted) {
        _pageController.jumpToPage(index);
        setState(() {
          _bottomNavIndex = index;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Core surfaces
    final scaffoldBg = isDark ? AppColors.nightBg : const Color(0xFFF5FAF3);
    final surfaceCard = isDark ? AppColors.nightCard : Colors.white;
    final avatarBg = isDark ? AppColors.nightCard : const Color(0xFFF1F1F1);

    // Text
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white60 : Colors.grey[600];
    final navInactiveIcon = isDark ? Colors.white38 : Colors.grey[400];
    final navInactiveText = isDark ? Colors.white54 : Colors.grey[500];

    // Brand / accent (green stays green, just lightens a touch in dark mode
    // so it doesn't disappear against the dark surfaces)
    final accent = isDark ? AppColors.forestLight : const Color(0xFF2D6A4F);
    final avatarIconColor = isDark ? AppColors.forestLight : Colors.green;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: surfaceCard,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: scaffoldBg,
        extendBody: true,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _bottomNavIndex = index);
              },
              children: [
                _buildHomeContent(
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  avatarBg: avatarBg,
                  avatarIconColor: avatarIconColor,
                ),
                const HistoryScreen(),
                const LearnHubScreen(),
                const SettingsScreen(),
              ],
            ),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: scaffoldBg,
                  child: Stack(
                    children: [
                      SkeletonLayout(pageIndex: _targetIndex),
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                        child: Container(
                          color: scaffoldBg.withAlpha(102),
                          child: const Center(child: TheobroTectLoader()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(top: 30),
          child: SizedBox(
            height: 56, // Slightly increased for a better touch target
            width: 56,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ScannerScreen()),
                );
              },
              backgroundColor: const Color(0xFF2D6A4F),
              elevation: 5,
              shape: const CircleBorder(),
              tooltip: 'Detect Cacao Disease', // Added for UX & accessibility
              child: const Icon(
                Icons
                    .camera_enhance_rounded, // Replaced QR icon with Smart Camera icon
                color: Colors.white,
                size: 28, // Made slightly larger for emphasis
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          color: surfaceCard,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          elevation: 20,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  0,
                  Icons.eco_outlined,
                  Icons.eco_rounded,
                  "Home",
                  accent,
                  navInactiveIcon,
                  navInactiveText,
                ),
                _buildNavItem(
                  1,
                  Icons.history_rounded,
                  Icons.history_rounded,
                  "History",
                  accent,
                  navInactiveIcon,
                  navInactiveText,
                ),
                const SizedBox(width: 40),
                _buildNavItem(
                  2,
                  Icons.menu_book_rounded,
                  Icons.menu_book_rounded,
                  "Learn",
                  accent,
                  navInactiveIcon,
                  navInactiveText,
                ),
                _buildNavItem(
                  3,
                  Icons.settings_rounded,
                  Icons.settings_rounded,
                  "Settings",
                  accent,
                  navInactiveIcon,
                  navInactiveText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    Color activeColor,
    Color? inactiveIconColor,
    Color? inactiveTextColor,
  ) {
    bool isActive = _bottomNavIndex == index;
    return GestureDetector(
      onTap: () => _handleNavigation(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            color: isActive ? activeColor : inactiveIconColor,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? activeColor : inactiveTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent({
    required bool isDark,
    required Color textPrimary,
    required Color? textSecondary,
    required Color avatarBg,
    required Color avatarIconColor,
  }) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Showcase(
                      key: _profileKey,
                      title: 'Your Profile',
                      description:
                          'Manage your farm settings and account details here.',
                      child: GestureDetector(
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.green.withAlpha(
                                (0.2 * 255).toInt(),
                              ),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: avatarBg,
                            child: Icon(
                              Icons.person_outline,
                              color: avatarIconColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _controller.getGreeting(),
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),
                        Text(
                          "${_controller.userName ?? 'Farmer'}!",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (context) => const NotificationScreen(),
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: NotificationIcon(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Showcase(
                  key: _catalogKey,
                  title: 'Disease Catalog',
                  description:
                      'Tap or swipe to see symptoms of common cacao diseases.',
                  child: DiseaseSlider(
                    diseaseData: _controller.diseaseData,
                    onDiseaseTap: (index) {
                      _showDiseaseDetails(_controller.diseaseData[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  Text(
                    "Quick Inspection",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Showcase(
                    key: _scannerKey,
                    title: 'AI Scanner',
                    description:
                        'Use your camera to identify diseases in the field.',
                    child: const InspectionCard(),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    "Recent Activity",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TotalScannedCard(controller: _controller),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
