import 'package:flutter/material.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/core/data/data_source/health_data_source.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/health_repository.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';

class HealthDebugScreen extends StatefulWidget {
  const HealthDebugScreen({super.key});

  @override
  State<HealthDebugScreen> createState() => _HealthDebugScreenState();
}

class _HealthDebugScreenState extends State<HealthDebugScreen> {
  final _lines = <String>[];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  void _log(String msg) {
    setState(() => _lines.add(msg));
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _loading = true;
      _lines.clear();
    });

    final healthDataSource = locator<HealthDataSource>();
    final healthRepo = locator<HealthRepository>();
    final configRepo = locator<ConfigRepository>();

    // 1. Config flag
    final hasAsked = await configRepo.getHasAskedHealthPermission();
    _log('hasAskedHealthPermission: $hasAsked');

    // 2. hasPermission check
    try {
      final hasPerm = await healthDataSource.hasPermission();
      _log('hasPermission(): $hasPerm');
    } catch (e) {
      _log('hasPermission() ERROR: $e');
    }

    // 3. Try reading active calories
    try {
      final calories = await healthDataSource.getActiveCaloriesToday();
      // This debug screen prints to the screen, not to the log, so it is a
      // calorie-bearing surface like any other.
      _log('getActiveCaloriesToday(): ${Figures.kcal(context, calories) ?? ''}');
    } catch (e) {
      _log('getActiveCaloriesToday() ERROR: $e');
    }

    // 4. Cached values from DB
    try {
      final (cached, updatedAt) = await healthRepo.getCachedActiveCalories();
      _log('Cached active calories: $cached');
      _log('Cached updatedAt: $updatedAt');
    } catch (e) {
      _log('getCachedActiveCalories() ERROR: $e');
    }

    // 5. Exercise multiplier
    final multiplier = await configRepo.getExerciseMultiplier();
    _log('Exercise multiplier: $multiplier');

    // 6. getKcalGoal trace
    try {
      final kcalGoalUsecase = locator<GetKcalGoalUsecase>();
      final goalWithHealth = await kcalGoalUsecase.getKcalGoal();
      final goalNoExercise =
          await kcalGoalUsecase.getKcalGoal(totalKcalActivitiesParam: 0);
      final earned = goalWithHealth - goalNoExercise;
      _log('--- getKcalGoal ---');
      _log('With HealthKit: ${goalWithHealth.toStringAsFixed(1)}');
      _log('No exercise:    ${goalNoExercise.toStringAsFixed(1)}');
      _log('Earned (diff):  ${earned.toStringAsFixed(1)}');
    } catch (e) {
      _log('getKcalGoal() ERROR: $e');
    }

    setState(() => _loading = false);
  }

  Future<void> _requestPermission() async {
    _log('--- Requesting permission ---');
    try {
      final healthDataSource = locator<HealthDataSource>();
      final result = await healthDataSource.requestPermission();
      _log('requestPermission() returned: $result');
    } catch (e) {
      _log('requestPermission() ERROR: $e');
    }
  }

  Future<void> _resetPermissionFlag() async {
    final configRepo = locator<ConfigRepository>();
    await configRepo.setHasAskedHealthPermission(false);
    _log('--- Reset hasAskedHealthPermission to false ---');
  }

  Future<void> _setMultiplier(double value) async {
    final configRepo = locator<ConfigRepository>();
    await configRepo.setExerciseMultiplier(value);
    _log('--- Set exercise multiplier to $value ---');
    _runDiagnostics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HealthKit Debug')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _loading ? null : _runDiagnostics,
                  child: const Text('Refresh'),
                ),
                ElevatedButton(
                  onPressed: _loading ? null : _requestPermission,
                  child: const Text('Request Permission'),
                ),
                ElevatedButton(
                  onPressed: _loading ? null : _resetPermissionFlag,
                  child: const Text('Reset Flag'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                const Text('Multiplier:', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                for (final m in [0.0, 0.5, 0.75, 1.0])
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: OutlinedButton(
                      onPressed: _loading ? null : () => _setMultiplier(m),
                      child: Text('$m'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _lines.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  _lines[i],
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
