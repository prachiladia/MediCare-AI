import '../models/medicine.dart';

// ============================================================================
// DEMO / SAMPLE DATA ONLY
// ============================================================================
// NOTE: This file provides mock data exclusively for UI design and prototype
// demonstration. No real backend, database, or reminder notifications are
// attached to these entries. All status changes occur strictly in-memory.
// Data is lost whenever the application restarts or the web browser reloads.
// ============================================================================

final List<Medicine> initialSampleMedicines = [
  const Medicine(
    id: 'med_1',
    name: 'Amoxicillin',
    dosage: '500 mg',
    scheduledTime: '09:00 AM',
    scheduledTimes: ['09:00 AM', '09:00 PM'],
    status: MedicineStatus.pending,
    instructions: 'Take after breakfast with water',
    type: MedicineType.capsule,
    isHeroReminder: true,
    minutesUntil: 25,
    frequency: 'Twice daily',
    isEnabled: true,
    isSampleData: true,
  ),
  const Medicine(
    id: 'med_2',
    name: 'Metformin',
    dosage: '850 mg',
    scheduledTime: '08:00 AM',
    scheduledTimes: ['08:00 AM'],
    status: MedicineStatus.taken,
    instructions: 'Take with breakfast',
    type: MedicineType.tablet,
    isHeroReminder: false,
    frequency: 'Once daily',
    isEnabled: true,
    isSampleData: true,
  ),
  const Medicine(
    id: 'med_3',
    name: 'Vitamin D3',
    dosage: '1000 IU',
    scheduledTime: '08:30 AM',
    scheduledTimes: ['08:30 AM'],
    status: MedicineStatus.taken,
    instructions: 'Take with morning meal',
    type: MedicineType.pill,
    isHeroReminder: false,
    frequency: 'Once daily',
    isEnabled: true,
    isSampleData: true,
  ),
  const Medicine(
    id: 'med_4',
    name: 'Lisinopril',
    dosage: '10 mg',
    scheduledTime: '01:00 PM',
    scheduledTimes: ['01:00 PM'],
    status: MedicineStatus.pending,
    instructions: 'Take before lunch',
    type: MedicineType.tablet,
    isHeroReminder: false,
    frequency: 'Once daily',
    isEnabled: true,
    isSampleData: true,
  ),
  const Medicine(
    id: 'med_5',
    name: 'Atorvastatin',
    dosage: '20 mg',
    scheduledTime: '09:00 PM',
    scheduledTimes: ['09:00 PM'],
    status: MedicineStatus.pending,
    instructions: 'Take before bedtime',
    type: MedicineType.tablet,
    isHeroReminder: false,
    frequency: 'Once daily at night',
    isEnabled: true,
    isSampleData: true,
  ),
];
