# NileGo - Mobile App

Flutter-based Android app for a bicycle sharing system.


## Initial Setup
Follow the instructions here to setup Flutter on your device - https://docs.flutter.dev/get-started/quick

To run : flutter run

## Workflow

- Clone to device: git clone url
- Pull latest changes: git pull origin develop
- Create feature branch: git checkout -b feature/</feature name>
- Make changes and commit: git commit -m "Add Bluetooth unlock function"
- Push: git push origin feature/bluetooth-unlock


## Features
- User authentication
- Bike location map
- Bluetooth unlock/lock
- Wallet & billing
- Ride history

## Setup
1. Install Flutter SDK
2. Run `flutter pub get`
3. Configure Firebase (add google-services.json)
4. Run `flutter run`

## Tech Stack
- Flutter 3.x
- Firebase Auth
- Firestore
- Google Maps
- Flutter Blue Plus (Bluetooth)




### Initial Commits
In firmware repo:
bashcd nilego-firmware
mkdir src docs
touch src/main.ino
touch docs/pin_diagram.md
touch README.md
git add .
git commit -m "Initial project structure"
git push origin main
In mobile repo:
bashcd nilego-mobile
flutter create nilego_app
cd nilego_app



### **9. Documentation Folder Structure**

Add `/docs` to each repo:

/docs
  requirements.md          - Project requirements
  architecture.md          - System design
  setup_guide.md          - How to run locally
  api_documentation.md    - API endpoints (backend)
  testing_plan.md         - Test cases

o	nilego-mobile (Flutter Code)
o	nilego-firmware (ESP32 C++ Code)
•	Branching Strategy: main (Working code only) and dev (Active work)
 

In each repo 
# Create develop branch
git checkout -b develop
git push origin develop

# Set develop as default branch on GitHub
# (Go to Settings → Branches → Default branch)


**Branch strategy:**
- `main` - production/demo ready code
- `develop` - integration branch
- `feature/gps-integration` - individual features
- `bugfix/lock-timeout` - bug fixes

---

### **4. Add .gitignore Files**

**firmware/.gitignore:**

# Arduino
*.hex
*.bin
*.elf
build/


**mobile/.gitignore:**

# Flutter
.dart_tool/
.flutter-plugins
.packages
.pub-cache/
build/
*.g.dart

# Firebase config (IMPORTANT - don't commit keys)
google-services.json
firebase_options.dart
.env


**backend/.gitignore:**

# Firebase
.firebase/
node_modules/
.env
serviceAccountKey.json


