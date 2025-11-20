// frontend/user_interface/lib/SCREENS/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:user_interface/SCREENS/home/utils/home_map_widget.dart';
import 'package:user_interface/SCREENS/home/utils/home_search_bar.dart';
import 'package:user_interface/SCREENS/home/utils/home_search_result_list.dart';
import 'package:user_interface/SCREENS/login/login_screen.dart';
import 'package:user_interface/MAIN%20UTILS/page_transition.dart';
import 'package:user_interface/SCREENS/start%20session/start_session_screen.dart';
import 'package:user_interface/SERVICES/AUTHETNTICATION%20HELPERS/secure_storage_service.dart';
import 'package:user_interface/SERVICES/parking_service.dart';
import 'package:user_interface/SERVICES/user_service.dart';
import 'package:user_interface/MODELS/parking_lot.dart';

// 新增导入: 用于处理图片资源
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

  // 用于存储自定义用户图标的 BitmapDescriptor
  BitmapDescriptor? _userLocationIcon;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<ParkingLot> _parkingLots = [];
  List<ParkingLot> _nearbyParkingLots = [];
  List<ParkingLot> _filteredParkingLots = [];

  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchExpanded = false;
  bool _isNavigating = false; // Correzione per il bug del focus
  static const double _searchBarHeight = 60.0;

  @override
  void initState() {
    super.initState();
    _loadAllUserData();
    _loadParkingLots();
    _getUserLocation();
    _loadCustomUserIcon(); // 加载自定义用户图标
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

  // 加载自定义用户图标并创建 BitmapDescriptor
  Future<void> _loadCustomUserIcon() async {
    // 1. 从 assets 中加载图片
    // 请确保文件路径 'assets/images/car_location_marker.png' 正确
    final ByteData byteData = await rootBundle.load(
      'assets/images/car_location_marker.png',
    );

    // 2. 转换为 BitmapDescriptor (targetWidth 用于调整图标大小，例如 80-120 像素)
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

    // 3. 更新状态，存储 BitmapDescriptor
    setState(() {
      _userLocationIcon = BitmapDescriptor.fromBytes(
        resizedByteData.buffer.asUint8List(),
      );
    });

    // 4. 由于图标加载完毕，重新渲染标记
    _filterAndDisplayParkings();
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
    if (_locationAccessGranted) {
      // 关键修改：将用户位置图标设置为自定义图标
      newMarkers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: _currentPosition,
          infoWindow: const InfoWindow(title: 'You are here'),
          icon: _userLocationIcon ?? BitmapDescriptor.defaultMarker, // 使用自定义图标
        ),
      );
    }

    _nearbyParkingLots = _parkingLots.where((lot) {
      final distanceInMeters = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        lot.centerPosition.latitude,
        lot.centerPosition.longitude,
      );
      return distanceInMeters <= (_distanceLimitKm * 1000);
    }).toList();

    _applySearchFilter(_nearbyParkingLots);

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
          icon: BitmapDescriptor.defaultMarker, // 保持停车场图标为默认图标
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
