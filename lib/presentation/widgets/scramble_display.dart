import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/solve/solve_bloc.dart';
import '../bloc/solve/solve_state.dart';
import '../bloc/solve/solve_event.dart';
import '../theme/app_theme.dart';

class ScrambleDisplay extends StatelessWidget {
  const ScrambleDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SolveBloc, SolveState>(
      builder: (context, state) {
        final currentScramble = state.currentScramble;
        if (currentScramble == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return LayoutBuilder(
          builder: (context, screenConstraints) {
            bool isSmallScreen = screenConstraints.maxWidth < 400;
            bool isMediumScreen = screenConstraints.maxWidth < 600;
            
            return Container(
              margin: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 16, 
                vertical: isSmallScreen ? 8 : 12
              ),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                border: Border.all(
                  color: AppTheme.textMuted.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: isSmallScreen ? 12 : 20,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(
                      isSmallScreen ? 16 : 24
                    ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Calculate responsive font size based on screen width - increased sizes
                          double baseFontSize = isSmallScreen ? 18 :
                                                isMediumScreen ? 22 : 26;
                          
                          // Adjust font size based on scramble length
                          int scrambleLength = currentScramble.notation.length;
                          double fontSizeMultiplier = scrambleLength > 100 ? 0.85 :
                                                     scrambleLength > 80 ? 0.9 :
                                                     scrambleLength > 60 ? 0.95 : 1.0;
                          
                          double finalFontSize = baseFontSize * fontSizeMultiplier;
                          
                          return SingleChildScrollView(
                            child: Center(
                              child: GestureDetector(
                                onTap: () {
                                  // Copy scramble to clipboard when tapped
                                  Clipboard.setData(
                                    ClipboardData(text: currentScramble.notation),
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
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontFamily: 'RobotoMono',
                                    fontSize: finalFontSize,
                                    letterSpacing: isSmallScreen ? 0.5 : 
                                                  isMediumScreen ? 0.8 : 1.2,
                                    height: isSmallScreen ? 1.4 : 1.5,
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ),
            );
          },
        );
      },
    );
  }
}