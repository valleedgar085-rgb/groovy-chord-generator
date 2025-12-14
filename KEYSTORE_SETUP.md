# Android Keystore Setup Guide

This guide will help you create and configure a keystore for signing release APKs of the Groovy Chord Generator app.

## Overview

Android requires all APKs to be digitally signed with a certificate before they can be installed. For release builds, you need to create your own signing key (keystore).

## Step 1: Generate a Keystore

Run the following command in your terminal:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### What this command does:
- Creates a keystore file at `~/upload-keystore.jks`
- Uses RSA algorithm with 2048-bit key size (recommended)
- Valid for 10,000 days (~27 years)
- Creates a key with alias "upload"

### You will be prompted for:
1. **Keystore password** - Choose a strong password and remember it!
2. **Key password** - Can be the same as keystore password for simplicity
3. **Your name** - Can be your real name or organization name
4. **Organizational unit** - e.g., "Development"
5. **Organization name** - e.g., "Your Company Name"
6. **City or Locality** - Your city
7. **State or Province** - Your state
8. **Country Code** - Two-letter country code (e.g., US, UK, IN)

### Example:
```
Enter keystore password: MySecurePassword123!
Re-enter new password: MySecurePassword123!
What is your first and last name?
  [Unknown]:  Edgar Valle
What is the name of your organizational unit?
  [Unknown]:  Development
What is the name of your organization?
  [Unknown]:  Groovy Apps
What is the name of your City or Locality?
  [Unknown]:  San Francisco
What is the name of your State or Province?
  [Unknown]:  California
What is the two-letter country code for this unit?
  [Unknown]:  US
Is CN=Edgar Valle, OU=Development, O=Groovy Apps, L=San Francisco, ST=California, C=US correct?
  [no]:  yes

Generating 2,048 bit RSA key pair and self-signed certificate...
```

## Step 2: Configure key.properties

1. Copy the template file:
   ```bash
   cd android
   cp key.properties.template key.properties
   ```

2. Edit `android/key.properties` and fill in your actual values:
   ```properties
   storePassword=YOUR_KEYSTORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=upload
   storeFile=/Users/yourusername/upload-keystore.jks
   ```

   Replace:
   - `YOUR_KEYSTORE_PASSWORD` with your keystore password
   - `YOUR_KEY_PASSWORD` with your key password
   - `/Users/yourusername/upload-keystore.jks` with the actual path to your keystore

### Example key.properties:
```properties
storePassword=MySecurePassword123!
keyPassword=MySecurePassword123!
keyAlias=upload
storeFile=/Users/edgar/upload-keystore.jks
```

**Windows users:** Use forward slashes in paths, e.g., `C:/Users/Edgar/upload-keystore.jks`

## Step 3: Verify Configuration

Your `android/key.properties` file should never be committed to version control. It's already listed in `.gitignore`.

To verify your setup works, try building a release APK:
```bash
flutter build apk --release
```

## Important Security Notes

⚠️ **Keep your keystore secure!**

1. **Backup your keystore** - Store it in a safe place. If you lose it, you won't be able to update your app on Google Play Store
2. **Never commit key.properties or .jks files** to version control
3. **Use strong passwords** - Use different passwords for production apps
4. **Store credentials securely** - Consider using a password manager

## Troubleshooting

### Error: "Keystore file not found"
- Check that `storeFile` path in `key.properties` is correct
- Use absolute path, not relative path
- On Windows, use forward slashes: `C:/path/to/keystore.jks`

### Error: "Keystore was tampered with, or password was incorrect"
- Double-check your passwords in `key.properties`
- Make sure there are no extra spaces or quotes

### Error: "keytool: command not found"
- `keytool` comes with Java JDK
- Make sure Java JDK is installed and in your PATH
- Try using full path: `/usr/libexec/java_home -V` (macOS) or check Java installation directory

## Building Without a Keystore

If you haven't set up a keystore yet, the build will automatically use debug signing. This is fine for testing but should NOT be used for production releases or Google Play Store uploads.

## Additional Resources

- [Android App Signing Documentation](https://developer.android.com/studio/publish/app-signing)
- [Flutter Android Build Documentation](https://docs.flutter.dev/deployment/android)
- [Google Play Console - App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)
