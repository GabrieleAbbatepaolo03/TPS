import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class PlateSearchSection extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onScan;
  final VoidCallback onSearch;

  const PlateSearchSection({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onScan,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildPlateTextField()),
            const SizedBox(width: 12),
            // Scan Button
            ElevatedButton(
              onPressed: isLoading ? null : onScan,
              style: _buttonStyle(Colors.amberAccent),
              child: const Icon(Icons.photo_camera, size: 28),
            ),
            const SizedBox(width: 12),
            // Search Button
            ElevatedButton(
              onPressed: isLoading ? null : onSearch,
              style: _buttonStyle(Colors.greenAccent),
              child: isLoading
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: Colors.greenAccent,
                        strokeWidth: 3,
                      ),
                    )
                  : const Icon(Icons.search, size: 28),
            ),
          ],
        ),
      ],
    );
  }

  ButtonStyle _buttonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF2A2D3E),
      foregroundColor: color,
      padding: const EdgeInsets.all(20),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color, width: 2),
      ),
    );
  }

  Widget _buildPlateTextField() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.sourceCodePro(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.normal,
          letterSpacing: 4,
        ),
        cursorColor: Colors.greenAccent,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
          TextInputFormatter.withFunction((oldValue, newValue) {
            return newValue.copyWith(text: newValue.text.toUpperCase());
          }),
        ],
        decoration: InputDecoration(
          hintText: "Plate No.",
          hintStyle: GoogleFonts.sourceCodePro(
            color: Colors.white24,
            fontSize: 22,
            letterSpacing: 4,
          ),
          filled: true,
          fillColor: const Color(0xFF2A2D3E),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white24, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.greenAccent, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 22,
          ),
        ),
        onSubmitted: (_) => onSearch(),
      ),
    );
  }
}