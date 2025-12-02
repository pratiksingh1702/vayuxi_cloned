import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/typeProvider/type_provider.dart';

import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/custom.dart';
import '../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../../../core/utlis/widgets/fields/phone_number_field.dart';
import '../../../../../core/utlis/widgets/file_upload.dart';
import '../providers/siteProvider.dart';
import '../repository/siteModel.dart';
import '../providers/site_service.dart';

class SiteDetailScreen extends ConsumerStatefulWidget {
  final SiteModel? site;

  const SiteDetailScreen({super.key, this.site});

  @override
  ConsumerState<SiteDetailScreen> createState() => _SiteDetailScreenState();
}

class _SiteDetailScreenState extends ConsumerState<SiteDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController siteNameController;
  late TextEditingController addressController;
  late TextEditingController contactPersonController;
  late TextEditingController gstNoController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController documentNumberController;
  late TextEditingController dateController;

  File? selectedImage;
  bool isLoading = false;
  DateTime selectedDate = DateTime.now();


  @override
  void initState() {
    super.initState();
    final site = widget.site;
    siteNameController = TextEditingController(text: site?.siteName ?? "");
    addressController = TextEditingController(text: site?.address ?? "");
    contactPersonController = TextEditingController(
      text: site?.contactPerson ?? "",
    );
    gstNoController = TextEditingController(text: site?.gstNo ?? "");
    phoneController = TextEditingController(text: site?.phoneNumber ?? "");
    emailController = TextEditingController(text: site?.emailId ?? "");
    documentNumberController = TextEditingController(
      text: site?.documentNumber ?? "",
    );
    final selectedformattedDate = "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";

    dateController = TextEditingController(text: selectedformattedDate);
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      final formattedDate = "${picked.day}/${picked.month}/${picked.year}";
      setState(() {
        dateController.text = formattedDate;
      });
    }
  }

  Future<void> saveSite() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      // Validate required fields - MOVE VALIDATION BEFORE setState
      _validateFields();

      final formData = FormData.fromMap({
        "siteName": siteNameController.text.trim(),
        "address": addressController.text.trim(),
        "contactPerson": contactPersonController.text.trim(),
        "phoneNumber": phoneController.text.trim(),
        "gstNo": gstNoController.text.trim(),
        "emailId": emailController.text.trim(),
        "documentNumber": documentNumberController.text.trim(),
        "selectedDate": dateController.text,
        "company": widget.site?.company ?? "",
        "type": widget.site?.type ?? "mechanical_work",
      });

      // Validate image

      formData.files.add(
        MapEntry(
          "file",
          await MultipartFile.fromFile(
            selectedImage!.path,
            filename: selectedImage!.path.split('/').last,
          ),
        ),
      );

      if (widget.site == null) {
        final type = ref.read(typeProvider);
        if (type == null || type.isEmpty) {
          throw ValidationException('Site type is required');
        }
        await SiteAPI.createSite(formData, type);
        _showSnackBar('Site created successfully!', isError: false);
      } else {
        await SiteAPI.updateSite(widget.site!.id, formData);
        _showSnackBar('Site updated successfully!', isError: false);
      }

      // Refresh sites list and navigate back
      ref.read(siteProvider.notifier).fetchSites();
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on ValidationException catch (e) {
      // Show validation errors to user
      _showSnackBar(e.message, isError: true);
      debugPrint("VALIDATION ERROR: ${e.message}");
    } on DioException catch (e) {
      // Handle Dio-specific errors
      final userMessage = _handleDioError(e);
      _showSnackBar(userMessage, isError: true);
      debugPrint("API Error: ${e.message}\nStatus: ${e.response?.statusCode}\nData: ${e.response?.data}");
    } catch (e, stack) {
      // Handle any other unexpected errors
      _showSnackBar("An unexpected error occurred. Please try again.", isError: true);
      debugPrint("UNEXPECTED ERROR: $e\nSTACK TRACE: $stack");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

// Helper method to show snackbar - REMOVE mounted check at the beginning
  void _showSnackBar(String message, {bool isError = false}) {
    // Use WidgetsBinding.instance.addPostFrameCallback to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle,
                color: isError ? Colors.red : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: isError ? Colors.red[800] : Colors.green[800],
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: isError ? Colors.red[50] : Colors.green[50],
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: isError ? 4 : 3),
          action: isError
              ? SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.red[800],
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          )
              : null,
        ),
      );
    });
  }

// Extract validation logic to separate method
  void _validateFields() {
    if (siteNameController.text.isEmpty) {
      throw ValidationException('Site name is required');
    }
    if (addressController.text.isEmpty) {
      throw ValidationException('Address is required');
    }
    if (contactPersonController.text.isEmpty) {
      throw ValidationException('Contact person is required');
    }
    if (phoneController.text.isEmpty) {
      throw ValidationException('Phone number is required');
    }

    // Validate phone number format
    final phoneDigits = phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.length != 10) {
      throw ValidationException('Please enter a valid 10-digit phone number');
    }

    // Validate email if provided
    if (emailController.text.isNotEmpty && !EmailValidator.validate(emailController.text)) {
      throw ValidationException('Please enter a valid email address');
    }

    // Validate GST format if provided
    if (gstNoController.text.isNotEmpty && !_isValidGST(gstNoController.text)) {
      throw ValidationException('Please enter a valid GST number');
    }
  }

