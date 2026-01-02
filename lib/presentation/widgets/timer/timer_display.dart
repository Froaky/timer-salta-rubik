import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../bloc/timer/timer_state.dart';

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
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: () => onTapCancel(),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            timerState.formattedTime,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: _getTextColor(),
                  fontSize: _getTimerFontSize(timerState.formattedTime),
                  fontWeight: FontWeight.w300,
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
    if (timerState.status == TimerStatus.inspection) {
      return Colors.orange;
    }
    return timerState.color == TimerColor.white ? Colors.black : Colors.white;
  }

  double _getTimerFontSize(String timeText) {
    if (timeText == 'RESOLUCIÓN') return 48;
    if (timeText.length <= 5) return 72;
    if (timeText.length <= 8) return 60;
    return 48;
  }
}
