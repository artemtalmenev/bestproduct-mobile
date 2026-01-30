class Task {
  final String id;
  final String title;
  final String? description;
  final String status;
  final DateTime? dueAt;
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.dueAt,
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'todo',
      dueAt: json['dueAt'] != null ? DateTime.tryParse(json['dueAt'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    DateTime? dueAt,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      dueAt: dueAt ?? this.dueAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
