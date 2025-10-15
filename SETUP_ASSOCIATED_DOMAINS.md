# Associated Domains Setup for Password Autofill

## Issue
The console shows: "Cannot show Automatic Strong Passwords... Make sure you have set up Associated Domains"

This warning appears because iOS AutoFill requires Associated Domains to be configured for automatic password suggestions to work properly.

## Solution Steps

### 1. Add Associated Domains Capability in Xcode

1. Open `TripSync.xcodeproj` in Xcode
2. Select the TripSync target
3. Go to "Signing & Capabilities" tab
4. Click the "+" button to add capability
5. Search for and add "Associated Domains"

### 2. Configure Domains

For development, you can use a placeholder domain:
```
applinks:tripsync-dev.example.com
```

For production, you'll need a real domain:
```
applinks:tripsync.app
applinks:www.tripsync.app
```

### 3. Web Domain Setup (Production Only)

Create an `apple-app-site-association` file on your web server at:
`https://yourdomain.com/.well-known/apple-app-site-association`

Example content:
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAMID.com.yourcompany.TripSync",
        "paths": ["/signin", "/reset-password"]
      }
    ]
  },
  "webcredentials": {
    "apps": [
      "TEAMID.com.yourcompany.TripSync"
    ]
  }
}
```

### 4. Alternative: Disable AutoFill Warnings (Development)

For development purposes, you can suppress these warnings by:

1. In your text field configuration, set:
```swift
textField.textContentType = .password
textField.passwordRules = nil
```

2. Or use a custom password field that doesn't trigger AutoFill:
```swift
textField.textContentType = .oneTimeCode // Prevents password AutoFill
```

## Current Status

- ✅ Biometric authentication working
- ✅ Manual password entry working  
- ⚠️ Automatic password suggestions disabled (needs Associated Domains)
- ✅ Password security validation working

## Notes

- This warning doesn't affect core app functionality
- Password autofill is a convenience feature
- For MVP/development, this can be addressed later
- Required for App Store submission if you want password autofill

## Related Files

- `AuthViewController.swift` - Contains password input fields
- `Info.plist` - May need NSFaceIDUsageDescription updates
- Project settings - Needs Associated Domains capability