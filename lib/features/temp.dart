import 'package:flutter/material.dart';
import 'package:ledger_master/core/services/sheet_sync_service.dart';

class TestSyncScreen extends StatefulWidget {
  const TestSyncScreen({super.key});

  @override
  TestSyncScreenState createState() => TestSyncScreenState();
}

class TestSyncScreenState extends State<TestSyncScreen> {
  final SheetSyncService syncService = SheetSyncService();
  bool isSyncing = false;
  bool isLoading = false;
  String statusMessage = 'Ready to test';
  Map<String, dynamic>? lastResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sync Test Screen')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(statusMessage),
                    if (isSyncing) SizedBox(height: 10),
                    if (isSyncing) CircularProgressIndicator(),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Test Buttons
            Column(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    setState(() => isLoading = true);
                    var result = await syncService.syncData();
                    debugPrint('Test result: $result');
                    setState(() {
                      isLoading = false;
                      statusMessage = result['success'] == true
                          ? '✅ API connected!'
                          : '❌ API error: ${result['error']}';
                    });
                  },
                  child: Text('Test API'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTestButton({
    required IconData icon,
    required String label,
    required Color color,
    required Function onPressed,
  }) {
    return ElevatedButton(
      onPressed: isLoading || isSyncing ? null : () => onPressed(),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.all(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Icon(icon), SizedBox(height: 5), Text(label)],
      ),
    );
  }

  // Show last result in dialog
  void showLastResult() {
    if (lastResult == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No result to show yet')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Last Result'),
        content: SingleChildScrollView(
          child: Text(
            formatResult(lastResult!),
            style: TextStyle(fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  String formatResult(Map<String, dynamic> result) {
    String output = '';
    result.forEach((key, value) {
      if (value is Map) {
        output += '$key:\n';
        value.forEach((k, v) {
          output += '  $k: $v\n';
        });
      } else if (value is List) {
        output += '$key: [${value.length} items]\n';
      } else {
        output += '$key: $value\n';
      }
    });
    return output;
  }
}
