import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/buffet_card_content.dart';

abstract class BuffetCardRepository {
  /// The buffet card and recent purchases for the logged-in student.
  Future<Either<Failure, BuffetCardContent>> getBuffetCard();
}
