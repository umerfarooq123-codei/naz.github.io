// lib/core/export/export_registry.dart

import 'package:flutter/material.dart';
import 'package:ledger_master/core/services/export_service.dart';
import 'package:ledger_master/core/services/generic_data_extractor.dart';

/// Registry for managing and reusing data extractors
class ExportRegistry {
  // Private constructor - this is a singleton
  ExportRegistry._();

  static final ExportRegistry _instance = ExportRegistry._();
  static ExportRegistry get instance => _instance;

  // Store extractors by model type
  final Map<Type, GenericDataExtractor> _extractors = {};

  /// Register an extractor for a specific model type
  void register<T extends ExportableData>(GenericDataExtractor<T> extractor) {
    _extractors[T] = extractor;
  }

  /// Get an extractor for a specific model type
  GenericDataExtractor<T>? get<T extends ExportableData>() {
    return _extractors[T] as GenericDataExtractor<T>?;
  }

  /// Check if an extractor exists for a model type
  bool has<T extends ExportableData>() {
    return _extractors.containsKey(T);
  }

  /// Remove an extractor for a model type
  void remove<T extends ExportableData>() {
    _extractors.remove(T);
  }

  /// Clear all registered extractors
  void clear() {
    _extractors.clear();
  }

  /// Get all registered model types
  List<Type> get registeredTypes => _extractors.keys.toList();

  /// Get count of registered extractors
  int get count => _extractors.length;
}

/// Helper class to initialize common extractors
class ExportRegistryInitializer {
  static void initializeCommonExtractors() {
    // final registry = ExportRegistry.instance;

    // Register LedgerEntry extractor (you'll need to create this)
    // registry.register<LedgerEntry>(LedgerEntry.createExtractor());

    // Register ItemLedgerEntry extractor (when ready)
    // registry.register<ItemLedgerEntry>(ItemLedgerEntry.createExtractor());

    // Register VendorLedgerEntry extractor (when ready)
    // registry.register<VendorLedgerEntry>(VendorLedgerEntry.createExtractor());

    // Add more extractors as you create them...
  }
}

class ExportHelper {
  /// Quick export with automatic extractor detection
  static Future<void> export<T extends ExportableData>({
    required BuildContext context,
    required List<T> data,
    required String fileName,
    String format = 'excel',
    GenericDataExtractor<T>? customExtractor,
  }) async {
    if (data.isEmpty) {
      _showMessage(context, 'No data to export', isError: false);
      return;
    }

    final extractor = customExtractor ?? ExportRegistry.instance.get<T>();

    if (extractor == null) {
      _showMessage(
        context,
        'No export configuration found for ${T.toString()}',
        isError: true,
      );
      return;
    }

    await DesktopExportService.exportData(
      context: context,
      data: data,
      extractor: extractor,
      defaultFileName: fileName,
      fileType: format,
    );
  }

  /// Export with dialog (user selects format)
  static Future<void> exportWithDialog<T extends ExportableData>({
    required BuildContext context,
    required List<T> data,
    required String baseFileName,
    String title = 'Export Data',
    GenericDataExtractor<T>? customExtractor,
  }) async {
    if (data.isEmpty) {
      _showMessage(context, 'No data to export', isError: false);
      return;
    }

    final extractor = customExtractor ?? ExportRegistry.instance.get<T>();

    if (extractor == null) {
      _showMessage(
        context,
        'No export configuration found for ${T.toString()}',
        isError: true,
      );
      return;
    }

    await DesktopExportService.showExportDialog(
      context: context,
      data: data,
      extractor: extractor,
      baseFileName: baseFileName,
      title: title,
    );
  }

  /// Quick export button widget
  static Widget exportButton<T extends ExportableData>({
    required BuildContext context,
    required List<T> data,
    required String fileName,
    String tooltip = 'Export',
    IconData icon = Icons.upload_file_outlined,
    String format = 'excel',
    GenericDataExtractor<T>? customExtractor,
    VoidCallback? onComplete,
    VoidCallback? onError,
  }) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: () async {
        try {
          await export(
            context: context,
            data: data,
            fileName: fileName,
            format: format,
            customExtractor: customExtractor,
          );
          onComplete?.call();
        } catch (e) {
          onError?.call();
        }
      },
    );
  }

  static void _showMessage(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
