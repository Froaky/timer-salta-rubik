import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/solve/solve_bloc.dart';
import '../bloc/solve/solve_state.dart';
import '../theme/app_theme.dart';

class ScrambleDisplay extends StatelessWidget {
  const ScrambleDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SolveBloc, SolveState>(
      builder: (context, state) {
        final currentScramble = state.currentScramble;
        if (currentScramble == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SizedBox(
              height: 72,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, screenConstraints) {
            final isSmallScreen = screenConstraints.maxWidth < 400;
            final isMediumScreen = screenConstraints.maxWidth < 600;
            final metrics = _buildMetrics(
              context,
              currentScramble.notation,
              currentScramble.cubeType,
              screenConstraints.maxWidth,
              isSmallScreen: isSmallScreen,
              isMediumScreen: isMediumScreen,
            );

            return Container(
              key: const ValueKey('main-scramble-card'),
              margin: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 16,
                vertical: isSmallScreen ? 6 : 10,
              ),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
                border: Border.all(
                  color: AppTheme.textMuted.withValues(alpha: 0.18),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: isSmallScreen ? 12 : 16,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: double.infinity,
                height: metrics.targetHeight,
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 9 : 10),
                    border: Border.all(
                      color: AppTheme.textMuted.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Padding(
                    padding: metrics.padding,
                    child: SingleChildScrollView(
                      physics: metrics.needsScroll
                          ? const ClampingScrollPhysics()
                          : const NeverScrollableScrollPhysics(),
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(
                                text: currentScramble.notation,
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Scramble copiado!'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: AppTheme.cardColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                          child: SelectableText(
                            currentScramble.notation,
                            key: const ValueKey('main-scramble-text'),
                            style: metrics.textStyle,
                            textAlign: TextAlign.center,
                            minLines: 1,
                            maxLines: null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  _ScrambleDisplayMetrics _buildMetrics(
    BuildContext context,
    String notation,
    String cubeType,
    double maxWidth, {
    required bool isSmallScreen,
    required bool isMediumScreen,
  }) {
    final baseFontSize = isSmallScreen
        ? 17.5
        : isMediumScreen
            ? 19.0
            : 21.0;
    final lengthMultiplier = notation.length > 200
        ? 0.7
        : notation.length > 140
            ? 0.78
            : notation.length > 110
                ? 0.84
                : notation.length > 80
                    ? 0.9
                    : notation.length > 55
                        ? 0.95
                        : 1.0;
    final cubeMultiplier = switch (cubeType) {
      '2x2' => 0.9,
      '3x3' || '3x3oh' || '3x3bf' || '3x3fm' => 1.0,
      '4x4' || '444bf' => 0.92,
      '5x5' || '555bf' => 0.88,
      '6x6' => 0.84,
      '7x7' => 0.8,
      'clock' || 'sq1' || 'pyraminx' => 0.95,
      _ => 1.0,
    };
    final fontSize = baseFontSize * lengthMultiplier * cubeMultiplier;
    final letterSpacing = isSmallScreen ? 0.2 : 0.4;
    final textStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontFamily: 'monospace', // Generic fallback to ensure consistency
          fontSize: fontSize,
          letterSpacing: letterSpacing,
          height: 1.35,
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        );

    final padding = EdgeInsets.symmetric(
      horizontal: isSmallScreen ? 14 : 18,
      vertical: isSmallScreen ? 14 : 18,
    );
    final textWidth =
        (maxWidth - padding.horizontal - (isSmallScreen ? 20 : 36))
            .clamp(100.0, 1000.0);
    final measuredTextHeight = _measureTextHeight(
      notation,
      textStyle!,
      textWidth,
    );

    const headerHeight = 0.0;
    final minHeight = isSmallScreen ? 74.0 : 84.0;

    // Significantly increased maxHeight to allow more lines to be visible
    // without scrolling on mobile (FIX-020).
    final maxHeight = switch (cubeType) {
      '6x6' || '7x7' || 'megaminx' => isSmallScreen ? 240.0 : 300.0,
      _ => isSmallScreen ? 200.0 : 240.0,
    };

    // Add a larger buffer (12px) to the measured height to prevent any clipping
    // due to line-height or font rendering differences.
    final contentHeight = measuredTextHeight + padding.vertical + 12.0;
    final targetHeight = contentHeight.clamp(minHeight, maxHeight);

    return _ScrambleDisplayMetrics(
      targetHeight: targetHeight,
      padding: padding,
      textStyle: textStyle,
      needsScroll: contentHeight > maxHeight,
    );
  }

  double _measureTextHeight(
    String text,
    TextStyle style,
    double maxWidth,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: null,
    )..layout(maxWidth: maxWidth);

    return painter.size.height;
  }
}

class _ScrambleDisplayMetrics {
  final double targetHeight;
  final EdgeInsets padding;
  final TextStyle textStyle;
  final bool needsScroll;

  const _ScrambleDisplayMetrics({
    required this.targetHeight,
    required this.padding,
    required this.textStyle,
    required this.needsScroll,
  });
}
