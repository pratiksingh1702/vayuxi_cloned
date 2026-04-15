# 📱 Phone OTP Authentication Migration Guide
## From Email OTP → Phone OTP (Full System)

> **Purpose**: This guide is written for an AI assistant to implement the migration step-by-step.
> Every section is self-contained. Read each section fully before touching any code.

---

## 📋 TABLE OF CONTENTS

1. [What We Are Changing and Why](#1-what-we-are-changing-and-why)
2. [Backend API Contract](#2-backend-api-contract)
3. [File-by-File Change Map](#3-file-by-file-change-map)
4. [Step 1 — AuthState & AuthNotifier](#step-1--authstate--authnotifier)
5. [Step 2 — AuthAPI Client](#step-2--authapi-client)
6. [Step 3 — RegisterScreen (UI)](#step-3--registerscreen-ui)
7. [Step 4 — LoginScreen (UI)](#step-4--loginscreen-ui)
8. [Step 5 — DioClient Token/Cookie Handling](#step-5--dioclient-tokencookie-handling)
9. [Step 6 — AppAccess & Boot Sequence](#step-6--appaccess--boot-sequence)
10. [Step 7 — DeviceId Flow](#step-7--deviceid-flow)
11. [Step 8 — Testing Checklist](#step-8--testing-checklist)
12. [Common Pitfalls](#common-pitfalls)
13. [Copy-Paste Prompt for AI](#copy-paste-prompt-for-ai)

---

## 1. What We Are Changing and Why

### Current System (Email OTP)
```
Login:    email → send OTP → verify OTP → JWT token
Register: fullName + phone + email → verify email OTP → register → JWT token
```

### Target System (Phone OTP)
```
Login (existing user):   phone → send OTP → verify OTP → JWT token (login complete)
Register (new user):     phone → send OTP → verify OTP → JWT token (partial user)
                         → complete-profile (fullName + email + companyName) → final JWT token
```

### Key Differences
| Aspect | Email (Old) | Phone (New) |
|--------|-------------|-------------|
| Primary identifier | Email address | Phone number (10 digits) |
| OTP delivery | Email | SMS via 2factor.in |
| Registration step | One step | Two steps (OTP first, profile second) |
| New user flag | N/A | `isNewUser: true` in verify-otp response |
| Company creation | Manual | Auto-created on profile completion |
| Grace period | N/A | 24hr to complete profile |
| Session | JWT token only | JWT token + sessionId |
| Token return | `res['token']['token']` | `res['token']['token']` (same path) |

---

## 2. Backend API Contract

Read this section carefully. These are the EXACT request/response shapes.

### 2.1 Send OTP
```
POST /api/v1/auth/send-otp
Content-Type: application/json

Body:
{
  "phoneNumber": "9876543210"   // 10 digits, no country code
}

Response 200:
{
  "message": "OTP sent successfully",
  "sessionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "expiresIn": 600,             // 10 minutes in seconds
  "isExistingUser": true/false  // tells UI what flow to show
}

Response 400:
{
  "error": "Phone number must be 10 digits"
}
```

### 2.2 Verify OTP
```
POST /api/v1/auth/verify-otp
Content-Type: application/json

Body:
{
  "phoneNumber": "9876543210",
  "otp": "1234"                 // 4-digit OTP received on phone
}

Response 200 (NEW USER):
{
  "message": "Registration successful. Please complete your profile within 24 hours.",
  "user": {
    "_id": "...",
    "phoneNumber": "9876543210",
    "isPhoneVerified": true
  },
  "token": {
    "token": "eyJhbGci..."       // JWT — SAME nested path as before
  },
  "isNewUser": true,
  "requiresProfileCompletion": true,
  "gracePeriodEndsAt": "2024-04-15T..."
}

Response 200 (EXISTING USER - LOGIN COMPLETE):
{
  "message": "Login successful",
  "user": {
    "_id": "...",
    "phoneNumber": "9876543210",
    "fullName": "John Doe",
    "email": "john.doe@example.com",
    "company": { "_id": "...", "name": "John Construction Co" }
  },
  "token": {
    "token": "eyJhbGci..."
  },
  "isNewUser": false,
  "requiresProfileCompletion": false
}

Response 400:
{
  "error": "Invalid OTP"
}
```

### 2.3 Complete Profile (New Users Only)
```
POST /api/v1/auth/complete-profile
Content-Type: application/json
Authorization: Bearer <token-from-verify-otp>

Body:
{
  "fullName": "John Doe",
  "email": "john.doe@example.com",
  "companyName": "John Construction Co"   // optional
}

Response 200:
{
  "message": "Profile completed successfully",
  "user": {
    "_id": "...",
    "phoneNumber": "9876543210",
    "fullName": "John Doe",
    "email": "john.doe@example.com",
    "company": { "_id": "...", "name": "John Construction Co" }
  },
  "token": {
    "token": "eyJhbGci..."               // NEW token — replace old one
  }
}

Response 401:
{
  "error": "Unauthorized"               // no/invalid Bearer token
}

Response 409:
{
  "error": "Email already exists"
}
```

### ⚠️ Critical Token Notes
- Token is ALWAYS at `res['token']['token']` — this nesting did NOT change
- After `complete-profile`, the token changes — you MUST save the new token
- Token should be saved to SharedPreferences key `'auth_token'`
- Token is sent via `Authorization: Bearer <token>` header (DioClient interceptor handles this)

---

## 3. File-by-File Change Map

```
lib/
├── features/
│   └── auth/
│       ├── service/
│       │   └── auth_client.dart        ← ADD: sendPhoneOtp(), verifyPhoneOtp(), completeProfile()
│       │                                  REMOVE: generateLoginOtp(), verifyLoginOtp(), generateEmailOtp(), verifyEmailOtp()
│       ├── provider/
│       │   └── auth_provider.dart      ← MODIFY: loginWithPhoneOtp(), register() rewrite
│       └── screens/
│           ├── login_screen.dart       ← REWRITE: phone input, OTP, no email
│           └── register_screen.dart    ← REWRITE: phone OTP first, then profile form
└── core/
    └── api/
        └── dio.dart                    ← NO CHANGE NEEDED (interceptor already handles token)
```

---

## STEP 1 — AuthState & AuthNotifier

**File**: `lib/features/auth/provider/auth_provider.dart`

### What Changes in AuthState
No structural changes needed. `AuthState` already has all required fields.

### What Changes in AuthNotifier

#### A. Replace `loginWithOtp(email, otp)` with `loginWithPhoneOtp(phoneNumber, otp)`

**Old method**:
```dart
Future<void> loginWithOtp(String email, String otp) async {
  // ...
  final res = await AuthAPI.verifyLoginOtp(email, otp);
  // ...
}
```

**New method**:
```dart
Future<Map<String, dynamic>> loginWithPhoneOtp(String phoneNumber, String otp) async {
  print("🔐 USER LOGIN WITH PHONE OTP - Starting");
  state = state.copyWith(isLoading: true, errorMessage: null);

  try {
    final res = await AuthAPI.verifyPhoneOtp(phoneNumber, otp);
    final token = res['token']?['token'] ?? "";
    final isNewUser = res['isNewUser'] == true;

    if (token.isEmpty) throw Exception("No token returned");

    // Always save the token
    await saveLogin(token);

    if (!isNewUser) {
      // Existing user — full login, load user data
      final userData = await AuthAPI.getCurrentUser();
      final user = User.fromJson(userData);
      await saveUserLogin(token, user);

      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        role: 'user',
        user: user,
        errorMessage: null,
      );
      await ref.read(appAccessProvider.notifier).initialize();
    } else {
      // New user — partial state, needs profile completion
      // Save phone in a minimal User or just keep isLoading: false
      // DO NOT call appAccessProvider.initialize() yet
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: false,    // Not fully logged in until profile is complete
        errorMessage: null,
      );
    }

    // Return full response so the UI can check isNewUser
    return res;
  } catch (e) {
    print("🔐 USER LOGIN WITH PHONE OTP - Error: $e");
    state = state.copyWith(
      isLoading: false,
      isLoggedIn: false,
      errorMessage: _getErrorMessage(e),
    );
    rethrow;
  }
}
```

#### B. Add `completeProfile(fullName, email, companyName)` method

```dart
Future<void> completeProfile({
  required String fullName,
  required String email,
  String? companyName,
}) async {
  print("🔐 COMPLETE PROFILE - Starting");
  state = state.copyWith(isLoading: true, errorMessage: null);

  try {
    final res = await AuthAPI.completeProfile(
      fullName: fullName,
      email: email,
      companyName: companyName,
    );

    // Backend returns a NEW token after profile completion — MUST replace old one
    final newToken = res['token']?['token'] ?? "";
    if (newToken.isEmpty) throw Exception("No token returned from complete-profile");

    final userData = await AuthAPI.getCurrentUser();
    final user = User.fromJson(userData);

    // Save the NEW token + user data
    await saveUserLogin(newToken, user);

    state = state.copyWith(
      isLoading: false,
      isLoggedIn: true,
      role: 'user',
      user: user,
      errorMessage: null,
    );

    // Now trigger the full boot sequence
    await ref.read(appAccessProvider.notifier).initialize();
  } catch (e) {
    print("🔐 COMPLETE PROFILE - Error: $e");
    state = state.copyWith(
      isLoading: false,
      errorMessage: _getErrorMessage(e),
    );
    rethrow;
  }
}
```

#### C. Modify `register()` — REMOVE old logic, use phone OTP flow

The old `register()` method called `AuthAPI.signup(userData)` which took fullName+phone+email.
The new registration is split into two API calls:
1. `verifyPhoneOtp()` — handled by `loginWithPhoneOtp()` UI flow
2. `completeProfile()` — handled by `completeProfile()` above

**Remove** the old `register()` method entirely, OR keep it as a no-op that redirects to the new flow. The UI will no longer call `register()` directly.

#### D. Keep `generateEmailOtp` and `verifyEmailOtp` ONLY if profile completion still uses email verification

Based on the backend API, `complete-profile` does NOT require email OTP — it just takes the email directly. So you can **remove** `generateEmailOtp` and `verifyEmailOtp` from AuthNotifier.

---

## STEP 2 — AuthAPI Client

**File**: `lib/features/auth/service/auth_client.dart`

### Add These Methods

```dart
// Send OTP to phone number
static Future<Map<String, dynamic>> sendPhoneOtp(String phoneNumber) async {
  try {
    final response = await DioClient.dio.post(
      '/auth/send-otp',
      data: {"phoneNumber": phoneNumber},
    );
    return response.data;
  } on DioException catch (e) {
    throw Exception(e.error ?? "Failed to send OTP");
  }
}

// Verify phone OTP (works for both login and registration)
static Future<Map<String, dynamic>> verifyPhoneOtp(
    String phoneNumber, String otp) async {
  try {
    final response = await DioClient.dio.post(
      '/auth/verify-otp',
      data: {"phoneNumber": phoneNumber, "otp": otp},
    );
    return response.data;
  } on DioException catch (e) {
    throw Exception(e.error ?? "Invalid OTP");
  }
}

// Complete profile (new users only, requires Bearer token already saved)
static Future<Map<String, dynamic>> completeProfile({
  required String fullName,
  required String email,
  String? companyName,
}) async {
  try {
    final body = {
      "fullName": fullName,
      "email": email,
    };
    if (companyName != null && companyName.trim().isNotEmpty) {
      body["companyName"] = companyName;
    }
    final response = await DioClient.dio.post(
      '/auth/complete-profile',
      data: body,
    );
    return response.data;
  } on DioException catch (e) {
    throw Exception(e.error ?? "Failed to complete profile");
  }
}
```

### Remove These Methods (if no longer used anywhere)
- `generateLoginOtp(email)`
- `verifyLoginOtp(email, otp)`
- `generateEmailOtp(email)` — used in old RegisterScreen for email verification
- `verifyEmailOtp(email, otp)` — same

**Before removing**, search the codebase for any other screen/widget that calls these methods. If found, update those call sites too.

---

## STEP 3 — RegisterScreen (UI)

**File**: `lib/features/auth/screens/register_screen.dart`

### New Registration Flow (2 Screens or 2 Phases in 1 Screen)

The registration now has two phases:

**Phase 1** — Phone OTP
```
[Phone number input] → [Send OTP button]
  → OTP received → [4-digit OTP input] → [Verify button]
  → If OTP valid: backend creates partial user, returns token + isNewUser:true
  → Navigate to Phase 2
```

**Phase 2** — Complete Profile
```
[Full Name input]
[Email input]
[Company Name input (optional)]
[Create Account button]
  → Calls complete-profile API
  → Gets new token
  → Full login, navigate to home
```

### Implementation Strategy

**Option A**: Replace RegisterScreen with two separate screens
- `PhoneOtpScreen` — handles phone + OTP
- `CompleteProfileScreen` — handles name/email/company

**Option B**: Use a single RegisterScreen with a `_phase` variable
```dart
enum RegisterPhase { phoneOtp, completeProfile }
```

**Recommended**: Option B (less navigation complexity).

### Complete New RegisterScreen Code

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../provider/auth_provider.dart';
import '../service/auth_client.dart';

enum _Phase { phoneOtp, completeProfile }

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  _Phase _phase = _Phase.phoneOtp;

  // Phase 1 controllers
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  // Phase 2 controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();

  bool _isSendingOtp = false;
  bool _otpSent = false;
  bool _isVerifyingOtp = false;
  bool _isCompletingProfile = false;

  // Resend cooldown
  int _resendCooldown = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  // ─── Validation ─────────────────────────────────────────────────────────

  bool get _isPhoneValid =>
      RegExp(r'^[0-9]{10}$').hasMatch(_phoneController.text.trim());

  bool get _isEmailValid =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_emailController.text.trim());

  // ─── Cooldown ────────────────────────────────────────────────────────────

  void _startCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendCooldown = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_resendCooldown <= 1) {
        t.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  // ─── Phase 1: Send OTP ───────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    if (!_isPhoneValid) {
      _showError("Please enter a valid 10-digit phone number");
      return;
    }
    setState(() => _isSendingOtp = true);
    try {
      await AuthAPI.sendPhoneOtp(_phoneController.text.trim());
      setState(() => _otpSent = true);
      _startCooldown();
      _showSuccess("OTP sent to +91-${_phoneController.text.trim()}");
    } catch (e) {
      _showError(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  // ─── Phase 1: Verify OTP ─────────────────────────────────────────────────

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 4) {
      _showError("Please enter the 4-digit OTP");
      return;
    }
    setState(() => _isVerifyingOtp = true);
    try {
      final res = await ref.read(authProvider.notifier).loginWithPhoneOtp(
        _phoneController.text.trim(),
        _otpController.text.trim(),
      );

      final isNewUser = res['isNewUser'] == true;

      if (isNewUser) {
        // Move to Phase 2 — complete profile
        if (mounted) setState(() => _phase = _Phase.completeProfile);
      } else {
        // Existing user — they should be on the LOGIN screen, not register
        // Navigate to home; appAccessProvider.initialize() was already called
        if (mounted) {
          _showError("This number is already registered. Please login.");
          context.go('/login');
        }
      }
    } catch (e) {
      _showError(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isVerifyingOtp = false);
    }
  }

  // ─── Phase 2: Complete Profile ───────────────────────────────────────────

  Future<void> _completeProfile() async {
    if (_fullNameController.text.trim().isEmpty) {
      _showError("Please enter your full name");
      return;
    }
    if (!_isEmailValid) {
      _showError("Please enter a valid email address");
      return;
    }

    setState(() => _isCompletingProfile = true);
    try {
      await ref.read(authProvider.notifier).completeProfile(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        companyName: _companyController.text.trim().isEmpty
            ? null
            : _companyController.text.trim(),
      );
      // appAccessProvider.initialize() is called inside completeProfile()
      // Router will redirect automatically
    } catch (e) {
      if (mounted) _showError(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isCompletingProfile = false);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_phase == _Phase.phoneOtp ? "Create account" : "Complete profile"),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _phase == _Phase.phoneOtp
              ? _buildPhoneOtpPhase()
              : _buildCompleteProfilePhase(),
        ),
      ),
    );
  }

  Widget _buildPhoneOtpPhase() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Enter your phone number to get started",
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
        const SizedBox(height: 24),

        // Phone number field
        Text("Phone Number *",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
        const SizedBox(height: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: "10-digit mobile number",
                counterText: "",
                prefixText: "+91  ",
                filled: true,
                fillColor: cs.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: cs.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: (_isPhoneValid && !_isSendingOtp) ? _sendOtp : null,
              child: _isSendingOtp
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.8),
                    )
                  : Text(
                      "Send OTP",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isPhoneValid ? cs.primary : cs.onSurfaceVariant,
                      ),
                    ),
            ),
          ],
        ),

        // OTP field (shows after OTP is sent)
        if (_otpSent) ...[
          const SizedBox(height: 24),
          Text("Enter OTP",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
          const SizedBox(height: 6),
          PinCodeTextField(
            appContext: context,
            length: 4,
            controller: _otpController,
            keyboardType: TextInputType.number,
            enableActiveFill: true,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(8),
              fieldHeight: 52,
              fieldWidth: 52,
              activeFillColor: cs.surface,
              inactiveFillColor: cs.surface,
              selectedFillColor: cs.surface,
              selectedColor: cs.primary,
              activeColor: cs.primary,
              inactiveColor: cs.outlineVariant,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 4),
          // Resend row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text("Didn't receive it? ",
                  style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
              GestureDetector(
                onTap: _resendCooldown == 0 ? _sendOtp : null,
                child: Text(
                  _resendCooldown == 0 ? "Resend" : "Resend in ${_resendCooldown}s",
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: _resendCooldown == 0 ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: (_otpController.text.length == 4 && !_isVerifyingOtp)
                  ? _verifyOtp
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isVerifyingOtp
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text("Verify & Continue",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onPrimary)),
            ),
          ),
        ],

        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Already have an account? ",
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Text("Login",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.primary)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompleteProfilePhase() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Almost there! Complete your profile to continue.",
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        // Grace period notice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text("You have 24 hours to complete this step.",
                    style: TextStyle(fontSize: 12.5, color: cs.onSurface)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _label("Full Name *"),
        const SizedBox(height: 6),
        _inputField(_fullNameController, "John Doe"),
        const SizedBox(height: 16),

        _label("Email Address *"),
        const SizedBox(height: 6),
        _inputField(_emailController, "john@example.com",
            type: TextInputType.emailAddress),
        const SizedBox(height: 16),

        _label("Company Name (optional)"),
        const SizedBox(height: 6),
        _inputField(_companyController, "ABC Construction Co"),
        const SizedBox(height: 32),

        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isCompletingProfile ? null : _completeProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isCompletingProfile
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text("Create Account",
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600, color: cs.onPrimary)),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface));
  }

  Widget _inputField(TextEditingController ctrl, String hint,
      {TextInputType type = TextInputType.text}) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: ctrl,
      keyboardType: type,
      onChanged: (_) => setState(() {}),
      style: TextStyle(fontSize: 14.5, color: cs.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
        filled: true,
        fillColor: cs.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.primary, width: 1.8),
        ),
      ),
    );
  }
}
```

---

## STEP 4 — LoginScreen (UI)

**File**: `lib/features/auth/screens/login_screen.dart`

### Key Changes
- Remove email field → Add phone field
- Remove `sendOtp(email)` → `sendOtp(phoneNumber)`
- Remove `verifyOtp(email, otp)` → `verifyOtp(phoneNumber, otp)`
- Add check: if `isNewUser == true` in response → redirect to RegisterScreen for profile completion

### Core Method Changes

```dart
// REPLACE sendOtp():
Future<void> sendOtp() async {
  final phone = phoneController.text.trim();

  if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
    _showErrorSnackBar("Please enter a valid 10-digit phone number");
    return;
  }

  setState(() => isSendingOtp = true);
  try {
    await AuthAPI.sendPhoneOtp(phone);
    setState(() => otpVisible = true);
    _startResendCooldown();
    _showSuccessSnackBar("OTP sent to +91-$phone");
  } catch (e) {
    _showErrorSnackBar(e.toString().replaceFirst("Exception: ", ""));
  } finally {
    if (mounted) setState(() => isSendingOtp = false);
  }
}

