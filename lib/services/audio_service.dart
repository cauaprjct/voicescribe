import 'dart:async';
import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';

/// Enum para o estado da gravação
enum RecordingState { idle, recording, paused }

/// Serviço responsável pela gravação e reprodução de áudio
class AudioService {
  static final AudioService instance = AudioService._init();

  AudioService._init();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  RecordingState _state = RecordingState.idle;
  String? _currentAudioPath;
  Duration _currentDuration = Duration.zero;
  Timer? _timer;

  // Stream controllers
  final StreamController<RecordingState> _stateController =
      StreamController<RecordingState>.broadcast();
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();
  final StreamController<List<double>> _amplitudeController =
      StreamController<List<double>>.broadcast();

  // Getters dos streams
  Stream<RecordingState> get stateStream => _stateController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<List<double>> get amplitudeStream => _amplitudeController.stream;

  // Getters dos valores atuais
  RecordingState get state => _state;
  Duration get currentDuration => _currentDuration;
  String? get currentAudioPath => _currentAudioPath;

  /// Solicita permissões necessárias
  Future<bool> requestPermissions() async {
    final microphoneStatus = await Permission.microphone.request();
    final storageStatus = await Permission.storage.request();

    return microphoneStatus.isGranted && storageStatus.isGranted;
  }

  /// Verifica se as permissões foram concedidas
  Future<bool> hasPermissions() async {
    final microphoneStatus = await Permission.microphone.status;
    final storageStatus = await Permission.storage.status;

    return microphoneStatus.isGranted && storageStatus.isGranted;
  }

  /// Inicia a gravação
  Future<bool> startRecording({String? language}) async {
    try {
      // Verifica permissões
      final hasPerms = await hasPermissions();
      if (!hasPerms) {
        final granted = await requestPermissions();
        if (!granted) return false;
      }

      // Gera caminho do arquivo
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentAudioPath = '${dir.path}/recording_$timestamp.m4a';

      // Configura e inicia gravação
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      );

      await _recorder.start(config, path: _currentAudioPath!);

      _state = RecordingState.recording;
      _stateController.add(_state);

      // Inicia timer de duração
      _startTimer();

      // Inicia monitoramento de amplitude
      _startAmplitudeMonitoring();

      return true;
    } catch (e) {
      print('Erro ao iniciar gravação: $e');
      return false;
    }
  }

  /// Pausa a gravação
  Future<void> pauseRecording() async {
    if (_state == RecordingState.recording) {
      await _recorder.pause();
      _state = RecordingState.paused;
      _stateController.add(_state);
      _timer?.cancel();
    }
  }

  /// Continua a gravação
  Future<void> resumeRecording() async {
    if (_state == RecordingState.paused) {
      await _recorder.resume();
      _state = RecordingState.recording;
      _stateController.add(_state);
      _startTimer();
      _startAmplitudeMonitoring();
    }
  }

  /// Para a gravação e retorna o caminho do arquivo
  Future<String?> stopRecording() async {
    try {
      _timer?.cancel();

      final path = await _recorder.stop();

      _state = RecordingState.idle;
      _stateController.add(_state);
      _durationController.add(_currentDuration);

      return path ?? _currentAudioPath;
    } catch (e) {
      print('Erro ao parar gravação: $e');
      return _currentAudioPath;
    }
  }

  /// Cancela a gravação (deleta o arquivo)
  Future<void> cancelRecording() async {
    final path = await stopRecording();
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    _currentDuration = Duration.zero;
    _durationController.add(_currentDuration);
  }

  /// Reinicia a gravação
  Future<void> restartRecording({String? language}) async {
    await stopRecording();
    await startRecording(language: language);
  }

  /// Inicia o timer de duração
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentDuration = Duration(seconds: timer.tick);
      _durationController.add(_currentDuration);
    });
  }

  /// Inicia o monitoramento de amplitude
  void _startAmplitudeMonitoring() {
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_state == RecordingState.recording) {
        _recorder.getAmplitude().then((amplitude) {
          _amplitudeController.add([amplitude.current, amplitude.max]);
        });
      }
    });
  }

  // ==================== REPRODUÇÃO ====================

  /// Reproduz um arquivo de áudio
  Future<void> playAudio(String path) async {
    try {
      await _player.setFilePath(path);
      await _player.play();
    } catch (e) {
      print('Erro ao reproduzir áudio: $e');
    }
  }

  /// Pausa a reprodução
  Future<void> pausePlayback() async {
    await _player.pause();
  }

  /// Para a reprodução
  Future<void> stopPlayback() async {
    await _player.stop();
  }

  /// Retorna se o áudio está tocando
  bool get isPlaying => _player.playing;

  /// Stream do estado do player
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Stream da duração do áudio
  Stream<Duration?> get audioDurationStream => _player.durationStream;

  /// Stream da posição atual
  Stream<Duration> get audioPositionStream => _player.positionStream;

  /// Define a posição de reprodução
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Define o volume
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  // ==================== UTILITÁRIOS ====================

  /// Formata a duração para exibição (mm:ss ou HH:mm:ss)
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  /// Limpa recursos
  Future<void> dispose() async {
    _timer?.cancel();
    await _recorder.dispose();
    await _player.dispose();
    await _stateController.close();
    await _durationController.close();
    await _amplitudeController.close();
  }
}
