import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/statistics.dart';
import '../bloc/session/session_bloc.dart';
import '../bloc/session/session_state.dart';
import '../bloc/solve/solve_bloc.dart';
import '../bloc/solve/solve_state.dart';
import '../bloc/solve/solve_event.dart';
import '../theme/app_theme.dart';

class StatisticsPanel extends StatelessWidget {
  const StatisticsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, SessionState sessionState) {
        if (sessionState.currentSession == null) {
          return const Center(
            child: Text('No session selected'),
          );
        }

        return BlocBuilder<SolveBloc, SolveState>(
          builder: (context, SolveState solveState) {
            if (solveState.status == SolveStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final currentSession = sessionState.currentSession;
            if (currentSession == null) {
              return const Center(
                child: Text('No session selected'),
              );
            }

            if (solveState.statistics == null) {
              // Load statistics for current session
              context.read<SolveBloc>().add(
                LoadStatistics(currentSession.id),
              );
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final stats = solveState.statistics!;
            final solveCount = solveState.solves.length;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Session info
                  _buildSessionInfo(context, currentSession.name, solveCount),
                  
                  const SizedBox(height: 24),
                  
                  // Main statistics
                  _buildMainStats(context, stats),
                  
                  const SizedBox(height: 24),
                  
                  // Current averages
                  _buildCurrentAverages(context, stats),
                  
                  const SizedBox(height: 24),
                  
                  // Best times
                  _buildBestTimes(context, stats),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSessionInfo(BuildContext context, String sessionName, int solveCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session: $sessionName',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '$solveCount solves',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStats(BuildContext context, statistics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Best',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                statistics.personalBest != null
                    ? Statistics.formatTime(statistics.personalBest!)
                    : 'N/A',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppTheme.timerGreen,
                  fontFamily: 'RobotoMono',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentAverages(BuildContext context, statistics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Averages',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              context,
              'Mean of 3 (mo3)',
              statistics.meanOf3 != null
                  ? Statistics.formatTime(statistics.meanOf3!)
                  : 'N/A',
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              context,
              'Average of 5 (ao5)',
              statistics.averageOf5 != null
                  ? Statistics.formatTime(statistics.averageOf5!)
                  : 'N/A',
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              context,
              'Average of 12 (ao12)',
              statistics.averageOf12 != null
                  ? Statistics.formatTime(statistics.averageOf12!)
                  : 'N/A',
            ),
            _buildStatRow(
              context,
              'Average of 25 (ao25)',
              statistics.averageOf25 != null
                  ? Statistics.formatTime(statistics.averageOf25!)
                  : 'N/A',
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              context,
              'Average of 100 (ao100)',
              statistics.averageOf100 != null
                  ? Statistics.formatTime(statistics.averageOf100!)
                  : 'N/A',
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              context,
              'Average of 200 (ao200)',
              statistics.averageOf200 != null
                  ? Statistics.formatTime(statistics.averageOf200!)
                  : 'N/A',
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              context,
              'Average of 500 (ao500)',
              statistics.averageOf500 != null
                  ? Statistics.formatTime(statistics.averageOf500!)
                  : 'N/A',
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              context,
              'Average of 1000 (ao1000)',
              statistics.averageOf1000 != null
                  ? Statistics.formatTime(statistics.averageOf1000!)
                  : 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestTimes(BuildContext context, statistics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Best Averages',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              context,
              'Best mo3',
              statistics.bestMeanOf3 != null
                  ? Statistics.formatTime(statistics.bestMeanOf3!)
                  : 'N/A',
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              context,
              'Best ao5',
              statistics.bestAverageOf5 != null
                  ? Statistics.formatTime(statistics.bestAverageOf5!)
                  : 'N/A',
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              context,
              'Best ao12',
              statistics.bestAverageOf12 != null
                  ? Statistics.formatTime(statistics.bestAverageOf12!)
                  : 'N/A',
            ),
            _buildStatRow(
              context,
              'Best ao25',
              statistics.bestAverageOf25 != null
                  ? Statistics.formatTime(statistics.bestAverageOf25!)
                  : 'N/A',
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              context,
              'Best ao100',
              statistics.bestAverageOf100 != null
                  ? Statistics.formatTime(statistics.bestAverageOf100!)
                  : 'N/A',
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              context,
              'Best ao200',
              statistics.bestAverageOf200 != null
                  ? Statistics.formatTime(statistics.bestAverageOf200!)
                  : 'N/A',
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              context,
              'Best ao500',
              statistics.bestAverageOf500 != null
                  ? Statistics.formatTime(statistics.bestAverageOf500!)
                  : 'N/A',
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              context,
              'Best ao1000',
              statistics.bestAverageOf1000 != null
                  ? Statistics.formatTime(statistics.bestAverageOf1000!)
                  : 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontFamily: 'RobotoMono',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}