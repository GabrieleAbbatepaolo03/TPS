import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user_interface/SERVICES/map_style_service.dart';

class HomeMapWidget extends StatefulWidget {
  final bool locationAccessGranted;
  final LatLng currentPosition;
  final Set<Marker> markers;
  final Function(GoogleMapController) onMapCreated;
  final bool isLoading;
  final void Function()? onTap;
  final bool gesturesEnabled;

  const HomeMapWidget({
    super.key,
    required this.locationAccessGranted,
    required this.currentPosition,
    required this.markers,
    required this.onMapCreated,
    required this.isLoading,
    this.onTap,
    required this.gesturesEnabled,
  });

  @override
  State<HomeMapWidget> createState() => _HomeMapWidgetState();
}

class _HomeMapWidgetState extends State<HomeMapWidget> {
  String _mapStyle = MapStyleService.lightStyle;
  GoogleMapController? _controller;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
  }

  @override
  void didUpdateWidget(HomeMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload style when widget updates
    _loadMapStyle();
  }

  Future<void> _loadMapStyle() async {
    final style = await MapStyleService.getCurrentStyle();
    if (mounted) {
      setState(() {
        _mapStyle = style;
      });
      // Update existing map controller if available
      _controller?.setMapStyle(_mapStyle);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    controller.setMapStyle(_mapStyle);
    widget.onMapCreated(controller);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        webCameraControlEnabled: false,
        initialCameraPosition: CameraPosition(
          target: widget.currentPosition,
          zoom: 16,
        ),
        markers: widget.markers,
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
}