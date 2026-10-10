class TeamMember {
  final String id;
  final String name;
  final String role;
  final String email;
  final int colorValue;
  final String username;
  final String password;

  const TeamMember({
    required this.id,
    required this.name,
    required this.role,
    this.email = '',
    required this.colorValue,
    this.username = '',
    this.password = '',
  });

  /// "John Doe" -> "JD"
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  TeamMember copyWith({
    String? name,
    String? role,
    String? email,
    int? colorValue,
    String? username,
    String? password,
  }) {
    return TeamMember(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      email: email ?? this.email,
      colorValue: colorValue ?? this.colorValue,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'email': email,
    'colorValue': colorValue,
    'username': username,
    'password': password,
  };

  factory TeamMember.fromJson(Map<String, dynamic> j) => TeamMember(
    id: j['id'] as String,
    name: j['name'] as String,
    role: j['role'] as String? ?? '',
    email: j['email'] as String? ?? '',
    colorValue: j['colorValue'] as int? ?? 0xFF1565C0,
    username: j['username'] as String? ?? '',
    password: j['password'] as String? ?? '',
  );
}