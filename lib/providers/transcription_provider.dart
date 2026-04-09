import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transcription.dart';
import '../models/settings.dart';
import '../services/database_service.dart';
import '../services/audio_service.dart';
import '../services/transcription_service.dart';
import '../services/export_service.dart';

// ==================== PROVIDERS DE SERVIÇO ====================

/// Provider do serviço de banco de dados
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

/// Provider do serviço de áudio
final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService.instance;
});

/// Provider do serviço de transcrição
final transcriptionServiceProvider = Provider<TranscriptionService>((ref) {
  return TranscriptionService.instance;
});

/// Provider do serviço de exportação
final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService.instance;
});

// ==================== PROVIDERS DE ESTADO ====================

/// Provider do estado de gravação
final recordingStateProvider = StreamProvider<RecordingState>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.stateStream;
});

/// Provider da duração da gravação
final recordingDurationProvider = StreamProvider<Duration>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.durationStream;
});

/// Provider da amplitude do áudio
final audioAmplitudeProvider = StreamProvider<List<double>>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.amplitudeStream;
});

// ==================== PROVIDERS DE TRANSCRIÇÃO ====================

/// Provider da lista de transcrições
final transcriptionsProvider = FutureProvider<List<Transcription>>((ref) async {
  final database = ref.watch(databaseServiceProvider);
  return database.getAllTranscriptions();
});

/// Provider de busca de transcrições
class SearchQuery extends StateNotifier<String> {
  SearchQuery() : super('');

  void update(String query) => state = query;
}

final searchQueryProvider = StateNotifierProvider<SearchQuery, String>((ref) {
  return SearchQuery();
});

/// Provider das transcrições filtradas por busca
final filteredTranscriptionsProvider = FutureProvider<List<Transcription>>((
  ref,
) async {
  final database = ref.watch(databaseServiceProvider);
  final query = ref.watch(searchQueryProvider);

  if (query.isEmpty) {
    return database.getAllTranscriptions();
  }
  return database.searchTranscriptions(query);
});

/// Provider de uma transcrição específica
final transcriptionProvider = FutureProvider.family<Transcription?, String>((
  ref,
  id,
) async {
  final database = ref.watch(databaseServiceProvider);
  return database.getTranscriptionById(id);
});

// ==================== PROVIDERS DE CONFIGURAÇÕES ====================

/// Provider das configurações
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  return SettingsNotifier(ref.watch(databaseServiceProvider));
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final DatabaseService _database;

  SettingsNotifier(this._database) : super(AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = await _database.getSettings();
  }

  Future<void> updateLanguage(String language) async {
    state = state.copyWith(language: language);
    await _database.updateSettings(state);
  }

  Future<void> toggleDarkMode() async {
    state = state.copyWith(darkMode: !state.darkMode);
    await _database.updateSettings(state);
  }

  Future<void> updateExportFormat(String format) async {
    state = state.copyWith(exportFormat: format);
    await _database.updateSettings(state);
  }
}

// ==================== PROVIDERS DE ESTATÍSTICAS ====================

/// Provider de estatísticas
final statsProvider = FutureProvider<UserStats>((ref) async {
  final database = ref.watch(databaseServiceProvider);
  return database.getStats();
});

// ==================== PROVIDERS DE AÇÃO ====================

/// Provider para salvar transcrição
final saveTranscriptionProvider = Provider<SaveTranscriptionController>((ref) {
  return SaveTranscriptionController(ref.watch(databaseServiceProvider));
});

class SaveTranscriptionController {
  final DatabaseService _database;

  SaveTranscriptionController(this._database);

  Future<void> call(Transcription transcription) async {
    await _database.insertTranscription(transcription);
  }
}

/// Provider para deletar transcrição
final deleteTranscriptionProvider = Provider<DeleteTranscriptionController>((
  ref,
) {
  return DeleteTranscriptionController(ref.watch(databaseServiceProvider));
});

class DeleteTranscriptionController {
  final DatabaseService _database;

  DeleteTranscriptionController(this._database);

  Future<void> call(String id) async {
    await _database.deleteTranscription(id);
  }
}

/// Provider para alternar favorito
final toggleFavoriteProvider = Provider<ToggleFavoriteController>((ref) {
  return ToggleFavoriteController(ref.watch(databaseServiceProvider));
});

class ToggleFavoriteController {
  final DatabaseService _database;

  ToggleFavoriteController(this._database);

  Future<void> call(String id, bool isFavorite) async {
    await _database.toggleFavorite(id, isFavorite);
  }
}

// ==================== PROVIDER DE TRANSCRIÇÃO EM ANDAMENTO ====================

/// Estado da transcrição em andamento
class TranscriptionState {
  final bool isLoading;
  final String? error;
  final TranscriptionResult? result;
  final double progress;

  TranscriptionState({
    this.isLoading = false,
    this.error,
    this.result,
    this.progress = 0,
  });

  TranscriptionState copyWith({
    bool? isLoading,
    String? error,
    TranscriptionResult? result,
    double? progress,
  }) {
    return TranscriptionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      result: result ?? this.result,
      progress: progress ?? this.progress,
    );
  }
}

class TranscriptionNotifier extends StateNotifier<TranscriptionState> {
  final TranscriptionService _transcriptionService;

  TranscriptionNotifier(this._transcriptionService)
    : super(TranscriptionState());

  Future<TranscriptionResult?> transcribe({
    required String audioPath,
    String language = 'pt-BR',
  }) async {
    state = state.copyWith(isLoading: true, error: null, progress: 0);

    try {
      // Simula progresso
      _simulateProgress();

      final result = await _transcriptionService.transcribe(
        audioPath: audioPath,
        language: language,
      );

      state = state.copyWith(isLoading: false, result: result, progress: 1);

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void _simulateProgress() {
    // Simulação simples de progresso
    Future.delayed(const Duration(milliseconds: 100), () {
      if (state.isLoading) {
        state = state.copyWith(progress: 0.3);
      }
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (state.isLoading) {
        state = state.copyWith(progress: 0.6);
      }
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (state.isLoading) {
        state = state.copyWith(progress: 0.9);
      }
    });
  }

  void reset() {
    state = TranscriptionState();
  }
}

final transcriptionProcessProvider =
    StateNotifierProvider<TranscriptionNotifier, TranscriptionState>((ref) {
      return TranscriptionNotifier(ref.watch(transcriptionServiceProvider));
    });
