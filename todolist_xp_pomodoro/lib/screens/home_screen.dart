import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../widgets/task_item.dart';
import 'pomodoro_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> _tasks = [];
  bool _hasActiveTimer = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkActiveTimer();
  }

  // Carregar tarefas salvas
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('tasks') ?? [];
    setState(() {
      _tasks = tasksJson.map((json) => Task.fromJson(json)).toList();
    });
  }

  // Salvar tarefas
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = _tasks.map((task) => task.toJson()).toList();
    await prefs.setStringList('tasks', tasksJson);
  }

  // Verificar se há timer ativo
  Future<void> _checkActiveTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final timerSeconds = prefs.getInt('timer_seconds_remaining');
    setState(() {
      _hasActiveTimer = timerSeconds != null && timerSeconds > 0;
    });
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
                  _tasks.add(
                    Task(
                      id: DateTime.now().toString(),
                      title: titleController.text,
                      description: descriptionController.text,
                    ),
                  );
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
      _tasks[index] = task.copyWith(isDone: !task.isDone);
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

  // Navegar para tela do Pomodoro (genérico)
  void _openPomodoro() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PomodoroScreen()),
    );
    _checkActiveTimer();
  }

  // Iniciar Pomodoro para tarefa específica
  void _startPomodoroForTask(int index) async {
    final task = _tasks[index];
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PomodoroScreen(
          task: task,
          onPomodoroComplete: () {
            setState(() {
              _tasks[index] = task.copyWith(
                pomodoroCount: task.pomodoroCount + 1,
              );
            });
            _saveData();
          },
        ),
      ),
    );
    _checkActiveTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📝 ToDoList + Pomodoro'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.timer),
                if (_hasActiveTimer)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Text('●', style: TextStyle(fontSize: 8)),
                    ),
                  ),
              ],
            ),
            onPressed: _openPomodoro,
            tooltip: 'Abrir Pomodoro',
          ),
        ],
      ),
      body: Column(
        children: [
          // Estatísticas
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'Total',
                  _tasks.length.toString(),
                  Icons.list,
                  Colors.blue,
                ),
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

          const SizedBox(height: 8),

          // Lista de tarefas
          Expanded(
            child: _tasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
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
                        onPomodoro: () => _startPomodoroForTask(index),
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

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    MaterialColor color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
          Text(label, style: TextStyle(fontSize: 12, color: color.shade700)),
        ],
      ),
    );
  }
}
