import 'package:doce_equilibrio/core/services/session_service.dart';
import 'package:doce_equilibrio/features/auth/models/user_model.dart';
import 'package:doce_equilibrio/features/auth/repositories/user_repository_interface.dart';
import 'package:doce_equilibrio/features/settings/controllers/profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeUserRepository repository;
  late _FakeSessionService sessionService;
  late ProfileController controller;

  setUp(() {
    repository = _FakeUserRepository();
    sessionService = _FakeSessionService();
    controller = ProfileController(repository, sessionService);
  });

  test('carrega o usuário da sessão atual', () async {
    sessionService.currentUserId = 7;
    repository.user = _user(id: 7);

    final result = await controller.loadCurrentUser();

    expect(result, same(repository.user));
    expect(repository.lastFoundId, 7);
  });

  test('não consulta o repository quando não existe sessão', () async {
    final result = await controller.loadCurrentUser();

    expect(result, isNull);
    expect(repository.lastFoundId, isNull);
  });

  test('atualiza dados vitais preservando os demais dados do perfil', () async {
    final currentUser = _user(id: 7);

    await controller.updateVitalData(
      currentUser: currentUser,
      weight: 72.5,
      height: 178,
    );

    expect(repository.updatedUser?.weight, 72.5);
    expect(repository.updatedUser?.height, 178);
    expect(repository.updatedUser?.email, currentUser.email);
    expect(repository.updatedUser?.glycemiaTarget, currentUser.glycemiaTarget);
  });

  test('logout encerra a sessão', () async {
    sessionService.currentUserId = 7;

    await controller.logout();

    expect(sessionService.currentUserId, isNull);
  });
}

UserModel _user({required int id}) {
  return UserModel(
    id: id,
    name: 'Usuário',
    email: 'usuario@example.com',
    diabetesType: 'Tipo 1',
    diagnosisYear: 2020,
    password: 'hash',
    salt: 'salt',
    weight: 70,
    height: 175,
  );
}

class _FakeSessionService implements SessionService {
  int? currentUserId;

  @override
  Future<void> endSession() async {
    currentUserId = null;
  }

  @override
  Future<int?> getCurrentUserId() async => currentUserId;

  @override
  Future<void> startSession(int userId) async {
    currentUserId = userId;
  }
}

class _FakeUserRepository implements UserRepositoryInterface {
  UserModel? user;
  UserModel? updatedUser;
  int? lastFoundId;

  @override
  Future<int> create(UserModel user) async => 1;

  @override
  Future<bool> emailJaCadastrado(String email) async => false;

  @override
  Future<UserModel?> find(int id) async {
    lastFoundId = id;
    return user;
  }

  @override
  Future<UserModel?> findByEmail(String email) async => user;

  @override
  Future<int> update(UserModel user) async {
    updatedUser = user;
    return 1;
  }
}
