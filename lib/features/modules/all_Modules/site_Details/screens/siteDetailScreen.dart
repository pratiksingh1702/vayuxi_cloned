import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';

import '../../../../../core/utlis/widgets/buttons.dart';
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

  File? selectedImage;
  bool isLoading = false;

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
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => selectedImage = File(pickedFile.path));
    }
  }

  Future<void> saveSite() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      final formData = FormData.fromMap({
        "siteName": siteNameController.text,
        "address": addressController.text,
        "contactPerson": contactPersonController.text,
        "phoneNumber": phoneController.text,
        "gstNo": gstNoController.text,
        "emailId": emailController.text,
        "documentNumber": documentNumberController.text,
        "company": widget.site?.company ?? "",
        "type": widget.site?.type ?? "mechanical_work",
      });

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
        // await SiteAPI.createSite(formData);
      } else {
        await SiteAPI.updateSite(widget.site!.id, formData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Site saved successfully!")),
        );
        ref.read(siteProvider.notifier).fetchSites();
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final site = widget.site;

    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title: site?.siteName ?? "New Site"),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Image Upload
              Align(
                alignment: Alignment.topLeft,
                child: Text("Upload Image"
                ,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),)
                ,
              ),
              UploadBox(
                title: "Rate.XLS",
                subtitle: "Upload file\nXLS, CSV, HTML (MAX 10MB)",
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
              CustomTextField(label: "GST Number", controller: gstNoController,TextSize: 22,),
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
              CustomTextField(
                label: "AMC Number",
                controller: documentNumberController,
                TextSize: 22,
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  RoundedButton(
                    text: "Back",
                    color: Colors.black,
                    textColor: Colors.black,
                    isOutlined: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  RoundedButton(
                    text: "Save & Submit",
                    color: Colors.blue,
                    textColor: Colors.white,
                    onPressed: saveSite,
                  ),
                ],
              )

            ],
          ),
        ),
      ),
    );
  }
}
