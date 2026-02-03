import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user_interface/SERVICES/map_style_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_interface/STATE/map_style_state.dart';

class HomeMapWidget extends ConsumerStatefulWidget {
  final bool locationAccessGranted;
  final LatLng currentPosition;
  final Set<Marker> markers;
  final Set<Polygon> polygons;
  final Function(GoogleMapController) onMapCreated;
  final bool isLoading;
  final VoidCallback? onTap;
  final bool gesturesEnabled;

  const HomeMapWidget({
    Key? key,
    required this.locationAccessGranted,
    required this.currentPosition,
    required this.markers,
    required this.polygons,
    required this.onMapCreated,
    required this.isLoading,
    this.onTap,
    this.gesturesEnabled = true,
  }) : super(key: key);

  @override
  ConsumerState<HomeMapWidget> createState() => _HomeMapWidgetState();
}

class _HomeMapWidgetState extends ConsumerState<HomeMapWidget> {
  GoogleMapController? _controller;

  @override
  Widget build(BuildContext context) {
    // Watch the map style provider to trigger rebuilds
    ref.listen<bool>(mapStyleProvider, (previous, next) {
      // When style changes, update the map
      if (previous != next && _controller != null) {
        _updateMapStyle();
      }
    });

    const backgroundGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        Color.fromARGB(255, 52, 12, 108),
        Color.fromARGB(255, 2, 11, 60),
      ],
    );
    
    if (widget.isLoading) {
      return Container(
        decoration: const BoxDecoration(gradient: backgroundGradient),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    
    if (widget.locationAccessGranted) {
      return GoogleMap(
        onMapCreated: _onMapCreated,
        zoomControlsEnabled: false,
        initialCameraPosition: CameraPosition(
          target: widget.currentPosition,
          zoom: 16,
        ),
        markers: widget.markers,
        polygons: widget.polygons,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onTap: (_) => widget.onTap?.call(),
        scrollGesturesEnabled: widget.gesturesEnabled,
        zoomGesturesEnabled: widget.gesturesEnabled,
        tiltGesturesEnabled: widget.gesturesEnabled,
        rotateGesturesEnabled: widget.gesturesEnabled,
      );
    } else {
      return Container(
        decoration: const BoxDecoration(gradient: backgroundGradient),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_disabled,
                    color: Colors.white70, size: 60),
                const SizedBox(height: 20),
                Text('Location Access Denied',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Text(
                    "Map visualization is disabled because location services are off or permissions were denied. Please enable location access in your device settings.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 16)),
              ],
            ),
          ),
        ),
      );
    }
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _controller = controller;
    await _updateMapStyle();
    widget.onMapCreated(controller);
  }

  Future<void> _updateMapStyle() async {
    if (_controller != null) {
      final style = await MapStyleService.getCurrentStyle();
      await _controller!.setMapStyle(style);
    }
  }
}