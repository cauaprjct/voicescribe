import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../config/theme.dart';
import '../widgets/common_widgets.dart';
import '../providers/transcription_provider.dart';
import '../services/audio_service.dart';
import '../models/transcription.dart';
import 'transcription_result_screen.dart';

/// Tela de gravação de áudio com design moderno
class RecordingScreen extends ConsumerStatefulWidget {
  const RecordingScreen({super.key});

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen> with SingleTickerProviderStateMixin {
  RecordingState _recordingState = RecordingState.idle;
  Duration _duration = Duration.zero;
  List<double> _amplitudes = [];
  
  final _uuid = const Uuid();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _startRecording();
  }

  /// Inicia a gravação
  Future<void> _startRecording() async {
    final audioService = ref.read(audioServiceProvider);
    final settings = ref.read(settingsProvider.notifier).state;
    
    final success = await audioService.startRecording(language: settings.language);
    
    if (success && mounted) {
      // Escuta streams
      audioService.stateStream.listen((state) {
        if (mounted) setState(() => _recordingState = state);
      });
      
      audioService.durationStream.listen((duration) {
        if (mounted) setState(() => _duration = duration);
      });
      
      audioService.amplitudeStream.listen((amplitudes) {
        if (mounted) setState(() => _amplitudes = amplitudes);
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível acessar o microfone'),
          backgroundColor: AppColors.error,
        ),
      );
      Navigator.pop(context);
    }
  }

  /// Pausa/continua a gravação
  Future<void> _togglePause() async {
    final audioService = ref.read(audioServiceProvider);
    
    if (_recordingState == RecordingState.recording) {
      await audioService.pauseRecording();
    } else if (_recordingState == RecordingState.paused) {
      await audioService.resumeRecording();
    }
  }

  /// Para a gravação e inicia transcrição
  Future<void> _stopAndTranscribe() async {
    final audioService = ref.read(audioServiceProvider);
    final path = await audioService.stopRecording();
    
    if (path != null && mounted) {
      // Mostra indicador de processamento
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 24),
                Text(
                  'Transcrevendo áudio...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Isso pode levar alguns segundos',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      
      // Inicia transcrição
      final transcriptionNotifier = ref.read(transcriptionProcessProvider.notifier);
      final settings = ref.read(settingsProvider.notifier).state;
      final result = await transcriptionNotifier.transcribe(
        audioPath: path,
        language: settings.language,
      );
      
      if (mounted) {
        Navigator.pop(context); // Fecha diálogo
        
        if (result != null) {
          // Cria transcrição
          final transcription = Transcription(
            id: _uuid.v4(),
            title: 'Gravação ${DateTime.now().toString().substring(0, 16)}',
            text: result.text,
            audioPath: path,
            createdAt: DateTime.now(),
            duration: _duration,
            language: settings.language,
            keywords: result.extractKeywords(),
          );
          
          // Salva no banco
          final save = ref.read(saveTranscriptionProvider);
          await save(transcription);
          
          // Navega para tela de resultado
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TranscriptionResultScreen(
                  transcription: transcription,
                ),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro na transcrição'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  /// Cancela a gravação
  Future<void> _cancelRecording() async {
    final audioService = ref.read(audioServiceProvider);
    await audioService.cancelRecording();
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // Confirma antes de sair
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Cancelar gravação?'),
            content: const Text('A gravação será perdida.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Continuar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        );
        
        if (shouldExit == true && mounted) {
          await _cancelRecording();
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _recordingState == RecordingState.paused
                    ? AppColors.warning.withValues(alpha: 0.1)
                    : AppColors.accent.withValues(alpha: 0.1),
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _cancelRecording,
                        ),
                      ),
                      const Spacer(),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _recordingState == RecordingState.paused
                              ? AppColors.warning
                              : AppColors.accent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (_recordingState == RecordingState.paused
                                      ? AppColors.warning
                                      : AppColors.accent)
                                  .withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(
                                      alpha: 0.5 + (_pulseController.value * 0.5),
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _recordingState == RecordingState.paused
                                  ? 'PAUSADO'
                                  : 'GRAVANDO',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Timer grande
                TimerDisplay(
                  duration: _duration,
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w200,
                    color: _recordingState == RecordingState.paused
                        ? AppColors.warning
                        : AppColors.accent,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: 4,
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Visualização de ondas de áudio
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: AudioWaveform(
                    amplitudes: _amplitudes,
                    color: _recordingState == RecordingState.paused
                        ? AppColors.warning
                        : AppColors.accent,
                    height: 120,
                  ),
                ),
                
                const Spacer(),
                
                // Controles modernos
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Botão cancelar
                      _buildControlButton(
                        icon: Icons.close,
                        label: 'Cancelar',
                        onPressed: _cancelRecording,
                        color: Colors.grey[400]!,
                        size: 64,
                      ),
                      
                      // Botão pausar/continuar
                      _buildControlButton(
                        icon: _recordingState == RecordingState.paused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        label: _recordingState == RecordingState.paused
                            ? 'Continuar'
                            : 'Pausar',
                        onPressed: _togglePause,
                        color: AppColors.warning,
                        size: 72,
                      ),
                      
                      // Botão parar e transcrever
                      _buildControlButton(
                        icon: Icons.check_rounded,
                        label: 'Concluir',
                        onPressed: _stopAndTranscribe,
                        color: AppColors.success,
                        size: 64,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
    required double size,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: Icon(
                icon,
                color: Colors.white,
                size: size * 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    // Garante que a gravação é parada ao sair
    if (_recordingState != RecordingState.idle) {
      ref.read(audioServiceProvider).stopRecording();
    }
    super.dispose();
  }
}
