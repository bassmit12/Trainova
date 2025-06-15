import 'package:flutter/material.dart';
import '../utils/error_handler.dart';

/// Validation result containing success status and error message
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? suggestion;

  ValidationResult.success()
    : isValid = true,
      errorMessage = null,
      suggestion = null;

  ValidationResult.error(this.errorMessage, {this.suggestion})
    : isValid = false;

  bool get hasError => !isValid;
}

/// Comprehensive validation utilities for the application
class AppValidator {
  /// Validate email address
  static ValidationResult validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return ValidationResult.error(
        'Email is required',
        suggestion: 'Please enter your email address',
      );
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email.trim())) {
      return ValidationResult.error(
        'Invalid email format',
        suggestion:
            'Please enter a valid email address (e.g., user@example.com)',
      );
    }

    return ValidationResult.success();
  }

  /// Validate password strength
  static ValidationResult validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return ValidationResult.error(
        'Password is required',
        suggestion: 'Please enter a password',
      );
    }

    if (password.length < 8) {
      return ValidationResult.error(
        'Password too short',
        suggestion: 'Password must be at least 8 characters long',
      );
    }

    if (password.length > 128) {
      return ValidationResult.error(
        'Password too long',
        suggestion: 'Password must be less than 128 characters',
      );
    }

    // Check for at least one uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return ValidationResult.error(
        'Password must contain uppercase letter',
        suggestion: 'Include at least one uppercase letter (A-Z)',
      );
    }

    // Check for at least one lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) {
      return ValidationResult.error(
        'Password must contain lowercase letter',
        suggestion: 'Include at least one lowercase letter (a-z)',
      );
    }

    // Check for at least one digit
    if (!password.contains(RegExp(r'[0-9]'))) {
      return ValidationResult.error(
        'Password must contain number',
        suggestion: 'Include at least one number (0-9)',
      );
    }

    return ValidationResult.success();
  }

  /// Validate workout name
  static ValidationResult validateWorkoutName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return ValidationResult.error(
        'Workout name is required',
        suggestion: 'Please enter a name for your workout',
      );
    }

    if (name.trim().length < 3) {
      return ValidationResult.error(
        'Workout name too short',
        suggestion: 'Name must be at least 3 characters long',
      );
    }

    if (name.trim().length > 50) {
      return ValidationResult.error(
        'Workout name too long',
        suggestion: 'Name must be less than 50 characters',
      );
    }

    // Check for inappropriate characters
    if (name.contains(RegExp(r'[<>{}[\]\\\/]'))) {
      return ValidationResult.error(
        'Invalid characters in name',
        suggestion:
            'Name cannot contain special characters like < > { } [ ] \\ /',
      );
    }

    return ValidationResult.success();
  }

  /// Validate exercise sets
  static ValidationResult validateSets(String? sets) {
    if (sets == null || sets.trim().isEmpty) {
      return ValidationResult.error(
        'Sets is required',
        suggestion: 'Please enter the number of sets',
      );
    }

    final setsInt = int.tryParse(sets.trim());
    if (setsInt == null) {
      return ValidationResult.error(
        'Invalid number format',
        suggestion: 'Please enter a valid whole number',
      );
    }

    if (setsInt < 1) {
      return ValidationResult.error(
        'Sets must be positive',
        suggestion: 'Number of sets must be at least 1',
      );
    }

    if (setsInt > 20) {
      return ValidationResult.error(
        'Too many sets',
        suggestion: 'Number of sets should be 20 or less',
      );
    }

    return ValidationResult.success();
  }

  /// Validate exercise reps
  static ValidationResult validateReps(String? reps) {
    if (reps == null || reps.trim().isEmpty) {
      return ValidationResult.error(
        'Reps is required',
        suggestion: 'Please enter the number of repetitions',
      );
    }

    final repsInt = int.tryParse(reps.trim());
    if (repsInt == null) {
      return ValidationResult.error(
        'Invalid number format',
        suggestion: 'Please enter a valid whole number',
      );
    }

    if (repsInt < 1) {
      return ValidationResult.error(
        'Reps must be positive',
        suggestion: 'Number of reps must be at least 1',
      );
    }

    if (repsInt > 100) {
      return ValidationResult.error(
        'Too many reps',
        suggestion: 'Number of reps should be 100 or less',
      );
    }

    return ValidationResult.success();
  }

  /// Validate weight input
  static ValidationResult validateWeight(String? weight) {
    if (weight == null || weight.trim().isEmpty) {
      return ValidationResult.error(
        'Weight is required',
        suggestion: 'Please enter the weight amount',
      );
    }

    final weightDouble = double.tryParse(weight.trim());
    if (weightDouble == null) {
      return ValidationResult.error(
        'Invalid weight format',
        suggestion: 'Please enter a valid number (e.g., 45.5)',
      );
    }

    if (weightDouble < 0) {
      return ValidationResult.error(
        'Weight cannot be negative',
        suggestion: 'Please enter a positive weight value',
      );
    }

    if (weightDouble > 1000) {
      return ValidationResult.error(
        'Weight too high',
        suggestion: 'Weight should be less than 1000 kg/lbs',
      );
    }

    return ValidationResult.success();
  }

  /// Validate URL format
  static ValidationResult validateUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return ValidationResult.error(
        'URL is required',
        suggestion: 'Please enter a URL',
      );
    }

    try {
      final uri = Uri.parse(url.trim());
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        return ValidationResult.error(
          'Invalid URL format',
          suggestion: 'URL must start with http:// or https://',
        );
      }

      if (!uri.hasAuthority) {
        return ValidationResult.error(
          'Invalid URL format',
          suggestion: 'URL must include a domain name',
        );
      }

      return ValidationResult.success();
    } catch (e) {
      return ValidationResult.error(
        'Invalid URL format',
        suggestion: 'Please enter a valid URL (e.g., https://example.com)',
      );
    }
  }

  /// Validate user age
  static ValidationResult validateAge(String? age) {
    if (age == null || age.trim().isEmpty) {
      return ValidationResult.error(
        'Age is required',
        suggestion: 'Please enter your age',
      );
    }

    final ageInt = int.tryParse(age.trim());
    if (ageInt == null) {
      return ValidationResult.error(
        'Invalid age format',
        suggestion: 'Please enter a whole number',
      );
    }

    if (ageInt < 13) {
      return ValidationResult.error(
        'Age too young',
        suggestion: 'You must be at least 13 years old to use this app',
      );
    }

    if (ageInt > 120) {
      return ValidationResult.error(
        'Invalid age',
        suggestion: 'Please enter a valid age',
      );
    }

    return ValidationResult.success();
  }

  /// Validate user height
  static ValidationResult validateHeight(double? height, String unit) {
    if (height == null || height <= 0) {
      return ValidationResult.error(
        'Height is required',
        suggestion: 'Please enter your height',
      );
    }

    if (unit.toLowerCase() == 'cm') {
      if (height < 100 || height > 250) {
        return ValidationResult.error(
          'Invalid height',
          suggestion: 'Height should be between 100-250 cm',
        );
      }
    } else if (unit.toLowerCase() == 'ft' || unit.toLowerCase() == 'feet') {
      if (height < 3 || height > 8) {
        return ValidationResult.error(
          'Invalid height',
          suggestion: 'Height should be between 3-8 feet',
        );
      }
    }

    return ValidationResult.success();
  }

  /// Validate user weight
  static ValidationResult validateUserWeight(double? weight, String unit) {
    if (weight == null || weight <= 0) {
      return ValidationResult.error(
        'Weight is required',
        suggestion: 'Please enter your weight',
      );
    }

    if (unit.toLowerCase() == 'kg') {
      if (weight < 30 || weight > 300) {
        return ValidationResult.error(
          'Invalid weight',
          suggestion: 'Weight should be between 30-300 kg',
        );
      }
    } else if (unit.toLowerCase() == 'lbs' || unit.toLowerCase() == 'pounds') {
      if (weight < 66 || weight > 660) {
        return ValidationResult.error(
          'Invalid weight',
          suggestion: 'Weight should be between 66-660 lbs',
        );
      }
    }

    return ValidationResult.success();
  }

  /// Validate that at least one item is selected from a list
  static ValidationResult validateSelection<T>(
    List<T> selectedItems,
    String fieldName,
  ) {
    if (selectedItems.isEmpty) {
      return ValidationResult.error(
        '$fieldName selection required',
        suggestion: 'Please select at least one $fieldName',
      );
    }

    return ValidationResult.success();
  }

  /// Validate text length within bounds
  static ValidationResult validateTextLength(
    String? text,
    String fieldName, {
    int minLength = 1,
    int maxLength = 255,
  }) {
    if (text == null || text.trim().isEmpty) {
      return ValidationResult.error(
        '$fieldName is required',
        suggestion: 'Please enter $fieldName',
      );
    }

    final trimmedText = text.trim();
    if (trimmedText.length < minLength) {
      return ValidationResult.error(
        '$fieldName too short',
        suggestion: '$fieldName must be at least $minLength characters long',
      );
    }

    if (trimmedText.length > maxLength) {
      return ValidationResult.error(
        '$fieldName too long',
        suggestion: '$fieldName must be less than $maxLength characters',
      );
    }

    return ValidationResult.success();
  }
}

