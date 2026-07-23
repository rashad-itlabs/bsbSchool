import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/buffet_card_content.dart';
import '../repositories/buffet_card_repository.dart';

class GetBuffetCard implements UseCase<BuffetCardContent, NoParams> {
  final BuffetCardRepository repository;
  const GetBuffetCard(this.repository);

  @override
  Future<Either<Failure, BuffetCardContent>> call(NoParams params) {
    return repository.getBuffetCard();
  }
}
