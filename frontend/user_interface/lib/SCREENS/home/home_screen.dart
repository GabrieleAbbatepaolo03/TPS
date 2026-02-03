import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:user_interface/SCREENS/home/utils/home_map_widget.dart';
import 'package:user_interface/SCREENS/home/utils/home_search_bar.dart';
import 'package:user_interface/SCREENS/home/utils/home_search_result_list.dart';
import 'package:user_interface/SCREENS/login/login_screen.dart';
import 'package:user_interface/SCREENS/start session/start_session_screen.dart';
import 'package:user_interface/SERVICES/AUTHETNTICATION HELPERS/secure_storage_service.dart';
import 'package:user_interface/SERVICES/parking_service.dart';
import 'package:user_interface/SERVICES/user_service.dart';
import 'package:user_interface/MODELS/parking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_interface/STATE/map_style_state.dart';

import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const double _distanceLimitKm = 10.0;

  final UserService _userService = UserService();
  final ParkingApiService _parkingService = ParkingApiService();
  bool _locationAccessGranted = false;
  bool _isLocationLoading = true;
  bool _isLoading = true;

  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(0.0, 0.0);
  final Set<Marker> _markers = {};
  final Set<Polygon> _polygons = {};

  BitmapDescriptor? _userLocationIcon;
  BitmapDescriptor? _parkingMarkerIcon;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Parking> _parkingLots = [];
  List<Parking> _nearbyParkingLots = [];
  List<Parking> _filteredParkingLots = [];

  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchExpanded = false;
  bool _isNavigating = false;
  static const double _searchBarHeight = 60.0;

  Parking? _selectedLot;

  int _mapKey = 0;

  @override
  void initState() {
    super.initState();
    _loadAllUserData();
    _loadParkingLots();
    _getUserLocation();
    _loadCustomUserIcon();
    _loadCustomParkingIcon();
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCustomUserIcon() async {
    final ByteData byteData = await rootBundle.load(
      'assets/images/car_location_marker.png',
    );

    final ui.Codec codec = await ui.instantiateImageCodec(
      byteData.buffer.asUint8List(),
      targetWidth: 200,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ui.Image largeImage = fi.image;

    const int targetSize = 200;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..filterQuality = FilterQuality.high;

    canvas.drawImageRect(
      largeImage,
      Rect.fromLTWH(0, 0, largeImage.width.toDouble(), largeImage.height.toDouble()),
      Rect.fromLTWH(0, 0, targetSize.toDouble(), targetSize.toDouble()),
      paint,
    );

    final ui.Image smallImage = await recorder.endRecording().toImage(targetSize, targetSize);
    final ByteData? resizedByteData =
        await smallImage.toByteData(format: ui.ImageByteFormat.png);

    if (!mounted || resizedByteData == null) return;

    setState(() {
      _userLocationIcon = BitmapDescriptor.fromBytes(
        resizedByteData.buffer.asUint8List(),
      );
    });

    _filterAndDisplayParkings();
  }

  Future<void> _loadCustomParkingIcon() async {
    final ByteData byteData = await rootBundle.load(
      'assets/images/parking_marker.png',
    );

    final ui.Codec codec = await ui.instantiateImageCodec(
      byteData.buffer.asUint8List(),
      targetWidth: 200,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ui.Image largeImage = fi.image;

    const int targetSize = 200;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..filterQuality = FilterQuality.high;

    canvas.drawImageRect(
      largeImage,
      Rect.fromLTWH(0, 0, largeImage.width.toDouble(), largeImage.height.toDouble()),
      Rect.fromLTWH(0, 0, targetSize.toDouble(), targetSize.toDouble()),
      paint,
    );

    final ui.Image smallImage = await recorder.endRecording().toImage(targetSize, targetSize);
    final ByteData? resizedByteData =
        await smallImage.toByteData(format: ui.ImageByteFormat.png);

    if (!mounted || resizedByteData == null) return;

    setState(() {
      _parkingMarkerIcon = BitmapDescriptor.fromBytes(
        resizedByteData.buffer.asUint8List(),
      );
    });
  }

  Future<void> _loadAllUserData() async {
    final userDataFuture = _userService.fetchUserProfile();
    final results = await Future.wait([userDataFuture]);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      final userData = results[0];
      if (userData == null && !_isLoading) {
        _handleLogout(context);
      }
    });
  }

  Future<void> _loadParkingLots() async {
    try {
      final lotsData = await _parkingService.fetchAllParkingLots();
      if (!mounted) return;
      setState(() {
        _parkingLots = lotsData;
      });
      _filterAndDisplayParkings();
    } catch (e) {
      print('Error loading parking lots: $e');
    }
  }

  void _applySearchFilter(List<Parking> sourceLots) {
    if (!mounted) return;
    if (_searchQuery.isEmpty) {
      _filteredParkingLots = sourceLots;
    } else {
      final lowerCaseQuery = _searchQuery.toLowerCase();
      _filteredParkingLots = sourceLots.where((lot) {
        return lot.name.toLowerCase().contains(lowerCaseQuery) ||
            lot.city.toLowerCase().contains(lowerCaseQuery) ||
            lot.address.toLowerCase().contains(lowerCaseQuery);
      }).toList();
    }
  }

  Future<void> _getUserLocation() async {
    try {
      // 1. Verifica se i servizi di geolocazione sono attivi
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      // 2. Controllo permessi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      // 3. Ottieni posizione
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLocationLoading = false;
        _locationAccessGranted = true;
      });

      // aggiorna marker e parcheggi
      _filterAndDisplayParkings();
    } catch (e) {
      debugPrint("Errore GPS: $e");
    }
  }

  void _handleLogout(BuildContext context) async {
    final storageService = SecureStorageService();
    await storageService.deleteTokens();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _filterAndDisplayParkings();
  }

  void _onSearchFocusChanged() {
    if (!mounted) return;
    if (_isNavigating) return;

    if (_searchFocusNode.hasFocus) {
      setState(() {
        _isSearchExpanded = true;
      });
    }
  }

  void _updateSearchQuery(String newQuery) {
    setState(() {
      _searchQuery = newQuery;
      _filterAndDisplayParkings();
    });
  }

  void _navigateToStartSession(Parking parkingLot) async {
    setState(() {
      _isNavigating = true;
    });

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StartSessionScreen(parkingLot: parkingLot),
      ),
    );

    if (mounted) {
      setState(() {
        _isNavigating = false;
      });
      FocusScope.of(context).unfocus();
    }
  }

  void _filterAndDisplayParkings() {
    if (!mounted) return;
    final Set<Marker> newMarkers = {};
    final Set<Polygon> newPolygons = {};
    
    // Get current theme state for polygon colors
    final isDarkMode = ref.read(mapStyleProvider);
    
    if (_locationAccessGranted) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: _currentPosition,
          infoWindow: const InfoWindow(title: 'You are here'),
          icon: _userLocationIcon ?? BitmapDescriptor.defaultMarker,
        ),
      );
    }

    _nearbyParkingLots = _parkingLots.where((lot) {
      final distanceInMeters = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        lot.latitude ?? 0.0,
        lot.longitude ?? 0.0,
      );
      return distanceInMeters <= (_distanceLimitKm * 1000);
    }).toList();

    _applySearchFilter(_nearbyParkingLots);

    for (var lot in _filteredParkingLots) {
      final LatLng lotPosition = LatLng(
        lot.markerLatitude ?? lot.latitude ?? 0.0,
        lot.markerLongitude ?? lot.longitude ?? 0.0,
      );
      
      newMarkers.add(
        Marker(
          markerId: MarkerId(lot.id.toString()),
          position: lotPosition,
          icon: _parkingMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () {
            setState(() => _selectedLot = lot);
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(lotPosition),
            );
          },
        ),
      );

      // Add polygon if coordinates exist with theme-aware colors
      if (lot.polygonCoords.isNotEmpty) {
        final polygonPoints = lot.polygonCoords
            .map((coord) => LatLng(coord.lat, coord.lng))
            .toList();

        // Theme-aware colors
        final strokeColor = isDarkMode ? Colors.greenAccent : Colors.indigo;
        final fillColor = isDarkMode 
            ? Colors.greenAccent.withOpacity(0.2) 
            : Colors.indigoAccent.withOpacity(0.15);

        newPolygons.add(
          Polygon(
            polygonId: PolygonId('polygon_${lot.id}'),
            points: polygonPoints,
            strokeColor: strokeColor,
            strokeWidth: 2,
            fillColor: fillColor,
            consumeTapEvents: true,
            onTap: () {
              setState(() => _selectedLot = lot);
              _mapController?.animateCamera(
                CameraUpdate.newLatLng(lotPosition),
              );
            },
          ),
        );
      }
    }

    setState(() {
      _markers.clear();
      _markers.addAll(newMarkers);
      _polygons.clear();
      _polygons.addAll(newPolygons);
    });

    if (_mapController != null && newMarkers.isNotEmpty) {
      LatLng targetPosition = _currentPosition;

      if (!_locationAccessGranted && _filteredParkingLots.isNotEmpty) {
        final firstLot = _filteredParkingLots.first;
        targetPosition = LatLng(
          firstLot.markerLatitude ?? firstLot.latitude ?? 0.0,
          firstLot.markerLongitude ?? firstLot.longitude ?? 0.0,
        );
      }

      Future.delayed(const Duration(milliseconds: 50), () {
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(targetPosition, 14.0),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch map style changes to rebuild polygons
    ref.listen<bool>(mapStyleProvider, (previous, next) {
      if (previous != next && mounted) {
        _filterAndDisplayParkings();
      }
    });

    const searchBarColor = Color.fromARGB(255, 6, 20, 43);

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final double topSpace = mediaQuery.padding.top + 20.0 + _searchBarHeight;
    final double bottomSpace = mediaQuery.padding.bottom + 20.0;
    final double maxListHeight = screenHeight - topSpace - bottomSpace;

    return Stack(
      children: [
        HomeMapWidget(
          key: ValueKey(_mapKey),
          locationAccessGranted: _locationAccessGranted,
          currentPosition: _currentPosition,
          markers: _markers,
          polygons: _polygons,
          onMapCreated: _onMapCreated,
          isLoading: _isLocationLoading,
          onTap: () {
            FocusScope.of(context).unfocus();
            setState(() {
              _isSearchExpanded = false;
              _selectedLot = null;
            });
          },
          gesturesEnabled: !_isSearchExpanded,
        ),
        
        // overlay card per marker selezionato con animazione slide da sinistra
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: _selectedLot != null
              ? Align(
                  key: ValueKey(_selectedLot!.id),
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromARGB(255, 52, 12, 108),
                            Color.fromARGB(255, 2, 11, 60),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header con info parcheggio
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.local_parking,
                                        color: Colors.amber,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedLot!.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _selectedLot!.address,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white70),
                                      onPressed: () => setState(() => _selectedLot = null),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Available spots: ${_selectedLot!.availableSpots}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Bottone Start full-width in basso
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.greenAccent,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                                onPressed: () => _navigateToStartSession(_selectedLot!),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.play_arrow, size: 24),
                                    SizedBox(width: 8),
                                    Text(
                                      'Tap to start a parking session',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        Align(
          alignment: Alignment.topCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(30),
                  color: searchBarColor,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HomeSearchBar(
                        searchBarHeight: _searchBarHeight,
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: _updateSearchQuery,
                      ),
                      if (_isSearchExpanded)
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: maxListHeight > 0 ? maxListHeight : 0,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: HomeSearchResultsList(
                              searchQuery: _searchQuery,
                              filteredParkingLots: _filteredParkingLots,
                              userPosition: _currentPosition,
                              onParkingLotTap: _navigateToStartSession,
                            ),
                          ),
                        ),
                      ],
                    ),
                ),
              ),
            ),
          ),
        ),
      ],  
    );
  }
}