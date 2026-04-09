/// Modelo representando uma transcrição de áudio
class Transcription {
  final String id;
  final String title;
  final String text;
  final String audioPath;
  final DateTime createdAt;
  final Duration duration;
  final String language;
  final List<String> keywords;
  final bool isFavorite;

  Transcription({
    required this.id,
    required this.title,
    required this.text,
    required this.audioPath,
    required this.createdAt,
    required this.duration,
    this.language = 'pt-BR',
    this.keywords = const [],
    this.isFavorite = false,
  });

  /// Cria uma transcrição a partir de um Map (banco de dados)
  factory Transcription.fromMap(Map<String, dynamic> map) {
    return Transcription(
      id: map['id'] as String,
      title: map['title'] as String,
      text: map['text'] as String,
      audioPath: map['audio_path'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      duration: Duration(seconds: map['duration'] as int),
      language: map['language'] as String? ?? 'pt-BR',
      keywords: map['keywords'] != null 
          ? List<String>.from((map['keywords'] as String).split(','))
          : [],
      isFavorite: map['is_favorite'] as int == 1,
    );
  }

  /// Converte a transcrição para um Map (banco de dados)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'text': text,
      'audio_path': audioPath,
      'created_at': createdAt.toIso8601String(),
      'duration': duration.inSeconds,
      'language': language,
      'keywords': keywords.join(','),
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  /// Retorna uma cópia com campos atualizados
  Transcription copyWith({
    String? id,
    String? title,
    String? text,
    String? audioPath,
    DateTime? createdAt,
    Duration? duration,
    String? language,
    List<String>? keywords,
    bool? isFavorite,
  }) {
    return Transcription(
      id: id ?? this.id,
      title: title ?? this.title,
      text: text ?? this.text,
      audioPath: audioPath ?? this.audioPath,
      createdAt: createdAt ?? this.createdAt,
      duration: duration ?? this.duration,
      language: language ?? this.language,
      keywords: keywords ?? this.keywords,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Retorna um preview do texto (primeiras 100 caracteres)
  String get textPreview {
    if (text.length <= 100) return text;
    return '${text.substring(0, 100)}...';
  }

  /// Retorna a duração formatada (mm:ss)
  String get formattedDuration {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Retorna a data formatada
  String get formattedDate {
    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    final year = createdAt.year;
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  /// Retorna o nome do idioma formatado
  String get languageName {
    switch (language) {
      case 'pt-BR':
        return 'Português';
      case 'en-US':
        return 'English';
      case 'es-ES':
        return 'Español';
      default:
        return language;
    }
  }
}
