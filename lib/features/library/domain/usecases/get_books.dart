import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/library_content.dart';
import '../repositories/library_repository.dart';

class GetBooks implements UseCase<LibraryContent, NoParams> {
  final LibraryRepository repository;
  const GetBooks(this.repository);

  @override
  Future<Either<Failure, LibraryContent>> call(NoParams params) {
    return repository.getLibrary();
  }
}
