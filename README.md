# Etalert Frontend

This is the **frontend** of the ETAlert system, developed using **Flutter** and **Dart**.

---

## Table of Contents
- [Requirements](#requirements)
- [Project Setup](#project-setup)
  - [Cloning the Repository](#cloning-the-repository)
  - [Environment Configuration](#environment-configuration)
  - [Installation](#installation)
  - [Running the Project](#running-the-project)
- [Backend Repository](#backend-repository)
- [API Key and URLs](#api-key-and-urls)
- [Folder Structure](#folder-structure)

---

## Requirements
To work with the Etalert frontend, ensure you have the following dependencies installed:

1. **Flutter SDK** (v3.x.x or higher)
   - Installation guide: [Flutter Docs](https://docs.flutter.dev/get-started/install)
2. **Dart SDK** (v3.x.x or higher) (comes with Flutter)
3. **VS Code** (recommended IDEs)
4. **Git**

To check if Flutter is correctly installed, run:
```bash
flutter doctor
```

---

## Project Setup

### Cloning the Repository
First, clone the frontend and backend repositories:

1. **Frontend Repository:**
```bash
git clone https://github.com/Etalert/Etalert-frontend.git
cd Etalert-frontend
```

2. **Backend Repository:**
```bash
git clone https://github.com/Erxical/etalert-backend.git
```

---

### Environment Configuration
To set up the environment variables, create a `.env` file in the root directory of the **frontend** project:

```plaintext
BASE_URL = "https://etalert.erxin.live"
WEBSOCKET_URL = "wss://etalert.erxin.live/ws"

# For local development:
# BASE_URL = "http://localhost:3000"
# WEBSOCKET_URL = "ws://localhost:3000/ws"

// Google Distance Matrix API Key
API_KEY=<PUT API_KEY HERE>
```

- Refer to [etalert-backend](https://github.com/Erxical/etalert-backend.git) on how to create API_KEY

---

### Installation
To install the dependencies, navigate to the project root and run:

```bash
flutter pub get
```

This will fetch all necessary Flutter and Dart packages.

---

### Running the Project
To run the Flutter project on your connected emulator/device, execute the following command:

```bash
flutter run
```

---

## Backend Repository
To run the backend server, refer to the **etalert-backend** repository:

Repository link: [etalert-backend](https://github.com/Erxical/etalert-backend.git)

Follow the backend installation and setup steps mentioned in the repository's README.

---

## API Key and URLs
Ensure your `.env` file contains the correct API and WebSocket URLs for production and development environments:

| Variable          | Production URL                       | Local Development URL       |
|-------------------|--------------------------------------|-----------------------------|
| `BASE_URL`        | `https://etalert.erxin.live`         | `http://localhost:3000`     |
| `WEBSOCKET_URL`   | `wss://etalert.erxin.live/ws`        | `ws://localhost:3000/ws`    |
| `API_KEY`         | Google Distance Matrix API Key       | Replace with your own key   |

---

## Folder Structure
Here's an overview of the main project folders:
```
Etalert-frontend/
│
├── lib/                  # Application source code
│   ├── main.dart         # Entry point of the application
│   ├── screens/          # UI screens
│   ├── services/         # API calls and services
│   ├── utils/            # Utility classes and helpers
│   ├── widgets/          # Reusable widgets
│
├── assets/               # Images, fonts, etc.
├── .env                  # Environment variables
├── pubspec.yaml          # Dependencies
└── README.md             # Project documentation
```
