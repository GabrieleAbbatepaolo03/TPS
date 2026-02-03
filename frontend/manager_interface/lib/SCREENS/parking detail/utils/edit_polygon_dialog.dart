import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:manager_interface/models/parking.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class EditPolygonDialog extends StatefulWidget {
  final List<ParkingCoordinate> initialCoords;
  final LatLng? centerPosition;

  const EditPolygonDialog({
    super.key,
    required this.initialCoords,
    this.centerPosition,
  });

  @override
  State<EditPolygonDialog> createState() => _EditPolygonDialogState();
}

class _EditPolygonDialogState extends State<EditPolygonDialog> {
  late List<ParkingCoordinate> polygonCoords;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};
  int? selectedMarkerIndex;
  LatLng? centerPosition;
  BitmapDescriptor? customCenterIcon;
  
  final Map<int, TextEditingController> latControllers = {};
  final Map<int, TextEditingController> lngControllers = {};
  
  static const String _mapStyle = '''
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

  @override
  void initState() {
    super.initState();
    polygonCoords = List.from(widget.initialCoords);
    centerPosition = widget.centerPosition;
    _initializeControllers();
    _loadCustomCenterIcon();
    _updateMapElements();
  }

  Future<void> _loadCustomCenterIcon() async {
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

    if (resizedByteData != null && mounted) {
      setState(() {
        customCenterIcon = BitmapDescriptor.fromBytes(
          resizedByteData.buffer.asUint8List(),
        );
      });
      _updateMapElements();
    }
  }

  void _initializeControllers() {
    for (int i = 0; i < polygonCoords.length; i++) {
      latControllers[i] = TextEditingController(
        text: polygonCoords[i].lat.toStringAsFixed(6),
      );
      lngControllers[i] = TextEditingController(
        text: polygonCoords[i].lng.toStringAsFixed(6),
      );
    }
  }

  @override
  void dispose() {
    latControllers.values.forEach((c) => c.dispose());
    lngControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  void _updateMapElements() {
    final newMarkers = <Marker>{};
    
    // Add center marker with custom icon if position exists
    if (centerPosition != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('center'),
          position: centerPosition!,
          draggable: true,
          onDragEnd: (newPosition) => _onCenterDragged(newPosition),
          icon: customCenterIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Center (Drag to move all)'),
        ),
      );
    }
    
    // Add polygon point markers
    for (int i = 0; i < polygonCoords.length; i++) {
      final coord = polygonCoords[i];
      newMarkers.add(
        Marker(
          markerId: MarkerId('point_$i'),
          position: LatLng(coord.lat, coord.lng),
          draggable: true,
          onDragEnd: (newPosition) => _onMarkerDragged(i, newPosition),
          onTap: () => setState(() => selectedMarkerIndex = i),
          icon: selectedMarkerIndex == i
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: 'Point ${i + 1}'),
        ),
      );
    }

    final newPolygons = <Polygon>{};
    if (polygonCoords.isNotEmpty) {
      newPolygons.add(
        Polygon(
          polygonId: const PolygonId('edit_polygon'),
          points: polygonCoords.map((c) => LatLng(c.lat, c.lng)).toList(),
          strokeColor: Colors.blue,
          strokeWidth: 3,
          fillColor: Colors.blue.withOpacity(0.2),
        ),
      );
    }

    setState(() {
      _markers = newMarkers;
      _polygons = newPolygons;
    });
  }

  void _onCenterDragged(LatLng newPosition) {
    if (centerPosition == null) return;
    
    final latOffset = newPosition.latitude - centerPosition!.latitude;
    final lngOffset = newPosition.longitude - centerPosition!.longitude;
    
    setState(() {
      centerPosition = newPosition;
      
      for (int i = 0; i < polygonCoords.length; i++) {
        polygonCoords[i] = ParkingCoordinate(
          lat: polygonCoords[i].lat + latOffset,
          lng: polygonCoords[i].lng + lngOffset,
        );
        
        latControllers[i]?.text = polygonCoords[i].lat.toStringAsFixed(6);
        lngControllers[i]?.text = polygonCoords[i].lng.toStringAsFixed(6);
      }
      
      _updateMapElements();
    });
  }

  void _onMarkerDragged(int index, LatLng newPosition) {
    setState(() {
      polygonCoords[index] = ParkingCoordinate(
        lat: newPosition.latitude,
        lng: newPosition.longitude,
      );
      
      latControllers[index]?.text = newPosition.latitude.toStringAsFixed(6);
      lngControllers[index]?.text = newPosition.longitude.toStringAsFixed(6);
      
      _updateMapElements();
    });
  }

  void _updateCoordinateFromTextField(int index) {
    final lat = double.tryParse(latControllers[index]?.text ?? '');
    final lng = double.tryParse(lngControllers[index]?.text ?? '');
    
    if (lat != null && lng != null) {
      setState(() {
        polygonCoords[index] = ParkingCoordinate(lat: lat, lng: lng);
        _updateMapElements();
        
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(lat, lng)),
        );
      });
    }
  }

  void _addNewPoint() {
    LatLng newPosition;
    if (polygonCoords.isNotEmpty) {
      final last = polygonCoords.last;
      newPosition = LatLng(last.lat + 0.0001, last.lng + 0.0001);
    } else {
      newPosition = widget.centerPosition ?? const LatLng(45.0703, 7.6869);
    }
    
    setState(() {
      final newIndex = polygonCoords.length;
      polygonCoords.add(ParkingCoordinate(
        lat: newPosition.latitude,
        lng: newPosition.longitude,
      ));
      
      latControllers[newIndex] = TextEditingController(
        text: newPosition.latitude.toStringAsFixed(6),
      );
      lngControllers[newIndex] = TextEditingController(
        text: newPosition.longitude.toStringAsFixed(6),
      );
      
      _updateMapElements();
    });
  }

  void _removePoint(int index) {
    if (polygonCoords.length <= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'A polygon must have at least 3 points',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      polygonCoords.removeAt(index);
      latControllers[index]?.dispose();
      lngControllers[index]?.dispose();
      latControllers.remove(index);
      lngControllers.remove(index);
      
      final newLatControllers = <int, TextEditingController>{};
      final newLngControllers = <int, TextEditingController>{};
      
      for (int i = 0; i < polygonCoords.length; i++) {
        if (i < index) {
          newLatControllers[i] = latControllers[i]!;
          newLngControllers[i] = lngControllers[i]!;
        } else {
          newLatControllers[i] = latControllers[i + 1]!;
          newLngControllers[i] = lngControllers[i + 1]!;
        }
      }
      
      latControllers.clear();
      lngControllers.clear();
      latControllers.addAll(newLatControllers);
      lngControllers.addAll(newLngControllers);
      
      if (selectedMarkerIndex == index) {
        selectedMarkerIndex = null;
      } else if (selectedMarkerIndex != null && selectedMarkerIndex! > index) {
        selectedMarkerIndex = selectedMarkerIndex! - 1;
      }
      
      _updateMapElements();
    });
  }

  LatLng _getPolygonCenter() {
    if (centerPosition != null) {
      return centerPosition!;
    }
    
    if (polygonCoords.isEmpty) {
      return widget.centerPosition ?? const LatLng(45.0703, 7.6869);
    }
    
    double sumLat = 0;
    double sumLng = 0;
    
    for (var coord in polygonCoords) {
      sumLat += coord.lat;
      sumLng += coord.lng;
    }
    
    return LatLng(sumLat / polygonCoords.length, sumLng / polygonCoords.length);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
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
        ),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Parking Polygon',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Drag markers on the map or edit coordinates manually',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Map and Points Editor Side by Side
            Expanded(
              child: Row(
                children: [
                  // Map Preview (60%)
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _getPolygonCenter(),
                            zoom: 16,
                          ),
                          markers: _markers,
                          polygons: _polygons,
                          onMapCreated: (controller) async {
                            _mapController = controller;
                            // Apply style immediately
                            await _mapController?.setMapStyle(_mapStyle);
                          },
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: true,
                          mapToolbarEnabled: false,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Points List (40%)
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Center Position Info
                        if (centerPosition != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.greenAccent, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Center Position',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Drag to move entire polygon',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Points (${polygonCoords.length})',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _addNewPoint,
                              icon: const Icon(Icons.add, size: 16),
                              label: Text('Add', style: GoogleFonts.poppins(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.greenAccent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.builder(
                            itemCount: polygonCoords.length,
                            itemBuilder: (context, index) {
                              final isSelected = selectedMarkerIndex == index;
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.white10,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.greenAccent
                                        : Colors.white24,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Point ${index + 1}',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.my_location, size: 18),
                                              color: Colors.blueAccent,
                                              onPressed: () {
                                                _mapController?.animateCamera(
                                                  CameraUpdate.newLatLngZoom(
                                                    LatLng(
                                                      polygonCoords[index].lat,
                                                      polygonCoords[index].lng,
                                                    ),
                                                    18,
                                                  ),
                                                );
                                                setState(() => selectedMarkerIndex = index);
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, size: 18),
                                              color: Colors.redAccent,
                                              onPressed: () => _removePoint(index),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildCoordField(
                                            latControllers[index]!,
                                            'Lat',
                                            () => _updateCoordinateFromTextField(index),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildCoordField(
                                            lngControllers[index]!,
                                            'Lng',
                                            () => _updateCoordinateFromTextField(index),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, {
                    'coords': polygonCoords,
                    'center': centerPosition,
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Save Changes',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoordField(
    TextEditingController controller,
    String label,
    VoidCallback onSubmit,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      style: const TextStyle(color: Colors.white, fontSize: 12),
      onEditingComplete: onSubmit,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 10),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}

Future<Map<String, dynamic>?> showEditPolygonDialog(
  BuildContext context, {
  required List<ParkingCoordinate> initialCoords,
  LatLng? centerPosition,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => EditPolygonDialog(
      initialCoords: initialCoords,
      centerPosition: centerPosition,
    ),
  );
}
