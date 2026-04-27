import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../theme/app_theme.dart';
import '../../bloc/timer/timer_state.dart';

class TimerDisplay extends StatefulWidget {
  final TimerState timerState;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;
  final ValueChanged<int>? onDisplayedElapsedChanged;
  final int? frozenElapsedMs;
  final Widget? previewOverlay;
  final double previewOverlayBottomOffset;
  final bool immersiveMode;

  const TimerDisplay({
    super.key,
    required this.timerState,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
    this.onDisplayedElapsedChanged,
    this.frozenElapsedMs,
    this.previewOverlay,
    this.previewOverlayBottomOffset = 18,
    this.immersiveMode = false,
  });

  @override
  State<TimerDisplay> createState() => _TimerDisplayState();
}

class _TimerDisplayState extends State<TimerDisplay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  int _liveElapsedMs = 0;
  int? _lastReportedElapsedMs;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      final nextElapsedMs = _computeLiveElapsedMs();
      if (nextElapsedMs != _liveElapsedMs && mounted) {
        setState(() {
          _liveElapsedMs = nextElapsedMs;
        });
      }
      _reportDisplayedElapsed(nextElapsedMs);
    });
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant TimerDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timerState.status != widget.timerState.status ||
        oldWidget.timerState.startTime != widget.timerState.startTime ||
        oldWidget.timerState.elapsedMs != widget.timerState.elapsedMs ||
        oldWidget.frozenElapsedMs != widget.frozenElapsedMs) {
      _syncTicker();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayState = _displayState;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: _getBackgroundColor(displayState),
        borderRadius: BorderRadius.circular(widget.immersiveMode ? 0 : 24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: widget.immersiveMode ? 0 : 20,
            offset: Offset(0, widget.immersiveMode ? 0 : 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => widget.onTapDown(),
              onPointerUp: (_) => widget.onTapUp(),
              onPointerCancel: (_) => widget.onTapCancel(),
              child: const SizedBox.expand(),
            ),
          ),
          IgnorePointer(
            child: Center(
              child: Text(
                displayState.formattedTime,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: _getTextColor(displayState),
                      fontSize: _getTimerFontSize(
                        displayState.formattedTime,
                        immersiveMode: widget.immersiveMode,
                      ),
                      fontWeight: FontWeight.w300,
                    ),
              ),
            ),
          ),
          if (widget.previewOverlay != null)
            Positioned(
              right: 18,
              bottom: widget.previewOverlayBottomOffset,
              child: widget.previewOverlay!,
            ),
        ],
      ),
    );
  }

  void _syncTicker() {
    _liveElapsedMs = _computeLiveElapsedMs();
    _reportDisplayedElapsed(_displayState.elapsedMs);

    if (_shouldUseLiveElapsed) {
      if (!_ticker.isActive) {
        _ticker.start();
      }
      return;
    }

    if (_ticker.isActive) {
      _ticker.stop();
    }
  }

  void _reportDisplayedElapsed(int elapsedMs) {
    if (_lastReportedElapsedMs == elapsedMs) {
      return;
    }
    _lastReportedElapsedMs = elapsedMs;
    widget.onDisplayedElapsedChanged?.call(elapsedMs);
  }

  bool get _shouldUseLiveElapsed =>
      widget.frozenElapsedMs == null &&
      widget.timerState.status == TimerStatus.running &&
      widget.timerState.startTime != null;

  int _computeLiveElapsedMs() {
    final startTime = widget.timerState.startTime;
    if (!_shouldUseLiveElapsed || startTime == null) {
      return widget.timerState.elapsedMs;
    }

    return math.max(
      widget.timerState.elapsedMs,
      DateTime.now().difference(startTime).inMilliseconds,
    );
  }

  TimerState get _displayState {
    if (widget.frozenElapsedMs != null) {
      return widget.timerState.copyWith(elapsedMs: widget.frozenElapsedMs);
    }

    if (!_shouldUseLiveElapsed) {
      return widget.timerState;
    }

    final displayElapsedMs = _computeLiveElapsedMs();
    return widget.timerState.copyWith(elapsedMs: displayElapsedMs);
  }

  Color _getBackgroundColor(TimerState displayState) {
    if (displayState.status == TimerStatus.inspection) {
      return Colors.white;
    }
    return AppTheme.getTimerColor(displayState.color.name);
  }

  Color _getTextColor(TimerState displayState) {
    if (displayState.status == TimerStatus.inspection) {
      return Colors.orange;
    }
    return displayState.color == TimerColor.white ? Colors.black : Colors.white;
  }

  double _getTimerFontSize(String timeText, {required bool immersiveMode}) {
    if (timeText == 'RESOLUCIÓN') return 48;
    if (timeText.length <= 5) return immersiveMode ? 92 : 72;
    if (timeText.length <= 8) return immersiveMode ? 76 : 60;
    return immersiveMode ? 60 : 48;
  }
}
