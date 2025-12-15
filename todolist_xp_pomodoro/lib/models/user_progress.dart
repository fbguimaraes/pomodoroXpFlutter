class UserProgress {
  final int totalXp;
  final int level;
  final int xpForNextLevel;

  UserProgress({
    this.totalXp = 0,
    this.level = 1,
  }) : xpForNextLevel = _calculateXpForLevel(level);

  // Calcular XP necessário para o próximo nível
  static int _calculateXpForLevel(int level) {
    return level * 100; // Cada nível requer 100 XP a mais
  }

  // Adicionar XP e calcular novo nível
  UserProgress addXp(int xp) {
    int newTotalXp = totalXp + xp;
    int newLevel = level;
    
    // Verificar se subiu de nível
    while (newTotalXp >= _calculateXpForLevel(newLevel)) {
      newTotalXp -= _calculateXpForLevel(newLevel);
      newLevel++;
    }
    
    return UserProgress(
      totalXp: newTotalXp,
      level: newLevel,
    );
  }

  // Progresso atual em porcentagem
  double get progressPercentage {
    return totalXp / xpForNextLevel;
  }

  // Converter para Map
  Map<String, dynamic> toMap() {
    return {
      'totalXp': totalXp,
      'level': level,
    };
  }

  // Criar a partir de Map
  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      totalXp: map['totalXp'] ?? 0,
      level: map['level'] ?? 1,
    );
  }
}
