import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import '../../models/user_type.dart';
import '../../services/auth_service.dart';
import '../../services/image_service.dart';
import '../../services/barangay_clearance_validator.dart';
import '../../constants/bohol_locations.dart';
import 'login_screen.dart';

// Custom input formatter for Philippine phone numbers
class PhilippinePhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    const prefix = '+63 ';

    // If the text doesn't start with prefix, add it
    if (!newValue.text.startsWith(prefix)) {
      // Extract only digits from the input
      final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
      final limitedDigits =
          digitsOnly.length > 10 ? digitsOnly.substring(0, 10) : digitsOnly;

      return TextEditingValue(
        text: prefix + limitedDigits,
        selection: TextSelection.collapsed(
          offset: prefix.length + limitedDigits.length,
        ),
      );
    }

    // Extract digits after prefix
    final afterPrefix = newValue.text.substring(prefix.length);
    final digitsOnly = afterPrefix.replaceAll(RegExp(r'[^0-9]'), '');

    // Limit to 10 digits maximum
    final limitedDigits =
        digitsOnly.length > 10 ? digitsOnly.substring(0, 10) : digitsOnly;

    return TextEditingValue(
      text: prefix + limitedDigits,
      selection: TextSelection.collapsed(
        offset: prefix.length + limitedDigits.length,
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  final UserType userType;

  const RegisterScreen({super.key, required this.userType});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedSkill;
  String? _selectedExperience;
  String? _selectedLocation;
  String? _profileImageBase64;
  String? _barangayClearanceBase64;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _isLoading = false;
  bool _isValidatingDocument = false;
  BarangayClearanceValidationResult? _validationResult;

  // Focus node for phone number field
  final FocusNode _phoneFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Add listener to phone focus node
    _phoneFocusNode.addListener(() {
      if (_phoneFocusNode.hasFocus && _phoneController.text.isEmpty) {
        setState(() {
          _phoneController.text = '+63 ';
          _phoneController.selection = TextSelection.collapsed(offset: 4);
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  // Pick profile image
  Future<void> _pickProfileImage() async {
    final imageBase64 = await ImageService.showImageSourceDialog(context);
    if (imageBase64 != null) {
      setState(() {
        _profileImageBase64 = imageBase64;
      });
    }
  }

  // Pick Barangay clearance image
  Future<void> _pickBarangayClearance() async {
    final imageBase64 = await ImageService.showImageSourceDialog(context);
    if (imageBase64 != null) {
      setState(() {
        _barangayClearanceBase64 = imageBase64;
        _validationResult = null; // Reset validation result
        _isValidatingDocument = true;
      });

      // Validate the document
      try {
        final result = await BarangayClearanceValidator.validateDocument(imageBase64);
        
        if (mounted) {
          setState(() {
            _validationResult = result;
            _isValidatingDocument = false;
          });

          // Show validation result
          if (result.isValid) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // Show error dialog with detailed information
            _showValidationErrorDialog(result);
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isValidatingDocument = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Validation failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Show validation error dialog
  void _showValidationErrorDialog(BarangayClearanceValidationResult result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Document Validation'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  result.message,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (result.errors.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Issues found:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...result.errors.map((error) => Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.red)),
                        Expanded(child: Text(error)),
                      ],
                    ),
                  )),
                ],
                if (result.warnings.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Warnings:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                  const SizedBox(height: 8),
                  ...result.warnings.map((warning) => Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.orange)),
                        Expanded(child: Text(warning)),
                      ],
                    ),
                  )),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Please ensure your document meets all requirements and try uploading again.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            if (BarangayClearanceValidator.shouldRetryValidation(result))
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _retryValidation();
                },
                child: const Text('Retry Validation'),
              ),
          ],
        );
      },
    );
  }

  // Retry validation
  Future<void> _retryValidation() async {
    if (_barangayClearanceBase64 == null) return;

    setState(() {
      _isValidatingDocument = true;
      _validationResult = null;
    });

    try {
      final result = await BarangayClearanceValidator.validateDocument(_barangayClearanceBase64);
      
      if (mounted) {
        setState(() {
          _validationResult = result;
          _isValidatingDocument = false;
        });

        if (result.isValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _showValidationErrorDialog(result);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValidatingDocument = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Validation failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Handle registration
  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate() && _acceptTerms) {
      try {
        setState(() {
          _isLoading = true;
        });

        // Prepare skills list for Helper
        List<String>? skills;
        if (widget.userType == UserType.helper && _selectedSkill != null) {
          skills = [_selectedSkill!];
        }

        // Register user
        await AuthService.register(
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          password: _passwordController.text,
          userType: widget.userType,
          photoUrl: _profileImageBase64,
          barangayClearance: _barangayClearanceBase64,
          skills: skills,
          experience:
              widget.userType == UserType.helper ? _selectedExperience : null,
          address:
              widget.userType == UserType.employer ? _selectedLocation : null,
        );

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful!')),
          );

          // Navigate to login
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => LoginScreen(userType: widget.userType),
            ),
            (route) => false, // Remove all previous routes
          );
        }
      } catch (e) {
        // Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration failed: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          child:
                              _profileImageBase64 != null
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: ImageService.base64ToImage(
                                      _profileImageBase64,
                                      width: 100,
                                      height: 100,
                                    ),
                                  )
                                  : Icon(
                                    Icons.person,
                                    size: 50,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Create a ${widget.userType == UserType.employer ? 'Employer' : 'Helper'} Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Register to join WeCare community',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 30),
                // Registration Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Name Field
                      _buildTextField(
                        controller: _nameController,
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Email Field
                      _buildTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          } else if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Phone Field
                      _buildTextField(
                        controller: _phoneController,
                        labelText: 'Phone Number',
                        hintText: '+63 1234567890',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        focusNode: _phoneFocusNode,
                        inputFormatters: [PhilippinePhoneFormatter()],
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              value == '+63 ') {
                            return 'Please enter your phone number';
                          } else if (value.length != 14) {
                            // +63 + space + 10 digits
                            return 'Please enter exactly 10 digits after +63';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Helper-specific fields
                      if (widget.userType == UserType.helper) ...[
                        _buildDropdownField(
                          labelText: 'Skills',
                          hintText: 'Select your primary skills',
                          items: const [
                            'Cleaning',
                            'Cooking',
                            'Childcare',
                            'Elderly Care',
                            'Driving',
                            'All-Around',
                          ],
                          value: _selectedSkill,
                          onChanged: (String? value) {
                            setState(() {
                              _selectedSkill = value;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildDropdownField(
                          labelText: 'Experience (Years)',
                          hintText: 'Select years of experience',
                          items: const [
                            'Less than 1',
                            '1-2',
                            '3-5',
                            '5-10',
                            'More than 10',
                          ],
                          value: _selectedExperience,
                          onChanged: (String? value) {
                            setState(() {
                              _selectedExperience = value;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                      // Employer-specific fields
                      if (widget.userType == UserType.employer) ...[
                        _buildLocationDropdown(),
                        const SizedBox(height: 20),
                      ],
                      // NBI Clearance Upload Button - show for both user types
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                                                  child: Column(
                            children: [
                              Text(
                                'Barangay Clearance Upload',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _barangayClearanceBase64 != null
                                  ? Container(
                                    width: 200,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _validationResult?.isValid == true 
                                            ? Colors.green 
                                            : _validationResult != null 
                                                ? Colors.red 
                                                : Colors.grey[400]!,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: ImageService.base64ToImage(
                                            _barangayClearanceBase64,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                        ),
                                        if (_validationResult?.isValid == true)
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        if (_validationResult != null && !_validationResult!.isValid)
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.error,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        if (_isValidatingDocument)
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  )
                                  : Icon(
                                    Icons.description,
                                    size: 60,
                                    color: Colors.grey[400],
                                  ),
                              const SizedBox(height: 12),
                              if (_isValidatingDocument)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 12.0),
                                  child: Text(
                                    'Validating document...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              if (_validationResult != null && !_isValidatingDocument)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _validationResult!.isValid ? Icons.check_circle : Icons.error,
                                        size: 16,
                                        color: _validationResult!.isValid ? Colors.green : Colors.red,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          _validationResult!.isValid 
                                              ? 'Document validated successfully'
                                              : 'Document validation failed',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _validationResult!.isValid ? Colors.green : Colors.red,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ElevatedButton.icon(
                                onPressed: _isValidatingDocument ? null : _pickBarangayClearance,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey[300],
                                ),
                                icon: _isValidatingDocument 
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.upload_file),
                                label: Text(
                                  _isValidatingDocument 
                                      ? 'Validating...'
                                      : _barangayClearanceBase64 != null
                                          ? 'Change Barangay Clearance'
                                          : 'Upload Barangay Clearance',
                                ),
                              ),
                              if (_barangayClearanceBase64 == null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Barangay Clearance is required for verification',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              if (_validationResult != null && _validationResult!.warnings.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    _validationResult!.warnings.first,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          ),
                      ),
                      const SizedBox(height: 20),
                      // Password Field
                      _buildTextField(
                        controller: _passwordController,
                        labelText: 'Password',
                        hintText: 'Create a password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          } else if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Confirm Password Field
                      _buildTextField(
                        controller: _confirmPasswordController,
                        labelText: 'Confirm Password',
                        hintText: 'Confirm your password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          } else if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Terms and Conditions Checkbox
                      CheckboxListTile(
                        value: _acceptTerms,
                        onChanged: (value) {
                          setState(() {
                            _acceptTerms = value ?? false;
                          });
                        },
                        title: Text(
                          'I agree to the Terms of Service and Privacy Policy',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        activeColor: Theme.of(context).colorScheme.primary,
                        checkColor: Colors.white,
                      ),
                      const SizedBox(height: 30),
                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                                                            onPressed:
                              _isLoading || !_acceptTerms || _isValidatingDocument
                                  ? null
                                  : () {
                                    // For both Helper and Employer, require Barangay Clearance
                                    if (_barangayClearanceBase64 == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please upload your Barangay Clearance',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    // Check if document validation passed
                                    if (_validationResult == null || !_validationResult!.isValid) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please upload a valid Barangay Clearance document',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    // For Employer, require barangay selection
                                    if (widget.userType == UserType.employer &&
                                        _selectedLocation == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please select your barangay in Tagbilaran City',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    _handleRegister();
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            disabledForegroundColor: Colors.grey[600],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
                                    'Register',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Login Link
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: 'Log In',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer:
                                    TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => LoginScreen(
                                                  userType: widget.userType,
                                                ),
                                          ),
                                        );
                                      },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      focusNode: focusNode,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(
          prefixIcon,
          color: Theme.of(context).colorScheme.primary,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String labelText,
    required String hintText,
    required List<String> items,
    required Function(String?) onChanged,
    String? value,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
      icon: Icon(
        Icons.arrow_drop_down,
        color: Theme.of(context).colorScheme.primary,
      ),
      dropdownColor: Colors.white,
      style: const TextStyle(color: Colors.black87),
      items:
          items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: TextStyle(color: Colors.black87)),
            );
          }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildLocationDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedLocation,
      decoration: InputDecoration(
        labelText: 'Barangay in Tagbilaran City',
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
        hintText: 'Select your barangay',
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(
          Icons.location_on_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
      icon: Icon(
        Icons.arrow_drop_down,
        color: Theme.of(context).colorScheme.primary,
      ),
      dropdownColor: Colors.white,
      style: const TextStyle(color: Colors.black87),
      items:
          BoholLocations.allLocations.map((String barangay) {
            return DropdownMenuItem<String>(
              value: barangay,
              child: Row(
                children: [
                  Text('Brgy. $barangay', style: const TextStyle(color: Colors.black87)),
                  const SizedBox(width: 4),
                  Text(
                    '(${BoholLocations.getLocationType(barangay)})',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            );
          }).toList(),
      onChanged: (String? value) {
        setState(() {
          _selectedLocation = value;
        });
      },
      validator: (value) {
        if (widget.userType == UserType.employer && value == null) {
          return 'Please select your barangay';
        }
        return null;
      },
    );
  }
}
