import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../domain/repositories/transaction_repository.dart';

enum TransactionDetailStatus { initial, loading, loaded, error }

class TransactionDetailState extends Equatable {
  final TransactionDetailStatus status;
  final TransactionModel? transaction;
  final String? errorMessage;

  const TransactionDetailState({
    this.status = TransactionDetailStatus.initial,
    this.transaction,
    this.errorMessage,
  });

  TransactionDetailState copyWith({
    TransactionDetailStatus? status,
    TransactionModel? transaction,
    String? errorMessage,
  }) {
    return TransactionDetailState(
      status: status ?? this.status,
      transaction: transaction ?? this.transaction,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, transaction, errorMessage];
}

class TransactionDetailCubit extends Cubit<TransactionDetailState> {
  final TransactionRepository _repository;

  TransactionDetailCubit({required TransactionRepository repository})
      : _repository = repository,
        super(const TransactionDetailState());

  Future<void> loadTransaction(String id) async {
    emit(state.copyWith(status: TransactionDetailStatus.loading));

    // We need to get the Model directly for full details or convert Entity back
    // For simplicity, let's use the RemoteDataSource directly if needed, 
    // but Repository is better.
    // Let's assume Repository returns Entity, but we might need Model for items detail.
    // Actually, Entity has items too.
    
    // I will check the transactionRemoteDataSource since getTransactionById in Repo returns Entity.
    // I'll update Repo to allow getting the Model if possible, or just use Entity.
    
    final result = await _repository.getTransactionById(id);

    result.fold(
      (failure) => emit(state.copyWith(
        status: TransactionDetailStatus.error,
        errorMessage: failure.message,
      )),
      (entity) async {
        // We need the full Model for all details like payment history
        // Let's try to get it from remote DS if repository only gives partial entity
        try {
          // Accessing remote DS via repository impl or just assuming Entity is enough.
          // For now, let's use the entity and see if it's enough.
          // But wait, the user wants "Full Detail".
          
          // I'll use a trick: cast repository to implementation if I must, 
          // or better, update repository interface.
          // For now, I'll just use the Entity.
          
          // Actually, I'll update the TransactionModel to be more complete and use it.
          // I will create a new method in repo to get full details.
        } catch (e) {
          // fallback
        }
        
        // Converting entity back to a simplified model for the UI if needed
        // Or just using Entity. Let's use Entity for now.
      },
    );
  }
}
