import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:manager_interface/SCREENS/live%20monitor%20screen/live_monitor_screen.dart';

// Import Models & Services
import 'package:manager_interface/SCREENS/parking%20detail/utils/cost_simulator/active_rules_card.dart';
import 'package:manager_interface/SCREENS/parking%20detail/utils/cost_simulator/cost_chart.dart';
import 'package:manager_interface/SCREENS/parking%20detail/utils/live_stats/live_stats_widgets.dart';
import 'package:manager_interface/SCREENS/parking%20detail/utils/parking_cost_calculator.dart';
import 'package:manager_interface/SCREENS/parking%20detail/utils/tariff_management/spot_stat_widgets.dart';
import 'package:manager_interface/SCREENS/parking%20detail/utils/tariff_management/tariff_selection_card.dart';
import 'package:manager_interface/models/parking.dart';
import 'package:manager_interface/models/spot.dart';
import 'package:manager_interface/models/tariff_config.dart';
import 'package:manager_interface/services/parking_service.dart';

class ParkingDetailScreen extends StatefulWidget {
  final int parkingId;

  const ParkingDetailScreen({super.key, required this.parkingId});

  @override
  State<ParkingDetailScreen> createState() => _ParkingDetailScreenState();
}

class _ParkingDetailScreenState extends State<ParkingDetailScreen> {
  Parking? parking;
  List<Spot> spots = [];
  bool isLoading = true;

  String _selectedRateType = 'HOURLY_LINEAR';
  final _dailyRateController = TextEditingController();
  final _dayRateController = TextEditingController();
  final _nightRateController = TextEditingController();
  TimeOfDay _nightStartTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _nightEndTime = const TimeOfDay(hour: 6, minute: 0);
  List<FlexRule> _flexRules = [];

  List<FlSpot> _chartData = [];

