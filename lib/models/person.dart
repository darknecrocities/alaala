class Person {
  const Person({
    required this.name,
    required this.relationship,
    required this.detail,
    required this.favoriteFood,
    this.birthday = '',
    this.visits = 0,
    this.lastSeen,
    this.embeddings = const [],
    this.notes = const [],
  });

  final String name;
  final String relationship;
  final String detail;
  final String favoriteFood;
  final String birthday;
  final int visits;
  final DateTime? lastSeen;
  final List<double> embeddings;
  final List<String> notes;

  Person copyWith({
    String? name,
    String? relationship,
    String? detail,
    String? favoriteFood,
    String? birthday,
    int? visits,
    DateTime? lastSeen,
    List<double>? embeddings,
    List<String>? notes,
  }) {
    return Person(
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      detail: detail ?? this.detail,
      favoriteFood: favoriteFood ?? this.favoriteFood,
      birthday: birthday ?? this.birthday,
      visits: visits ?? this.visits,
      lastSeen: lastSeen ?? this.lastSeen,
      embeddings: embeddings ?? this.embeddings,
      notes: notes ?? this.notes,
    );
  }
}
