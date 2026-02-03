import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:manager_interface/models/parking.dart';
import 'package:manager_interface/models/city.dart';
import 'package:manager_interface/services/parking_service.dart';
import 'package:manager_interface/SERVICES/user_session.dart';
import 'package:manager_interface/SCREENS/parking%20detail/utils/edit_polygon_dialog.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

Future<Parking?> showAddParkingDialog(
  BuildContext context, {
  required List<String> authorizedCities,
  String? selectedCity,
  List<City>? citiesWithCoordinates,
  Parking? existingParking, // Add this parameter for edit mode
}) async {
  final bool isEditMode = existingParking != null;
  
  final nameController = TextEditingController(text: existingParking?.name ?? '');
  final addressController = TextEditingController(text: existingParking?.address ?? '');
  final totalSpotsController = TextEditingController(text: existingParking?.totalSpots.toString() ?? '');
  final latController = TextEditingController(text: existingParking?.latitude?.toStringAsFixed(6) ?? '');
  final lngController = TextEditingController(text: existingParking?.longitude?.toStringAsFixed(6) ?? '');
  final newCityController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final session = UserSession();
  final isSuperAdmin = session.isSuperAdmin;

  List<String> displayOptions = [];

  if (isSuperAdmin) {
    final allSuggestions = {
      ...authorizedCities,
      'Milano',
      'Roma',
      'Torino',
    }.toList();
    allSuggestions.sort();

    displayOptions = ['New City...', ...allSuggestions];
  } else {
    displayOptions = authorizedCities;
  }

  String selectedCityOption = displayOptions.isNotEmpty
      ? (existingParking?.city ?? // Use existing city if editing
          (selectedCity != null && displayOptions.contains(selectedCity) 
              ? selectedCity 
              : displayOptions.first))
      : '';

  bool isLoading = false;
  List<ParkingCoordinate> polygonCoords = existingParking?.polygonCoords ?? [];
  GoogleMapController? mapController;
  
  // Map preview state
  Set<Marker> previewMarkers = {};
  Set<Polygon> previewPolygons = {};
  LatLng? centerPosition = existingParking != null && 
                          existingParking.latitude != null && 
                          existingParking.longitude != null
      ? LatLng(existingParking.latitude!, existingParking.longitude!)
      : null;
  BitmapDescriptor? customMarkerIcon; // ADD THIS LINE - declare it here

  // Map style JSON (same as home screen)
 const String _mapStyle = '''
[
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "transit",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  }
]
''';

  // Load custom parking marker icon
  Future<BitmapDescriptor> loadCustomMarker() async {
    final ByteData byteData = await rootBundle.load(
      'assets/images/parking_marker.png',
    );

    final ui.Codec codec = await ui.instantiateImageCodec(
      byteData.buffer.asUint8List(),
      targetWidth: 80,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ui.Image image = fi.image;

    final ByteData? resizedByteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return BitmapDescriptor.fromBytes(resizedByteData!.buffer.asUint8List());
  }

  // Map dimensions - change these to resize everything
  const double _mapSize = 650.0;
  const double _dialogWidthPercentage = 0.75; // Reduced from 0.9 to 0.75 (200px less on typical screen)
  // Remove unused variable
  // const double _dialogHeightPercentage = 0.85;

  return showDialog<Parking>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          // Declare updateMapPreview before it's used
          void updateMapPreview({LatLng? newCenter}) {
            // If dragging center with existing polygon, translate polygon points
            if (newCenter != null && centerPosition != null && polygonCoords.isNotEmpty) {
              final latOffset = newCenter.latitude - centerPosition!.latitude;
              final lngOffset = newCenter.longitude - centerPosition!.longitude;
              
              // Translate all polygon points by the same offset
              polygonCoords = polygonCoords.map((coord) {
                return ParkingCoordinate(
                  lat: coord.lat + latOffset,
                  lng: coord.lng + lngOffset,
                );
              }).toList();
            }
            
            if (newCenter != null) {
              centerPosition = newCenter;
              latController.text = newCenter.latitude.toStringAsFixed(6);
              lngController.text = newCenter.longitude.toStringAsFixed(6);
            } else {
              final lat = double.tryParse(latController.text.replaceAll(',', '.'));
              final lng = double.tryParse(lngController.text.replaceAll(',', '.'));
              
              if (lat != null && lng != null) {
                centerPosition = LatLng(lat, lng);
              }
            }
            
            final newMarkers = <Marker>{};
            final newPolygons = <Polygon>{};
            
            if (centerPosition != null) {
              // Add center marker with custom icon - NOW DRAGGABLE
              newMarkers.add(
                Marker(
                  markerId: const MarkerId('center'),
                  position: centerPosition!,
                  draggable: true,  // Make marker draggable
                  onDragEnd: (newPosition) {
                    // Update when dragging ends - this will translate polygon
                    updateMapPreview(newCenter: newPosition);
                  },
                  icon: customMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                  infoWindow: const InfoWindow(title: 'Parking Center (Drag to move)'),
                ),
              );
              
              // Animate camera to center only if it's a new position
              if (newCenter != null && mapController != null) {
                mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(centerPosition!, 16),
                );
              }
            }
            
            // Add polygon if at least 3 points
            if (polygonCoords.length >= 3) {
              newPolygons.add(
                Polygon(
                  polygonId: const PolygonId('preview'),
                  points: polygonCoords.map((c) => LatLng(c.lat, c.lng)).toList(),
                  strokeColor: Colors.blueAccent,
                  strokeWidth: 3,
                  fillColor: Colors.blueAccent.withOpacity(0.2),
                ),
              );
              
              // Calculate polygon center for camera
              if (centerPosition == null && polygonCoords.isNotEmpty) {
                double sumLat = 0;
                double sumLng = 0;
                for (var coord in polygonCoords) {
                  sumLat += coord.lat;
                  sumLng += coord.lng;
                }
                final polygonCenter = LatLng(sumLat / polygonCoords.length, sumLng / polygonCoords.length);
                mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(polygonCenter, 16),
                );
              }
            }
            
            setState(() {
              previewMarkers = newMarkers;
              previewPolygons = newPolygons;
            });
          }

          // Load marker icon on first build
          if (customMarkerIcon == null) {
            loadCustomMarker().then((icon) {
              setState(() {
                customMarkerIcon = icon;
              });
              // Initialize map preview after icon is loaded in edit mode
              if (isEditMode) {
                updateMapPreview();
              }
            });
          }

          // MOVE getInitialMapPosition INSIDE StatefulBuilder
          LatLng getInitialMapPosition() {
            if (centerPosition != null) {
              return centerPosition!;
            }
            
            // If polygon exists, use its center
            if (polygonCoords.length >= 3) {
              double sumLat = 0;
              double sumLng = 0;
              for (var coord in polygonCoords) {
                sumLat += coord.lat;
                sumLng += coord.lng;
              }
              return LatLng(sumLat / polygonCoords.length, sumLng / polygonCoords.length);
            }
            
            // Try to get coordinates from citiesWithCoordinates based on selected city in dropdown
            if (citiesWithCoordinates != null && selectedCityOption.isNotEmpty && selectedCityOption != 'New City...') {
              final city = citiesWithCoordinates.firstWhere(
                (c) => c.name == selectedCityOption,
                orElse: () => City(name: '', latitude: null, longitude: null),
              );
              
              if (city.latitude != null && city.longitude != null) {
                return LatLng(city.latitude!, city.longitude!);
              }
            }
            
            // Default to Turin if no coordinates found
            return const LatLng(45.0703, 7.6869);
          }

          // NEW: Calculate optimal zoom level for edit mode
          double getOptimalZoom() {
            // If in edit mode with polygon, calculate zoom to fit polygon
            if (isEditMode && polygonCoords.length >= 3) {
              double minLat = polygonCoords[0].lat;
              double maxLat = polygonCoords[0].lat;
              double minLng = polygonCoords[0].lng;
              double maxLng = polygonCoords[0].lng;

              for (var coord in polygonCoords) {
                if (coord.lat < minLat) minLat = coord.lat;
                if (coord.lat > maxLat) maxLat = coord.lat;
                if (coord.lng < minLng) minLng = coord.lng;
                if (coord.lng > maxLng) maxLng = coord.lng;
              }

              // Calculate the span
              double latSpan = maxLat - minLat;
              double lngSpan = maxLng - minLng;
              double maxSpan = latSpan > lngSpan ? latSpan : lngSpan;

              // Calculate zoom level (roughly)
              // Smaller span = higher zoom
              if (maxSpan > 0.1) return 13.0;      // Large polygon
              if (maxSpan > 0.05) return 14.0;     // Medium polygon
              if (maxSpan > 0.01) return 15.0;     // Small polygon
              if (maxSpan > 0.005) return 16.0;    // Very small polygon
              return 17.0;                          // Tiny polygon
            }

            // If in edit mode with only center point, zoom in closely
            if (isEditMode && centerPosition != null) {
              return 16.5; // Close zoom for center-only parkings
            }

            // Default zoom for new parkings
            return 12.0;
          }

          // NEW: Animate map to optimal position when entering edit mode
          void centerMapOnParking() {
            if (!isEditMode || mapController == null) return;

            final position = getInitialMapPosition();
            final zoom = getOptimalZoom();

            Future.delayed(const Duration(milliseconds: 300), () {
              mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(position, zoom),
              );
            });
          }

          void handleSave() async {
            if (!formKey.currentState!.validate()) return;

            if (!isSuperAdmin && displayOptions.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Error: No city permissions assigned to your account.',
                  ),
                ),
              );
              return;
            }

            if (isSuperAdmin &&
                selectedCityOption == 'New City...' &&
                newCityController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select or enter a new city name.'),
                ),
              );
              return;
            }

            setState(() => isLoading = true);

            String finalCity;
            if (isSuperAdmin) {
              finalCity = (selectedCityOption != 'New City...'
                  ? selectedCityOption
                  : newCityController.text.trim());
            } else {
              finalCity = selectedCityOption;
            }

            final parkingData = Parking(
              id: existingParking?.id ?? 0, // Use existing ID if editing
              name: nameController.text,
              city: finalCity,
              address: addressController.text,
              ratePerHour: existingParking?.ratePerHour ?? 2.5,
              totalSpots: int.parse(totalSpotsController.text), 
              occupiedSpots: existingParking?.occupiedSpots ?? 0,
              todayEntries: existingParking?.todayEntries ?? 0, 
              todayRevenue: existingParking?.todayRevenue ?? 0.0,
              latitude: double.tryParse(latController.text.replaceAll(',', '.')),
              longitude: double.tryParse(lngController.text.replaceAll(',', '.')),
              tariffConfigJson: existingParking?.tariffConfigJson ?? Parking.defaultTariffConfig.toJson(),
              polygonCoords: polygonCoords,
              entrances: existingParking?.entrances ?? [],
            );

            try {
              final savedParking = await ParkingService.saveParking(parkingData);
              
              // Only create spots if adding new parking
              if (!isEditMode) {
                final int spotsToCreate = int.parse(totalSpotsController.text);

                if (spotsToCreate > 0) {
                  List<Future> spotFutures = [];
                  for (int i = 0; i < spotsToCreate; i++) {
                    spotFutures.add(ParkingService.addSpot(savedParking.id));
                  }
                  await Future.wait(spotFutures);
                }
              }

              final finalParking = Parking(
                id: savedParking.id,
                name: savedParking.name,
                city: savedParking.city,
                address: savedParking.address,
                ratePerHour: savedParking.ratePerHour,
                totalSpots: savedParking.totalSpots, 
                occupiedSpots: savedParking.occupiedSpots,
                todayEntries: savedParking.todayEntries, 
                todayRevenue: savedParking.todayRevenue,
                latitude: savedParking.latitude,
                longitude: savedParking.longitude,
                markerLatitude: savedParking.markerLatitude,
                markerLongitude: savedParking.markerLongitude,
                tariffConfigJson: savedParking.tariffConfigJson,
                polygonCoords: savedParking.polygonCoords,
                entrances: savedParking.entrances,
              );

              Navigator.of(context).pop(finalParking);
            } catch (e) {
              setState(() => isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error ${isEditMode ? "updating" : "creating"} parking: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }

          void addPolygonPoint() async {
            // Warn user if they try to create polygon with less than 3 points
            if (polygonCoords.isNotEmpty && polygonCoords.length < 2) {
              final shouldContinue = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF020B3C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Text('Polygon requires 3+ points', style: GoogleFonts.poppins(color: Colors.white)),
                  content: Text(
                    'You need at least 3 points to create a valid polygon area. Continue adding points?',
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white54)),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(backgroundColor: Colors.blueAccent),
                      child: Text('Continue', style: GoogleFonts.poppins(color: Colors.white)),
                    ),
                  ],
                ),
              );
              
              if (shouldContinue != true) return;
            }
            
            LatLng? centerPos;
            final lat = double.tryParse(latController.text.replaceAll(',', '.'));
            final lng = double.tryParse(lngController.text.replaceAll(',', '.'));
            if (lat != null && lng != null) {
              centerPos = LatLng(lat, lng);
            }
            
            final result = await showEditPolygonDialog(
              context,
              initialCoords: polygonCoords,
              centerPosition: centerPos,
            );
            
            if (result != null) {
              final updatedCoords = result['coords'] as List<ParkingCoordinate>;
              final updatedCenter = result['center'] as LatLng?;
              
              setState(() {
                polygonCoords = updatedCoords;
                
                // Update center position from dialog
                if (updatedCenter != null) {
                  centerPosition = updatedCenter;
                  latController.text = updatedCenter.latitude.toStringAsFixed(6);
                  lngController.text = updatedCenter.longitude.toStringAsFixed(6);
                }
                
                // Only keep polygon if it has 3+ points, otherwise clear it
                if (polygonCoords.length > 0 && polygonCoords.length < 3) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF020B3C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text('Invalid Polygon', style: GoogleFonts.poppins(color: Colors.white)),
                      content: Text(
                        'Polygons must have at least 3 points. The polygon was not saved.',
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('OK', style: GoogleFonts.poppins(color: Colors.blueAccent)),
                        ),
                      ],
                    ),
                  );
                  polygonCoords = [];
                }
                
                updateMapPreview();
              });
            }
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * _dialogWidthPercentage,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color.fromARGB(255, 52, 12, 108),
                    Color.fromARGB(255, 2, 11, 60),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align content to top
                  children: [
                    // LEFT SIDE: Form Fields - flexible width
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * _dialogWidthPercentage - _mapSize - 60,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditMode ? 'Edit Parking' : 'Add New Parking',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // City Information
                              Row(
                                children: [
                                  Expanded(child: Container(height: 1, color: Colors.white30)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text(
                                      'City Information',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Container(height: 1, color: Colors.white30)),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // City selector
                              if (displayOptions.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(15),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                                  ),
                                  child: Text(
                                    "No city permissions found for this account.",
                                    style: GoogleFonts.poppins(color: Colors.redAccent),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              else if (isEditMode)
                                // CITY READ-ONLY IN EDIT MODE
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_city, color: Colors.greenAccent),
                                      const SizedBox(width: 10),
                                      Text(
                                        selectedCityOption,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(Icons.lock_outline, color: Colors.white30, size: 18),
                                    ],
                                  ),
                                )
                              else if (!isSuperAdmin && displayOptions.length == 1)
                                // ...existing single city case...
                              
                                _buildCitySelector(
                                  selectedCityOption,
                                  displayOptions,
                                  (String? newValue) {
                                    setState(() {
                                      selectedCityOption = newValue!;
                                      
                                      // RESET map data when city changes
                                      centerPosition = null;
                                      polygonCoords = [];
                                      previewMarkers = {};
                                      previewPolygons = {};
                                      
                                      // Clear coordinate text fields
                                      latController.clear();
                                      lngController.clear();
                                      
                                      // Recenter map to new city
                                      final newCityPosition = getInitialMapPosition();
                                      mapController?.animateCamera(
                                        CameraUpdate.newLatLngZoom(
                                          newCityPosition,
                                          12,
                                        ),
                                      );
                                    });
                                  },
                                ),

                              if (isSuperAdmin && selectedCityOption == 'New City...') ...[
                                const SizedBox(height: 16),
                                _buildStyledTextField(
                                  newCityController,
                                  'New City Name',
                                  false,
                                  isEnabled: !isLoading,
                                ),
                              ],

                              const SizedBox(height: 20),
                              Container(height: 1, color: Colors.white30),
                              const SizedBox(height: 20),

                              _buildStyledTextField(nameController, 'Parking Name', false, isEnabled: !isLoading),
                              const SizedBox(height: 16),
                              _buildStyledTextField(addressController, 'Address', false, isEnabled: !isLoading),
                              const SizedBox(height: 16),
                              
                              // TOTAL SPOTS - READ-ONLY IN EDIT MODE (only show once!)
                              isEditMode 
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Spots',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(15),
                                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              totalSpotsController.text,
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const Spacer(),
                                            const Icon(Icons.lock_outline, color: Colors.white30, size: 18),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Use "Spot Management" in parking detail screen',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white38,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  )
                                : _buildStyledTextField(totalSpotsController, 'Total Spots', true, isEnabled: !isLoading),

                              const SizedBox(height: 16),
                              
                              // Coordinates section header
                              Row(
                                children: [
                                  Expanded(child: Container(height: 1, color: Colors.white30)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text(
                                      'Location',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Container(height: 1, color: Colors.white30)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Instructions
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.touch_app, color: Colors.blueAccent, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Click on map or drag the marker to set center',
                                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Coordinates with update button
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStyledTextField(
                                      latController,
                                      'Center Latitude',
                                      true,
                                      isEnabled: !isLoading,
                                      onChanged: (value) => updateMapPreview(),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildStyledTextField(
                                      lngController,
                                      'Center Longitude',
                                      true,
                                      isEnabled: !isLoading,
                                      onChanged: (value) => updateMapPreview(),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 20),
                              Container(height: 1, color: Colors.white30),
                              const SizedBox(height: 20),

                              // Polygon Section
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Polygon (${polygonCoords.length} pts)',
                                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: addPolygonPoint,
                                    icon: const Icon(Icons.edit_location_alt, size: 16),
                                    label: Text('Edit', style: GoogleFonts.poppins(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              
                              if (polygonCoords.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${polygonCoords.length} points defined',
                                        style: GoogleFonts.poppins(color: Colors.greenAccent, fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Preview shown on map →',
                                        style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 24),

                              ElevatedButton(
                                onPressed: isLoading ? null : handleSave,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isEditMode ? Colors.greenAccent : Colors.white,
                                  foregroundColor: Colors.black,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: isLoading
                                    ? const CircularProgressIndicator()
                                    : Text(
                                        isEditMode ? 'Update Parking' : 'Save Parking',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // RIGHT SIDE: Map Preview - fixed size based on _mapSize
                    SizedBox(
                      width: _mapSize,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Map Preview',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: _mapSize,
                            width: _mapSize,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.white24, width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: getInitialMapPosition(),
                                  zoom: 12,
                                ),
                                markers: previewMarkers,
                                polygons: previewPolygons,
                                onMapCreated: (controller) async {
                                  mapController = controller;
                                  // Apply style immediately
                                  await mapController?.setMapStyle(_mapStyle);
                                  
                                  // Initialize preview immediately in edit mode
                                  if (isEditMode) {
                                    // Small delay to ensure map is fully initialized
                                    Future.delayed(const Duration(milliseconds: 100), () {
                                      updateMapPreview();
                                      centerMapOnParking();
                                    });
                                  }
                                },

                                onTap: (position) {
                                  updateMapPreview(newCenter: position);
                                },
                                myLocationButtonEnabled: false,
                                zoomControlsEnabled: true,
                                mapToolbarEnabled: false,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Legend
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildLegendItem(
                                Icons.location_on,
                                'Center Marker',
                                Colors.green,
                              ),
                              _buildLegendItem(
                                Icons.pentagon_outlined,
                                'Parking Zone',
                                Colors.blueAccent,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildLegendItem(IconData icon, String label, Color color) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 6),
      Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.white70,
          fontSize: 11,
        ),
      ),
    ],
  );
}

Widget _buildStyledTextField(
  TextEditingController controller,
  String label,
  bool isNumber, {
  bool isEnabled = true,
  ValueChanged<String>? onChanged,
}) {
  return TextFormField(
    controller: controller,
    enabled: isEnabled,
    onChanged: onChanged,
    keyboardType: isNumber
        ? const TextInputType.numberWithOptions(decimal: true, signed: true)
        : TextInputType.text,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    cursorColor: Colors.white,
    validator: (value) {
      if (value == null || value.isEmpty) return 'Required';
      if (isNumber) {
        final normalized = value.replaceAll(',', '.');
        if (double.tryParse(normalized) == null) return 'Invalid';
      }
      return null;
    },
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    ),
  );
}

Widget _buildCitySelector(
  String selectedValue,
  List<String> items,
  ValueChanged<String?> onChanged,
) {
  // Assicura che selectedValue sia presente nella lista items
  // Se non c'è (caso raro di desincronizzazione), fallback sul primo elemento
  final validValue = items.contains(selectedValue)
      ? selectedValue
      : items.first;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.white.withOpacity(0.3)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: validValue,
        isExpanded: true,
        dropdownColor: const Color.fromARGB(255, 52, 12, 108),
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
        onChanged: onChanged,
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: GoogleFonts.poppins()),
          );
        }).toList(),
      ),
    ),
  );
}
