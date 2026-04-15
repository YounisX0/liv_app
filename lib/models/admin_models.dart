class AdminOverview {
  final int totalUsers;
  final int totalCows;

  const AdminOverview({
    required this.totalUsers,
    required this.totalCows,
  });

  factory AdminOverview.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return AdminOverview(
      totalUsers: toInt(json['totalUsers']),
      totalCows: toInt(json['totalCows']),
    );
  }
}