import 'package:flutter/material.dart';
import 'package:user_interface/MAIN%20UTILS/BOTTOM%20NAV%20BAR/bottom_nav_btn.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;
  final List<IconData> icons;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
    required this.icons,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(25),
        color: Colors.transparent,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 6, 20, 43),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              icons.length,
              (index) => BottomNavBTN(
                onPressed: onItemSelected,
                icon: icons[index],
                currentIndex: currentIndex,
                index: index,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
