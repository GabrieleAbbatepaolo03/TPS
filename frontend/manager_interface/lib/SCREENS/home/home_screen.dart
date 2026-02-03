// frontend/manager_interface/lib/SCREENS/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:manager_interface/MAIN%20UTILS/add_parking_dialog.dart';
import 'package:manager_interface/MAIN%20UTILS/search_bar_widget.dart';
import 'package:manager_interface/SCREENS/parking%20detail/parking_detail_screen.dart';
import 'package:manager_interface/models/parking.dart';
import 'package:manager_interface/SCREENS/home/utils/parking_card.dart';
import '../../services/parking_service.dart';
import 'package:manager_interface/SERVICES/auth_service.dart';
import 'package:manager_interface/SCREENS/login_screen.dart';
import 'package:manager_interface/models/city.dart';

import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- State Data ---
  List<String> cities = [];
  List<String> filteredCities = [];
  List<City> citiesWithCoordinates = []; // Add this

  List<Parking> allParkings = [];
  List<Parking> selectedCityParkings = [];
  List<Parking> filteredCityParkings = [];

  String? selectedCity;
  bool isLoading = true;
  bool isParkingsLoading = false;

  // --- Map Data ---
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};
  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(41.8719, 12.5674), // Default Italy
    zoom: 5.5,
  );

  BitmapDescriptor? _parkingIcon;

  // Map style JSON
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
    _initDashboard();
    _loadCustomParkingIcon();
  }

  Future<void> _loadCustomParkingIcon() async {
    final ByteData byteData = await rootBundle.load(
      'assets/images/parking_marker.png',
    );

    final ui.Codec codec = await ui.instantiateImageCodec(
      byteData.buffer.asUint8List(),
      targetWidth: 70,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ui.Image image = fi.image;

    final ByteData? resizedByteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (!mounted || resizedByteData == null) return;

    setState(() {
      _parkingIcon = BitmapDescriptor.fromBytes(
        resizedByteData.buffer.asUint8List(),
      );
    });

    if (selectedCity != null) {
      _onCitySelected(selectedCity!, reload: true);
    }
  }

  // --- Data Loading ---
  Future<void> _initDashboard() async {
    setState(() => isLoading = true);
    try {
      debugPrint("🔍 Loading cities...");
      
      // Load cities with coordinates (includes all cities in DB)
      final citiesWithCoords = await ParkingService.getCitiesWithCoordinates();
      debugPrint("✅ Cities with coordinates loaded: ${citiesWithCoords.length}");
      
      // Extract city names for the list
      final cityNames = citiesWithCoords.map((c) => c.name).toList();
      cityNames.sort();
      debugPrint("✅ City names: $cityNames");

      setState(() {
        cities = cityNames;
        filteredCities = cityNames;
        citiesWithCoordinates = citiesWithCoords;
        isLoading = false;
      });
      
      debugPrint("✅ Dashboard initialized successfully");
    } catch (e, stackTrace) {
      debugPrint("❌ Error loading dashboard: $e");
      debugPrint("Stack trace: $stackTrace");
      setState(() => isLoading = false);
      
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading cities: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // --- Logic Handlers ---

  Future<void> _onCitySelected(String city, {bool reload = false}) async {
    if (!reload) {
      setState(() {
        selectedCity = city;
        isParkingsLoading = true;
      });
    }

    try {
      final parkings = await ParkingService.getParkingsByCity(city);

      final newMarkers = <Marker>{};
      final newPolygons = <Polygon>{};

      for (var p in parkings) {
        // Add marker - either from markerLatitude/Longitude OR from latitude/longitude
        LatLng? markerPosition;
        
        if (p.markerLatitude != null && p.markerLongitude != null) {
          markerPosition = LatLng(p.markerLatitude!, p.markerLongitude!);
        } else if (p.latitude != null && p.longitude != null) {
          // Fallback to center coordinates if no marker position
          markerPosition = LatLng(p.latitude!, p.longitude!);
        }

        if (markerPosition != null) {
          newMarkers.add(
            Marker(
              markerId: MarkerId('p_${p.id}'),
              position: markerPosition,
              infoWindow: InfoWindow(
                title: p.name,
                snippet: p.address,
              ),
              onTap: () => _navigateToDetail(p),
              icon: _parkingIcon ?? BitmapDescriptor.defaultMarker,
            ),
          );
        }

        // Add polygon ONLY if it has 3+ points
        if (p.polygonCoords.length >= 3) {
          newPolygons.add(
            Polygon(
              polygonId: PolygonId('poly_${p.id}'),
              points: p.polygonCoords
                  .map((c) => LatLng(c.lat, c.lng))
                  .toList(),
              strokeColor: Colors.indigo,
              strokeWidth: 3,
              fillColor: Colors.indigoAccent.withOpacity(0.3),
              consumeTapEvents: true,
              onTap: () => _navigateToDetail(p),
            ),
          );
        }
      }

      setState(() {
        selectedCityParkings = parkings;
        filteredCityParkings = parkings;
        _markers = newMarkers;
        _polygons = newPolygons;
        isParkingsLoading = false;
      });

      // Center map on first parking (with fallback to center coordinates)
      if (parkings.isNotEmpty) {
        LatLng? cameraTarget;
        
        if (parkings.first.markerLatitude != null && parkings.first.markerLongitude != null) {
          cameraTarget = LatLng(parkings.first.markerLatitude!, parkings.first.markerLongitude!);
        } else if (parkings.first.latitude != null && parkings.first.longitude != null) {
          cameraTarget = LatLng(parkings.first.latitude!, parkings.first.longitude!);
        }

        if (cameraTarget != null) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(cameraTarget, 12),
          );
        }
      }
    } catch (e) {
      setState(() => isParkingsLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading parkings: $e")));
    }
  }

  void _navigateToDetail(Parking parking) async {
    // Corrected navigation to the Detail Screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ParkingDetailScreen(parkingId: parking.id),
      ),
    );

    if (selectedCity != null) {
      _onCitySelected(selectedCity!);
    }
  }

  // --- Search Logics ---

  void _onCitySearch(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCities = cities;
      } else {
        filteredCities = cities
            .where((c) => c.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _onParkingSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCityParkings = selectedCityParkings;
      } else {
        filteredCityParkings = selectedCityParkings
            .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // --- Add Parking Handler ---
  Future<void> _handleAddParking() async {
    final newParking = await showAddParkingDialog(
      context,
      authorizedCities: cities,
      selectedCity: selectedCity,
      citiesWithCoordinates: citiesWithCoordinates, // Pass city coordinates
    );

    if (newParking != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Parking "${newParking.name}" added successfully!'),
        ),
      );

      // Reload ALL cities with coordinates (not just cities with parkings)
      final citiesWithCoords = await ParkingService.getCitiesWithCoordinates();
      final cityNames = citiesWithCoords.map((c) => c.name).toList();
      cityNames.sort();

      setState(() {
        cities = cityNames;
        filteredCities = cityNames;
        citiesWithCoordinates = citiesWithCoords;
      });

      // Automatically select the new city to update the list and map
      _onCitySelected(newParking.city);
    }
  }

  Future<void> _deleteParking(Parking parking) async {
    try {
      await ParkingService.deleteParking(parking.id);
      setState(() {
        selectedCityParkings.removeWhere((p) => p.id == parking.id);
        filteredCityParkings.removeWhere((p) => p.id == parking.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parking deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color.fromARGB(255, 52, 12, 108),
              Color.fromARGB(255, 2, 11, 60),
            ],
          ),
        ),
        child: Column(
          children: [
            // --- HEADER ---
            _buildHeader(),

            // --- BODY COLUMNS ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                child: Row(
                  children: [
                    // COL 1: MAPPA (50% Width -> flex 2)
                    Expanded(flex: 2, child: _buildMapColumn()),
                    const SizedBox(width: 20),

                    // COL 2: LISTA CITTÀ (25% Width -> flex 1)
                    Expanded(flex: 1, child: _buildCitiesColumn()),
                    const SizedBox(width: 20),

                    // COL 3: LISTA PARCHEGGI (25% Width -> flex 1)
                    Expanded(flex: 1, child: _buildParkingsColumn()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TPS Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Manage your infrastructure',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _handleAddParking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: const Color(0xFF020B3C),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Add Parking',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    await AuthService.logout();
                    if (!mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: Colors.white10),
                    ),
                  ),
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: Text(
                    'Logout',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnContainer({required Widget child, required String title}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 5),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: child,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapColumn() {
    return _buildColumnContainer(
      title: 'Map Overview',
      child: GoogleMap(
        initialCameraPosition: _initialCameraPosition,
        markers: _markers,
        polygons: _polygons,
        onMapCreated: (c) async {
          _mapController = c;
          // Apply style immediately
          await _mapController?.setMapStyle(_mapStyle);
        },
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
        mapToolbarEnabled: false,
      ),
    );
  }

  Widget _buildCitiesColumn() {
    return _buildColumnContainer(
      title: 'Select City',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBarWidget(
              hintText: "Find city...",
              onChanged: _onCitySearch,
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: filteredCities.length,
                    itemBuilder: (context, index) {
                      final city = filteredCities[index];
                      final isSelected = city == selectedCity;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white10,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          title: Text(
                            city,
                            style: GoogleFonts.poppins(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.grey,
                          ),
                          onTap: () => _onCitySelected(city),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildParkingsColumn() {
    return _buildColumnContainer(
      title: selectedCity == null ? 'Parkings' : 'Parkings in $selectedCity',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBarWidget(
              hintText: "Find parking...",
              onChanged: _onParkingSearch,
            ),
          ),
          Expanded(
            child: selectedCity == null
                ? Center(
                    child: Text(
                      "Select a city\nto see parkings",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.white30),
                    ),
                  )
                : isParkingsLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : filteredCityParkings.isEmpty
                ? Center(
                    child: Text(
                      "No parkings found",
                      style: GoogleFonts.poppins(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: filteredCityParkings.length,
                    itemBuilder: (context, index) {
                      final parking = filteredCityParkings[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ParkingCard(
                          parking: parking,
                          onTap: () => _navigateToDetail(parking),
                          onDelete: _deleteParking,
                          allParkings: filteredCityParkings,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
