import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/payment_result.dart';
import '../../domain/entities/payment_session.dart';
import '../../domain/repositories/payment_repository.dart';
import '../services/payment_service.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentService service;

  const PaymentRepositoryImpl({required this.service});

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
  Future<Either<Failure, PaymentResult>> getStatus(String reference) async {
    try {
      return Right(await service.getStatus(reference));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
