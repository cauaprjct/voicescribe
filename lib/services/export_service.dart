import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/transcription.dart';

/// Serviço responsável por exportar transcrições
class ExportService {
  static final ExportService instance = ExportService._init();

  ExportService._init();

  /// Exporta transcrição para TXT
  Future<File> exportToTxt(Transcription transcription) async {
    final content = _buildTxtContent(transcription);
    final fileName = _generateFileName(transcription, 'txt');
    final file = await _saveToFile(content, fileName);
    return file;
  }

  /// Exporta transcrição para PDF
  Future<File> exportToPdf(Transcription transcription) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Título
              pw.Text(
                transcription.title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),

              // Metadados
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetadataBlock('Data', transcription.formattedDate),
                  _buildMetadataBlock(
                    'Duração',
                    transcription.formattedDuration,
                  ),
                  _buildMetadataBlock('Idioma', transcription.languageName),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 16),

              // Texto transcrito
              pw.Text(
                transcription.text,
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Spacer(),

              // Rodapé
              pw.Text(
                'Exportado por VoiceScribe',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
              ),
            ],
          );
        },
      ),
    );

    final fileName = _generateFileName(transcription, 'pdf');
    final file = await _savePdfToFile(pdf, fileName);
    return file;
  }

  /// Constrói o conteúdo TXT
  String _buildTxtContent(Transcription transcription) {
    final buffer = StringBuffer();

    buffer.writeln('=' * 50);
    buffer.writeln('VoiceScribe - Transcrição de Áudio');
    buffer.writeln('=' * 50);
    buffer.writeln();
    buffer.writeln('Título: ${transcription.title}');
    buffer.writeln('Data: ${transcription.formattedDate}');
    buffer.writeln('Duração: ${transcription.formattedDuration}');
    buffer.writeln('Idioma: ${transcription.languageName}');
    buffer.writeln();
    buffer.writeln('-' * 50);
    buffer.writeln();
    buffer.writeln(transcription.text);
    buffer.writeln();
    buffer.writeln('-' * 50);
    buffer.writeln('Exportado por VoiceScribe');

    return buffer.toString();
  }

  /// Cria bloco de metadados para PDF
  pw.Widget _buildMetadataBlock(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  /// Gera nome do arquivo
  String _generateFileName(Transcription transcription, String extension) {
    final date = DateFormat('yyyyMMdd_HHmmss').format(transcription.createdAt);
    return 'VoiceScribe_${transcription.title.replaceAll(' ', '_')}_$date.$extension';
  }

  /// Salva conteúdo em arquivo TXT
  Future<File> _saveToFile(String content, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsString(content);
    return file;
  }

  /// Salva PDF em arquivo
  Future<File> _savePdfToFile(pw.Document pdf, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Compartilha arquivo
  Future<void> shareFile(File file, {String? subject}) async {
    await Share.shareXFiles([
      XFile(file.path),
    ], subject: subject ?? 'Transcrição VoiceScribe');
  }

  /// Compartilha texto diretamente
  Future<void> shareText(String text, {String? subject}) async {
    await Share.share(text, subject: subject ?? 'Transcrição VoiceScribe');
  }

  /// Copia texto para área de transferência
  Future<void> copyToClipboard(String text) async {
    // Será implementado no widget usando Clipboard
    throw UnimplementedError('Use Clipboard.copy(text) no widget');
  }

  /// Exporta múltiplas transcrições para um único PDF
  Future<File> exportMultipleToPdf(List<Transcription> transcriptions) async {
    final pdf = pw.Document();

    for (int i = 0; i < transcriptions.length; i++) {
      final transcription = transcriptions[i];

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  transcription.title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  '${transcription.formattedDate} • ${transcription.formattedDuration}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
                pw.Divider(),
                pw.SizedBox(height: 16),
                pw.Text(
                  transcription.text,
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            );
          },
        ),
      );

      // Adiciona página separadora (exceto na última)
      if (i < transcriptions.length - 1) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Text(
                  '•••',
                  style: pw.TextStyle(fontSize: 24, color: PdfColors.grey),
                ),
              );
            },
          ),
        );
      }
    }

    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'VoiceScribe_Coletânea_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
