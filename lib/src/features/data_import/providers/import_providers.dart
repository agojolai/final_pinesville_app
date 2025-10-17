import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/import_models.dart';
import '../data/services/file_parser_service.dart';
import '../data/services/data_validator_service.dart';
import '../data/repositories/import_repository.dart';

/// Provider for file parser service (supports both CSV and JSON)
final fileParserServiceProvider = Provider<FileParserService>((ref) {
  return FileParserService();
});

/// Provider for data validator service
final dataValidatorServiceProvider = Provider<DataValidatorService>((ref) {
  return DataValidatorService(FirebaseFirestore.instance);
});

/// Provider for import repository
final importRepositoryProvider = Provider<ImportRepository>((ref) {
  return ImportRepository(FirebaseFirestore.instance);
});

/// State notifier for import process
class ImportStateNotifier extends StateNotifier<AsyncValue<ImportResult?>> {
  final FileParserService _fileParser;
  final DataValidatorService _validator;
  final ImportRepository _repository;

  ImportStateNotifier(this._fileParser, this._validator, this._repository)
      : super(const AsyncValue.data(null));

  /// Import bills from CSV or JSON file
  Future<void> importBills(Uint8List fileBytes, String fileName, {Function(int, int)? onProgress}) async {
    state = const AsyncValue.loading();
    try {
      // Parse file (auto-detects CSV or JSON)
      final billsData = await _fileParser.parseBillsFile(fileBytes, fileName);

      // Validate
      final validationErrors = await _validator.validateBills(billsData);
      if (validationErrors.isNotEmpty) {
        throw Exception('Validation failed: ${validationErrors.length} errors found');
      }

      // Import
      final result = await _repository.importBills(billsData, onProgress: onProgress);
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Import payments from CSV or JSON file
  Future<void> importPayments(Uint8List fileBytes, String fileName, {Function(int, int)? onProgress}) async {
    state = const AsyncValue.loading();
    try {
      final paymentsData = await _fileParser.parsePaymentsFile(fileBytes, fileName);
      final validationErrors = await _validator.validatePayments(paymentsData);
      if (validationErrors.isNotEmpty) {
        throw Exception('Validation failed: ${validationErrors.length} errors found');
      }

      final result = await _repository.importPayments(paymentsData, onProgress: onProgress);
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Validate bills file without importing (supports CSV and JSON)
  Future<List<ValidationError>> validateBillsFile(Uint8List fileBytes, String fileName) async {
    try {
      final billsData = await _fileParser.parseBillsFile(fileBytes, fileName);
      return await _validator.validateBills(billsData);
    } catch (e) {
      return [
        ValidationError(
          rowNumber: 0,
          field: 'file',
          message: 'Failed to parse file: $e',
        )
      ];
    }
  }

  /// Validate payments file without importing (supports CSV and JSON)
  Future<List<ValidationError>> validatePaymentsFile(Uint8List fileBytes, String fileName) async {
    try {
      final paymentsData = await _fileParser.parsePaymentsFile(fileBytes, fileName);
      return await _validator.validatePayments(paymentsData);
    } catch (e) {
      return [
        ValidationError(
          rowNumber: 0,
          field: 'file',
          message: 'Failed to parse file: $e',
        )
      ];
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for import state
final importStateProvider =
    StateNotifierProvider<ImportStateNotifier, AsyncValue<ImportResult?>>((ref) {
  return ImportStateNotifier(
    ref.watch(fileParserServiceProvider),
    ref.watch(dataValidatorServiceProvider),
    ref.watch(importRepositoryProvider),
  );
});