  double dailyEntries = 0.0;
  double projectedRevenue = 0.0;
  final double avgStayHours = 3.5;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);
    try {
      parking = await ParkingService.getParking(widget.parkingId);
      spots = await ParkingService.getSpots(widget.parkingId);

      _initializeTariffState(parking!.tariffConfig);
      _simulateCostProjection();
      _calculateProjectedRevenue();

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load dashboard: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _initializeTariffState(TariffConfig config) {
    _selectedRateType = config.type;
    _dailyRateController.text = config.dailyRate.toStringAsFixed(2);
    _dayRateController.text = config.dayBaseRate.toStringAsFixed(2);
    _nightRateController.text = config.nightBaseRate.toStringAsFixed(2);

    try {
      final startParts = config.nightStartTime.split(':');
      _nightStartTime = TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      );
      final endParts = config.nightEndTime.split(':');
      _nightEndTime = TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      );
    } catch (_) {
      _nightStartTime = const TimeOfDay(hour: 22, minute: 0);
      _nightEndTime = const TimeOfDay(hour: 6, minute: 0);
    }

    _flexRules =
        (config.flexRulesRaw as List<dynamic>?)
            ?.map((r) => FlexRule.fromTariffConfig(r as Map<String, dynamic>))
            .toList() ??
        [];
  }

  TariffConfig _getCurrentTariffConfig() {
    return TariffConfig(
      type: _selectedRateType,
      dailyRate: double.tryParse(_dailyRateController.text) ?? 0.0,
      dayBaseRate: double.tryParse(_dayRateController.text) ?? 0.0,
      nightBaseRate: double.tryParse(_nightRateController.text) ?? 0.0,
      nightStartTime:
          '${_nightStartTime.hour.toString().padLeft(2, '0')}:${_nightStartTime.minute.toString().padLeft(2, '0')}',
      nightEndTime:
          '${_nightEndTime.hour.toString().padLeft(2, '0')}:${_nightEndTime.minute.toString().padLeft(2, '0')}',
      flexRulesRaw: _flexRules.map((r) => r.toJson()).toList(),
    );
  }

  void _onTariffDataChanged() {
    setState(() {
      _simulateCostProjection();
      _calculateProjectedRevenue();
    });
  }

  Future<void> _updateTariff() async {
    if (parking == null) return;

    final config = _getCurrentTariffConfig();

    double displayRate;
    if (config.type == 'FIXED_DAILY') {
      displayRate = config.dailyRate;
    } else {
      displayRate = config.dayBaseRate;
    }

    final updatedParking = Parking(
      id: parking!.id,
      name: parking!.name,
      city: parking!.city,
      address: parking!.address,
      totalSpots: parking!.totalSpots,
      occupiedSpots: parking!.occupiedSpots,
      ratePerHour: displayRate,
      tariffConfig: config,
      latitude: parking!.latitude,
      longitude: parking!.longitude,
    );

    try {
      await ParkingService.saveParking(updatedParking);
      parking = updatedParking;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tariff and Rules updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update tariff: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addSpot() async {
    try {
      final newSpot = await ParkingService.addSpot(parking!.id);
      final newSpotsList = List<Spot>.from(spots)..add(newSpot);
      final newParking = Parking(
        id: parking!.id,
        name: parking!.name,
        city: parking!.city,
        address: parking!.address,
        totalSpots: parking!.totalSpots + 1,
        occupiedSpots: parking!.occupiedSpots,
        ratePerHour: parking!.ratePerHour,
        tariffConfig: parking!.tariffConfig,
        latitude: parking!.latitude,
        longitude: parking!.longitude,
      );

      setState(() {
        spots = newSpotsList;
        parking = newParking;
        _calculateProjectedRevenue();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Spot added.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add spot: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteSpot(int spotId) async {
    try {
      final success = await ParkingService.deleteSpot(spotId);
      if (success) {
        final spotToRemove = spots.firstWhere(
          (s) => s.id == spotId,
          orElse: () => spots.last,
        );
        final newSpotsList = spots.where((s) => s.id != spotId).toList();
        final newParking = Parking(
          id: parking!.id,
          name: parking!.name,
          city: parking!.city,
          address: parking!.address,
          totalSpots: parking!.totalSpots - 1,
          occupiedSpots:
              parking!.occupiedSpots - (spotToRemove.isOccupied ? 1 : 0),
          ratePerHour: parking!.ratePerHour,
          tariffConfig: parking!.tariffConfig,
          latitude: parking!.latitude,
          longitude: parking!.longitude,
        );

        setState(() {
          spots = newSpotsList;
          parking = newParking;
          _calculateProjectedRevenue();
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Spot deleted.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete spot: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openLiveMonitor() {
    if (parking == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveMonitorScreen(
          parkingId: parking!.id,
          parkingName: parking!.name,
        ),
      ),
    ).then((_) => _loadDashboardData());
  }

  void _simulateCostProjection() {
    if (parking == null) return;
    if (!mounted) return;

    final config = _getCurrentTariffConfig();
    final calculator = CostCalculator(config);
    final List<FlSpot> newChartData = [];

    for (int hours = 0; hours <= 24; hours += 1) {
      double cost = calculator.calculateCostForHours(hours.toDouble());
      newChartData.add(FlSpot(hours.toDouble(), cost));
    }

    setState(() {
      _chartData = newChartData;
    });
  }

  void _calculateProjectedRevenue() {
    if (parking == null) return;
    final totalSpots = parking!.totalSpots;
    final occupiedSpots = parking!.occupiedSpots;

    if (totalSpots == 0) {
      projectedRevenue = 0.0;
      dailyEntries = 0.0;
      return;
    }

    final TariffConfig currentConfig = _getCurrentTariffConfig();
    final calculator = CostCalculator(currentConfig);

    final costPer24h = calculator.calculateCostForHours(24);

    projectedRevenue = costPer24h * occupiedSpots;

    dailyEntries = (occupiedSpots * (24 / avgStayHours));
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || parking == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final int availableSpots = parking!.availableSpots;
    final int occupiedSpots = parking!.occupiedSpots;
    final int totalSpots = parking!.totalSpots;
    final double occupancyPercentage = totalSpots > 0
        ? (occupiedSpots / totalSpots) * 100
        : 0.0;
    final config = _getCurrentTariffConfig();
    final lastSpot = spots.isNotEmpty ? spots.last : null;

    return Scaffold(
      backgroundColor: const Color(0xFF020B3C),
      appBar: AppBar(
        title: Text(
          '${parking!.name} - Dashboard',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton.icon(
            onPressed: _openLiveMonitor,
            icon: const Icon(
              Icons.monitor_heart_outlined,
              color: Colors.greenAccent,
            ),
            label: Text(
              'Live Monitor',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        height: double.infinity,
        padding: const EdgeInsets.all(20),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // COLUMN 1: Tariff Management (25% width)
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tariff Management',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildCard(
                      title: 'Tariff & Rules',
                      child: TariffManagementCard(
                        selectedRateType: _selectedRateType,
                        dailyRateController: _dailyRateController,
                        dayRateController: _dayRateController,
                        nightRateController: _nightRateController,
                        nightStartTime: _nightStartTime,
                        nightEndTime: _nightEndTime,
                        flexRules: _flexRules,
                        onDataChanged: _onTariffDataChanged,
                        onSelectType: (type) => setState(() {
                          _selectedRateType = type;
                          _onTariffDataChanged();
                        }),
                        onStartTimeChanged: (newTime) =>
                            setState(() => _nightStartTime = newTime),
                        onEndTimeChanged: (newTime) =>
                            setState(() => _nightEndTime = newTime),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildCard(
                      title: 'Spot Management',
                      child: SpotStatCard(
                        totalSpots: totalSpots,
                        occupiedSpots: occupiedSpots,
                        availableSpots: availableSpots,
                        onAddSpot: _addSpot,
                        onRemoveLastSpot: () {
                          if (lastSpot != null) {
                            _deleteSpot(lastSpot.id);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No spots available to delete.'),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _updateTariff,
                        icon: const Icon(Icons.save, color: Colors.black),
                        label: Text(
                          'Save Tariff & Rules',
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 20),

            // COLUMN 2: Cost Simulator (50% width)
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cost Simulator',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildCard(
                      title: 'Cost Projection (24h)',
                      child: CostChart(chartData: _chartData),
                    ),
                    const SizedBox(height: 20),

                    _buildCard(
                      title: 'Active Rules Summary',
                      child: ActiveRulesCard(config: config),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 20),

            // COLUMN 3: Live Stats (25% width)
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Stats',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildCard(
                      title: 'Current Occupancy',
                      child: OccupancyCard(
                        percentage: occupancyPercentage,
                        totalSpots: totalSpots,
                        occupiedSpots: occupiedSpots,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildCard(
                      title: 'Projected Daily Revenue',
                      child: RevenueCard(projectedRevenue: projectedRevenue),
                    ),
                    const SizedBox(height: 20),

                    _buildCard(
                      title: 'Estimated Daily Entries',
                      child: DailyEntriesCard(
                        dailyEntries: dailyEntries.round(),
                        avgStayHours: avgStayHours,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
