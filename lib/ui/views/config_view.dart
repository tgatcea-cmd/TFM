import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/database_service.dart';
import '../../main.dart';

class ConfigView extends ConsumerWidget {
  final DatabaseService db;

  const ConfigView({
    super.key,
    required this.db,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admin controls: Clear Database
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Database Maintenance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red.shade900,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Purge Local Database'),
                          content: const Text(
                            'Warning: All historical records, weather information, and predictions will be permanently deleted.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              onPressed: () {
                                db.clearAllData();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Database cleared successfully!',
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Clear Database'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Clear Database'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // GPS Manual Refresh
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await ref.read(locationProvider.notifier).updateFromGps();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Location updated successfully')),
                      );
                    },
                    icon: const Icon(Icons.my_location),
                    label: const Text('Refresh Location from GPS'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
