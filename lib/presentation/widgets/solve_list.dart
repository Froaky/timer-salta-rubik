import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/solve.dart';

import '../bloc/session/session_bloc.dart';
import '../bloc/session/session_state.dart';
import '../bloc/solve/solve_bloc.dart';
import '../bloc/solve/solve_state.dart';
import '../bloc/solve/solve_event.dart';
import '../theme/app_theme.dart';

class SolveList extends StatelessWidget {
  const SolveList({super.key});

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
              // Load solves for current session
              context.read<SolveBloc>().add(
                LoadSolves(sessionId: currentSession.id),
              );
              return const Center(
                child: Text('No solves yet'),
              );
            }

            return Column(
              children: [
                // Header
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${solveState.solves.length} total',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
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
                    itemCount: solveState.solves.length,
                    itemBuilder: (context, index) {
                      final solve = solveState.solves[index];
                      final isLatest = index == 0;
                      
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

  Widget _buildSolveItem(BuildContext context, Solve solve, int number, bool isLatest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLatest ? AppTheme.accentColor.withOpacity(0.05) : AppTheme.cardColor,
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
    // For +2, show: original +2 (effective)
    if (solve.penalty == Penalty.plus2) {
      final original = _formatMs(solve.timeMs);
      final effective = _formatMs(solve.effectiveTimeMs);
      return '$original +2 ($effective)';
    }
    // For DNF, just show DNF
    if (solve.penalty == Penalty.dnf) {
      return 'DNF';
    }
    // No penalty: show normal formatted time
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

  void _showEditDialog(BuildContext context, Solve solve) {
    showDialog(
      context: context,
      builder: (context) => _EditSolveDialog(solve: solve),
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