import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/session.dart';
import '../../domain/entities/solve.dart';

import '../bloc/session/session_bloc.dart';
import '../bloc/session/session_state.dart';
import '../bloc/solve/solve_bloc.dart';
import '../bloc/solve/solve_state.dart';
import '../bloc/solve/solve_event.dart';
import '../theme/app_theme.dart';

enum SortOption {
  timeAsc,
  timeDesc,
  dateAsc,
  dateDesc,
}

class SolveList extends StatefulWidget {
  const SolveList({super.key});

  @override
  State<SolveList> createState() => _SolveListState();
}

class _SolveListState extends State<SolveList> {
  SortOption _currentSort = SortOption.dateDesc;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, SessionState sessionState) {
        if (sessionState.currentSession == null) {
          return const Center(
            child: Text('No session selected'),
          );
        }

        return BlocBuilder<SolveBloc, SolveState>(
          builder: (context, SolveState solveState) {
            if (solveState.status == SolveStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final currentSession = sessionState.currentSession;
            if (currentSession == null) {
              return const Center(
                child: Text('No session selected'),
              );
            }

            if (solveState.solves.isEmpty) {
              // Cargar solo si el estado todavía no corresponde a esta
              // sesión: si la sesión ya cargó vacía, re-despachar en cada
              // build genera un loop infinito loading→empty→loading.
              if (solveState.sessionId != currentSession.id) {
                context.read<SolveBloc>().add(
                      LoadSolves(sessionId: currentSession.id),
                    );
              }
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No solves yet'),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => _showAddDialog(
                        context,
                        currentSession,
                        solveState.currentScramble?.notation,
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add time manually'),
                    ),
                  ],
                ),
              );
            }

            // Ordenar solves según la opción seleccionada
            final sortedSolves = _sortSolves(solveState.solves);

            return Column(
              children: [
                // Header
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.textMuted.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.history_rounded,
                          color: AppTheme.accentColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Solves',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            '${solveState.solves.length} total',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Add manual time button
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add_rounded, size: 20),
                          onPressed: () {
                            _showAddDialog(
                              context,
                              currentSession,
                              solveState.currentScramble?.notation,
                            );
                          },
                          tooltip: 'Add solve manually',
                          color: AppTheme.accentColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Sort button
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.textMuted.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: PopupMenuButton<SortOption>(
                          icon: const Icon(Icons.sort_rounded, size: 20),
                          tooltip: 'Sort solves',
                          color: AppTheme.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (option) {
                            setState(() {
                              _currentSort = option;
                            });
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: SortOption.dateDesc,
                              child: Row(
                                children: [
                                  Icon(Icons.schedule, size: 16),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Date (newest first)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: SortOption.dateAsc,
                              child: Row(
                                children: [
                                  Icon(Icons.schedule, size: 16),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Date (oldest first)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: SortOption.timeAsc,
                              child: Row(
                                children: [
                                  Icon(Icons.timer, size: 16),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Time (fastest first)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: SortOption.timeDesc,
                              child: Row(
                                children: [
                                  Icon(Icons.timer, size: 16),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Time (slowest first)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon:
                              const Icon(Icons.delete_sweep_rounded, size: 20),
                          onPressed: () {
                            _showDeleteAllDialog(
                              context,
                              currentSession.id,
                              solveState.solves.length,
                            );
                          },
                          tooltip: 'Delete all solves in session',
                          color: AppTheme.errorColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.textMuted.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                          onPressed: () {
                            context.read<SolveBloc>().add(
                                  LoadSolves(sessionId: currentSession.id),
                                );
                          },
                          tooltip: 'Refresh solves',
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: sortedSolves.length,
                    itemBuilder: (context, index) {
                      final solve = sortedSolves[index];
                      final isLatest =
                          _currentSort == SortOption.dateDesc && index == 0;

                      return _buildSolveItem(
                        context,
                        solve,
                        index + 1,
                        isLatest,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSolveItem(
      BuildContext context, Solve solve, int number, bool isLatest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLatest
            ? AppTheme.accentColor.withOpacity(0.05)
            : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLatest
              ? AppTheme.accentColor.withOpacity(0.2)
              : AppTheme.textMuted.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Number badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getPenaltyColor(solve.penalty).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getPenaltyColor(solve.penalty).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: TextStyle(
                  color: _getPenaltyColor(solve.penalty),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time and penalty
                Row(
                  children: [
                    Text(
                      _buildTimeDisplay(solve),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontFamily: 'RobotoMono',
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                          ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Scramble
                Text(
                  solve.scramble,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'RobotoMono',
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                // Time ago
                Text(
                  _formatDateTime(solve.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),

          // Menu button
          Container(
            decoration: BoxDecoration(
              color: AppTheme.textMuted.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: AppTheme.textSecondary,
                size: 18,
              ),
              color: AppTheme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditDialog(context, solve);
                    break;
                  case 'delete':
                    _showDeleteDialog(context, solve);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        color: AppTheme.textSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Edit',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_rounded,
                        color: AppTheme.errorColor,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Delete',
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPenaltyColor(Penalty penalty) {
    switch (penalty) {
      case Penalty.none:
        return AppTheme.accentColor;
      case Penalty.plus2:
        return AppTheme.timerYellow;
      case Penalty.dnf:
        return AppTheme.timerRed;
    }
  }

  String _getPenaltyText(Penalty penalty) {
    switch (penalty) {
      case Penalty.none:
        return '';
      case Penalty.plus2:
        return '+2';
      case Penalty.dnf:
        return 'DNF';
    }
  }

  String _buildTimeDisplay(Solve solve) {
    // Para +2, mostrar: tiempo original +2 (tiempo final)
    if (solve.penalty == Penalty.plus2) {
      final original = _formatMs(solve.timeMs);
      final effective = _formatMs(solve.effectiveTimeMs);
      return '$original +2';
    }
    // Para DNF, mostrar DNF
    if (solve.penalty == Penalty.dnf) {
      return 'DNF';
    }
    // Sin penalización: mostrar tiempo normal
    return _formatMs(solve.timeMs);
  }

  String _formatMs(int milliseconds) {
    if (milliseconds < 0) return 'DNF';
    final seconds = milliseconds / 1000;
    if (seconds >= 60) {
      final minutes = (seconds / 60).floor();
      final remainingSeconds = seconds % 60;
      return '$minutes:${remainingSeconds.toStringAsFixed(2).padLeft(5, '0')}';
    } else {
      return seconds.toStringAsFixed(2);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  List<Solve> _sortSolves(List<Solve> solves) {
    final sorted = List<Solve>.from(solves);

    switch (_currentSort) {
      case SortOption.timeAsc:
        sorted.sort((a, b) {
          // Primero ordenar por DNF (DNF va al final)
          if (a.isDnf && !b.isDnf) return 1;
          if (!a.isDnf && b.isDnf) return -1;
          if (a.isDnf && b.isDnf) return 0;
          // Luego por tiempo efectivo
          return a.effectiveTimeMs.compareTo(b.effectiveTimeMs);
        });
        break;
      case SortOption.timeDesc:
        sorted.sort((a, b) {
          // Primero ordenar por DNF (DNF va al principio)
          if (a.isDnf && !b.isDnf) return -1;
          if (!a.isDnf && b.isDnf) return 1;
          if (a.isDnf && b.isDnf) return 0;
          // Luego por tiempo efectivo descendente
          return b.effectiveTimeMs.compareTo(a.effectiveTimeMs);
        });
        break;
      case SortOption.dateAsc:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOption.dateDesc:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return sorted;
  }

  void _showEditDialog(BuildContext context, Solve solve) {
    showDialog(
      context: context,
      builder: (context) => _EditSolveDialog(solve: solve),
    );
  }

  void _showAddDialog(
    BuildContext context,
    Session session,
    String? scrambleNotation,
  ) {
    final solveBloc = context.read<SolveBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: solveBloc,
        child: _AddSolveDialog(
          session: session,
          scrambleNotation: scrambleNotation,
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Solve solve) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Solve',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this solve (${solve.formattedTime})?',
          style: TextStyle(
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () {
                context.read<SolveBloc>().add(DeleteSolveEvent(solve.id));
                Navigator.of(context).pop();
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog(
      BuildContext context, String sessionId, int solveCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Session Solves',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Delete all $solveCount solves from this session? This cannot be undone.',
          style: TextStyle(
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () {
                context.read<SolveBloc>().add(
                      DeleteSessionSolvesEvent(sessionId),
                    );
                Navigator.of(context).pop();
              },
              child: Text(
                'Delete all',
                style: TextStyle(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditSolveDialog extends StatefulWidget {
  final Solve solve;

  const _EditSolveDialog({required this.solve});

  @override
  State<_EditSolveDialog> createState() => _EditSolveDialogState();
}

class _EditSolveDialogState extends State<_EditSolveDialog> {
  late Penalty _selectedPenalty;
  late TextEditingController _timeController;

  @override
  void initState() {
    super.initState();
    _selectedPenalty = widget.solve.penalty;
    _timeController = TextEditingController(
      text: (widget.solve.timeMs / 1000).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Edit Solve',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _timeController,
            decoration: InputDecoration(
              labelText: 'Time (seconds)',
              hintText: '12.34',
              labelStyle: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              hintStyle: TextStyle(
                color: AppTheme.textMuted,
              ),
            ),
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontFamily: 'RobotoMono',
              fontWeight: FontWeight.w500,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Penalty>(
            value: _selectedPenalty,
            decoration: InputDecoration(
              labelText: 'Penalty',
              labelStyle: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            dropdownColor: AppTheme.cardColor,
            items: Penalty.values.map((penalty) {
              return DropdownMenuItem(
                value: penalty,
                child: Text(
                  _getPenaltyDisplayName(penalty),
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
            onChanged: (penalty) {
              if (penalty != null) {
                setState(() {
                  _selectedPenalty = penalty;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextButton(
            onPressed: () {
              final timeSeconds = double.tryParse(_timeController.text);
              if (timeSeconds != null && timeSeconds > 0) {
                final updatedSolve = widget.solve.copyWith(
                  timeMs: (timeSeconds * 1000).round(),
                  penalty: _selectedPenalty,
                );
                context.read<SolveBloc>().add(UpdateSolveEvent(updatedSolve));
                Navigator.of(context).pop();
              }
            },
            child: Text(
              'Save',
              style: TextStyle(
                color: AppTheme.accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getPenaltyDisplayName(Penalty penalty) {
    switch (penalty) {
      case Penalty.none:
        return 'No penalty';
      case Penalty.plus2:
        return '+2 seconds';
      case Penalty.dnf:
        return 'DNF (Did Not Finish)';
    }
  }
}

/// Convierte la entrada manual de tiempo a milisegundos.
///
/// Acepta segundos (`12.34`) o minutos:segundos (`1:23.45`). Devuelve null si
/// el texto no es un tiempo válido mayor a cero.
int? parseManualTimeMs(String input) {
  final trimmed = input.trim().replaceAll(',', '.');
  if (trimmed.isEmpty) {
    return null;
  }

  final parts = trimmed.split(':');
  if (parts.length > 2) {
    return null;
  }

  // Solo dígitos con decimal opcional: rechaza signos, exponentes ('1e3'),
  // 'Infinity' y demás formas que double.tryParse aceptaría.
  final secondsText = parts.last;
  if (!RegExp(r'^(\d+(\.\d+)?|\.\d+)$').hasMatch(secondsText)) {
    return null;
  }
  final seconds = double.parse(secondsText);

  var totalMs = (seconds * 1000).round();
  if (parts.length == 2) {
    if (!RegExp(r'^\d+$').hasMatch(parts.first) || seconds >= 60) {
      return null;
    }
    totalMs += int.parse(parts.first) * 60000;
  }

  return totalMs > 0 ? totalMs : null;
}

class _AddSolveDialog extends StatefulWidget {
  final Session session;
  final String? scrambleNotation;

  const _AddSolveDialog({required this.session, this.scrambleNotation});

  @override
  State<_AddSolveDialog> createState() => _AddSolveDialogState();
}

class _AddSolveDialogState extends State<_AddSolveDialog> {
  final TextEditingController _timeController = TextEditingController();
  Penalty _selectedPenalty = Penalty.none;
  String? _errorText;

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  void _submit() {
    final timeMs = parseManualTimeMs(_timeController.text);
    if (timeMs == null) {
      setState(() {
        _errorText = 'Enter a valid time, e.g. 12.34 or 1:23.45';
      });
      return;
    }

    final solve = Solve(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: widget.session.id,
      timeMs: timeMs,
      penalty: _selectedPenalty,
      scramble: widget.scrambleNotation ?? '',
      cubeType: widget.session.cubeType,
      lane: 0,
      createdAt: DateTime.now(),
    );
    context.read<SolveBloc>().add(AddSolveEvent(solve));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Add Solve',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _timeController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Time',
              hintText: '12.34 or 1:23.45',
              errorText: _errorText,
              labelStyle: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              hintStyle: TextStyle(
                color: AppTheme.textMuted,
              ),
            ),
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontFamily: 'RobotoMono',
              fontWeight: FontWeight.w500,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Penalty>(
            value: _selectedPenalty,
            decoration: InputDecoration(
              labelText: 'Penalty',
              labelStyle: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            dropdownColor: AppTheme.cardColor,
            items: Penalty.values.map((penalty) {
              return DropdownMenuItem(
                value: penalty,
                child: Text(
                  _penaltyDisplayName(penalty),
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
            onChanged: (penalty) {
              if (penalty != null) {
                setState(() {
                  _selectedPenalty = penalty;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextButton(
            onPressed: _submit,
            child: Text(
              'Add',
              style: TextStyle(
                color: AppTheme.accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _penaltyDisplayName(Penalty penalty) {
    switch (penalty) {
      case Penalty.none:
        return 'No penalty';
      case Penalty.plus2:
        return '+2 seconds';
      case Penalty.dnf:
        return 'DNF (Did Not Finish)';
    }
  }
}
