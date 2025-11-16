import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user_interface/MODELS/parking_lot.dart';
import 'package:user_interface/MAIN%20UTILS/parking_lot_card.dart';

class HomeSearchResultsList extends StatelessWidget {
  final String searchQuery;
  final List<ParkingLot> filteredParkingLots;
  final LatLng userPosition;
  final void Function(ParkingLot) onParkingLotTap;

  const HomeSearchResultsList({
    super.key,
    required this.searchQuery,
    required this.filteredParkingLots,
    required this.userPosition,
    required this.onParkingLotTap,
  });

  @override
  Widget build(BuildContext context) {

    if (searchQuery.isNotEmpty && filteredParkingLots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'No results for "$searchQuery"',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true, 
      physics: const ClampingScrollPhysics(), 
      padding: const EdgeInsets.only(top: 10, bottom: 0, left: 10, right: 10),
      itemCount: filteredParkingLots.length,
      itemBuilder: (context, index) {
        final lot = filteredParkingLots[index];
        return ParkingLotCard(
          parkingLot: lot,
          userPosition: userPosition, 
          onTap: () {
            onParkingLotTap(lot);
          },
        );
      },
    );
  }
}