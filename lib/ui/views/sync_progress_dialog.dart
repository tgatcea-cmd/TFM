import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';
import '../styles.dart';

class SyncProgressDialog extends ConsumerWidget {
  const SyncProgressDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SyncProgressDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectionSyncProgressProvider);

    // Auto-dismiss dialog if sync completed successfully (after the delay) and stage goes back to idle
    if (state.stage == SyncStage.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
    }

    final isFinished = state.stage == SyncStage.completed || state.stage == SyncStage.failed;

    return PopScope(
      canPop: isFinished,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !isFinished) {
          ref.read(connectionSyncProgressProvider.notifier).submitBypassDecision(false);
                    
          if (state.stage == SyncStage.connecting || state.stage == SyncStage.pairing) {
            ref.read(bleServiceProvider).disconnect();
          }
          
          ref.read(connectionSyncProgressProvider.notifier).reset();
        }
      },
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        ),
        title: Row(
          children: [
            Icon(Icons.sync, color: AppStyles.primaryTeal(context)),
            const SizedBox(width: 10),
            Text(
              'Weather Data Bridge',
              style: AppStyles.titleStyle(context),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall Status
              Text(
                state.statusMessage.isNotEmpty
                    ? state.statusMessage
                    : _getStageText(ref, state.stage),
                style: AppStyles.subTitleStyle(context),
              ),
              const SizedBox(height: 20),

              if (state.stage == SyncStage.waitingBypass) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    border: Border.all(color: Colors.amber.shade200),
                    borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
                          const SizedBox(width: 8),
                          Text(
                            'Insufficient History Data',
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This station requires 48 hours of telemetry logs for accurate humidity predictions. Remaining wait time is ${state.hoursToWait} hours.',
                        style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade700,
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                            onPressed: () {
                              ref.read(connectionSyncProgressProvider.notifier).submitBypassDecision(true);
                            },
                            child: const Text('Proceed Anyway'),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.amber.shade900,
                              side: BorderSide(color: Colors.amber.shade400),
                            ),
                            onPressed: () {
                              ref.read(connectionSyncProgressProvider.notifier).submitBypassDecision(false);
                            },
                            child: const Text('Wait'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Step 1: Connection
                _buildStepProgress(
                  ref: ref,
                  title: 'Device Connection',
                  progress: state.connectingProgress,
                  isActive: state.stage == SyncStage.connecting,
                  isDone: state.stage.index > SyncStage.connecting.index,
                  isFailed: state.stage == SyncStage.failed && state.connectingProgress < 1.0,
                ),
                const SizedBox(height: 16),

                // Step 2: Pairing
                _buildStepProgress(
                  ref: ref,
                  title: 'Security Handshake',
                  progress: state.pairingProgress,
                  isActive: state.stage == SyncStage.pairing,
                  isDone: state.stage.index > SyncStage.pairing.index,
                  isFailed: state.stage == SyncStage.failed && state.connectingProgress >= 1.0 && state.pairingProgress < 1.0,
                ),
                const SizedBox(height: 16),

                // Step 3: Refresh/Sync
                _buildStepProgress(
                  ref: ref,
                  title: 'Data Synchronization',
                  progress: state.refreshingProgress,
                  isActive: state.stage == SyncStage.refreshing,
                  isDone: state.stage == SyncStage.completed,
                  isFailed: state.stage == SyncStage.failed && state.pairingProgress >= 1.0 && state.refreshingProgress < 1.0,
                ),
              ],

              if (state.errorMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppStyles.dangerRedBg(context),
                    border: Border.all(color: AppStyles.dangerRedBorder(context)),
                    borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline, color: AppStyles.dangerRed(context), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: TextStyle(
                            color: AppStyles.dangerRed(context),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (isFinished)
            TextButton(
              onPressed: () {
                ref.read(connectionSyncProgressProvider.notifier).reset();
                Navigator.pop(context);
              },
              child: const Text('Close'),
            )
          else
            TextButton(
              onPressed: () {
                // Abort sequence
                ref.read(connectionSyncProgressProvider.notifier).submitBypassDecision(false);
                
                if (state.stage == SyncStage.connecting || state.stage == SyncStage.pairing) {
                  ref.read(bleServiceProvider).disconnect();
                }
                
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppStyles.dangerRed(context),
              ),
              child: const Text('Cancel'),
            ),
        ],
      ),
    );
  }

  String _getStageText(WidgetRef ref, SyncStage stage) {
    switch (stage) {
      case SyncStage.idle:
        return 'Idle';
      case SyncStage.connecting:
        return 'Connecting';
      case SyncStage.pairing:
        return 'Pairing';
      case SyncStage.refreshing:
        return 'Synchronizing';
      case SyncStage.waitingBypass:
        return 'Waiting Bypass Decision';
      case SyncStage.completed:
        return 'Success';
      case SyncStage.failed:
        return 'Failed';
    }
  }

  Widget _buildStepProgress({
    required WidgetRef ref,
    required String title,
    required double progress,
    required bool isActive,
    required bool isDone,
    required bool isFailed,
  }) {
    final context = ref.context;
    Color titleColor = Colors.grey.shade500;
    Color barColor = Colors.grey.shade300;
    Widget statusIcon = const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 18);

    if (isDone) {
      titleColor = AppStyles.darkSlate(context);
      barColor = AppStyles.primaryTeal(context);
      statusIcon = Icon(Icons.check_circle, color: AppStyles.primaryTeal(context), size: 18);
    } else if (isFailed) {
      titleColor = AppStyles.dangerRed(context);
      barColor = AppStyles.dangerRed(context);
      statusIcon = Icon(Icons.cancel, color: AppStyles.dangerRed(context), size: 18);
    } else if (isActive) {
      titleColor = AppStyles.primaryTeal(context);
      barColor = AppStyles.primaryTeal(context);
      statusIcon = SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppStyles.primaryTeal(context)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.normal,
                  color: titleColor,
                ),
              ),
            ),
            statusIcon,
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: isDone ? 1.0 : (isFailed ? 1.0 : progress),
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}
