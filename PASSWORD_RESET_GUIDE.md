# Password Reset Implementation Guide

## 📋 Overview

Complete OTP-based password reset system matching the backend's secure 3-step verification flow. Supports both email and phone number recovery methods.

## 🔄 Password Reset Flow

### Backend Flow (3 Steps)

```
1. Request OTP → User enters email/phone
   ↓
2. Verify OTP → User enters 6-digit code
   ↓
3. Reset Password → User sets new password
```

### Implementation Details

#### Step 1: Request OTP

**Endpoint**: `POST /auth/reset/request-otp`

```dart
// Request Body
{
  "emailOrPhone": "user@example.com" // or phone number
}

// Response (Success)
{
  "success": true,
  "message": "OTP sent successfully to your email.",
  "data": { "channel": "email" }
}
```

**Features**:

- ✅ Accepts email OR phone number
- ✅ Sends 6-digit OTP code
- ✅ OTP expires in 10 minutes
- ✅ 1-minute cooldown between requests
- ✅ Security: Always returns 200 (prevents user enumeration)

#### Step 2: Verify OTP

**Endpoint**: `POST /auth/reset/verify-otp`

```dart
// Request Body
{
  "emailOrPhone": "user@example.com",
  "otpCode": "123456"
}

// Response (Success)
{
  "success": true,
  "message": "OTP verified. You may now change your password.",
  "data": {
    "resetToken": "eyJhbGciOiJIUzI1NiIs...",
    "expiresIn": 900  // 15 minutes in seconds
  }
}
```

**Features**:

- ✅ Validates 6-digit OTP code
- ✅ Maximum 5 attempts per OTP
- ✅ Returns short-lived reset token (15 minutes)
- ✅ OTP is burned after successful verification

#### Step 3: Change Password

**Endpoint**: `POST /auth/reset/change-password`

```dart
// Headers
{
  "Authorization": "Bearer <resetToken>"
}

// Request Body
{
  "newPassword": "newSecurePassword123"
}

// Response (Success)
{
  "success": true,
  "message": "Password reset successfully. Please log in with your new password."
}
```

**Features**:

- ✅ Requires valid reset token
- ✅ Password minimum 6 characters
- ✅ Invalidates all existing refresh tokens
- ✅ Clears reset session after success

## 📁 File Structure

```
lib/
├── services/
│   └── password_reset_service.dart    # API service for password reset
├── screens/
│   ├── forgot_password_screen.dart    # Step 1: Enter email/phone
│   ├── verify_otp_screen.dart         # Step 2: Enter OTP code
│   ├── new_password_screen.dart       # Step 3: Set new password
│   └── login_screen.dart              # Updated with "Forgot Password" link
```

## 🎨 UI/UX Features

### Forgot Password Screen

- Clean, card-free design with app bar
- Email/phone input with validation
- "Send Verification Code" button
- Loading states
- Back to login link
- Icon: 🔓 Lock reset

### Verify OTP Screen

- 6-digit code input
- Large, centered input with letter spacing
- 60-second countdown timer
- Resend OTP functionality with cooldown
- Real-time validation
- Shows destination (email/phone)
- Icon: ✉️ Email verified

### New Password Screen

- New password input
- Confirm password input
- Password visibility toggles
- Password match validation
- Loading states
- Security message
- Icon: 🔓 Lock open

## 🔐 Security Features

1. **OTP Expiration**

   - 10-minute lifespan
   - Burned after verification
   - Cannot be reused

2. **Rate Limiting**

   - 1-minute cooldown between OTP requests
   - Maximum 5 verification attempts
   - 429 status on rate limit exceeded

3. **Reset Token**

   - Short-lived (15 minutes)
   - JWT-based with purpose validation
   - Cleared after password reset

4. **Password Requirements**

   - Minimum 6 characters
   - Cannot be same as current (backend validates)
   - Invalidates all sessions on reset

5. **User Enumeration Prevention**
   - Always returns 200 for OTP request
   - Generic success messages
   - No indication if account exists

## 📊 User Experience

### Success Flow

```
Login → Forgot Password? → Enter Email/Phone
  ↓
OTP Sent → Enter Code → Verify (60s timer)
  ↓
Code Verified → Enter New Password → Confirm
  ↓
Password Reset → Success Message → Login Screen
```

### Error Handling

1. **Invalid Email/Phone**

   - "Enter a valid email or phone number"

2. **OTP Request Too Soon**

   - "Please wait X second(s) before requesting another OTP"

3. **Invalid/Expired OTP**

   - "Invalid or expired OTP"