/// Form validator widget that provides real-time validation feedback
class ValidatedTextFormField extends StatefulWidget {
  final String? initialValue;
  final String? labelText;
  final String? hintText;
  final ValidationResult Function(String?) validator;
  final Function(String)? onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextEditingController? controller;
  final int? maxLines;
  final int? maxLength;

  const ValidatedTextFormField({
    super.key,
    this.initialValue,
    this.labelText,
    this.hintText,
    required this.validator,
    this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.controller,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  State<ValidatedTextFormField> createState() => _ValidatedTextFormFieldState();
}

class _ValidatedTextFormFieldState extends State<ValidatedTextFormField> {
  ValidationResult? _currentValidation;
  bool _hasBeenTouched = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: widget.initialValue,
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
            errorText:
                _hasBeenTouched && _currentValidation?.hasError == true
                    ? _currentValidation?.errorMessage
                    : null,
            suffixIcon:
                _hasBeenTouched
                    ? Icon(
                      _currentValidation?.isValid == true
                          ? Icons.check_circle
                          : Icons.error,
                      color:
                          _currentValidation?.isValid == true
                              ? Colors.green
                              : Colors.red,
                    )
                    : null,
          ),
          onChanged: (value) {
            setState(() {
              _hasBeenTouched = true;
              _currentValidation = widget.validator(value);
            });
            widget.onChanged?.call(value);
          },
          validator: (value) {
            final result = widget.validator(value);
            return result.hasError ? result.errorMessage : null;
          },
        ),
        if (_hasBeenTouched && _currentValidation?.suggestion != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _currentValidation!.suggestion!,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
      ],
    );
  }
}
