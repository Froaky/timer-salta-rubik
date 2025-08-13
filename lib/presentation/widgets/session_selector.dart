import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/session.dart';

import '../bloc/session/session_bloc.dart';
import '../bloc/session/session_state.dart';
import '../bloc/session/session_event.dart';
import '../bloc/solve/solve_bloc.dart';
import '../bloc/solve/solve_event.dart';
import '../theme/app_theme.dart';
class SessionSelector extends StatelessWidget {
  const SessionSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, SessionState state) {
        if (state.status == SessionStatus.loading) {
          return const LinearProgressIndicator();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.textMuted.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Current session dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.textMuted.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Session>(
                      value: state.currentSession,
                      hint: Text(
                        'Select a session',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      isExpanded: true,
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textSecondary,
                      ),
                      dropdownColor: AppTheme.cardColor,
                      items: state.sessions.map((session) {
                        return DropdownMenuItem<Session>(
                          value: session,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getCubeIcon(session.cubeType),
                                  size: 18,
                                  color: AppTheme.accentColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      session.name,
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      session.cubeType.toUpperCase(),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (session) {
                        if (session != null) {
                          context.read<SessionBloc>().add(SelectSession(session.id));
                          // Load solves and statistics for the new session
                          context.read<SolveBloc>().add(LoadSolves(sessionId: session.id));
                          context.read<SolveBloc>().add(LoadStatistics(session.id));
                        }
                      },
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Add session button
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add_rounded, size: 20),
                  onPressed: () => _showCreateSessionDialog(context),
                  tooltip: 'Create new session',
                  color: AppTheme.accentColor,
                ),
              ),
              
              // Session menu
              if (state.currentSession != null) ...[
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    color: AppTheme.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditSessionDialog(context, state.currentSession!);
                          break;
                        case 'delete':
                          _showDeleteSessionDialog(context, state.currentSession!);
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
                               size: 18,
                             ),
                             const SizedBox(width: 12),
                             Text(
                               'Edit Session',
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
                               size: 18,
                             ),
                             const SizedBox(width: 12),
                             Text(
                               'Delete Session',
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
            ],
          ),
        );
      },
    );
  }

  IconData _getCubeIcon(String cubeType) {
    switch (cubeType) {
      case '2x2':
        return Icons.crop_square;
      case '3x3':
        return Icons.view_module;
      case '4x4':
        return Icons.grid_4x4;
      case '5x5':
        return Icons.grid_view;
      case 'pyraminx':
        return Icons.change_history;
      case 'megaminx':
        return Icons.hexagon;
      case 'skewb':
        return Icons.diamond;
      default:
        return Icons.view_module;
    }
  }

  void _showCreateSessionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _CreateSessionDialog(),
    );
  }

  void _showEditSessionDialog(BuildContext context, Session session) {
    showDialog(
      context: context,
      builder: (context) => _EditSessionDialog(session: session),
    );
  }

  void _showDeleteSessionDialog(BuildContext context, Session session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Session',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${session.name}"? This will also delete all associated solves.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<SessionBloc>().add(DeleteSessionEvent(session.id));
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              backgroundColor: AppTheme.errorColor.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CreateSessionDialog extends StatefulWidget {
  const _CreateSessionDialog();

  @override
  State<_CreateSessionDialog> createState() => _CreateSessionDialogState();
}

class _CreateSessionDialogState extends State<_CreateSessionDialog> {
  final _nameController = TextEditingController();
  String _selectedCubeType = '3x3';

  final List<String> _cubeTypes = [
    '2x2',
    '3x3',
    '4x4',
    '5x5',
    'pyraminx',
    'megaminx',
    'skewb',
  ];

  @override
  void dispose() {
    _nameController.dispose();
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
        'Create New Session',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Session Name',
              hintText: 'My 3x3 Session',
              labelStyle: TextStyle(color: AppTheme.textSecondary),
              hintStyle: TextStyle(color: AppTheme.textMuted),
            ),
            style: TextStyle(color: AppTheme.textPrimary),
            autofocus: true,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _selectedCubeType,
            decoration: InputDecoration(
              labelText: 'Cube Type',
              labelStyle: TextStyle(color: AppTheme.textSecondary),
            ),
            dropdownColor: AppTheme.cardColor,
            style: TextStyle(color: AppTheme.textPrimary),
            items: _cubeTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(
                  type.toUpperCase(),
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCubeType = value;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isNotEmpty) {
              final session = Session(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                cubeType: _selectedCubeType,
                createdAt: DateTime.now(),
              );
              context.read<SessionBloc>().add(CreateSessionEvent(session));
              Navigator.of(context).pop();
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.accentColor,
            backgroundColor: AppTheme.accentColor.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _EditSessionDialog extends StatefulWidget {
  final Session session;

  const _EditSessionDialog({required this.session});

  @override
  State<_EditSessionDialog> createState() => _EditSessionDialogState();
}

class _EditSessionDialogState extends State<_EditSessionDialog> {
  late TextEditingController _nameController;
  late String _selectedCubeType;

  final List<String> _cubeTypes = [
    '2x2',
    '3x3',
    '4x4',
    '5x5',
    'pyraminx',
    'megaminx',
    'skewb',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.session.name);
    _selectedCubeType = widget.session.cubeType;
  }

  @override
  void dispose() {
    _nameController.dispose();
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
        'Edit Session',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Session Name',
              labelStyle: TextStyle(color: AppTheme.textSecondary),
            ),
            style: TextStyle(color: AppTheme.textPrimary),
            autofocus: true,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _selectedCubeType,
            decoration: InputDecoration(
              labelText: 'Cube Type',
              labelStyle: TextStyle(color: AppTheme.textSecondary),
            ),
            dropdownColor: AppTheme.cardColor,
            style: TextStyle(color: AppTheme.textPrimary),
            items: _cubeTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(
                  type.toUpperCase(),
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCubeType = value;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isNotEmpty) {
              final updatedSession = widget.session.copyWith(
                name: name,
                cubeType: _selectedCubeType,
              );
              context.read<SessionBloc>().add(UpdateSessionEvent(updatedSession));
              Navigator.of(context).pop();
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.accentColor,
            backgroundColor: AppTheme.accentColor.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}