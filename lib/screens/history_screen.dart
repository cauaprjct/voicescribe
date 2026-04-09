import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../config/theme.dart';
import '../widgets/common_widgets.dart';
import '../providers/transcription_provider.dart';
import '../models/transcription.dart';
import 'transcription_result_screen.dart';

/// Tela de histórico de transcrições
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Confirma e deleta todas as transcrições
  Future<void> _clearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar histórico'),
        content: const Text(
          'Esta ação irá excluir permanentemente todas as transcrições e seus arquivos de áudio. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Limpar tudo'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Deletar todas as transcrições e arquivos
      final transcriptionsAsync = await ref.read(transcriptionsProvider.future);

      for (final transcription in transcriptionsAsync) {
        final delete = ref.read(deleteTranscriptionProvider);
        await delete(transcription.id);

        // Deleta arquivo de áudio
        final audioFile = File(transcription.audioPath);
        if (await audioFile.exists()) {
          await audioFile.delete();
        }
      }

      if (mounted) {
        ref.refresh(transcriptionsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Histórico limpo com sucesso'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTranscriptionsAsync = ref.watch(
      filteredTranscriptionsProvider,
    );
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          if (_searchQuery.isEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAllHistory,
              tooltip: 'Limpar histórico',
            ),
        ],
      ),
      body: Column(
        children: [
          // Estatísticas rápidas
          SizedBox(
            height: 120,
            child: statsAsync.when(
              data: (stats) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  children: [
                    StatCard(
                      icon: Icons.mic,
                      label: 'Gravações',
                      value: stats.totalRecordings.toString(),
                    ),
                    const SizedBox(width: 12),
                    StatCard(
                      icon: Icons.timer,
                      label: 'Tempo Total',
                      value: stats.formattedTotalTime,
                    ),
                    const SizedBox(width: 12),
                    StatCard(
                      icon: Icons.text_fields,
                      label: 'Palavras',
                      value: stats.totalWords >= 1000
                          ? '${(stats.totalWords / 1000).toStringAsFixed(1)}k'
                          : stats.totalWords.toString(),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          const Divider(),

          // Barra de busca
          CustomSearchBar(
            query: _searchQuery,
            onChanged: (query) {
              setState(() => _searchQuery = query);
              ref.read(searchQueryProvider.notifier).update(query);
            },
            onClear: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
              ref.read(searchQueryProvider.notifier).update('');
            },
          ),

          // Lista de transcrições
          Expanded(
            child: filteredTranscriptionsAsync.when(
              data: (transcriptions) {
                if (transcriptions.isEmpty) {
                  return EmptyState(
                    icon: _searchQuery.isEmpty
                        ? Icons.history
                        : Icons.search_off,
                    title: _searchQuery.isEmpty
                        ? 'Nenhuma transcrição'
                        : 'Nenhum resultado encontrado',
                    subtitle: _searchQuery.isEmpty
                        ? 'Suas transcrições aparecerão aqui'
                        : 'Tente buscar com outros termos',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(filteredTranscriptionsProvider.future),
                  child: ListView.builder(
                    itemCount: transcriptions.length,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemBuilder: (context, index) {
                      final transcription = transcriptions[index];

                      return Dismissible(
                        key: Key(transcription.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          color: AppColors.error,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Excluir transcrição'),
                              content: const Text(
                                'Deseja excluir esta transcrição permanentemente?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                  ),
                                  child: const Text('Excluir'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) async {
                          final delete = ref.read(deleteTranscriptionProvider);
                          await delete(transcription.id);

                          // Deleta arquivo de áudio
                          final audioFile = File(transcription.audioPath);
                          if (await audioFile.exists()) {
                            await audioFile.delete();
                          }

                          ref.refresh(filteredTranscriptionsProvider);
                          ref.refresh(transcriptionsProvider);
                          ref.refresh(statsProvider);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Transcrição excluída'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                        child: TranscriptionCard(
                          title: transcription.title,
                          textPreview: transcription.textPreview,
                          duration: transcription.formattedDuration,
                          date: transcription.formattedDate,
                          isFavorite: transcription.isFavorite,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TranscriptionResultScreen(
                                  transcription: transcription,
                                ),
                              ),
                            );
                          },
                          onFavoriteToggle: () {
                            final toggle = ref.read(toggleFavoriteProvider);
                            toggle(transcription.id, !transcription.isFavorite);
                            ref.refresh(filteredTranscriptionsProvider);
                            ref.refresh(transcriptionsProvider);
                          },
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () =>
                  const LoadingIndicator(message: 'Carregando histórico...'),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text('Erro ao carregar: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.refresh(filteredTranscriptionsProvider);
                      },
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
