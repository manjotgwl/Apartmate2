class Profile {
  final String id;
  final String displayName;
  final String bio;
  final String? phoneNumber;

  const Profile({
    required this.id,
    required this.displayName,
    required this.bio,
    this.phoneNumber,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      displayName: json["display_name"] as String,
      bio: json['bio'] as String,
      phoneNumber: json['phone_number'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'display_name': displayName, 'bio': bio};
  }
}
