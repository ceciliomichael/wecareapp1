import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

enum DocumentFormat { pdf, jpeg, png, unknown }

class DocumentValidationResult {
  final bool isValid;
  final String message;
  final DocumentFormat? format;

  DocumentValidationResult({
    required this.isValid,
    required this.message,
    this.format,
  });
}

class DocumentFormatValidator {
  // Supported formats for barangay clearance
  static const List<DocumentFormat> _supportedFormats = [
    DocumentFormat.pdf,
    DocumentFormat.jpeg,
    DocumentFormat.png,
  ];

  // File size limits (in bytes)
  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int _minFileSizeBytes = 1024; // 1KB

  /// Validate document format and basic properties
  static DocumentValidationResult validateFormat(String? base64Document) {
    if (base64Document == null || base64Document.isEmpty) {
      return DocumentValidationResult(
        isValid: false,
        message: 'No document provided',
      );
    }

    try {
      // Decode base64 to get file bytes
      final bytes = base64Decode(base64Document);
      
      // Check file size
      if (bytes.length < _minFileSizeBytes) {
        return DocumentValidationResult(
          isValid: false,
          message: 'Document file is too small (minimum 1KB required)',
        );
      }

      if (bytes.length > _maxFileSizeBytes) {
        return DocumentValidationResult(
          isValid: false,
          message: 'Document file is too large (maximum 10MB allowed)',
        );
      }

      // Detect file format
      final format = _detectFormat(bytes);
      
      if (format == DocumentFormat.unknown) {
        return DocumentValidationResult(
          isValid: false,
          message: 'Unsupported file format. Please use PDF, JPEG, or PNG files.',
        );
      }

      if (!_supportedFormats.contains(format)) {
        return DocumentValidationResult(
          isValid: false,
          message: 'File format not supported for barangay clearance. Please use PDF, JPEG, or PNG files.',
          format: format,
        );
      }

      // Additional format-specific validation
      final formatValidation = _validateFormatSpecific(bytes, format);
      if (!formatValidation.isValid) {
        return formatValidation;
      }

      return DocumentValidationResult(
        isValid: true,
        message: 'Document format is valid',
        format: format,
      );
    } catch (e) {
      debugPrint('Error validating document format: $e');
      return DocumentValidationResult(
        isValid: false,
        message: 'Invalid document format or corrupted file',
      );
    }
  }

  /// Detect file format from byte signature
  static DocumentFormat _detectFormat(Uint8List bytes) {
    if (bytes.length < 4) return DocumentFormat.unknown;

    // PDF signature: %PDF
    if (bytes.length >= 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46) {
      return DocumentFormat.pdf;
    }

    // JPEG signature: FF D8 FF
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return DocumentFormat.jpeg;
    }

    // PNG signature: 89 50 4E 47 0D 0A 1A 0A
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return DocumentFormat.png;
    }

    return DocumentFormat.unknown;
  }

  /// Format-specific validation
  static DocumentValidationResult _validateFormatSpecific(
    Uint8List bytes,
    DocumentFormat format,
  ) {
    switch (format) {
      case DocumentFormat.pdf:
        return _validatePdf(bytes);
      case DocumentFormat.jpeg:
        return _validateJpeg(bytes);
      case DocumentFormat.png:
        return _validatePng(bytes);
      default:
        return DocumentValidationResult(
          isValid: false,
          message: 'Unknown format validation',
        );
    }
  }

  /// Validate PDF format
  static DocumentValidationResult _validatePdf(Uint8List bytes) {
    // Check for PDF EOF marker
    final String fileContent = String.fromCharCodes(bytes);
    if (!fileContent.contains('%%EOF')) {
      return DocumentValidationResult(
        isValid: false,
        message: 'PDF file appears to be corrupted or incomplete',
        format: DocumentFormat.pdf,
      );
    }

    return DocumentValidationResult(
      isValid: true,
      message: 'PDF format is valid',
      format: DocumentFormat.pdf,
    );
  }

  /// Validate JPEG format
  static DocumentValidationResult _validateJpeg(Uint8List bytes) {
    // Check for JPEG end marker (FF D9)
    if (bytes.length < 2) {
      return DocumentValidationResult(
        isValid: false,
        message: 'JPEG file is too small or corrupted',
        format: DocumentFormat.jpeg,
      );
    }

    // Look for end marker at the end of file
    final endBytes = bytes.sublist(bytes.length - 2);
    if (endBytes[0] != 0xFF || endBytes[1] != 0xD9) {
      return DocumentValidationResult(
        isValid: false,
        message: 'JPEG file appears to be corrupted or incomplete',
        format: DocumentFormat.jpeg,
      );
    }

    return DocumentValidationResult(
      isValid: true,
      message: 'JPEG format is valid',
      format: DocumentFormat.jpeg,
    );
  }

  /// Validate PNG format
  static DocumentValidationResult _validatePng(Uint8List bytes) {
    // Check for PNG end chunk (IEND)
    if (bytes.length < 12) {
      return DocumentValidationResult(
        isValid: false,
        message: 'PNG file is too small or corrupted',
        format: DocumentFormat.png,
      );
    }

    // Look for IEND chunk at the end
    final String fileContent = String.fromCharCodes(bytes);
    if (!fileContent.contains('IEND')) {
      return DocumentValidationResult(
        isValid: false,
        message: 'PNG file appears to be corrupted or incomplete',
        format: DocumentFormat.png,
      );
    }

    return DocumentValidationResult(
      isValid: true,
      message: 'PNG format is valid',
      format: DocumentFormat.png,
    );
  }

  /// Check if document appears to be legible (basic checks)
  static DocumentValidationResult validateLegibility(
    String base64Document,
    DocumentFormat format,
  ) {
    try {
      final bytes = base64Decode(base64Document);

      // For images, do minimal quality checks - let AI handle detailed assessment
      if (format == DocumentFormat.jpeg || format == DocumentFormat.png) {
        // Only check for extremely small images that are likely corrupted
        if (bytes.length < 5 * 1024) { // Less than 5KB (very small, likely corrupted)
          return DocumentValidationResult(
            isValid: false,
            message: 'Image file appears to be corrupted or too small.',
          );
        }
      }

      // For PDFs, check basic structure (very minimal)
      if (format == DocumentFormat.pdf) {
        final String content = String.fromCharCodes(bytes);
        // Check if PDF has some basic content (very minimal check)
        if (content.length < 500) { // Very small PDF, likely corrupted
          return DocumentValidationResult(
            isValid: false,
            message: 'PDF appears to be corrupted or incomplete.',
          );
        }
      }

      // Pass legibility check - let AI handle the actual quality assessment
      return DocumentValidationResult(
        isValid: true,
        message: 'Document format is acceptable',
      );
    } catch (e) {
      return DocumentValidationResult(
        isValid: false,
        message: 'Unable to process document file',
      );
    }
  }
}
