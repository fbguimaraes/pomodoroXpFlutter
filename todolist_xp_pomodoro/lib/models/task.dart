import 'dart:convert';

class Task {
  final String id;
  final String title;
  final String description;
  final bool isDone;
  final int pomodoroCount;

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.isDone = false,
    this.pomodoroCount = 0,
  });

  // Copiar Task com modificações
  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isDone,
    int? pomodoroCount,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isDone: isDone ?? this.isDone,
      pomodoroCount: pomodoroCount ?? this.pomodoroCount,
    );
  }

  // Converter para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isDone': isDone,
      'pomodoroCount': pomodoroCount,
    };
  }

  // Criar a partir de Map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      isDone: map['isDone'],
      pomodoroCount: map['pomodoroCount'] ?? 0,
    );
  }

  // Converter para JSON
  String toJson() => json.encode(toMap());

  // Criar a partir de JSON
  factory Task.fromJson(String source) => Task.fromMap(json.decode(source));
}