// REPLACE verifyOtp():
Future<void> verifyOtp() async {
  final otp = otpController.text.trim();

  if (otp.length != 4) {
    _showErrorSnackBar("Please enter a valid 4-digit OTP");
    return;
  }

  setState(() => otpButtonLoading = true);

  try {
    final res = await ref.read(authProvider.notifier).loginWithPhoneOtp(
      phoneController.text.trim(),
      otp,
    );

    _resendTimer?.cancel();

    final isNewUser = res['isNewUser'] == true;
    if (isNewUser && mounted) {
      // User exists in DB but never completed profile
      // Redirect to registration profile-completion phase
      context.push('/register');
    }
    // Existing users: router handles redirect automatically via appAccessProvider
  } catch (e) {
    if (!mounted) return;
    _showErrorSnackBar(
      e.toString().contains('Invalid OTP')
          ? "Invalid OTP. Please check and try again"
          : e.toString().replaceFirst("Exception: ", ""),
    );
  } finally {
    if (mounted) setState(() => otpButtonLoading = false);
  }
}
```

### UI Field Changes in `build()`

Replace the email TextField section with:
```dart
// Phone number field
_FieldLabel(label: "Phone Number"),
const SizedBox(height: 6),
_PhoneField(
  controller: phoneController,        // rename from emailController
  isSendingOtp: isSendingOtp,
  isPhoneValid: _isPhoneValid,
  hasInput: _hasPhoneInput,
  onSend: sendOtp,
  onChanged: (_) => setState(() {}),
),
```

Replace the getter:
```dart
// OLD:
bool get _isEmailValid => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
    .hasMatch(emailController.text.trim());
