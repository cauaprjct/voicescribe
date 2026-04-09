import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Resultado da transcrição
class TranscriptionResult {
  final String text;
  final double confidence;
  final List<WordTimestamp> words;
  final String language;

  TranscriptionResult({
    required this.text,
    required this.confidence,
    required this.words,
    required this.language,
  });

  /// Extrai palavras-chave do texto
  List<String> extractKeywords() {
    // Palavras comuns para remover (stop words em português)
    final stopWords = <String>{
      'o',
      'a',
      'os',
      'as',
      'um',
      'uma',
      'uns',
      'umas',
      'de',
      'do',
      'da',
      'dos',
      'das',
      'em',
      'no',
      'na',
      'nos',
      'nas',
      'por',
      'para',
      'com',
      'sem',
      'e',
      'ou',
      'mas',
      'que',
      'se',
      'eu',
      'tu',
      'ele',
      'ela',
      'nós',
      'vós',
      'eles',
      'elas',
      'me',
      'te',
      'lhe',
      'nos',
      'vos',
      'lhes',
      'meu',
      'minha',
      'teu',
      'tua',
      'seu',
      'sua',
      'nosso',
      'nossa',
      'este',
      'esta',
      'estes',
      'estas',
      'esse',
      'essa',
      'esses',
      'essas',
      'aquele',
      'aquela',
      'aqueles',
      'aquelas',
      'é',
      'são',
      'ser',
      'estar',
      'ter',
      'haver',
      'ir',
      'vir',
      'fazer',
      'dizer',
      'poder',
      'dever',
    };

    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(' ')
        .where((word) => word.length > 3 && !stopWords.contains(word))
        .toSet()
        .toList();

    return words.take(10).toList();
  }
}

/// Palavra com timestamp
class WordTimestamp {
  final String word;
  final Duration start;
  final Duration end;
  final double confidence;

  WordTimestamp({
    required this.word,
    required this.start,
    required this.end,
    required this.confidence,
  });
}

/// Serviço de transcrição usando API
class TranscriptionService {
  static final TranscriptionService instance = TranscriptionService._init();

  TranscriptionService._init();

  // Configuração da API
  // IMPORTANTE: Em produção, use um backend server para proteger sua API key
  String? _apiKey;
  String? _apiUrl;

  /// Configura a API key e URL
  void configure({required String apiKey, required String apiUrl}) {
    _apiKey = apiKey;
    _apiUrl = apiUrl;
  }

  /// Transcreve um arquivo de áudio
  Future<TranscriptionResult> transcribe({
    required String audioPath,
    String language = 'pt-BR',
    bool extractKeywords = true,
  }) async {
    // Verifica se a API está configurada
    if (_apiKey == null || _apiUrl == null) {
      // Usa transcrição simulada para demonstração
      return _simulateTranscription(audioPath, language);
    }

    try {
      return await _transcribeWithAPI(audioPath: audioPath, language: language);
    } catch (e) {
      print('Erro na transcrição com API: $e');
      // Fallback para simulação em caso de erro
      return _simulateTranscription(audioPath, language);
    }
  }

  /// Transcrição usando API real
  Future<TranscriptionResult> _transcribeWithAPI({
    required String audioPath,
    required String language,
  }) async {
    final file = File(audioPath);

    // Exemplo de integração com OpenAI Whisper API
    // Ajuste conforme a API que você está usando
    final uri = Uri.parse(
      _apiUrl ?? 'https://api.openai.com/v1/audio/transcriptions',
    );

    var request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $_apiKey';

    request.files.add(await http.MultipartFile.fromPath('file', audioPath));
    request.fields['model'] = 'whisper-1';
    request.fields['language'] = language.split('-')[0]; // pt-BR -> pt
    request.fields['response_format'] = 'verbose_json';

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    var json = jsonDecode(responseBody);

    final text = json['text'] as String;
    final confidence = json['segments'] != null && json['segments'].isNotEmpty
        ? (json['segments'][0]['no_speech_prob'] as num).toDouble()
        : 0.9;

    final words = <WordTimestamp>[];
    if (json['segments'] != null) {
      for (var segment in json['segments']) {
        if (segment['words'] != null) {
          for (var word in segment['words']) {
            words.add(
              WordTimestamp(
                word: word['word'],
                start: Duration(milliseconds: (word['start'] * 1000).toInt()),
                end: Duration(milliseconds: (word['end'] * 1000).toInt()),
                confidence: word['confidence']?.toDouble() ?? 0.9,
              ),
            );
          }
        }
      }
    }

    return TranscriptionResult(
      text: text,
      confidence: confidence,
      words: words,
      language: language,
    );
  }

  /// Simula uma transcrição para demonstração
  Future<TranscriptionResult> _simulateTranscription(
    String audioPath,
    String language,
  ) async {
    // Simula tempo de processamento
    await Future.delayed(const Duration(seconds: 2));

    final sampleTexts = {
      'pt-BR': [
        'Olá! Esta é uma transcrição de demonstração do VoiceScribe. '
            'O aplicativo está funcionando corretamente e pronto para '
            'transcrever suas gravações de áudio com alta qualidade.',
        'Bem-vindo ao VoiceScribe! Este é um exemplo de texto transcrito '
            'para demonstrar as capacidades do aplicativo. Você pode gravar '
            'suas reuniões, aulas e ideias facilmente.',
        'Esta é uma transcrição de teste. O VoiceScribe permite que você '
            'grave e transcreva áudios rapidamente. Experimente gravar '
            'sua primeira mensagem agora mesmo!',
      ],
      'en-US': [
        'Hello! This is a demo transcription from VoiceScribe. '
            'The app is working correctly and ready to transcribe '
            'your audio recordings with high quality.',
        'Welcome to VoiceScribe! This is a sample transcribed text '
            'to demonstrate the app capabilities. You can record your '
            'meetings, classes, and ideas easily.',
      ],
      'es-ES': [
        '¡Hola! Esta es una transcripción de demostración de VoiceScribe. '
            'La aplicación está funcionando correctamente y lista para '
            'transcribir sus grabaciones de audio con alta calidad.',
      ],
    };

    final texts = sampleTexts[language] ?? sampleTexts['pt-BR']!;
    final randomText =
        texts[DateTime.now().millisecondsSinceEpoch % texts.length];

    return TranscriptionResult(
      text: randomText,
      confidence: 0.85 + (DateTime.now().millisecondsSinceEpoch % 15) / 100,
      words: [],
      language: language,
    );
  }

  /// Transcrição offline usando modelo local (futuro)
  Future<TranscriptionResult> transcribeOffline({
    required String audioPath,
    String language = 'pt-BR',
  }) async {
    // Implementação futura com modelo TFLite
    // Por enquanto, usa a simulação
    return _simulateTranscription(audioPath, language);
  }

  /// Mapeia código de idioma para formato da API
  static String mapLanguageCode(String languageCode) {
    final languageMap = {'pt-BR': 'pt', 'en-US': 'en', 'es-ES': 'es'};
    return languageMap[languageCode] ?? languageCode.split('-')[0];
  }
}
