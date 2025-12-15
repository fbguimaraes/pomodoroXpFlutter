import 'dart:convert';

class Task {
  final String id;
  final String title;
  final String description;
  final bool isDone;
  final int xpReward;
  final int pomodoroCount;

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.isDone = false,
    this.xpReward = 50,
    this.pomodoroCount = 0,
  });

  // Converter Task para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isDone': isDone,
      'xpReward': xpReward,
      'pomodoroCount': pomodoroCount,
    };
  }

  // Criar Task a partir de Map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      isDone: map['isDone'],
      xpReward: map['xpReward'],
      pomodoroCount: map['pomodoroCount'],
    );
  }

  // Converter para JSON
  String toJson() => json.encode(toMap());

  // Criar a partir de JSON
  factory Task.fromJson(String source) => Task.fromMap(json.decode(source));

  // Copiar Task com modificações
  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isDone,
    int? xpReward,
    int? pomodoroCount,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isDone: isDone ?? this.isDone,
      xpReward: xpReward ?? this.xpReward,
      pomodoroCount: pomodoroCount ?? this.pomodoroCount,
    );
  }
}
