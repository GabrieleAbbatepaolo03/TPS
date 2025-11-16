import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';

class HomeSearchBar extends StatelessWidget {
  final double searchBarHeight;
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String) onChanged;

  const HomeSearchBar({
    super.key,
    required this.searchBarHeight,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: searchBarHeight,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, child) {
          final bool hasText = value.text.isNotEmpty;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: GoogleFonts.poppins(color: Colors.indigoAccent, fontSize: 20),
              cursorColor: Colors.indigoAccent,
              decoration: InputDecoration(
                hintText: 'Search Parkings in Your Area...',
                hintStyle: GoogleFonts.poppins(color: Colors.indigoAccent),
                prefixIcon:
                    const Icon(IconlyLight.search, color: Colors.indigoAccent),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                suffixIcon: hasText
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.indigoAccent),
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                      )
                    : null,
              ),
              onChanged: onChanged,
            ),
          );
        },
      ),
    );
  }
}