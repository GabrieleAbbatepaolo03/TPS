
class Vehicle {
  final int id;
  final String plate;
  final String name; 
  final bool isFavorite; 

  Vehicle({
    required this.id,
    required this.plate,
    required this.name,
    this.isFavorite = false, 
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as int,
      plate: json['plate'] as String? ?? '',
      name: json['name'] as String? ?? '', 
      isFavorite: json['is_favorite'] as bool? ?? false, 
    );
  }

  // Metodo per aggiornare lo stato di preferito
  Vehicle copyWith({
    int? id,
    String? plate,
    String? name,
    bool? isFavorite,
  }) {
    return Vehicle(
      id: id ?? this.id,
      plate: plate ?? this.plate,
      name: name ?? this.name,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  static List<Vehicle> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((item) => Vehicle.fromJson(item as Map<String, dynamic>)).toList();
  }
}