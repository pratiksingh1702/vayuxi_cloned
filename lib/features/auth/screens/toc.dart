import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms & Conditions"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: const Text(
            '''
VAYUXI

Terms & Conditions
Last Updated: January 16, 2025

Welcome to VAYUXI. These Terms and Conditions govern your use of our construction site management application and services.

1. Acceptance of Terms
By creating an account or using VAYUXI ERP services, you agree to be bound by these Terms and our Privacy Policy.

2. Eligibility
• Must be 18+ years old
• Legal capacity to enter contracts
• Provide accurate registration info
• Maintain account security

3. Account Registration & Security
You are responsible for maintaining confidentiality of credentials and all activities under your account.

4. Subscription & Payment
Subscription fees are billed monthly or annually in advance.
We may modify pricing with notice.

5. Use of Services
You may not:
• Violate laws
• Upload malicious content
• Reverse engineer the software
• Share credentials
• Resell services

6. Intellectual Property
All software, content, trademarks belong to VAYUXI ERP Pvt Ltd.

7. Data & Privacy
Use is governed by our Privacy Policy.

8. Service Availability
We do not guarantee uninterrupted or error-free service.

9. Termination
We may suspend accounts for violations or non-payment.

10. Limitation of Liability
Services provided "as is". We are not liable for indirect damages.

11. Governing Law
Governed by laws of India.
Disputes resolved via arbitration in Surat, Gujarat.

Contact:
VAYUXI ERP Pvt Ltd
Email: info@vayuxierp.com
Phone: +91-8320554983
Address: Surat, Gujarat, India

VAYUXI
From Site to Sheet, Simplified.
''',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
      ),
    );
  }
}