import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transcription.dart';
import '../models/settings.dart';

/// Serviço de banco de dados SQLite
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  /// Obtém a instância do banco de dados
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('voicescribe.db');
    return _database!;
  }

  /// Inicializa o banco de dados
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  /// Cria as tabelas do banco de dados
  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    // Tabela de transcrições
    await db.execute('''
      CREATE TABLE transcriptions (
        id $idType,
        title $textType,
        text $textType,
        audio_path $textType,
        created_at $textType,
        duration $intType,
        language TEXT DEFAULT 'pt-BR',
        keywords TEXT DEFAULT '',
        is_favorite $intType DEFAULT 0
      )
    ''');

    // Tabela de configurações
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        language TEXT DEFAULT 'pt-BR',
        auto_save $intType DEFAULT 1,
        dark_mode $intType DEFAULT 0,
        export_format TEXT DEFAULT 'txt',
        max_recordings $intType DEFAULT 100,
        high_quality $intType DEFAULT 1
      )
    ''');

    // Insere configurações padrão
    await db.insert('settings', {
      'language': 'pt-BR',
      'auto_save': 1,
      'dark_mode': 0,
      'export_format': 'txt',
      'max_recordings': 100,
      'high_quality': 1,
    });
  }

  // ==================== TRANSCRIÇÕES ====================

  /// Insere uma nova transcrição
  Future<void> insertTranscription(Transcription transcription) async {
    final db = await database;
    await db.insert(
      'transcriptions',
      transcription.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtém todas as transcrições ordenadas por data
  Future<List<Transcription>> getAllTranscriptions() async {
    final db = await database;
    final result = await db.query(
      'transcriptions',
      orderBy: 'created_at DESC',
    );
    return result.map((map) => Transcription.fromMap(map)).toList();
  }

  /// Busca transcrições por palavra-chave
  Future<List<Transcription>> searchTranscriptions(String query) async {
    final db = await database;
    final result = await db.query(
      'transcriptions',
      where: 'title LIKE ? OR text LIKE ? OR keywords LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => Transcription.fromMap(map)).toList();
  }

  /// Obtém uma transcrição pelo ID
  Future<Transcription?> getTranscriptionById(String id) async {
    final db = await database;
    final result = await db.query(
      'transcriptions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Transcription.fromMap(result.first);
    }
    return null;
  }

  /// Atualiza uma transcrição
  Future<void> updateTranscription(Transcription transcription) async {
    final db = await database;
    await db.update(
      'transcriptions',
      transcription.toMap(),
      where: 'id = ?',
      whereArgs: [transcription.id],
    );
  }

  /// Deleta uma transcrição
  Future<void> deleteTranscription(String id) async {
    final db = await database;
    await db.delete(
      'transcriptions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Alterna o status de favorito
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    final db = await database;
    await db.update(
      'transcriptions',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obtém estatísticas das transcrições
  Future<UserStats> getStats() async {
    final db = await database;
    final transcriptions = await getAllTranscriptions();

    if (transcriptions.isEmpty) {
      return UserStats(
        firstRecording: DateTime.now(),
        lastRecording: DateTime.now(),
      );
    }

    final totalRecordings = transcriptions.length;
    final totalRecordingTime = transcriptions.fold<Duration>(
      Duration.zero,
      (prev, t) => prev + t.duration,
    );
    final totalWords = transcriptions.fold<int>(
      0,
      (prev, t) => prev + t.text.split(' ').length,
    );
    final firstRecording = transcriptions.last.createdAt;
    final lastRecording = transcriptions.first.createdAt;

    return UserStats(
      totalRecordings: totalRecordings,
      totalRecordingTime: totalRecordingTime,
      totalWords: totalWords,
      firstRecording: firstRecording,
      lastRecording: lastRecording,
    );
  }

  /// Deleta todas as transcrições
  Future<void> deleteAllTranscriptions() async {
    final db = await database;
    await db.delete('transcriptions');
  }

  // ==================== CONFIGURAÇÕES ====================

  /// Obtém as configurações atuais
  Future<AppSettings> getSettings() async {
    final db = await database;
    final result = await db.query('settings', limit: 1);
    if (result.isNotEmpty) {
      return AppSettings.fromMap(result.first);
    }
    return AppSettings();
  }

  /// Atualiza as configurações
  Future<void> updateSettings(AppSettings settings) async {
    final db = await database;
    await db.update(
      'settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  /// Fecha o banco de dados
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
