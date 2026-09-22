class CarModel {
  final String carId;
  final String name;
  final String category; // "SUV", "MUV", "Sedan", "Hatchback"
  final String fuelType; // "Petrol", "Diesel", "EV", "Hybridge", "CNG"
  final int seatingCapacity;
  final String transmission; // "Automatic", "Manual"
  final double pricePerHour;
  final int totalUnits;
  final String imageUrl;
  final String district; // e.g. "Ahmedabad", "Surat", etc.

  CarModel({
    required this.carId,
    required this.name,
    required this.category,
    required this.fuelType,
    required this.seatingCapacity,
    required this.transmission,
    required this.pricePerHour,
    required this.totalUnits,
    required this.imageUrl,
    this.district = 'Ahmedabad',
  });

  factory CarModel.fromMap(Map<String, dynamic> map, String id) {
    return CarModel(
      carId: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      fuelType: map['fuelType'] ?? '',
      seatingCapacity: map['seatingCapacity'] ?? 0,
      transmission: map['transmission'] ?? '',
      pricePerHour: (map['pricePerHour'] ?? 0).toDouble(),
      totalUnits: map['totalUnits'] ?? 0,
      imageUrl: map['imageUrl'] ?? '',
      district: map['district'] ?? 'Ahmedabad',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'fuelType': fuelType,
      'seatingCapacity': seatingCapacity,
      'transmission': transmission,
      'pricePerHour': pricePerHour,
      'totalUnits': totalUnits,
      'imageUrl': imageUrl,
      'district': district,
    };
  }
}
