import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart'; // se usi Iconly per le icone

class SearchBarWidget extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final TextEditingController controller;
  final FocusNode? focusNode; 

  const SearchBarWidget({
    super.key,
    required this.hintText,
    required this.onChanged,
    required this.controller,
    this.focusNode, 
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final bool hasText = value.text.isNotEmpty;

        return Container(
          padding: const EdgeInsets.only(left: 6),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 6, 20, 43),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            child: TextField(
              controller: controller,
              focusNode: focusNode, 
              style: GoogleFonts.poppins(
                  color: Colors.indigoAccent, fontSize: 20),
              cursorColor: Colors.indigoAccent,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.poppins(color: Colors.indigoAccent),
                prefixIcon:
                    const Icon(IconlyLight.search, color: Colors.indigoAccent),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                suffixIcon: hasText
                    ? IconButton(
                        icon:
                            const Icon(Icons.close, color: Colors.indigoAccent),
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                      )
                    : null,
              ),
              onChanged: onChanged, 
            ),
          ),
        );
      },
    );
  }
}