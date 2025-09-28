import 'package:flutter/material.dart';

class PumoTabBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const PumoTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF000000),
        border: Border(
          top: BorderSide(
            color: Colors.grey,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(4, (index) {
              return _buildTabItem(index);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index) {
    final isSelected = currentIndex == index;
    final imagePath = isSelected
        ? 'assets/resources/tabar_pre/pumo_tab_${index + 1}.webp'
        : 'assets/resources/tabar_nor/pumo_tab_${index + 1}.webp';

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Image.asset(
          imagePath,
          width: 29,
          height: 29,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
