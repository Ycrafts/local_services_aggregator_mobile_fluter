class JobType {
  final int id;
  final String name;
  final double baselinePrice;

  JobType({
    required this.id,
    required this.name,
    required this.baselinePrice,
  });

  factory JobType.fromJson(Map<String, dynamic> json) {
    return JobType(
      id: json['id'],
      name: json['name'],
      baselinePrice: double.parse(json['baseline_price'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'baseline_price': baselinePrice,
    };
  }
} 