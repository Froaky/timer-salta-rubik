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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: EdgeInsets.fromLTRB(
                          isSmallScreen ? 10 : 12,
                          8,
                          isSmallScreen ? 10 : 12,
                          6,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppTheme.textMuted.withValues(alpha: 0.14),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'SCRAMBLE',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.6,
                                    ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withValues(
                                  alpha: 0.14,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                currentScramble.cubeType.toUpperCase(),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppTheme.textAccent,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.7,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 2,
                        margin: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 10 : 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.accentColor.withValues(alpha: 0.0),
                              AppTheme.accentColor.withValues(alpha: 0.95),
                              AppTheme.accentColor.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
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
                    ],
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
        ? 16.5
        : isMediumScreen
            ? 18
            : 19.5;
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
      'clock' || 'sq1' => 0.92,
      _ => 0.95,
    };
    final fontSize = baseFontSize * lengthMultiplier * cubeMultiplier;
    final letterSpacing = isSmallScreen ? 0.25 : 0.5;
    final textStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontFamily: 'RobotoMono',
          fontSize: fontSize,
          letterSpacing: letterSpacing,
          height: 1.3,
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        );

    final padding = EdgeInsets.symmetric(
      horizontal: isSmallScreen ? 12 : 16,
      vertical: isSmallScreen ? 8 : 10,
    );
    final textWidth =
        (maxWidth - padding.horizontal - (isSmallScreen ? 16 : 32))
            .clamp(120.0, 720.0);
    final measuredTextHeight = _measureTextHeight(
      notation,
      textStyle!,
      textWidth,
    );
    final headerHeight = isSmallScreen ? 32.0 : 36.0;
    // Allow the card to size down to a single text line for short scrambles
    // like 2x2 (FIX-019) so it does not leave huge empty space.
    final lineHeight = (textStyle.fontSize ?? 16) * (textStyle.height ?? 1.3);
    final minHeight = (lineHeight + padding.vertical + headerHeight).clamp(
      isSmallScreen ? 64.0 : 72.0,
      isSmallScreen ? 110.0 : 120.0,
    );
    // Slightly taller cap so 6x6/7x7 scrambles get more breathing room before
    // falling back to internal scroll, but never push the timer below usable.
    final maxHeight = switch (cubeType) {
      '6x6' || '7x7' => isSmallScreen ? 188.0 : 220.0,
      _ => isSmallScreen ? 168.0 : 196.0,
    };
    final contentHeight = measuredTextHeight + padding.vertical + headerHeight;
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
