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
      builder: (context, SolveState state) {
        final currentScramble = state.currentScramble;
        if (currentScramble == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.textMuted.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              // Scramble text container with responsive design
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate responsive font size based on screen width
                      double baseFontSize = constraints.maxWidth > 600 ? 20 : 
                                          constraints.maxWidth > 400 ? 18 : 16;
                      
                      // Adjust font size based on scramble length
                      int scrambleLength = currentScramble.notation.length;
                      double fontSizeMultiplier = scrambleLength > 100 ? 0.85 :
                                                 scrambleLength > 80 ? 0.9 :
                                                 scrambleLength > 60 ? 0.95 : 1.0;
                      
                      double finalFontSize = baseFontSize * fontSizeMultiplier;
                      
                      return SingleChildScrollView(
                        child: Center(
                          child: SelectableText(
                            currentScramble.notation,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontFamily: 'RobotoMono',
                              fontSize: finalFontSize,
                              letterSpacing: constraints.maxWidth > 400 ? 1.2 : 0.8,
                              height: 1.5,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Scramble info and actions
              Container(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Move count
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.textMuted.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${currentScramble.moves.length} moves',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                     
                     // Actions
                     Row(
                       children: [
                         // Copy button
                         Container(
                           decoration: BoxDecoration(
                             color: AppTheme.textMuted.withValues(alpha: 0.1),
                             borderRadius: BorderRadius.circular(12),
                           ),
                           child: IconButton(
                             icon: const Icon(Icons.copy_rounded, size: 20),
                             onPressed: () {
                               Clipboard.setData(
                                 ClipboardData(text: currentScramble.notation),
                               );
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(
                                   content: const Text('Scramble copied to clipboard'),
                                   duration: const Duration(seconds: 2),
                                   backgroundColor: AppTheme.cardColor,
                                   behavior: SnackBarBehavior.floating,
                                   shape: RoundedRectangleBorder(
                                     borderRadius: BorderRadius.circular(12),
                                   ),
                                 ),
                               );
                             },
                             tooltip: 'Copy scramble',
                             color: AppTheme.textSecondary,
                           ),
                         ),
                         
                         const SizedBox(width: 8),
                         
                         // Refresh button
                         Container(
                           decoration: BoxDecoration(
                             color: AppTheme.accentColor.withValues(alpha: 0.1),
                             borderRadius: BorderRadius.circular(12),
                           ),
                           child: IconButton(
                             icon: state.isGeneratingScramble
                                 ? SizedBox(
                                     width: 20,
                                     height: 20,
                                     child: CircularProgressIndicator(
                                       strokeWidth: 2,
                                       color: AppTheme.accentColor,
                                     ),
                                   )
                                 : const Icon(Icons.refresh_rounded, size: 20),
                             onPressed: state.isGeneratingScramble
                                 ? null
                                 : () {
                                     context.read<SolveBloc>().add(GenerateNewScramble('3x3'));
                                   },
                             tooltip: 'Generate new scramble',
                             color: AppTheme.accentColor,
                           ),
                         ),
                       ],
                     ),
                   ],
                 ),
               ),
             ],
           ),
         );
      },
    );
  }
}