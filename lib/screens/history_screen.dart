import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = [
      {
        'medicine': 'Paracetamol',
        'time': '9:00 AM',
        'status': 'Taken',
      },
      {
        'medicine': 'Vitamin D',
        'time': '1:00 PM',
        'status': 'Taken',
      },
      {
        'medicine': 'Antibiotic',
        'time': '8:00 PM',
        'status': 'Missed',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication History'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              'Medicine History',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {

                  final item = history[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        item['status'] == 'Taken'
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: item['status'] == 'Taken'
                            ? Colors.green
                            : Colors.red,
                      ),

                      title: Text(
                        item['medicine']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      subtitle: Text(item['time']!),

                      trailing: Text(
                        item['status']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: item['status'] == 'Taken'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}