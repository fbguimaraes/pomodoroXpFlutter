import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class PomodoroScreen extends StatefulWidget {
  final Task? task;
  final VoidCallback? onPomodoroComplete;

  const PomodoroScreen({super.key, this.task, this.onPomodoroComplete});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  static const int workDuration = 25 * 60; // 25 minutos em segundos
  static const int shortBreakDuration = 5 * 60; // 5 minutos em segundos
  static const int longBreakDuration = 15 * 60; // 15 minutos em segundos

  int _secondsRemaining = workDuration;
  bool _isRunning = false;
  PomodoroPhase _currentPhase = PomodoroPhase.work;
  Timer? _timer;
  int _completedWorkSessions = 0;

  @override
  void initState() {
    super.initState();
    _loadTimerState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _saveTimerState();
    super.dispose();
  }

  // Carregar estado do timer
  Future<void> _loadTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSeconds = prefs.getInt('timer_seconds_remaining');
    final savedPhase = prefs.getString('timer_phase');
    final savedRunning = prefs.getBool('timer_is_running') ?? false;
    final savedSessions = prefs.getInt('timer_completed_sessions') ?? 0;
    final savedTaskId = prefs.getString('timer_task_id');
    final savedLastUpdate = prefs.getString('timer_last_update');

    // Verificar se o timer salvo é para esta tarefa
    final taskMatches =
        (widget.task?.id == savedTaskId) ||
        (widget.task == null && savedTaskId == null);

    if (savedSeconds != null && taskMatches && savedPhase != null) {
      setState(() {
        _completedWorkSessions = savedSessions;
        _secondsRemaining = savedSeconds;
        _currentPhase = PomodoroPhase.values.firstWhere(
          (e) => e.name == savedPhase,
          orElse: () => PomodoroPhase.work,
        );

        // Se estava rodando, calcular tempo decorrido
        if (savedRunning && savedLastUpdate != null) {
          final lastUpdate = DateTime.parse(savedLastUpdate);
          final elapsed = DateTime.now().difference(lastUpdate).inSeconds;
          _secondsRemaining = (_secondsRemaining - elapsed).clamp(
            0,
            workDuration,
          );

          if (_secondsRemaining > 0) {
            _isRunning = true;
            _startTimer();
          }
        }
      });
    }
  }

  // Salvar estado do timer
  Future<void> _saveTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('timer_seconds_remaining', _secondsRemaining);
    await prefs.setString('timer_phase', _currentPhase.name);
    await prefs.setBool('timer_is_running', _isRunning);
    await prefs.setInt('timer_completed_sessions', _completedWorkSessions);
    await prefs.setString('timer_task_id', widget.task?.id ?? '');
    await prefs.setString(
      'timer_last_update',
      DateTime.now().toIso8601String(),
    );
  }

  // Limpar estado do timer
  Future<void> _clearTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('timer_seconds_remaining');
    await prefs.remove('timer_phase');
    await prefs.remove('timer_is_running');
    await prefs.remove('timer_completed_sessions');
    await prefs.remove('timer_task_id');
    await prefs.remove('timer_last_update');
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;

          // Salvar estado periodicamente
          if (_secondsRemaining % 10 == 0) {
            _saveTimerState();
          }
        } else {
          // Timer completado
          _timer?.cancel();
          _isRunning = false;
          _handlePhaseCompletion();
        }
      });
    });
  }

  void _pauseTimer() {
    setState(() {
      _isRunning = false;
      _timer?.cancel();
    });
    _saveTimerState();
  }

  void _resetTimer() {
    setState(() {
      _timer?.cancel();
      _isRunning = false;
      _secondsRemaining = _getDurationForPhase(_currentPhase);
    });
    _saveTimerState();
  }

  int _getDurationForPhase(PomodoroPhase phase) {
    switch (phase) {
      case PomodoroPhase.work:
        return workDuration;
      case PomodoroPhase.shortBreak:
        return shortBreakDuration;
      case PomodoroPhase.longBreak:
        return longBreakDuration;
    }
  }

  void _handlePhaseCompletion() {
    if (_currentPhase == PomodoroPhase.work) {
      _completedWorkSessions++;

      // Chamar callback se for um Pomodoro de tarefa
      if (widget.task != null && widget.onPomodoroComplete != null) {
        widget.onPomodoroComplete!();
      }

      _showWorkCompleteDialog();
    } else {
      _showBreakCompleteDialog();
    }
    _saveTimerState();
  }

  void _showWorkCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Pomodoro Completo!'),
        content: Text(
          widget.task != null
              ? 'Você completou um pomodoro de "${widget.task!.title}"!\n\n'
                    'Pomodoros completados: $_completedWorkSessions'
              : 'Você completou um pomodoro de trabalho!\n\n'
                    'Pomodoros completados: $_completedWorkSessions',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startBreak();
            },
            child: Text(
              _completedWorkSessions % 4 == 0
                  ? 'Iniciar Pausa Longa (15 min)'
                  : 'Iniciar Pausa Curta (5 min)',
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearTimerState(); // Limpar estado ao voltar
              Navigator.of(context).pop(); // Voltar para tela principal
            },
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }

  void _startBreak() {
    setState(() {
      if (_completedWorkSessions % 4 == 0) {
        // Pausa longa após 4 pomodoros
        _currentPhase = PomodoroPhase.longBreak;
        _secondsRemaining = longBreakDuration;
      } else {
        // Pausa curta
        _currentPhase = PomodoroPhase.shortBreak;
        _secondsRemaining = shortBreakDuration;
      }
    });
    _saveTimerState();
  }

  void _showBreakCompleteDialog() {
    final isLongBreak = _currentPhase == PomodoroPhase.longBreak;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isLongBreak ? '⏰ Pausa Longa Completa!' : '⏰ Pausa Curta Completa!',
        ),
        content: const Text('Hora de voltar ao trabalho!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _currentPhase = PomodoroPhase.work;
                _secondsRemaining = workDuration;
              });
              _saveTimerState();
            },
            child: const Text('Iniciar Trabalho'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearTimerState(); // Limpar estado ao voltar
              Navigator.of(context).pop(); // Voltar para tela principal
            },
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  MaterialColor _getPhaseColor() {
    switch (_currentPhase) {
      case PomodoroPhase.work:
        return Colors.red;
      case PomodoroPhase.shortBreak:
        return Colors.green;
      case PomodoroPhase.longBreak:
        return Colors.blue;
    }
  }

  String _getPhaseTitle() {
    switch (_currentPhase) {
      case PomodoroPhase.work:
        return widget.task != null
            ? '🍅 ${widget.task!.title}'
            : '🍅 Pomodoro - Trabalho';
      case PomodoroPhase.shortBreak:
        return '☕ Pausa Curta';
      case PomodoroPhase.longBreak:
        return '🌴 Pausa Longa';
    }
  }

  @override
  Widget build(BuildContext context) {
    final phaseColor = _getPhaseColor();

    return Scaffold(
      appBar: AppBar(
        title: Text(_getPhaseTitle()),
        backgroundColor: phaseColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [phaseColor.shade400, phaseColor.shade800],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Indicador de fase
              Text(
                _currentPhase == PomodoroPhase.work
                    ? widget.task != null
                          ? 'Trabalhando em: ${widget.task!.title}'
                          : 'Tempo de Foco'
                    : _currentPhase == PomodoroPhase.shortBreak
                    ? 'Pausa Curta'
                    : 'Pausa Longa',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Timer circular
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _formatTime(_secondsRemaining),
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: phaseColor.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Botões de controle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isRunning ? _pauseTimer : _startTimer,
                    icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                    label: Text(_isRunning ? 'Pausar' : 'Iniciar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: phaseColor.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Resetar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.9),
                      foregroundColor: Colors.grey.shade800,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Estatísticas
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Pomodoros Completados Hoje',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_completedWorkSessions 🍅',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Próxima pausa: ${_completedWorkSessions % 4 == 3 ? "Longa" : "Curta"}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum PomodoroPhase { work, shortBreak, longBreak }
