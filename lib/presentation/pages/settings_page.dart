import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/timer/timer_bloc.dart';
import '../bloc/timer/timer_event.dart';
import '../bloc/timer/timer_state.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_centered.dart';

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
          return ResponsiveCentered(
            maxWidth: 620,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: ListView(
              children: [
                Text(
                  'Preferencias del timer',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Se guardan automáticamente en este dispositivo.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 24),
                _SettingsSection(
                  title: 'Cronómetro',
                  children: [
                    _SettingSwitch(
                      icon: Icons.hourglass_bottom_rounded,
                      title: 'Inspección',
                      subtitle:
                          '15 segundos de cuenta regresiva antes de iniciar.',
                      value: state.inspectionEnabled,
                      onChanged: (_) => context
                          .read<TimerBloc>()
                          .add(const TimerToggleInspection()),
                    ),
                    _SettingSwitch(
                      icon: Icons.touch_app_rounded,
                      title: 'Inicio rápido',
                      subtitle:
                          'Inicia con un solo toque, sin mantener presionado.',
                      value: state.tapToStartEnabled,
                      onChanged: (_) => context
                          .read<TimerBloc>()
                          .add(const TimerToggleTapToStart()),
                    ),
                    _SettingSwitch(
                      icon: Icons.visibility_off_rounded,
                      title: 'Ocultar timer',
                      subtitle: 'Muestra "RESOLUCIÓN" en lugar del tiempo.',
                      value: state.hideTimerEnabled,
                      onChanged: (_) => context
                          .read<TimerBloc>()
                          .add(const TimerToggleHideTimer()),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SettingsSection(
                  title: 'Competencia',
                  children: [
                    _SettingSwitch(
                      icon: Icons.emoji_events_rounded,
                      title: 'Modo competir',
                      subtitle:
                          'Restringe el acceso al historial durante una resolución.',
                      value: state.competeMode,
                      onChanged: (_) => context
                          .read<TimerBloc>()
                          .add(const TimerToggleCompeteMode()),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.textMuted.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 64,
                    color: AppTheme.textMuted.withValues(alpha: 0.12),
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: value
                    ? AppTheme.accentColor.withValues(alpha: 0.16)
                    : AppTheme.textMuted.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: value ? AppTheme.textAccent : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.accentColor,
            ),
          ],
        ),
      ),
    );
  }
}
