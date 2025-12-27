# Firebase Configuration Script
# This script helps you configure Firebase for the Groovy Chord Generator

echo "🎵 Groovy Chord Generator - Firebase Setup Helper"
echo "=================================================="
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    echo "   Visit: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n 1)"
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "⚠️  Firebase CLI not found. Installing..."
    npm install -g firebase-tools
else
    echo "✅ Firebase CLI found"
fi

# Check if FlutterFire CLI is installed
if ! command -v flutterfire &> /dev/null; then
    echo "⚠️  FlutterFire CLI not found. Installing..."
    dart pub global activate flutterfire_cli
else
    echo "✅ FlutterFire CLI found"
fi

echo ""
echo "📦 Installing Flutter dependencies..."
flutter pub get

echo ""
echo "🔥 Firebase Configuration"
echo "========================="
echo ""
echo "We'll now configure Firebase for your app."
echo "This will:"
echo "  1. Login to Firebase (if needed)"
echo "  2. Select or create a Firebase project"
echo "  3. Register your app with Firebase"
echo "  4. Download configuration files"
echo ""
read -p "Press Enter to continue..."

# Login to Firebase
echo ""
echo "🔐 Logging in to Firebase..."
firebase login

# Configure FlutterFire
echo ""
echo "⚙️  Configuring FlutterFire..."
flutterfire configure

echo ""
echo "✅ Firebase configuration complete!"
echo ""
echo "📋 Next Steps:"
echo "=============="
echo ""
echo "1. Enable Firebase services in the Firebase Console:"
echo "   - Go to: https://console.firebase.google.com/"
echo "   - Select your project"
echo "   - Enable Firestore Database (Start in test mode)"
echo "   - Enable Authentication > Anonymous"
echo ""
echo "2. Update your Firebase configuration in:"
echo "   lib/services/firebase_service.dart"
echo "   (Replace placeholder values with your actual config)"
echo ""
echo "3. Test your app:"
echo "   flutter run"
echo ""
echo "📚 For detailed instructions, see:"
echo "   - FIREBASE_SETUP.md"
echo "   - QUICKSTART.md"
echo ""
echo "🎉 Setup complete! Happy coding!"
