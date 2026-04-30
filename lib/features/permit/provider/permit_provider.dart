import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/permit_repository.dart';
import '../data/permit_models.dart';

// ── Repository ──────────────────────────────────────────────────
final permitRepositoryProvider = Provider<PermitRepository>(
  (_) => PermitRepository(),
);

// ── Applications List State ──────────────────────────────────────
sealed class ApplicationsState {}

class ApplicationsInitial extends ApplicationsState {}

class ApplicationsLoading extends ApplicationsState {}

class ApplicationsLoaded extends ApplicationsState {
  final List<PermitApplication> applications;
  ApplicationsLoaded(this.applications);
}

class ApplicationsError extends ApplicationsState {
  final String message;
  ApplicationsError(this.message);
}

// ── Create Application State ─────────────────────────────────────
sealed class CreateApplicationState {}

class CreateApplicationInitial extends CreateApplicationState {}

class CreateApplicationLoading extends CreateApplicationState {}

class CreateApplicationSuccess extends CreateApplicationState {
  final PermitApplication application;
  CreateApplicationSuccess(this.application);
}

class CreateApplicationError extends CreateApplicationState {
  final String message;
  CreateApplicationError(this.message);
}

// ── Applications List Notifier ───────────────────────────────────
class ApplicationsNotifier extends StateNotifier<ApplicationsState> {
  final PermitRepository _repo;
  ApplicationsNotifier(this._repo) : super(ApplicationsInitial());

  Future<void> loadApplications() async {
    state = ApplicationsLoading();
    try {
      final list = await _repo.getApplications();
      state = ApplicationsLoaded(list);
    } catch (e) {
      state = ApplicationsError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void reset() => state = ApplicationsInitial();
}

// ── Create Application Notifier ──────────────────────────────────
class CreateApplicationNotifier extends StateNotifier<CreateApplicationState> {
  final PermitRepository _repo;
  CreateApplicationNotifier(this._repo) : super(CreateApplicationInitial());

  Future<void> createApplication(CreateApplicationRequest request) async {
    state = CreateApplicationLoading();
    try {
      final app = await _repo.createApplication(request);
      state = CreateApplicationSuccess(app);
    } catch (e) {
      state = CreateApplicationError(
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void reset() => state = CreateApplicationInitial();
}

// ── Providers ────────────────────────────────────────────────────
final applicationsProvider =
    StateNotifierProvider<ApplicationsNotifier, ApplicationsState>((ref) {
      return ApplicationsNotifier(ref.read(permitRepositoryProvider));
    });

final createApplicationProvider =
    StateNotifierProvider<CreateApplicationNotifier, CreateApplicationState>((
      ref,
    ) {
      return CreateApplicationNotifier(ref.read(permitRepositoryProvider));
    });
