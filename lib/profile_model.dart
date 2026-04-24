class UserProfile {
  final String uid;
  final String? displayName;
  final String? photoUrl;
  final String? phone;
  final String? bio;
  final String? birthday; // เก็บเป็น "YYYY-MM-DD" ง่าย ๆ
  final int? updatedAt;

  UserProfile({
    required this.uid,
    this.displayName,
    this.photoUrl,
    this.phone,
    this.bio,
    this.birthday,
    this.updatedAt,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic>? data) {
    final d = data ?? {};
    return UserProfile(
      uid: uid,
      displayName: d['displayName'],
      photoUrl: d['photoUrl'],
      phone: d['phone'],
      bio: d['bio'],
      birthday: d['birthday'],
      updatedAt: d['updatedAt'],
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'photoUrl': photoUrl,
        'phone': phone,
        'bio': bio,
        'birthday': birthday,
        'updatedAt': updatedAt ?? DateTime.now().millisecondsSinceEpoch,
      }..removeWhere((k, v) => v == null);
}
