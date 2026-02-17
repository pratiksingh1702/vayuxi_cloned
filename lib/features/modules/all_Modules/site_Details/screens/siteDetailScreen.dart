import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/typeProvider/type_provider.dart';

import '../../../../../core/utlis/app_toasts.dart';
import '../../../../../core/utlis/common_functions.dart';
import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/custom.dart';
import '../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../../../core/utlis/widgets/fields/phone_number_field.dart';
import '../../../../../core/utlis/widgets/file_upload.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../tour/domain/tour_controller.dart';
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
  late TextEditingController shippingAddressController;


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
print(_formatDocumentDate(site?.documentDate));


    dateController = TextEditingController(
      text: _formatDocumentDate(site?.documentDate),
    );
    shippingAddressController =
        TextEditingController(text: site?.shippingAddress ?? "");

  }
  String _formatDocumentDate(String? documentDate) {
    try {
      if (documentDate == null || documentDate.isEmpty) {
        final now = DateTime.now();
        return "${now.day}/${now.month}/${now.year}";
      }

      final parsed = DateTime.parse(documentDate); // expects ISO
      return "${parsed.day}/${parsed.month}/${parsed.year}";
    } catch (_) {
      // fallback if backend sends garbage
      final now = DateTime.now();
      return "${now.day}/${now.month}/${now.year}";
    }
  }


  Future<void> pickImage() async {
    final helper = ImageUploadHelper(context);
    final file = await helper.pickAndCropImage(
      enableCropping: true,
      cropTitle: 'Crop Site Image',
    );

    if (file != null) {
      setState(() => selectedImage = file);
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
        "shippingAddress": shippingAddressController.text.trim(), // ✅ NEW
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

      if (selectedImage != null) {
        formData.files.add(
          MapEntry(
            "file",
            await MultipartFile.fromFile(
              selectedImage!.path,
              filename: selectedImage!.path.split('/').last,
            ),
          ),
        );
      }


      if (widget.site == null) {
        final type = ref.read(typeProvider);
        if (type == null || type.isEmpty) {
          throw ValidationException('Site type is required');
        }
        await SiteAPI.createSite(formData, type);
        await ref.read(tourPersistenceProvider).markSiteDone();
        AppToast.success("Site creation Successful ✅");

        // _showSnackBar('Site created successfully!', isError: false);
      } else {
        await SiteAPI.updateSite(widget.site!.id, formData);
        _showSnackBar('Site updated successfully!', isError: false);
      }

      // Refresh sites list and navigate back
      ref.read(siteProvider.notifier).fetchSites();
      if (mounted) {
        Navigator.pop(context, true);
        context.push("/site-list/site");
      }
    } on ValidationException catch (e) {
      // Show validation errors to user
      _showSnackBar(e.message, isError: true);
      debugPrint("VALIDATION ERROR: ${e.message}");
    } on DioException catch (e) {
      // Handle Dio-specific errors
      final userMessage = extractBackendError(e);
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (isError) {
        AppToast.error(message);
      } else {
        AppToast.success(message);
      }
    });
  }

// Extract validation logic to separate method
  void _validateFields() {
    if (siteNameController.text.isEmpty) {
      throw ValidationException('Site name is required');
    }




    // Validate email if provided
    if ( !EmailValidator.validate(emailController.text)&&emailController.text.isNotEmpty) {
      throw ValidationException('Please enter a valid email address');
    }


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
 AppToast.success(message);
  }

// Helper method to show error snackbar
  void showErrorSnackBar(String message) {
    if (!mounted) return;
    final error=extractBackendError(message);
  AppToast.error(error);
  }

// GST validation helper
  bool _isValidGST(String gst) {
    // Basic GST validation - adjust based on your country's GST format
    final gstRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
    return gstRegex.hasMatch(gst.toUpperCase());
  }
  Future<void> _confirmDeleteSite() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Site"),
        content: const Text(
          "Are you sure you want to delete this site?\n\n"
              "This action cannot be undone and all related data may be lost.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deleteSite();
    }
  }
  Future<void> _deleteSite() async {
    try {
      setState(() => isLoading = true);

      await SiteAPI.delete(widget.site!.id);

      // refresh list
      ref.read(siteProvider.notifier).fetchSites();

      if (!mounted) return;

      _showSnackBar("Site deleted successfully!", isError: false);

      Navigator.pop(context); // leave detail screen


    } on DioException catch (e) {
      final msg = extractBackendError(e);
      _showSnackBar(msg, isError: true);
    } catch (e) {
      _showSnackBar("Failed to delete site", isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    final site = widget.site;

    return Scaffold(
      drawer: const CustomDrawer(),
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
                  if (widget.site != null) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text(
                          "Delete Site",
                          style: TextStyle(color: Colors.red, fontSize: 16),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _confirmDeleteSite,
                      ),
                    ),
                  ],

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
                  subtitle: "Tap to select and crop image",
                  buttonText: "Choose File",
                  onPressed: pickImage,
                  selectedFile: selectedImage,
                  previewWidget: selectedImage != null
                      ? UploadBoxPreview(
                    file: selectedImage!,
                    isImage: true,
                    onRemove: () => setState(() => selectedImage = null),
                    onEdit: pickImage,
                  )
                      : null,
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
                  CustomTextField(
                    label: "Shipping Address",
                    controller: shippingAddressController,
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