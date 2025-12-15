import 'dart:async';
import 'package:flutter/material.dart';
import '../models/task.dart';

class PomodoroScreen extends StatefulWidget {
  final Task task;
  final Function(int) onPomodoroComplete;

  const PomodoroScreen({
    super.key,
    required this.task,
    required this.onPomodoroComplete,
  });

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  static const int workDuration = 25 * 60; // 25 minutos em segundos
  static const int breakDuration = 5 * 60; // 5 minutos em segundos
  
  int _secondsRemaining = workDuration;
  bool _isRunning = false;
  bool _isWorkTime = true;
  Timer? _timer;
  int _completedPomodoros = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          // Timer completado
          _timer?.cancel();
          _isRunning = false;
          
          if (_isWorkTime) {
            // Completou um pomodoro de trabalho
            _completedPomodoros++;
            _showCompletionDialog();
          } else {
            // Completou uma pausa
            _showBreakCompleteDialog();
          }
        }
      });
    });
  }

  void _pauseTimer() {
    setState(() {
      _isRunning = false;
      _timer?.cancel();
    });
  }

  void _resetTimer() {
    setState(() {
      _timer?.cancel();
      _isRunning = false;
      _secondsRemaining = _isWorkTime ? workDuration : breakDuration;
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Pomodoro Completo!'),
        content: Text('Você completou um pomodoro de ${widget.task.title}!\n\nGanhou +25 XP!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onPomodoroComplete(25); // 25 XP por pomodoro
              setState(() {
                _isWorkTime = false;
                _secondsRemaining = breakDuration;
              });
            },
            child: const Text('Iniciar Pausa'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onPomodoroComplete(25);
              Navigator.of(context).pop(); // Voltar para tela principal
            },
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }

  void _showBreakCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⏰ Pausa Completa!'),
        content: const Text('Hora de voltar ao trabalho!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isWorkTime = true;
                _secondsRemaining = workDuration;
              });
            },
            child: const Text('Iniciar Trabalho'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isWorkTime ? '🍅 Pomodoro - Trabalho' : '☕ Pausa'),
        backgroundColor: _isWorkTime ? Colors.red : Colors.green,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isWorkTime 
                ? [Colors.red.shade400, Colors.red.shade800]
                : [Colors.green.shade400, Colors.green.shade800],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.task.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
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
                      color: _isWorkTime ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isRunning ? _pauseTimer : _startTimer,
                    icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                    label: Text(_isRunning ? 'Pausar' : 'Iniciar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _isWorkTime ? Colors.red.shade700 : Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
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
                      '$_completedPomodoros 🍅',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
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
