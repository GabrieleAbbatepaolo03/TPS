import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:user_interface/SCREENS/home/utils/home_map_widget.dart';
import 'package:user_interface/SCREENS/home/utils/home_search_bar.dart';
import 'package:user_interface/SCREENS/home/utils/home_search_result_list.dart';
import 'package:user_interface/SCREENS/login/login_screen.dart';
import 'package:user_interface/MAIN UTILS/page_transition.dart';
import 'package:user_interface/SCREENS/start session/start_session_screen.dart';
import 'package:user_interface/SERVICES/AUTHETNTICATION HELPERS/secure_storage_service.dart';
import 'package:user_interface/SERVICES/parking_service.dart';
import 'package:user_interface/SERVICES/user_service.dart';
import 'package:user_interface/MODELS/parking_lot.dart';

import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _distanceLimitKm = 10.0;

  final UserService _userService = UserService();
  final ParkingApiService _parkingService = ParkingApiService();
  bool _locationAccessGranted = false;
  bool _isLocationLoading = true;
  bool _isLoading = true;

  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(41.9028, 12.4964);
  final Set<Marker> _markers = {};

  BitmapDescriptor? _userLocationIcon;
  BitmapDescriptor? _parkingMarkerIcon;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<ParkingLot> _parkingLots = [];
  List<ParkingLot> _nearbyParkingLots = [];
  List<ParkingLot> _filteredParkingLots = [];

  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchExpanded = false;
  bool _isNavigating = false;
  static const double _searchBarHeight = 60.0;

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
      targetWidth: 100,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ui.Image image = fi.image;
    final ByteData? resizedByteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

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
      targetWidth: 100,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ui.Image image = fi.image;
    final ByteData? resizedByteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

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

  void _applySearchFilter(List<ParkingLot> sourceLots) {
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
    bool accessGranted = false;
    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentPosition = LatLng(position.latitude, position.longitude);
      accessGranted = true;
    } catch (e) {
      accessGranted = false;
    }

    if (!mounted) return;

    setState(() {
      _locationAccessGranted = accessGranted;
      _isLocationLoading = false;
    });

    _filterAndDisplayParkings();
  }

  void _handleLogout(BuildContext context) async {
    final storageService = SecureStorageService();
    await storageService.deleteTokens();
    if (mounted) {
      Navigator.of(context).pushReplacement(slideRoute(const LoginScreen()));
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

  void _navigateToStartSession(ParkingLot parkingLot) async {
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

    print(
      'Current GPS Position: ${_currentPosition.latitude}, ${_currentPosition.longitude}',
    );

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

    final List<ParkingLot> tempNearbyList = [];
    final double distanceLimitInMeters = _distanceLimitKm * 1000;

    for (var lot in _parkingLots) {
      final distanceInMeters = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        lot.centerPosition.latitude,
        lot.centerPosition.longitude,
      );

      print(
        'Lot ${lot.name} (${lot.id}) distance: ${distanceInMeters.toStringAsFixed(2)} meters',
      );

      if (distanceInMeters <= distanceLimitInMeters) {
        tempNearbyList.add(lot);
      }
    }

    _nearbyParkingLots = tempNearbyList;

    _applySearchFilter(_nearbyParkingLots);

    print(
      'Parkings displayed after all filters: ${_filteredParkingLots.length}',
    );

    for (var lot in _filteredParkingLots) {
      newMarkers.add(
        Marker(
          markerId: MarkerId(lot.id.toString()),
          position: lot.centerPosition,
          infoWindow: InfoWindow(
            title: lot.name,
            snippet: 'Tap to start session...',
            onTap: () {
              _navigateToStartSession(lot);
            },
          ),
          icon:
              _parkingMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () {
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(lot.centerPosition),
            );
          },
        ),
      );
    }

    setState(() {
      _markers.clear();
      _markers.addAll(newMarkers);
    });

    if (_mapController != null && newMarkers.isNotEmpty) {
      LatLng targetPosition = _currentPosition;

      if (!_locationAccessGranted && _filteredParkingLots.isNotEmpty) {
        targetPosition = _filteredParkingLots.first.centerPosition;
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
    const searchBarColor = Color.fromARGB(255, 6, 20, 43);

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final double topSpace = mediaQuery.padding.top + 20.0 + _searchBarHeight;
    final double bottomSpace = mediaQuery.padding.bottom + 20.0;
    final double maxListHeight = screenHeight - topSpace - bottomSpace;

    return Stack(
      children: [
        HomeMapWidget(
          locationAccessGranted: _locationAccessGranted,
          currentPosition: _currentPosition,
          markers: _markers,
          onMapCreated: _onMapCreated,
          isLoading: _isLocationLoading,
          onTap: () {
            FocusScope.of(context).unfocus();
            setState(() => _isSearchExpanded = false);
          },
          gesturesEnabled: !_isSearchExpanded,
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
