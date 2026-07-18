class Memory {
  const Memory({
    required this.id,
    required this.title,
    required this.detail,
    required this.when,
    required this.category,
    required this.personName,
    required this.timestamp,
    this.location = '',
    this.emotion = '',
    this.tags = const [],
    this.voiceTranscript = '',
  });

  final String id;
  final String title;
  final String detail;
  final String when;
  final String category;
  final String personName;
  final DateTime timestamp;
  final String location;
  final String emotion;
  final List<String> tags;
  final String voiceTranscript;

  Memory copyWith({
    String? id,
    String? title,
    String? detail,
    String? when,
    String? category,
    String? personName,
    DateTime? timestamp,
    String? location,
    String? emotion,
    List<String>? tags,
    String? voiceTranscript,
  }) {
    return Memory(
      id: id ?? this.id,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      when: when ?? this.when,
      category: category ?? this.category,
      personName: personName ?? this.personName,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
      emotion: emotion ?? this.emotion,
      tags: tags ?? this.tags,
      voiceTranscript: voiceTranscript ?? this.voiceTranscript,
    );
  }
}
