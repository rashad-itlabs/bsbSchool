import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/payment_result.dart';
import '../../domain/entities/payment_session.dart';
import '../../domain/repositories/payment_repository.dart';
import '../services/payment_service.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentService service;

  /// Source of the `student_id` for tuition — the child the parent has
  /// switched to.
  final AuthRepository authRepository;

  const PaymentRepositoryImpl({
    required this.service,
    required this.authRepository,
  });

  @override
  Future<Either<Failure, PaymentSession>> startTopUp(double amount) async {
    try {
      return Right(await service.startTopUp(amount));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, PaymentSession>> startFeePayment({
    required int feeId,
    required double amount,
  }) async {
    try {
      return Right(
        await service.startFeePayment(feeId: feeId, amount: amount),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, PaymentResult>> getStatus(String reference) async {
    try {
      return Right(await service.getStatus(reference));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, PaymentSession>> startTuitionPayment(
      double amount) async {
    try {
      return Right(await service.startTuitionPayment(
        amount: amount,
        studentId: authRepository.activeStudentId,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, PaymentResult>> getTuitionStatus(
      String reference) async {
    try {
      return Right(await service.getTuitionStatus(reference));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
