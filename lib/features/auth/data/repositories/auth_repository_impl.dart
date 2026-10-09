import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/selected_child_storage.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/storage/user_storage.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/child_account.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_user_model.dart';
import '../models/child_account_model.dart';
import '../services/auth_service.dart';
import '../../../../core/l10n/l10n.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService service;
  final TokenStorage tokenStorage;
  final UserStorage userStorage;
  final SelectedChildStorage selectedChildStorage;
  final NetworkInfo networkInfo;

  /// Sanctum requires a device name to label the issued token.
  final String deviceName;

  const AuthRepositoryImpl({
    required this.service,
    required this.tokenStorage,
    required this.userStorage,
    required this.selectedChildStorage,
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

  /// Resolution order: the student the parent picked, then the one the token
  /// belongs to (`user_id`), then the first in the list. The last two keep a
  /// fresh install — where nothing has been picked yet — pointing at the same
  /// student the API would return on its own.
  @override
  ChildAccount? get activeChild {
    final children = currentUser?.children ?? const <ChildAccount>[];
    if (children.isEmpty) return null;

    final selectedId = selectedChildStorage.selectedChildId;
    for (final child in children) {
      if (selectedId != null && child.childId == selectedId) return child;
    }
    for (final child in children) {
      if (child.childId == currentUser?.id) return child;
    }
    return children.first;
  }

  @override
  int? get activeStudentId => activeChild?.childId ?? currentUser?.id;

  @override
  int? get activeClassId => activeChild?.classId ?? currentUser?.classId;

  @override
  Future<Either<Failure, Unit>> selectChild(int childId) async {
    final known = (currentUser?.children ?? const <ChildAccount>[])
        .any((c) => c.childId == childId);
    if (!known) {
      return Left(ValidationFailure(L.s.errChildNotYoursShort));
    }

    try {
      final refreshed = await service.selectChild(childId);
      // Order matters: the pick is only stored once the backend has moved
      // `users.user_id`, otherwise the app would show one student while every
      // endpoint answers for another.
      await selectedChildStorage.save(childId);
      if (refreshed != null) {
        await userStorage.saveUser(_merged(refreshed));
      }
      return const Right(unit);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> attachChild({
    required String admissionNo,
    String? relation,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final refreshed = await service.attachChild(
        admissionNo: admissionNo,
        relation: relation,
      );
      // The whole point of the call: the response's `info` carries the new
      // student, and caching it is what makes [activeChild] and the switcher
      // see them. An endpoint that only acknowledges leaves the list as it
      // was — the student is linked on the server, and the next login picks
      // them up.
      if (refreshed != null) {
        await userStorage.saveUser(_withStudent(_merged(refreshed)));
      }
      // Deliberately no [selectedChildStorage] write: linking a student is
      // not switching to them. The parent stays on the one they were looking
      // at, and moves over through the switcher if they want to.
      return const Right(unit);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  /// No `NetworkInfo` pre-flight, for the same reason as [deleteAccount].
  @override
  Future<Either<Failure, Unit>> detachChild({
    required int childId,
    required String password,
  }) async {
    if (!_isOwnChild(childId)) {
      return Left(ValidationFailure(L.s.errChildNotYoursShort));
    }

    try {
      await service.detachChild(childId: childId, password: password);

      final current = userStorage.cachedUser;
      if (current != null) {
        await userStorage.saveUser(_withoutChild(current, childId));
      }
      // A pick naming a student who is gone would otherwise outlive them on
      // this device.
      if (selectedChildStorage.selectedChildId == childId) {
        await selectedChildStorage.clear();
      }
      return const Right(unit);
    } on FieldValidationException catch (e) {
      // Before ValidationException — it is a subclass, and the plain branch
      // would drop the per-field message.
      return Left(FieldValidationFailure(e.fieldErrors, e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> updateProfile({
    required String name,
    required String email,
    required String phone,
    String? otp,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final refreshed = await service.updateProfile(
        name: name,
        email: email,
        phone: phone,
        otp: otp,
      );
      final current = userStorage.cachedUser;

      if (refreshed != null) {
        await userStorage.saveUser(_merged(refreshed));
      } else if (current != null) {
        // The endpoint only acknowledged. What was sent is what the server now
        // holds, so applying it locally is both correct and what keeps the
        // profile from showing yesterday's name until the next login.
        await userStorage.saveUser(
          _withDetails(current, name: name, email: email, phone: phone),
        );
      }
      return const Right(unit);
    } on FieldValidationException catch (e) {
      // Caught before ValidationException — it is a subclass, and dropping to
      // the plain branch would throw the per-field map away.
      return Left(FieldValidationFailure(e.fieldErrors, e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      await service.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Right(unit);
    } on FieldValidationException catch (e) {
      // Caught before ValidationException — it is a subclass, and dropping to
      // the plain branch would throw the per-field map away.
      return Left(FieldValidationFailure(e.fieldErrors, e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  /// No `NetworkInfo` pre-flight: that probe pings a third party, and an
  /// offline device already surfaces as a connection error from the service.
  @override
  Future<Either<Failure, String?>> deleteAccount({
    required String password,
  }) async {
    try {
      return Right(await service.deleteAccount(password: password));
    } on FieldValidationException catch (e) {
      // Before ValidationException — it is a subclass, and the plain branch
      // would drop the per-field message.
      return Left(FieldValidationFailure(e.fieldErrors, e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> updateChildEmail({
    required int childId,
    required String email,
    String? otp,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    if (!_isOwnChild(childId)) {
      return Left(ValidationFailure(L.s.errChildNotYoursShort));
    }

    try {
      final refreshed = await service.updateChildEmail(
        childId: childId,
        email: email,
        otp: otp,
      );
      final current = userStorage.cachedUser;

      if (refreshed != null) {
        await userStorage.saveUser(_merged(refreshed));
      } else if (current != null) {
        await userStorage.saveUser(
          _withChildEmail(current, childId: childId, email: email),
        );
      }
      return const Right(unit);
    } on FieldValidationException catch (e) {
      // Caught before ValidationException — it is a subclass, and dropping to
      // the plain branch would throw the per-field map away.
      return Left(FieldValidationFailure(e.fieldErrors, e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, int>> sendEmailChangeOtp({
    required String email,
    int? childId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    if (childId != null && !_isOwnChild(childId)) {
      return Left(ValidationFailure(L.s.errChildNotYoursShort));
    }

    try {
      return Right(
        await service.sendEmailChangeOtp(email: email, childId: childId),
      );
    } on FieldValidationException catch (e) {
      // Before ValidationException — it is a subclass, and the plain branch
      // would drop the per-field message.
      return Left(FieldValidationFailure(e.fieldErrors, e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  /// Rejected here as well as on the server: the id comes from the roster
  /// this account was handed, so one that isn't on it is the app's bug, not
  /// a round trip worth making.
  bool _isOwnChild(int childId) =>
      (currentUser?.children ?? const <ChildAccount>[])
          .any((c) => c.childId == childId);

  /// The cached user with the details the profile form just sent.
  ///
  /// Takes the values verbatim, [_merged]'s "keep what we had" rule
  /// deliberately not applied: a parent who cleared their phone means it.
  AuthUserModel _withDetails(
    AuthUserModel user, {
    required String name,
    required String email,
    required String phone,
  }) {
    return AuthUserModel(
      id: user.id,
      accountId: user.accountId,
      pushId: user.pushId,
      name: name,
      childName: user.childName,
      role: user.role,
      email: email,
      phone: phone.isEmpty ? null : phone,
      classId: user.classId,
      className: user.className,
      categories: user.categories,
      children: user.children,
    );
  }

  /// The cached user with one student's e-mail replaced.
  AuthUserModel _withChildEmail(
    AuthUserModel user, {
    required int childId,
    required String email,
  }) {
    return AuthUserModel(
      id: user.id,
      accountId: user.accountId,
      pushId: user.pushId,
      name: user.name,
      childName: user.childName,
      role: user.role,
      email: user.email,
      phone: user.phone,
      classId: user.classId,
      className: user.className,
      categories: user.categories,
      children: [
        for (final child in user.children)
          if (child.childId == childId)
            ChildAccountModel(
              childId: child.childId,
              isActive: child.isActive,
              classId: child.classId,
              username: child.username,
              categories: child.categories,
              className: child.className,
              childName: child.childName,
              childSurname: child.childSurname,
              email: email,
              password: child.password,
              paymentId: child.paymentId,
            )
          else
            ChildAccountModel.from(child),
      ],
    );
  }

  /// The cached user with one student taken off the roster.
  ///
  /// Built here rather than from the `/detachChild` response: [_merged] keeps
  /// the cached roster when the incoming one is empty and the cached `id` when
  /// the incoming one is null, so the last student removed would come
  /// straight back.
  ///
  /// When the account's own student is the one removed, `id` moves to the
  /// next one left — or to null once none is, which is [AuthUser.needsChild]
  /// and sends the parent to `AddChildScreen`.
  AuthUserModel _withoutChild(AuthUserModel user, int childId) {
    final remaining = [
      for (final child in user.children)
        if (child.childId != childId) ChildAccountModel.from(child),
    ];

    // Still pointing at a student who is on the roster: only the list changes.
    if (remaining.isNotEmpty && user.id != childId) {
      return AuthUserModel(
        id: user.id,
        accountId: user.accountId,
        pushId: user.pushId,
        name: user.name,
        childName: user.childName,
        role: user.role,
        email: user.email,
        phone: user.phone,
        classId: user.classId,
        className: user.className,
        categories: user.categories,
        children: remaining,
      );
    }

    final next = remaining.isEmpty ? null : remaining.first;
    return AuthUserModel(
      id: next?.childId,
      accountId: user.accountId,
      pushId: user.pushId,
      name: user.name,
      childName: next?.fullName ?? '',
      role: user.role,
      email: user.email,
      phone: user.phone,
      classId: next?.classId,
      className: next?.className,
      categories: next?.categories ?? '',
      children: remaining,
    );
  }

  /// Points an account with no student at the first one it now has.
  ///
  /// The backend does this itself — `users.user_id` is set to the newly linked
  /// student when the column was null — but a response that carried only the
  /// roster leaves the app's copy at `id: null`. [AuthUser.needsChild] would
  /// then keep sending the parent back to `AddChildScreen` to add the child
  /// they just added. No-op once the account has an id, which is every case
  /// where the endpoint answered with a full user.
  AuthUserModel _withStudent(AuthUserModel user) {
    if (user.id != null) return user;

    final childId = user.children
        .map((c) => c.childId)
        .firstWhere((id) => id != null, orElse: () => null);
    if (childId == null) return user;

    return AuthUserModel(
      id: childId,
      accountId: user.accountId,
      pushId: user.pushId,
      name: user.name,
      childName: user.childName,
      role: user.role,
      email: user.email,
      phone: user.phone,
      classId: user.classId,
      className: user.className,
      categories: user.categories,
      children: user.children,
    );
  }

  /// Folds a `/selectChild` or `/attachChild` response into the cached user.
  ///
  /// Either endpoint's job is to move `user_id` / `class_id` or extend
  /// `info`, so both may answer with a trimmed user. Anything left out keeps
  /// its cached value —
  /// dropping `role` would send the account back to the login screen on the
  /// next launch (see [UserStorageImpl]), and dropping `info` would empty the
  /// switcher the parent just used.
  AuthUserModel _merged(AuthUserModel incoming) {
    final current = userStorage.cachedUser;
    if (current == null) return incoming;

    return AuthUserModel(
      id: incoming.id ?? current.id,
      // `/selectChild` answers with the student, so it never carries the
      // parent's own row — dropping either of these would change the push
      // external id mid-session and orphan every notification already queued
      // for it. This is the switch-between-children path, so it is exactly
      // where that would show up.
      accountId: incoming.accountId ?? current.accountId,
      pushId: incoming.pushId ?? current.pushId,
      name: incoming.name.isNotEmpty ? incoming.name : current.name,
      childName:
          incoming.childName.isNotEmpty ? incoming.childName : current.childName,
      role: incoming.role.isNotEmpty ? incoming.role : current.role,
      email: incoming.email.isNotEmpty ? incoming.email : current.email,
      phone: incoming.phone ?? current.phone,
      classId: incoming.classId ?? current.classId,
      className: incoming.className ?? current.className,
      categories: incoming.categories.isNotEmpty
          ? incoming.categories
          : current.categories,
      children:
          incoming.children.isNotEmpty ? incoming.children : current.children,
    );
  }

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
      // A different account may have signed in on this device — a leftover
      // pick would point at a student this parent has nothing to do with.
      await selectedChildStorage.clear();
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
  Future<Either<Failure, Unit>> sendResetCode({required String email}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await service.sendResetCode(email: email);
      return const Right(unit);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> resetPassword({
    required String email,
    required String password,
    required String otp,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await service.resetPassword(email: email, password: password, otp: otp);
      return const Right(unit);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> registerParent({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String admissionNo,
    String? relation,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await service.registerParent(
        name: name,
        email: email,
        phone: phone,
        password: password,
        admissionNo: admissionNo,
        relation: relation,
      );
      return const Right(unit);
    } on FieldValidationException catch (e) {
      // Caught before ValidationException — it is a subclass, and dropping to
      // the plain branch would throw the per-field map away.
      return Left(FieldValidationFailure(e.fieldErrors, e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await service.verifyOtp(email: email, otp: otp);
      return const Right(unit);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> resendOtp({required String email}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await service.resendOtp(email: email);
      return const Right(unit);
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
    await selectedChildStorage.clear();
    return const Right(unit);
  }

  /// `child_status`-dakı is_active dəyərlərini keşlənmiş uşaqlara tətbiq edir.
  AuthUserModel _withChildStatuses(
      AuthUserModel user,
      Map<int, bool> activeById,
      ) {
    return AuthUserModel(
      id: user.id,
      accountId: user.accountId,
      pushId: user.pushId,
      name: user.name,
      childName: user.childName,
      role: user.role,
      email: user.email,
      phone: user.phone,
      classId: user.classId,
      className: user.className,
      categories: user.categories,
      children: [
        for (final child in user.children)
          if (child.childId != null && activeById.containsKey(child.childId))
            ChildAccountModel(
              childId: child.childId,
              isActive: activeById[child.childId]! ? 'yes' : 'no',
              classId: child.classId,
              username: child.username,
              categories: child.categories,
              className: child.className,
              childName: child.childName,
              childSurname: child.childSurname,
              email: child.email,
              password: child.password,
              paymentId: child.paymentId,
            )
          else
            ChildAccountModel.from(child),
      ],
    );
  }

  @override
  Future<Either<Failure, AuthUser>> refreshUser() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    final childId = activeChild?.childId;
    if (childId == null) {
      return const Left(ServerFailure());
    }

    try {
      final statuses = await service.fetchChildStatuses(childId);

      final user = userStorage.cachedUser;
      if (user == null) return const Left(ServerFailure());
      if (statuses.isEmpty) return Right(user);

      final updated = _withChildStatuses(user, statuses);
      await userStorage.saveUser(updated);
      return Right(updated);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
