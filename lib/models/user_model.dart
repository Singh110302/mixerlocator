class UserModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final bool isSharing;

  UserModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.isSharing,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      isSharing: json['isSharing'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'isSharing': isSharing,
  };
}
