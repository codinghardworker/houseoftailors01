# Firebase Password Reset Email Setup Guide

## 🔥 Firebase Console Configuration

### 1. Configure Email Templates
1. Go to Firebase Console → Authentication → Templates
2. Click on **Password reset** template
3. Configure the email template:
   - **From name**: House of Tailors
   - **Reply-to email**: noreply@houseoftailors.com
   - **Subject**: Reset your House of Tailors password
   - **Body**: Customize with your branding

### 2. Configure Authorized Domains
1. Go to Firebase Console → Authentication → Settings → Authorized domains
2. Add these domains:
   - `houseoftailors1-786c5.firebaseapp.com` (your Firebase hosting domain)
   - `houseoftailors.page.link` (for dynamic links)
   - `localhost` (for testing)
   - Your production domain (when you have one)

### 3. Setup Firebase Dynamic Links
1. Go to Firebase Console → Dynamic Links
2. Create a new link domain: `houseoftailors.page.link`
3. Configure the link:
   - **Domain**: houseoftailors.page.link
   - **Android**: com.houseoftailors.app
   - **iOS**: com.houseoftailors.app (if you have iOS)

## 📱 Android Configuration

### 1. Deep Link Intent Filters (Already Added)
The AndroidManifest.xml has been updated with:
- Firebase auth domain links
- Dynamic links
- Custom scheme fallback

### 2. Digital Asset Links (Optional)
For production, add a digital asset links file to verify domain ownership.

## 🔧 Code Implementation

### 1. Password Reset Email Configuration
The `forgotPassword` method in AuthService now includes:
- Custom action code settings
- Deep link configuration
- Mobile app redirection

### 2. Deep Link Handling
- Dynamic link listener in main.dart
- Automatic navigation to reset password screen
- oobCode verification and processing

### 3. Reset Password Flow
- Validates reset code before showing UI
- Uses Firebase Auth's confirmPasswordReset
- Proper error handling and user feedback

## 🧪 Testing the Implementation

### 1. Email Sending Test
```dart
// Test in your app
final authService = AuthService();
final success = await authService.forgotPassword(email: 'test@example.com');
```

### 2. Deep Link Testing
Test these URLs in your Android device:
- `https://houseoftailors1-786c5.firebaseapp.com/__/auth/action?mode=resetPassword&oobCode=TEST_CODE`
- `houseoftailors://reset?oobCode=TEST_CODE`

### 3. Complete Flow Test
1. Send password reset email
2. Check email for reset link
3. Click link → should open app
4. Reset password → should work
5. Login with new password

## 🌐 Web Support

The same Firebase email configuration works for web. The reset links will:
- Open the web app if accessed from a browser
- Open the mobile app if accessed from a mobile device with the app installed
- Fallback to web if mobile app not installed

## 🔍 Troubleshooting

### Common Issues:
1. **Email not received**: Check spam folder, verify email address
2. **Link doesn't open app**: Verify intent filters and digital asset links
3. **Invalid oobCode**: Code may be expired (valid for 1 hour)
4. **Deep links not working**: Check package name matches Firebase configuration

### Debug Commands:
```bash
# Test deep link from ADB
adb shell am start -W -a android.intent.action.VIEW -d "houseoftailors://reset?oobCode=test" com.houseoftailors.app

# Check app link verification
adb shell pm get-app-links com.houseoftailors.app
```

## ✅ Verification Checklist

- [ ] Firebase Console email templates configured
- [ ] Authorized domains added
- [ ] Dynamic Links domain created
- [ ] Android manifest updated
- [ ] Deep link handling implemented
- [ ] Password reset flow tested
- [ ] Email sending tested
- [ ] Mobile app opens from email links
- [ ] Web fallback works

## 🚀 Production Deployment

For production:
1. Replace Firebase project ID with production project
2. Update authorized domains with your production domain
3. Configure custom email domain in Firebase Console
4. Set up proper SSL certificates
5. Test on multiple devices and email providers