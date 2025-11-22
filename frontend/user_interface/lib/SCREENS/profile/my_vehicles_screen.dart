import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_interface/MAIN UTILS/my_vehicle_section.dart';
import 'package:user_interface/MAIN%20UTILS/app_theme.dart';

class MyVehiclesScreen extends StatelessWidget {
  const MyVehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Vehicles',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: AppTheme.backgroundGradientDecoration,
        child: const SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.0),
            child: MyVehiclesSection(),
          ),
        ),
      ),
    );
  }
}
