import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/library_content.dart';

abstract class LibraryRepository {
  /// Books available to the logged-in student's class.
  Future<Either<Failure, LibraryContent>> getLibrary();
}
