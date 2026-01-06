import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/timer/timer_bloc.dart';
import '../bloc/timer/timer_event.dart';
import '../bloc/timer/timer_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common/glass_container.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<TimerBloc, TimerState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              GlassContainer(
                child: Column(
                  children: [
                    SwitchListTile(
                      activeColor: AppTheme.accentColor,
                      title: const Text('Inspección'),
                      subtitle: const Text(
                          '15 segundos de cuenta regresiva antes de iniciar'),
                      value: state.inspectionEnabled,
                      onChanged: (value) {
                        context
                            .read<TimerBloc>()
                            .add(const TimerToggleInspection());
                      },
                    ),
                    Divider(
                        color: AppTheme.textMuted.withValues(alpha: 0.1),
                        height: 1),
                    SwitchListTile(
                      activeColor: AppTheme.accentColor,
                      title: const Text('Ocultar timer'),
                      subtitle: const Text(
                          'Mostrar "RESOLUCIÓN" en lugar del tiempo'),
                      value: state.hideTimerEnabled,
                      onChanged: (value) {
                        context
                            .read<TimerBloc>()
                            .add(const TimerToggleHideTimer());
                      },
                    ),
                    Divider(
                        color: AppTheme.textMuted.withValues(alpha: 0.1),
                        height: 1),
                    SwitchListTile(
                      activeColor: AppTheme.accentColor,
                      title: const Text('Modo competir'),
                      subtitle: const Text(
                          'Restringir acceso al historial durante resolución'),
                      value: state.competeMode,
                      onChanged: (value) {
                        context
                            .read<TimerBloc>()
                            .add(const TimerToggleCompeteMode());
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
