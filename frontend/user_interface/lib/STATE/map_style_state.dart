import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_interface/SERVICES/map_style_service.dart';

final mapStyleProvider = StateNotifierProvider<MapStyleNotifier, bool>((ref) {
  return MapStyleNotifier();
});

class MapStyleNotifier extends StateNotifier<bool> {
  MapStyleNotifier() : super(false) {
    _loadInitialStyle();
  }

  Future<void> _loadInitialStyle() async {
    state = await MapStyleService.isDarkMode();
  }

  Future<void> toggleStyle(bool isDark) async {
    await MapStyleService.setDarkMode(isDark);
    state = isDark;
  }
}