// Handle Dio errors
  String _handleDioError(DioException e) {
    // Extract server validation errors
    if (e.response?.statusCode == 422 || e.response?.statusCode == 400) {
      final errors = _extractValidationErrors(e.response?.data);
      if (errors.isNotEmpty) {
        // Show first error only to avoid too long messages
        return errors.first;
      } else if (e.response?.data?['message'] != null) {
        return e.response!.data!['message'].toString();
      }
    }

    // Handle specific status codes
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return "Request timeout. Please check your internet connection.";

      case DioExceptionType.connectionError:
        return "No internet connection. Please check your network.";

      case DioExceptionType.badResponse:
        switch (e.response?.statusCode) {
          case 401:
            return "Your session has expired. Please log in again.";
          case 403:
            return "You don't have permission to perform this action.";
          case 404:
            return "Resource not found.";
          case 409:
            return "A site with this name already exists.";
          case 500:
          case 502:
          case 503:
          case 504:
            return "Server is currently unavailable. Please try again later.";
        }
        break;

      case DioExceptionType.cancel:
        return "Request was cancelled.";

      case DioExceptionType.badCertificate:
        return "Security certificate error. Please contact support.";

      default:
        return "Failed to save site. Please try again.";
    }

    return "Failed to save site. Please try again.";
  }

// Helper method to extract validation errors from server response
  List<String> _extractValidationErrors(dynamic responseData) {
    final List<String> errors = [];

    try {
      if (responseData is Map<String, dynamic>) {
        if (responseData['errors'] != null) {
          if (responseData['errors'] is Map<String, dynamic>) {
            for (final entry in (responseData['errors'] as Map<String, dynamic>).entries) {
              if (entry.value is List) {
                for (final error in (entry.value as List)) {
                  errors.add("${entry.key}: ${error.toString()}");
                }
              } else {
                errors.add("${entry.key}: ${entry.value.toString()}");
              }
            }
          } else if (responseData['errors'] is List) {
            for (final error in (responseData['errors'] as List)) {
              errors.add(error.toString());
            }
          }
        } else if (responseData['message'] != null) {
          errors.add(responseData['message'].toString());
        }
      }
    } catch (e) {
      debugPrint("Error parsing validation errors: $e");
    }

    return errors;
  }

// Helper method to show success snackbar
  void showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[50],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

// Helper method to show error snackbar
  void showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red[50],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

// GST validation helper
  bool _isValidGST(String gst) {
    // Basic GST validation - adjust based on your country's GST format
    final gstRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
    return gstRegex.hasMatch(gst.toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    final site = widget.site;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [CustomSliverAppBar(title: site?.siteName ?? "New Site")];
        },
        body: BottomButtonWrapper(
          customButtons: [
            CustomButton(
              button: RoundedButton(
                text: "Save & Submit",
                color: Colors.blue,
                textColor: Colors.white,
                onPressed: saveSite,
              ),
            ),
          ],
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Image Upload
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      "Upload Image",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  UploadBox(
                    title: "Select Site Image",
                    subtitle: "Upload file (XLS, CSV, HTML (MAX 10MB))",
                    buttonText: "Choose File",
                    onPressed: () {
                      pickImage(); // reuse your existing image picker logic here
                    },
                  ),

                  const SizedBox(height: 24),

                  const SizedBox(height: 12),
                  CustomTextField(
                    label: "Site Name",
                    controller: siteNameController,
                    TextSize: 22,
                  ),
                  CustomTextField(
                    label: "GST Number",
                    controller: gstNoController,
                    TextSize: 22,
                  ),
                  CustomTextField(
                    label: "Address",
                    controller: addressController,
                    TextSize: 22,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 24),

                  CustomTextField(
                    label: "Contact Person",
                    controller: contactPersonController,
                    TextSize: 22,
                  ),
                  PhoneInputField(controller: phoneController),
                  CustomTextField(
                    label: "Email ID",
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    TextSize: 22,
                  ),

                  const SizedBox(height: 12),

                  // Date Selection Field
                  GestureDetector(
                    onTap: _selectDate,
                    child: AbsorbPointer(
                      child: CustomTextField(
                        label: "Select Date",
                        controller: dateController,
                        TextSize: 22,
                        prefixIcon: Icon(Icons.calendar_today, color: Colors.grey[600]),
                        hint: "DD/MM/YYYY",
                      ),
                    ),
                  ),

                  CustomTextField(
                    label: "AMC Number",
                    controller: documentNumberController,
                    TextSize: 22,
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);

  @override
  String toString() => message;
}

// Email validator class
class EmailValidator {
  static bool validate(String email) {
    return RegExp(
        r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+'
    ).hasMatch(email);
  }
}