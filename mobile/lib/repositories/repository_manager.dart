import '../services/auth_service.dart';
import 'firestore_medicine_repository.dart';
import 'in_memory_medicine_repository.dart';
import 'medicine_repository.dart';

/// Central repository manager for MediCare AI.
///
/// Decouples UI screens from concrete repository implementations:
/// - When a user is signed in with Firebase Auth (non-demo), supplies [FirestoreMedicineRepository]
///   bound to their Firebase `uid`.
/// - When in demo mode or unauthenticated, supplies [InMemoryMedicineRepository.defaultInstance].
/// - Allows dependency injection for tests via [setRepository] and [reset].
class RepositoryManager {
  static MedicineRepository? _customRepository;

  /// Retrieves the active [MedicineRepository].
  ///
  /// Priority:
  /// 1. Custom repository override (if injected via [setRepository]).
  /// 2. [FirestoreMedicineRepository] if user is authenticated and not in demo mode.
  /// 3. [InMemoryMedicineRepository.defaultInstance] for demo mode, unauthenticated fallback, or offline preview.
  static MedicineRepository get instance {
    if (_customRepository != null) {
      return _customRepository!;
    }

    final auth = AuthManager.instance;
    final user = auth.currentUser;

    if (user != null && !auth.isDemoMode) {
      return FirestoreMedicineRepository(userId: user.uid);
    }

    return InMemoryMedicineRepository.defaultInstance;
  }

  /// Sets a custom repository (e.g. for testing or explicit mocking).
  static void setRepository(MedicineRepository repository) {
    _customRepository = repository;
  }

  /// Resets repository overrides to default state.
  static void reset() {
    _customRepository = null;
  }
}
