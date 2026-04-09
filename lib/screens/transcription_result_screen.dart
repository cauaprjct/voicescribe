import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../config/theme.dart';
import '../widgets/common_widgets.dart';
import '../models/transcription.dart';
import '../providers/transcription_provider.dart';
import '../services/export_service.dart';

/// Tela de resultado da transcrição
class TranscriptionResultScreen extends ConsumerStatefulWidget {
  final Transcription transcription;

  const TranscriptionResultScreen({Key? key, required this.transcription})
    : super(key: key);

  @override
  ConsumerState<TranscriptionResultScreen> createState() =>
      _TranscriptionResultScreenState();
}

class _TranscriptionResultScreenState
    extends ConsumerState<TranscriptionResultScreen> {
  late TextEditingController _textController;
  late Transcription _transcription;
  bool _isEditing = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _transcription = widget.transcription;
    _textController = TextEditingController(text: _transcription.text);
    _isFavorite = _transcription.isFavorite;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Salva as edições
  Future<void> _saveEdits() async {
    final newText = _textController.text.trim();

    if (newText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O texto não pode estar vazio'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final updated = _transcription.copyWith(text: newText);
    final save = ref.read(saveTranscriptionProvider);
    await save(updated);

    setState(() {
      _transcription = updated;
      _isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alterações salvas'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  /// Copia texto para área de transferência
  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _transcription.text));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Texto copiado para a área de transferência'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  /// Compartilha texto
  Future<void> _shareText() async {
    final exportService = ref.read(exportServiceProvider);
    await exportService.shareText(
      _transcription.text,
      subject: 'Transcrição: ${_transcription.title}',
    );
  }

  /// Exporta para arquivo
  Future<void> _exportFile(String format) async {
    final exportService = ref.read(exportServiceProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Exportando...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      File file;
      if (format == 'pdf') {
        file = await exportService.exportToPdf(_transcription);
      } else {
        file = await exportService.exportToTxt(_transcription);
      }

      if (mounted) {
        Navigator.pop(context); // Fecha diálogo

        // Oferece opções de compartilhar
        final action = await showModalBottomSheet<String>(
          context: context,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Compartilhar arquivo'),
                  onTap: () => Navigator.pop(context, 'share'),
                ),
                ListTile(
                  leading: const Icon(Icons.check),
                  title: const Text('Concluído'),
                  onTap: () => Navigator.pop(context, 'done'),
                ),
              ],
            ),
          ),
        );

        if (action == 'share' && mounted) {
          await exportService.shareFile(file);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Alterna favorito
  Future<void> _toggleFavorite() async {
    final toggle = ref.read(toggleFavoriteProvider);
    final newFavorite = !_isFavorite;

    await toggle(_transcription.id, newFavorite);

    setState(() {
      _isFavorite = newFavorite;
      _transcription = _transcription.copyWith(isFavorite: newFavorite);
    });
  }

  /// Confirma e deleta transcrição
  Future<void> _deleteTranscription() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir transcrição'),
        content: const Text(
          'Esta ação não pode ser desfeita. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final delete = ref.read(deleteTranscriptionProvider);
      await delete(_transcription.id);

      // Deleta arquivo de áudio
      final audioFile = File(_transcription.audioPath);
      if (await audioFile.exists()) {
        await audioFile.delete();
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transcrição excluída'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transcrição'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? AppColors.accent : null,
            ),
            onPressed: _toggleFavorite,
            tooltip: 'Favoritar',
          ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveEdits,
              tooltip: 'Salvar',
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Editar',
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'copy':
                  _copyToClipboard();
                  break;
                case 'share':
                  _shareText();
                  break;
                case 'export_txt':
                  _exportFile('txt');
                  break;
                case 'export_pdf':
                  _exportFile('pdf');
                  break;
                case 'delete':
                  _deleteTranscription();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy, size: 20),
                    SizedBox(width: 12),
                    Text('Copiar texto'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 12),
                    Text('Compartilhar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_txt',
                child: Row(
                  children: [
                    Icon(Icons.description, size: 20),
                    SizedBox(width: 12),
                    Text('Exportar como TXT'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 20),
                    SizedBox(width: 12),
                    Text('Exportar como PDF'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: AppColors.error, size: 20),
                    SizedBox(width: 12),
                    Text('Excluir', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Header com informações
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Título editável
                if (_isEditing)
                  TextField(
                    controller: TextEditingController(
                      text: _transcription.title,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        setState(() {
                          _transcription = _transcription.copyWith(
                            title: value.trim(),
                          );
                        });
                      }
                    },
                  )
                else
                  Text(
                    _transcription.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 12),

                // Metadados
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetadataItem(
                      Icons.schedule,
                      _transcription.formattedDuration,
                    ),
                    _buildMetadataItem(
                      Icons.calendar_today,
                      _transcription.formattedDate.split(' ')[0],
                    ),
                    _buildMetadataItem(
                      Icons.language,
                      _transcription.languageName,
                    ),
                  ],
                ),

                // Keywords
                if (_transcription.keywords.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _transcription.keywords.map((keyword) {
                      return Chip(
                        label: Text(
                          keyword,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          // Texto transcrito
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _isEditing
                  ? TextField(
                      controller: _textController,
                      maxLines: null,
                      minLines: 10,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Texto da transcrição...',
                      ),
                      style: const TextStyle(fontSize: 16),
                    )
                  : SelectableText(
                      _transcription.text,
                      style: const TextStyle(fontSize: 16, height: 1.6),
                    ),
            ),
          ),

          // Barra de ações rápida
          if (!_isEditing)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _copyToClipboard,
                        icon: const Icon(Icons.copy),
                        label: const Text('Copiar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _shareText,
                        icon: const Icon(Icons.share),
                        label: const Text('Compartilhar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetadataItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
