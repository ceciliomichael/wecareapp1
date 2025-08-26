import 'package:flutter/material.dart';
import 'document_format_validator.dart';
import 'gemini_ai_service.dart';

class BarangayClearanceValidationResult {
  final bool isValid;
  final String message;
  final List<String> errors;
  final List<String> warnings;
  final DocumentFormat? format;
  final bool hasRequiredContent;
  final String? extractedName;
  final String? extractedAddress;
  final bool hasBarangayLogo;

  BarangayClearanceValidationResult({
    required this.isValid,
    required this.message,
    required this.errors,
    required this.warnings,
    this.format,
    required this.hasRequiredContent,
    this.extractedName,
    this.extractedAddress,
    required this.hasBarangayLogo,
  });
}

class BarangayClearanceValidator {
  /// Comprehensive validation of barangay clearance document
  static Future<BarangayClearanceValidationResult> validateDocument(
    String? base64Document,
  ) async {
    final List<String> errors = [];
    final List<String> warnings = [];
    
    try {
      // Step 1: Basic format validation
      final formatValidation = DocumentFormatValidator.validateFormat(base64Document);
      
      if (!formatValidation.isValid) {
        errors.add(formatValidation.message);
        return BarangayClearanceValidationResult(
          isValid: false,
          message: 'Document format validation failed',
          errors: errors,
          warnings: warnings,
          hasRequiredContent: false,
          hasBarangayLogo: false,
        );
      }

      final DocumentFormat format = formatValidation.format!;

      // Step 2: Legibility check (minimal - let AI handle quality)
      final legibilityValidation = DocumentFormatValidator.validateLegibility(
        base64Document!,
        format,
      );

      if (!legibilityValidation.isValid) {
        errors.add(legibilityValidation.message);
        // If basic legibility fails, don't proceed to AI validation
        return BarangayClearanceValidationResult(
          isValid: false,
          message: 'Document file validation failed',
          errors: errors,
          warnings: warnings,
          format: format,
          hasRequiredContent: false,
          hasBarangayLogo: false,
        );
      }

      // Step 3: AI-powered content validation
      DocumentContentValidation contentValidation;
      try {
        contentValidation = await GeminiAiService.validateBarangayClearanceContent(
          base64Document,
          format,
        );
      } catch (e) {
        debugPrint('AI validation failed: $e');
        // Fallback to basic validation if AI fails
        contentValidation = DocumentContentValidation(
          isValid: false,
          message: 'AI validation service is temporarily unavailable. Please try again later.',
          hasName: false,
          hasAddress: false,
          hasBarangayLogo: false,
        );
        errors.add(contentValidation.message);
      }

      // Step 4: Compile validation results
      final bool hasRequiredContent = contentValidation.hasName && contentValidation.hasAddress;
      
      // Add content validation errors
      if (!contentValidation.isValid) {
        if (!contentValidation.hasName && !contentValidation.hasAddress) {
          errors.add('Document is missing required information: name and address');
        } else if (!contentValidation.hasName) {
          errors.add('Document is missing required information: name');
        } else if (!contentValidation.hasAddress) {
          errors.add('Document is missing required information: address');
        } else {
          errors.add(contentValidation.message);
        }
      }

      // Add warnings for optional elements
      if (!contentValidation.hasBarangayLogo) {
        warnings.add('No barangay logo detected (optional but recommended)');
      }

      // Step 5: Determine overall validation result
      final bool isOverallValid = formatValidation.isValid && 
                                 legibilityValidation.isValid && 
                                 contentValidation.isValid;

      String finalMessage;
      if (isOverallValid) {
        finalMessage = 'Barangay clearance document validation successful';
      } else if (errors.length == 1) {
        finalMessage = errors.first;
      } else {
        finalMessage = 'Document validation failed with ${errors.length} issues';
      }

      return BarangayClearanceValidationResult(
        isValid: isOverallValid,
        message: finalMessage,
        errors: errors,
        warnings: warnings,
        format: format,
        hasRequiredContent: hasRequiredContent,
        extractedName: contentValidation.extractedName,
        extractedAddress: contentValidation.extractedAddress,
        hasBarangayLogo: contentValidation.hasBarangayLogo,
      );

    } catch (e) {
      debugPrint('Unexpected error during document validation: $e');
      errors.add('An unexpected error occurred during validation');
      
      return BarangayClearanceValidationResult(
        isValid: false,
        message: 'Document validation failed due to an unexpected error',
        errors: errors,
        warnings: warnings,
        hasRequiredContent: false,
        hasBarangayLogo: false,
      );
    }
  }

  /// Quick format-only validation (for immediate feedback)
  static DocumentValidationResult quickFormatValidation(String? base64Document) {
    return DocumentFormatValidator.validateFormat(base64Document);
  }

  /// Get validation requirements description
  static String getValidationRequirements() {
    return '''
Barangay Clearance Document Requirements:

Required Elements:
• Valid file format (PDF, JPEG, or PNG)
• Clear and legible document
• Person's full name
• Complete address
• Maximum file size: 10MB

Optional Elements:
• Barangay logo or official seal (recommended)

Supported Formats:
• PDF documents
• JPEG images (.jpg, .jpeg)
• PNG images (.png)

Quality Guidelines:
• Ensure text is clearly readable
• Avoid blurry or low-resolution images
• Make sure the entire document is visible
• Use good lighting when taking photos
''';
  }

  /// Get format-specific tips
  static String getFormatTips(DocumentFormat format) {
    switch (format) {
      case DocumentFormat.pdf:
        return '''
PDF Document Tips:
• Ensure the PDF is not corrupted
• Text should be selectable when possible
• Avoid password-protected PDFs
• Keep file size under 10MB
''';
      case DocumentFormat.jpeg:
        return '''
JPEG Image Tips:
• Use good lighting when photographing
• Keep the camera steady to avoid blur
• Ensure the entire document is in frame
• Use the highest quality setting on your camera
''';
      case DocumentFormat.png:
        return '''
PNG Image Tips:
• PNG format preserves text clarity
• Avoid compression that reduces quality
• Ensure good contrast between text and background
• Keep the entire document visible in the image
''';
      case DocumentFormat.unknown:
        return '''
Unsupported Format:
• Please use PDF, JPEG, or PNG formats only
• Convert your document to a supported format
• Ensure the file is not corrupted
''';
    }
  }

  /// Check if validation should be retried
  static bool shouldRetryValidation(BarangayClearanceValidationResult result) {
    // Retry if there were network/API errors but format is valid
    return !result.isValid && 
           result.format != null && 
           result.errors.any((error) => 
             error.contains('temporarily unavailable') ||
             error.contains('try again') ||
             error.contains('network') ||
             error.contains('API')
           );
  }
}
