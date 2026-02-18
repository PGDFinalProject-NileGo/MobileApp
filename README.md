# NileGo - Mobile App

Flutter-based Android app for a bicycle sharing system.

## Initial Setup

Follow the instructions here to setup Flutter on your device - https://docs.flutter.dev/get-started/quick

## Features
- User authentication
- Bike location map
- Bluetooth unlock/lock
- Wallet & billing
- Ride history

## Tech Stack
- Flutter
- Firebase Auth
- Firestore
- Google Maps
- Flutter Blue Plus (Bluetooth)

## **Documentation Folder Structure**

/docs
- requirements.md          - Project requirements
- architecture.md          - System design
- setup_guide.md          - How to run locally
- api_documentation.md    - API endpoints (backend)
- testing_plan.md         - Test cases
- /pin_diagram.md         - Pin Diagram

## Workflow

- Clone to device: git clone url
- Pull latest changes: git pull origin develop
- Create feature branch: git checkout -b feature/</feature name>
- Make changes and commit: git commit -m "Add Bluetooth unlock function"
- Push: git push origin feature/<feature-title>

## **Branch strategy:**

- `main` - production/demo ready code
- `develop` - integration branch
- `feature/gps-integration` - individual features
- `bugfix/lock-timeout` - bug fixes
