import 'package:flutter/material.dart';

class MedicineReminderScreen extends StatefulWidget {
  const MedicineReminderScreen({super.key});

  @override
  State<MedicineReminderScreen> createState() =>
      _MedicineReminderScreenState();
}

class _MedicineReminderScreenState
    extends State<MedicineReminderScreen> {

  final medicineController = TextEditingController();
  final doseController = TextEditingController();
  final durationController = TextEditingController();

  TimeOfDay? selectedTime;

  List<Map<String, String>> medicines = [];

  Future<void> selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }

  void addMedicine() {
    if (medicineController.text.isEmpty ||
        doseController.text.isEmpty ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required details'),
        ),
      );
      return;
    }

    setState(() {
      medicines.add({
        'name': medicineController.text,
        'dose': doseController.text,
        'time': selectedTime!.format(context),
        'duration': durationController.text,
      });
    });

    medicineController.clear();
    doseController.clear();
    durationController.clear();

    setState(() {
      selectedTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Reminder'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              'My Medicines',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Add your medicines and reminder times.',
              style: TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: medicineController,
              decoration: InputDecoration(
                labelText: 'Medicine Name',
                prefixIcon: const Icon(Icons.medication),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: doseController,
              decoration: InputDecoration(
                labelText: 'Dose',
                hintText: 'Example: 1 tablet',
                prefixIcon: const Icon(Icons.local_pharmacy),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: durationController,
              decoration: InputDecoration(
                labelText: 'Duration',
                hintText: 'Example: 7 days',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text(
                  selectedTime == null
                      ? 'Select Reminder Time'
                      : 'Reminder: ${selectedTime!.format(context)}',
                ),
                onPressed: selectTime,
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Medicine'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                onPressed: addMedicine,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: medicines.isEmpty
                  ? const Center(
                      child: Text(
                        'No medicines added yet.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: medicines.length,
                      itemBuilder: (context, index) {

                        final medicine = medicines[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Icon(
                                Icons.medication,
                                color: Colors.white,
                              ),
                            ),

                            title: Text(
                              medicine['name']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            subtitle: Text(
                              '${medicine['dose']} • '
                              '${medicine['time']}\n'
                              'Duration: ${medicine['duration']}',
                            ),

                            trailing: const Icon(
                              Icons.notifications_active,
                              color: Colors.teal,
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