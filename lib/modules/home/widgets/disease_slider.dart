import 'package:flutter/material.dart';

class DiseaseSlider extends StatefulWidget {
  final List<Map<String, dynamic>> diseaseData;
  final Function(int) onDiseaseTap;

  const DiseaseSlider({
    super.key,
    required this.diseaseData,
    required this.onDiseaseTap,
  });

  @override
  State<DiseaseSlider> createState() => _DiseaseSliderState();
}

class _DiseaseSliderState extends State<DiseaseSlider> {
  late PageController _pageController;
  // Start tracking from index 1 (the 2nd image)
  int _activePage = 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.82,
      initialPage: 1,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.diseaseData.length,
            onPageChanged: (int index) {
              setState(() => _activePage = index);
            },
            itemBuilder: (context, index) {
              return _buildRectangleCard(context, index);
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildIndicator(context),
      ],
    );
  }

  Widget _buildRectangleCard(BuildContext context, int index) {
    bool isActive = index == _activePage;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => widget.onDiseaseTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: isActive ? 0 : 12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16), 
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? (isActive ? 90 : 40) : (isActive ? 51 : 13)),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background Image
              Image.asset(
                widget.diseaseData[index]["image"]!,
                fit: BoxFit.cover,
              ),

              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withAlpha(204),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),

              Positioned(
                top: 12,
                right: 12,
                child: _buildBadge(),
              ),

              // 4. Information Layer
              Positioned(
                bottom: 15,
                left: 15,
                right: 15,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.diseaseData[index]["title"]!.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.diseaseData[index]["origin"] ?? "Global",
                      style: TextStyle(
                        color: Colors.white.withAlpha(204), // 0.8 * 255 = 204
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51), // 0.2 * 255 = 51
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withAlpha(77)), // 0.3 * 255 = 77
      ),
      child: const Text(
        "COMMON DISEASE",
        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildIndicator(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? Colors.white24 : Colors.grey.withAlpha(77);
    final activeColor = isDark ? Colors.greenAccent.shade400 : Colors.green;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.diseaseData.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 4,
          width: _activePage == index ? 18 : 6,
          decoration: BoxDecoration(
            color: _activePage == index ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}