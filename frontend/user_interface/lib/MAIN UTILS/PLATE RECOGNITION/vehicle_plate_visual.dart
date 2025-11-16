import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_interface/MAIN UTILS/PLATE RECOGNITION/plate_recognition_service.dart';

class PlateWidget extends StatelessWidget {
  final PlateCountry? country;
  final String plate;

  const PlateWidget({
    super.key,
    required this.country,
    required this.plate,
  });

  @override
  Widget build(BuildContext context) {
    final style = plateStyles[country?.countryCode] ?? plateStyles['EU']!;

    return Container(
      width: 190,
      height: 50,
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.7),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          style.leftBandBuilder(country),
          Expanded(
            child: Center(
              child: Text(
                plate,
                style: GoogleFonts.robotoMono(
                  color: style.textColor,
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          style.rightBandBuilder(country),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              STYLE DEFINITIONS                              */
/* -------------------------------------------------------------------------- */

class PlateStyle {
  final Color backgroundColor;
  final Color textColor;
  final Widget Function(PlateCountry?) leftBandBuilder;
  final Widget Function(PlateCountry?) rightBandBuilder;

  const PlateStyle({
    required this.backgroundColor,
    required this.textColor,
    required this.leftBandBuilder,
    required this.rightBandBuilder,
  });
}

final Map<String, PlateStyle> plateStyles = {
  // 🇪🇺 Standard Europe
  'EU': PlateStyle(
    backgroundColor: Colors.white,
    textColor: Colors.black,
    leftBandBuilder: (country) => _EUBlueBandLeft(country),
    rightBandBuilder: (country) => _EUBlueBandRight(),
  ),

  // 🇮🇹 Italia (stesse europee ma con codice IT)
  'I': PlateStyle(
    backgroundColor: Colors.white,
    textColor: Colors.black,
    leftBandBuilder: (country) => _EUBlueBandLeft(country),
    rightBandBuilder: (country) => _EUBlueBandRight(),
  ),

  // 🇫🇷 Francia
  'F': PlateStyle(
    backgroundColor: Colors.white,
    textColor: Colors.black,
    leftBandBuilder: (country) => _EUBlueBandLeft(country),
    rightBandBuilder: (country) => _EUBlueBandRight(),
  ),

  // 🇩🇪 Germania
  'D': PlateStyle(
    backgroundColor: Colors.white,
    textColor: Colors.black,
    leftBandBuilder: (country) => _EUBlueBandLeft(country),
    rightBandBuilder: (country) => _EUBlueBandRight(),
  ),

  // 🇪🇸 Spagna
  'E': PlateStyle(
    backgroundColor: Colors.white,
    textColor: Colors.black,
    leftBandBuilder: (country) => _EUBlueBandLeft(country),
    rightBandBuilder: (country) => _EUBlueBandRight(),
  ),

  // 🇨🇭 Svizzera
  'CH': PlateStyle(
    backgroundColor: Colors.white,
    textColor: Colors.black,
    leftBandBuilder: (country) => _CHLeftBand(),
    rightBandBuilder: (country) => const SizedBox(width: 10),
  ),

  // 🇳🇱 Paesi Bassi
  'NL': PlateStyle(
    backgroundColor: const Color.fromARGB(255, 255, 196, 0),
    textColor: Colors.black,
    leftBandBuilder: (country) => _EUBlueBandLeft(country),
    rightBandBuilder: (country) => _EUBlueBandRight(),
  ),

  // 🇵🇱 Polonia
  'PL': PlateStyle(
    backgroundColor: Colors.white,
    textColor: Colors.black,
    leftBandBuilder: (country) => _SimpleBlueBand(country),
    rightBandBuilder: (country) => const SizedBox(width: 10),
  ),

  // 🇬🇧 Regno Unito
  'UK': PlateStyle(
    backgroundColor: const Color.fromARGB(255, 255, 196, 0),
    textColor: Colors.black,
    leftBandBuilder: (country) => const SizedBox(width: 10),
    rightBandBuilder: (country) => const SizedBox(width: 10),
  ),

  // 🇳🇴 Norvegia
  'N': PlateStyle(
    backgroundColor: Colors.white,
    textColor: Colors.black,
    leftBandBuilder: (country) => _SimpleBlueBand(country),
    rightBandBuilder: (country) => const SizedBox(width: 10),
  ),
};

/* -------------------------------------------------------------------------- */
/*                           BLUE BANDS & WIDGETS                              */
/* -------------------------------------------------------------------------- */

Widget _EUBlueBandLeft(PlateCountry? country) {
  return Container(
    width: 25,
    decoration: const BoxDecoration(
      color: Color(0xFF003399),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(5),
        bottomLeft: Radius.circular(5),
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStarCircle(size: 20),
        const SizedBox(height: 2),
        Text(
          country?.countryCode ?? '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        )
      ],
    ),
  );
}

Widget _EUBlueBandRight() {
  return Container(
    width: 25,
    decoration: const BoxDecoration(
      color: Color(0xFF003399),
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(5),
        bottomRight: Radius.circular(5),
      ),
    ),
    child: Align( 
      alignment: Alignment.topCenter, 
      child: Padding( 
        padding: const EdgeInsets.only(top: 6), 
        child: Container( 
          width: 18, height: 18, 
          decoration: BoxDecoration( 
            color: Colors.transparent, 
            shape: BoxShape.circle, 
            border: Border.all(color: const Color(0xFFFFCC00), width: 1), 
          ), 
        ), 
      ), 
    ),
  );
}

Widget _SimpleBlueBand(PlateCountry? country) {
  return Container(
    width: 25,
    color: const Color(0xFF003399),
    child: Center(
      child: Text(
        country?.countryCode ?? '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

Widget _CHLeftBand() {
  return Container(
    width: 30,

    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(5),
        bottomLeft: Radius.circular(5),
      ),
    ),
    child: const Center(
      child: Text(
        "CH",
        style: TextStyle(
          color: Colors.red,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

/* -------------------------------------------------------------------------- */
/*                                EU STARS                                    */
/* -------------------------------------------------------------------------- */

Widget _buildStarCircle({required double size}) {
  return SizedBox(
    width: size,
    height: size,
    child: Stack(
      children: List.generate(12, (index) {
        double angle = 2 * math.pi * (index / 12);
        double radius = size / 2.5;

        return Positioned(
          left: size / 2 + radius * math.cos(angle) - 2,
          top: size / 2 + radius * math.sin(angle) - 2,
          child: const Icon(
            Icons.star,
            color: Color(0xFFFFCC00),
            size: 4,
          ),
        );
      }),
    ),
  );
}
