class ActivityLog {
  final String id;
  final String message;
  final String memberId;
  final DateTime timestamp;

  const ActivityLog({
    required this.id,
    required this.message,
    required this.memberId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'message': message,
    'memberId': memberId,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ActivityLog.fromJson(Map<String, dynamic> j) => ActivityLog(
    id: j['id'] as String,
    message: j['message'] as String,
    memberId: j['memberId'] as String,
    timestamp: DateTime.parse(j['timestamp'] as String),
  );
}