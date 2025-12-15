import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/user_progress.dart';
import '../widgets/xp_bar.dart';
import '../widgets/task_item.dart';
import 'pomodoro_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> _tasks = [];
  UserProgress _userProgress = UserProgress();
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Carregar dados salvos
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Carregar progresso do usuário
    final progressMap = prefs.getString('user_progress');
    if (progressMap != null) {
      setState(() {
        _userProgress = UserProgress.fromMap(json.decode(progressMap));
      });
    }
    
    // Carregar tarefas
    final tasksJson = prefs.getStringList('tasks') ?? [];
    setState(() {
      _tasks = tasksJson.map((json) => Task.fromJson(json)).toList();
    });
  }

  // Salvar dados
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Salvar progresso
    await prefs.setString('user_progress', json.encode(_userProgress.toMap()));
    
    // Salvar tarefas
    final tasksJson = _tasks.map((task) => task.toJson()).toList();
    await prefs.setStringList('tasks', tasksJson);
  }

  // Adicionar nova tarefa
  void _addTask() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Tarefa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                setState(() {
                  _tasks.add(Task(
                    id: DateTime.now().toString(),
                    title: titleController.text,
                    description: descriptionController.text,
                  ));
                });
                _saveData();
                Navigator.pop(context);
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  // Marcar tarefa como concluída
  void _toggleTask(int index) {
    setState(() {
      final task = _tasks[index];
      final updatedTask = task.copyWith(isDone: !task.isDone);
      _tasks[index] = updatedTask;
      
      // Se a tarefa foi marcada como concluída, ganhar XP
      if (updatedTask.isDone && !task.isDone) {
        _userProgress = _userProgress.addXp(task.xpReward);
        _showXpGainedSnackbar(task.xpReward);
      }
    });
    _saveData();
  }

  // Excluir tarefa
  void _deleteTask(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Tarefa'),
        content: const Text('Tem certeza que deseja excluir esta tarefa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _tasks.removeAt(index);
              });
              _saveData();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  // Iniciar Pomodoro
  void _startPomodoro(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PomodoroScreen(
          task: _tasks[index],
          onPomodoroComplete: (xpGained) {
            setState(() {
              _userProgress = _userProgress.addXp(xpGained);
              _tasks[index] = _tasks[index].copyWith(
                pomodoroCount: _tasks[index].pomodoroCount + 1,
              );
            });
            _saveData();
            _showXpGainedSnackbar(xpGained);
          },
        ),
      ),
    );
  }

  // Mostrar notificação de XP ganho
  void _showXpGainedSnackbar(int xp) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Você ganhou $xp XP!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📝 ToDoList XP'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barra de XP
          Padding(
            padding: const EdgeInsets.all(16),
            child: XpBar(
              level: _userProgress.level,
              currentXp: _userProgress.totalXp,
              xpForNextLevel: _userProgress.xpForNextLevel,
              progressPercentage: _userProgress.progressPercentage,
            ),
          ),
          
          // Estatísticas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Total', _tasks.length.toString(), Icons.list, Colors.blue),
                _buildStatCard(
                  'Concluídas',
                  _tasks.where((t) => t.isDone).length.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatCard(
                  'Pendentes',
                  _tasks.where((t) => !t.isDone).length.toString(),
                  Icons.pending,
                  Colors.orange,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Lista de tarefas
          Expanded(
            child: _tasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma tarefa ainda',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Clique no + para adicionar',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      return TaskItem(
                        task: _tasks[index],
                        onToggle: () => _toggleTask(index),
                        onDelete: () => _deleteTask(index),
                        onPomodoro: () => _startPomodoro(index),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTask,
        icon: const Icon(Icons.add),
        label: const Text('Nova Tarefa'),
        backgroundColor: Colors.blue.shade700,
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
