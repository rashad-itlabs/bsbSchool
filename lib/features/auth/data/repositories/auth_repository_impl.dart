import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/storage/user_storage.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_user_model.dart';
import '../services/auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService service;
  final TokenStorage tokenStorage;
  final UserStorage userStorage;
  final NetworkInfo networkInfo;

  /// Sanctum requires a device name to label the issued token.
  final String deviceName;

  const AuthRepositoryImpl({
    required this.service,
    required this.tokenStorage,
    required this.userStorage,
    required this.networkInfo,
    this.deviceName = 'bsb_mobile',
  });

  /// A token alone isn't enough: sessions stored before the user was cached
  /// would leave the UI with no name to show, so treat those as logged out
  /// and make the user sign in again.
  @override
  bool get isLoggedIn => tokenStorage.hasToken && userStorage.cachedUser != null;

  @override
  AuthUser? get currentUser => userStorage.cachedUser;

  @override
  Future<Either<Failure, AuthSession>> login({
    required String email,
    required String password,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final session = await service.login(
        email: email,
        password: password,
        deviceName: deviceName,
      );
      await tokenStorage.saveToken(session.token);
      await userStorage.saveUser(session.user as AuthUserModel);
      return Right(session);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      // Best-effort revoke; ignore network/server errors on the way out.
      await service.logout();
    } catch (_) {
      // no-op
    }
    await tokenStorage.clear();
    await userStorage.clear();
    return const Right(unit);
  }
}
