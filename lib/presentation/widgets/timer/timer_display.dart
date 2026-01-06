import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../bloc/timer/timer_state.dart';
import '../common/glass_container.dart';

class TimerDisplay extends StatelessWidget {
  final TimerState timerState;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;

  const TimerDisplay({
    super.key,
    required this.timerState,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isArmed = timerState.status == TimerStatus.armed;
    final isInspection = timerState.status == TimerStatus.inspection;

    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: () => onTapCancel(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            if (isArmed || isInspection)
              BoxShadow(
                color: isInspection
                    ? Colors.orange.withValues(alpha: 0.3)
                    : AppTheme.timerGreen.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: GlassContainer(
          borderRadius: 24,
          color: _getBackgroundColor().withValues(alpha: 0.1),
          borderColor:
              isArmed ? AppTheme.timerGreen.withValues(alpha: 0.5) : null,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: Theme.of(context).textTheme.displayLarge!.copyWith(
                color: _getTextColor(),
                fontSize: _getTimerFontSize(timerState.formattedTime),
                fontWeight: FontWeight.w600,
                letterSpacing: -1,
                shadows: [
                  if (isArmed || isInspection)
                    Shadow(
                      color: isInspection ? Colors.orange : AppTheme.timerGreen,
                      blurRadius: 20,
                    ),
                ],
              ),
              child: Text(timerState.formattedTime),
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (timerState.status == TimerStatus.inspection) {
      return Colors.white;
    }
    return AppTheme.getTimerColor(timerState.color.name);
  }

  Color _getTextColor() {
    return Colors.white;
  }

  double _getTimerFontSize(String timeText) {
    if (timeText == 'RESOLUCIÓN') return 48;
    if (timeText.length <= 5) return 72;
    if (timeText.length <= 8) return 60;
    return 48;
  }
}
