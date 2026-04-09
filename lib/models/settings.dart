/// Modelo de configurações do aplicativo
class AppSettings {
  final String language;
  final bool autoSave;
  final bool darkMode;
  final String exportFormat;
  final int maxRecordings;
  final bool highQuality;

  AppSettings({
    this.language = 'pt-BR',
    this.autoSave = true,
    this.darkMode = false,
    this.exportFormat = 'txt',
    this.maxRecordings = 100,
    this.highQuality = true,
  });

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      language: map['language'] as String? ?? 'pt-BR',
      autoSave: (map['auto_save'] as int?) == 1,
      darkMode: (map['dark_mode'] as int?) == 1,
      exportFormat: map['export_format'] as String? ?? 'txt',
      maxRecordings: map['max_recordings'] as int? ?? 100,
      highQuality: (map['high_quality'] as int?) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'auto_save': autoSave ? 1 : 0,
      'dark_mode': darkMode ? 1 : 0,
      'export_format': exportFormat,
      'max_recordings': maxRecordings,
      'high_quality': highQuality ? 1 : 0,
    };
  }

  AppSettings copyWith({
    String? language,
    bool? autoSave,
    bool? darkMode,
    String? exportFormat,
    int? maxRecordings,
    bool? highQuality,
  }) {
    return AppSettings(
      language: language ?? this.language,
      autoSave: autoSave ?? this.autoSave,
      darkMode: darkMode ?? this.darkMode,
      exportFormat: exportFormat ?? this.exportFormat,
      maxRecordings: maxRecordings ?? this.maxRecordings,
      highQuality: highQuality ?? this.highQuality,
    );
  }

  /// Lista de idiomas suportados
  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'pt-BR', 'name': 'Português', 'flag': '🇧🇷'},
    {'code': 'en-US', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'es-ES', 'name': 'Español', 'flag': '🇪🇸'},
  ];
}

/// Estatísticas do usuário
class UserStats {
  final int totalRecordings;
  final Duration totalRecordingTime;
  final int totalWords;
  final DateTime firstRecording;
  final DateTime lastRecording;

  UserStats({
    this.totalRecordings = 0,
    this.totalRecordingTime = const Duration(),
    this.totalWords = 0,
    DateTime? firstRecording,
    DateTime? lastRecording,
  }) : firstRecording = firstRecording ?? DateTime.now(),
       this.lastRecording = lastRecording ?? DateTime.now();

  /// Retorna o tempo total formatado
  String get formattedTotalTime {
    final hours = totalRecordingTime.inHours;
    final minutes = totalRecordingTime.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours hora${hours > 1 ? 's' : ''} e $minutes minuto${minutes != 1 ? 's' : ''}';
    }
    return '$minutes minuto${minutes != 1 ? 's' : ''}';
  }

  /// Retorna média de palavras por gravação
  double get avgWordsPerRecording {
    if (totalRecordings == 0) return 0;
    return totalWords / totalRecordings;
  }
}
