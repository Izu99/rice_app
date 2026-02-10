import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';

/// Base use case interface
/// All use cases should implement this interface
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Empty parameters class for use cases that don't need parameters
class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}
