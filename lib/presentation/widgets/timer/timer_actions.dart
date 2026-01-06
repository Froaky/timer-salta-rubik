import 'package:flutter/material.dart';
import '../../bloc/timer/timer_state.dart';
import '../common/glass_container.dart';

class TimerActions extends StatelessWidget {
  final TimerStatus status;
  final bool isGeneratingScramble;
  final VoidCallback onReset;
  final VoidCallback onScramble;

  const TimerActions({
    super.key,
    required this.status,
    required this.isGeneratingScramble,
    required this.onReset,
    required this.onScramble,
  });

  @override
  Widget build(BuildContext context) {
    if (status == TimerStatus.running) return const SizedBox.shrink();

    return Stack(
      children: [
        // Reset button - top left
        Positioned(
          top: 20,
          left: 20,
          child: _ActionButton(
            onPressed: onReset,
            icon: Icons.refresh_rounded,
            label: 'Reset',
          ),
        ),

        // New scramble button - top right
        Positioned(
          top: 20,
          right: 20,
          child: _ActionButton(
            onPressed:
                (status == TimerStatus.idle || status == TimerStatus.stopped)
                    ? onScramble
                    : null,
            icon: Icons.shuffle_rounded,
            label: 'Scramble',
            isLoading: isGeneratingScramble,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool isLoading;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;

    return GlassContainer(
      borderRadius: 16,
      blur: 8,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isEnabled ? 1.0 : 0.4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 18,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