bool get _hasEmailInput => emailController.text.trim().isNotEmpty;

// NEW:
bool get _isPhoneValid =>
    RegExp(r'^[0-9]{10}$').hasMatch(phoneController.text.trim());
bool get _hasPhoneInput => phoneController.text.trim().isNotEmpty;
```

Replace `_EmailField` widget with `_PhoneField`:
```dart
class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final bool isSendingOtp;
  final bool isPhoneValid;
  final bool hasInput;
  final VoidCallback onSend;
  final ValueChanged<String> onChanged;

  const _PhoneField({
    required this.controller,
    required this.isSendingOtp,
    required this.isPhoneValid,
    required this.hasInput,
    required this.onSend,
    required this.onChanged,
  });

  bool get _canSend => isPhoneValid && !isSendingOtp;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: "10-digit mobile number",
            prefixText: "+91  ",
            counterText: "",    // hide the maxLength counter
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
            filled: true,
            fillColor: colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
            errorText: hasInput && !isPhoneValid
                ? "Enter a valid 10-digit number"
                : null,
            errorStyle: const TextStyle(fontSize: 11),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _canSend ? onSend : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: isSendingOtp
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.8),
                  )
                : Text(
                    "Send OTP",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _canSend ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
```

Also **rename** `emailController` → `phoneController` in the state class and `dispose()`.

---

## STEP 5 — DioClient Token/Cookie Handling

**File**: `lib/core/api/dio.dart`

### Good News: No Changes Needed

The DioClient interceptor already handles the auth token correctly:
```dart
// This existing interceptor code handles everything:
final prefs = await SharedPreferences.getInstance();
final token = prefs.getString('auth_token');
if (token != null) {
  options.headers['Authorization'] = 'Bearer $token';
}
```

Since we always save the token via `saveLogin(token)` which stores it at `auth_token`, the interceptor will automatically pick up and send the correct token on every request including `complete-profile`.

### What to Verify (No Code Change, Just Confirm)
1. `saveLogin(token)` saves to key `'auth_token'` — ✅ it does
2. `complete-profile` endpoint needs `Authorization: Bearer <token>` — ✅ interceptor adds this
3. After profile completion, `saveUserLogin(newToken, user)` replaces the old token — ✅ it calls `saveLogin()` which overwrites

### Cookie Note
The existing `cookieJar` and `CookieManager` setup is unchanged. If the backend sets session cookies they will be automatically persisted. No new cookie handling needed for phone OTP.

---

## STEP 6 — AppAccess & Boot Sequence

**File**: `lib/core/router/app_access.dart`

### No Structural Changes Needed

The `AppAccessNotifier` already handles the boot sequence correctly:
1. Waits for `AuthNotifier` to restore from cache
2. If not logged in → clear state
3. If logged in → sync onboarding + subscription
4. Calls `accessControlProvider.notifier.evaluate()`

### One Important Check

When a new user completes their phone OTP but has NOT yet completed their profile:
- `AuthNotifier.loginWithPhoneOtp()` sets `isLoggedIn: false`
- Therefore `AppAccessNotifier.initialize()` will NOT be called in this partial state
- This is CORRECT — the user stays on the profile completion screen

When profile IS completed via `AuthNotifier.completeProfile()`:
- Token is saved, user is saved, `isLoggedIn: true`
- `appAccessProvider.notifier.initialize()` is called
- Boot sequence runs normally
- Router redirects to appropriate screen

### If Grace Period Expires
If the user doesn't complete their profile within 24 hours and tries the flow again:
- `verify-otp` will return `isNewUser: true` again (backend re-issues token)
- The app will show the profile completion screen again
- No special handling needed

---

## STEP 7 — DeviceId Flow

**File**: `lib/features/modules/screen/device_id_helper.dart` (and related)

### How DeviceId Works with Phone OTP

In the email-based registration, `AuthAPI.signup()` returned a `deviceId` in the response.
In the phone OTP flow:

1. **`send-otp`** response — does NOT return deviceId
2. **`verify-otp`** response — may or may not return deviceId
3. **`complete-profile`** response — may return deviceId

### Check Your Backend

Look at the `verify-otp` and `complete-profile` responses. If either returns `deviceId`:

```dart
// In AuthNotifier.loginWithPhoneOtp():
final deviceId = res['deviceId']?.toString() ?? '';
if (deviceId.isNotEmpty) {
  await DevicePrefs.saveDeviceId(deviceId);
  await DioClient.setDeviceIdCookie(deviceId);
  print("📱 PHONE LOGIN - Saved deviceId: $deviceId");
}

// In AuthNotifier.completeProfile():
final deviceId = res['deviceId']?.toString() ?? '';
if (deviceId.isNotEmpty) {
  await DevicePrefs.saveDeviceId(deviceId);
  await DioClient.setDeviceIdCookie(deviceId);
  print("📱 COMPLETE PROFILE - Saved deviceId: $deviceId");
}
```

If neither returns `deviceId`, the existing device management system (via `AppAccessNotifier.initialize()` which restores deviceId from `DevicePrefs`) continues to work as before.

### The Existing DeviceId Restoration in AppAccess
This code already in `AppAccessNotifier.initialize()` handles device identity:
```dart
final savedDeviceId = await DevicePrefs.getDeviceId();
if (savedDeviceId != null && savedDeviceId.isNotEmpty) {
  await DioClient.setDeviceIdCookie(savedDeviceId);
}
```
This runs on every app boot — so the device stays identified regardless of auth method.

---

## STEP 8 — Testing Checklist

Use this checklist to verify the implementation works end-to-end.

### 8.1 New User Registration Flow
```
[ ] 1. Open app, navigate to Register screen
[ ] 2. Enter a phone number that HAS NEVER been registered
[ ] 3. Tap "Send OTP"
       → Check: OTP received on phone
       → Check: UI shows OTP input field + resend countdown
[ ] 4. Enter the correct OTP
       → Check: API returns isNewUser: true
       → Check: UI transitions to "Complete Profile" phase
[ ] 5. Enter Full Name, Email, Company Name
[ ] 6. Tap "Create Account"
       → Check: complete-profile API is called with Bearer token
       → Check: NEW token is saved (different from verify-otp token)
       → Check: User is navigated to home/onboarding
[ ] 7. Verify: Check SharedPreferences 'auth_token' — should be the FINAL token
[ ] 8. Verify: Logout and log back in with same phone — should go to EXISTING USER flow
```

### 8.2 Existing User Login Flow
```
[ ] 1. Open app, navigate to Login screen
[ ] 2. Enter a phone number that IS already registered
[ ] 3. Tap "Send OTP"
       → Check: OTP received
[ ] 4. Enter the correct OTP
       → Check: API returns isNewUser: false, message: "Login successful"
       → Check: User is navigated to home screen
       → Check: No profile completion screen shown
```

### 8.3 Error Cases
```
[ ] Invalid phone (3 digits) → error shown, no API call
[ ] Invalid OTP ("0000") → "Invalid OTP" error shown
[ ] Complete profile without token → 401 error shown
[ ] Duplicate email in complete-profile → "Email already exists" error shown
[ ] OTP after 10 minutes → "Invalid OTP" error (OTP expired on server)
```

### 8.4 Token Tests
```
[ ] After verify-otp (new user): SharedPreferences 'auth_token' has FIRST token
[ ] After complete-profile: SharedPreferences 'auth_token' has SECOND (final) token
[ ] DioClient interceptor sends correct Bearer token on next API call
```

### 8.5 Resend OTP
```
[ ] "Resend" button is disabled for 30 seconds after sending
[ ] After 30 seconds, "Resend" becomes active
[ ] Tapping resend sends new OTP and resets countdown
```

---

## Common Pitfalls

### ❌ Pitfall 1: Using the Wrong Token for complete-profile
The `complete-profile` endpoint needs the JWT from `verify-otp`. Make sure `saveLogin(token)` is called BEFORE the `completeProfile()` API method is invoked. The DioClient interceptor reads from SharedPreferences on each request.

### ❌ Pitfall 2: Forgetting to Replace Token After complete-profile
The backend returns a NEW token after `complete-profile`. If you keep the old token, subsequent API calls may fail or return partial user data. Always call `saveUserLogin(newToken, user)` with the token from `complete-profile` response.

### ❌ Pitfall 3: Calling appAccessProvider.initialize() Too Early
For new users, do NOT call `appAccessProvider.notifier.initialize()` after `verify-otp`. Call it only after `complete-profile` succeeds. Otherwise the boot sequence runs with an incomplete user.

### ❌ Pitfall 4: Phone Validation
The backend expects exactly 10 digits, no country code, no spaces. Validate with `RegExp(r'^[0-9]{10}$')`. The UI shows "+91" as a prefix hint but should NOT include it in the API call.

### ❌ Pitfall 5: Timer Leak
Always cancel `_resendTimer` in `dispose()`. If the user navigates away mid-countdown, the timer fires on a dead widget → crash.

### ❌ Pitfall 6: isNewUser Check on Login Screen
If a user goes to the Login screen with a phone number they used for `verify-otp` but never completed `complete-profile`, `isNewUser` will be `true` again. Handle this by redirecting to RegisterScreen (or specifically to the profile completion phase).

---

## Copy-Paste Prompt for AI

Use this prompt verbatim when giving instructions to an AI assistant:

---

```
I am migrating my Flutter app from email-based OTP authentication to phone-based OTP authentication.
I have a detailed guide. Please follow it EXACTLY in order.

Here is what the backend expects:

SEND OTP: POST /api/v1/auth/send-otp
  Body: { "phoneNumber": "9876543210" }
  Response: { "message": "OTP sent successfully", "sessionId": "...", "expiresIn": 600, "isExistingUser": true/false }

VERIFY OTP: POST /api/v1/auth/verify-otp
  Body: { "phoneNumber": "9876543210", "otp": "1234" }
  Response (new user): { "token": { "token": "eyJ..." }, "isNewUser": true, "requiresProfileCompletion": true }
  Response (existing user): { "token": { "token": "eyJ..." }, "isNewUser": false, "message": "Login successful" }

COMPLETE PROFILE: POST /api/v1/auth/complete-profile (requires Authorization: Bearer <token>)
  Body: { "fullName": "John Doe", "email": "john@example.com", "companyName": "ABC Co" }
  Response: { "token": { "token": "eyJ..." (NEW token) }, "user": { ... } }

Here are the changes to make in order:

STEP 1 — lib/features/auth/service/auth_client.dart
Add these three static methods:
  - sendPhoneOtp(String phoneNumber) → POST /auth/send-otp
  - verifyPhoneOtp(String phoneNumber, String otp) → POST /auth/verify-otp
  - completeProfile({required fullName, required email, String? companyName}) → POST /auth/complete-profile
Do NOT remove existing methods yet.

STEP 2 — lib/features/auth/provider/auth_provider.dart
A. Replace loginWithOtp(email, otp) with loginWithPhoneOtp(phoneNumber, otp) that:
   - Calls AuthAPI.verifyPhoneOtp(phoneNumber, otp)
   - Saves token via saveLogin(token)
   - If isNewUser == false: loads user, calls saveUserLogin, sets isLoggedIn:true, calls appAccessProvider.notifier.initialize()
   - If isNewUser == true: sets isLoading:false, isLoggedIn:false (no appAccessProvider call yet)
   - Returns the full response Map so the UI can read isNewUser

B. Add completeProfile({required fullName, required email, String? companyName}) that:
   - Calls AuthAPI.completeProfile(...)
   - Extracts the NEW token from res['token']['token']
   - Calls AuthAPI.getCurrentUser() to get fresh user data
   - Calls saveUserLogin(newToken, user) — MUST use the NEW token
   - Sets isLoggedIn:true, role:'user'
   - Calls appAccessProvider.notifier.initialize()

STEP 3 — lib/features/auth/screens/login_screen.dart
Replace email flow with phone flow:
   - Replace emailController with phoneController
   - Replace email validation with 10-digit phone validation: RegExp(r'^[0-9]{10}$')
   - sendOtp() now calls AuthAPI.sendPhoneOtp(phone)
   - verifyOtp() now calls authProvider.notifier.loginWithPhoneOtp(phone, otp)
   - After verifyOtp, if res['isNewUser'] == true → context.push('/register')
   - Replace _EmailField widget with _PhoneField widget that shows "+91" prefix and validates 10 digits
   - Remove any mention of email OTP or _showAccountNotFoundDialog for email

STEP 4 — lib/features/auth/screens/register_screen.dart
Complete rewrite with 2-phase flow:
   Phase 1 (_Phase.phoneOtp):
     - Phone number input (10 digits, +91 prefix shown)
     - "Send OTP" triggers AuthAPI.sendPhoneOtp()
     - 4-digit PinCodeTextField for OTP
     - "Verify & Continue" triggers authProvider.notifier.loginWithPhoneOtp()
     - If isNewUser == true → setState to _Phase.completeProfile
     - If isNewUser == false → show "already registered" error → push('/login')
   
   Phase 2 (_Phase.completeProfile):
     - Full Name field (required)
     - Email field (required)
     - Company Name field (optional)
     - "Create Account" triggers authProvider.notifier.completeProfile()
     - Show 24-hour grace period notice
     - On success: router redirects automatically (appAccessProvider handles it)

IMPORTANT RULES:
- Token path is ALWAYS res['token']['token'] — do not change this
- Never call appAccessProvider.notifier.initialize() after verify-otp for new users
- Always call appAccessProvider.notifier.initialize() after complete-profile succeeds
- The complete-profile request needs Bearer token — DioClient interceptor handles this automatically
- Always cancel _resendTimer in dispose() methods
- Phone number sent to API must be exactly 10 digits, no "+91", no spaces
- Validate: RegExp(r'^[0-9]{10}$') before any API call

Do not change:
- lib/core/api/dio.dart (no changes needed)
- lib/core/router/app_access.dart (no changes needed)
- Any other files not listed above
```

---

*End of Guide*