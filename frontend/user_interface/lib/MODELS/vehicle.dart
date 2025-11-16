
class Vehicle {
  final int id;
  final String plate;
  final String name; 

  Vehicle({
    required this.id,
    required this.plate,
    required this.name,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as int,
      plate: json['plate'] as String? ?? '',
      name: json['name'] as String? ?? '', 
    );
  }

  static List<Vehicle> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((item) => Vehicle.fromJson(item as Map<String, dynamic>)).toList();
  }
}