4. **Too Many Attempts**

   - "Too many OTP attempts. Please request a new code."

5. **Passwords Don't Match**

   - "Passwords do not match"

6. **Token Expired**
   - "Invalid or expired reset token"

## 🛠️ Implementation Code Examples

### Request OTP

```dart
final service = PasswordResetService();
final result = await service.requestResetOTP("user@example.com");

if (result['success'] == true) {
  // Navigate to OTP screen
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => VerifyOTPScreen(
        emailOrPhone: email,
      ),
    ),
  );
}
```

### Verify OTP

```dart
final result = await service.verifyResetOTP(
  emailOrPhone,
  otpCode,
);

if (result['success'] == true) {
  final resetToken = result['data']['resetToken'];
  // Navigate to new password screen
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => NewPasswordScreen(
        resetToken: resetToken,
      ),
    ),
  );
}
```

### Reset Password

```dart
final result = await service.changePasswordWithToken(
  resetToken,
  newPassword,
);

if (result['success'] == true) {
  // Navigate to login
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (context) => const LoginScreen(),
    ),
    (route) => false,
  );
}
```

## ⏱️ Timers & Cooldowns

### OTP Request Cooldown

- **Duration**: 60 seconds
- **UI**: "Resend in X s" countdown
- **Behavior**: Button disabled during countdown

### OTP Expiration

- **Duration**: 10 minutes (backend)
- **UI**: User informed to request new code if expired
- **Backend**: Returns 400 for expired OTP

### Reset Token Expiration

- **Duration**: 15 minutes
- **Backend**: Validates timestamp and session ID
- **UI**: User redirected to start over if expired

## 🧪 Testing Checklist

### Functional Tests

- [ ] Request OTP with email
- [ ] Request OTP with phone
- [ ] Verify OTP with correct code
- [ ] Verify OTP with incorrect code
- [ ] Verify OTP after expiration
- [ ] Test 5-attempt limit
- [ ] Test cooldown timer
- [ ] Reset password successfully
- [ ] Test password validation (min 6 chars)
- [ ] Test password match validation
- [ ] Test expired reset token
- [ ] Test back navigation flow

### Edge Cases

- [ ] Network error during OTP request
- [ ] Network error during verification
- [ ] Network error during password reset
- [ ] App backgrounded during OTP entry
- [ ] Invalid email/phone format
- [ ] Empty inputs
- [ ] Very long email/phone
- [ ] Special characters in OTP field

## 📱 Navigation Flow

```
LoginScreen
    ↓ "Forgot Password?" link
ForgotPasswordScreen
    ↓ OTP sent
VerifyOTPScreen
    ↓ OTP verified
NewPasswordScreen
    ↓ Password reset
LoginScreen (clear navigation stack)
```

## 🎯 Backend Compatibility

### Matched Features

✅ OTP generation and delivery  
✅ Email AND phone support  
✅ 10-minute OTP expiration  
✅ 1-minute request cooldown  
✅ 5-attempt verification limit  
✅ Short-lived reset tokens  
✅ Session invalidation  
✅ User enumeration prevention

### Mobile-Specific Handling

✅ No cookie-based sessions  
✅ Token passed in Authorization header  
✅ Stateless flow (no session storage needed)  
✅ Error message extraction  
✅ Loading state management

## 🔄 Future Enhancements

- [ ] Biometric re-authentication after password reset
- [ ] Password strength indicator
- [ ] Recent password history check
- [ ] SMS OTP support (if backend adds it)
- [ ] Alternative recovery methods
- [ ] Security questions
- [ ] Account recovery via support
- [ ] Push notification for password change
- [ ] Email notification on successful reset
- [ ] Device verification

## 🐛 Troubleshooting

### OTP Not Received

1. Check email spam folder
2. Verify email/phone is correct
3. Wait for cooldown to expire
4. Try requesting again

### OTP Verification Fails

1. Check if OTP is expired (10 min)
2. Verify correct digits entered
3. Check for attempt limit reached
4. Request new OTP if needed

### Password Reset Fails

1. Verify reset token not expired (15 min)
2. Check password requirements (min 6 chars)
3. Ensure passwords match
4. Check network connection

## 📊 Analytics & Monitoring

### Key Metrics to Track

- OTP request success rate
- OTP verification success rate
- Average time to complete reset
- Common failure points
- Resend OTP frequency
- Token expiration rate

---

**Implementation Status**: ✅ Complete  
**Last Updated**: 2025-01-09  
**Version**: 1.0.0  
**Backend Compatibility**: Full
