# Eloqi Mobile - Flutter App

🎭 Revolutionary Accent Training with AI-powered Accent Twin Technology

## Overview

Eloqi Mobile is the Flutter frontend for the Eloqi accent training platform. This app provides users with an intuitive interface to interact with the comprehensive Eloqi API, featuring AI-powered voice analysis, accent twin generation, and personalized training programs.

## Features

### 🔐 Authentication
- Secure JWT-based authentication
- User registration with accent preferences
- Profile management

### 🎤 Voice Analysis
- Multi-format audio recording (WAV, MP3, M4A, OGG, WEBM)
- Real-time voice analysis with ML-powered accent classification
- Detailed feedback on pronunciation, rhythm, and intonation

### 🎭 Accent Twin Technology ⭐
- Generate your voice speaking in different accents (US, UK, AU, CA, IE, IN, NZ, ZA)
- Side-by-side comparison with original recording
- Phoneme-level gap analysis and recommendations

### 🏋️ Training Programs
- Personalized training sessions based on analysis
- Multiple training types: Pronunciation, Rhythm, Intonation, Word Stress, Connected Speech
- Progress tracking and streak system

### 📊 Progress Analytics
- Comprehensive progress tracking
- Accent-specific improvement metrics
- Session history and scoring

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── core/                     # Core functionality
│   ├── app/                  # App configuration
│   ├── di/                   # Dependency injection
│   ├── models/               # Data models
│   ├── providers/            # State management
│   ├── routing/              # Navigation
│   ├── services/             # API services
│   └── theme/               # App theme
└── features/                # Feature modules
    ├── auth/                # Authentication
    ├── home/                # Home dashboard
    ├── voice/               # Voice analysis & accent twin
    ├── training/            # Training sessions
    ├── progress/            # Progress tracking
    └── profile/             # User profile
```

## Technology Stack

- **Framework**: Flutter 3.1+
- **State Management**: Riverpod
- **Navigation**: Go Router
- **HTTP Client**: Dio + Retrofit
- **Local Storage**: Hive + Shared Preferences + Secure Storage
- **Audio**: Record + Just Audio + Audio Waveforms
- **UI Components**: Material Design 3

## Getting Started

### Prerequisites

- Flutter SDK 3.1.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code with Flutter extensions
- Running Eloqi API backend (http://localhost:8000)

### Installation

1. **Clone the repository**
   ```bash
   cd /path/to/your/workspace
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code files**
   ```bash
   flutter pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Configuration

The app is configured to connect to the Eloqi API at `http://localhost:8000`. To change this:

1. Update the base URL in `lib/core/di/injection_container.dart`
2. Update the base URL in API service files in `lib/core/services/`

## API Integration

The app integrates with the comprehensive Eloqi REST API:

- **Authentication**: JWT tokens with refresh mechanism
- **Voice Analysis**: Multi-provider ML analysis pipeline
- **Accent Twin**: Advanced TTS with voice cloning
- **Training**: Personalized session management
- **Progress**: Comprehensive analytics and tracking

## Key Features Implementation

### 🔐 Secure Authentication
- JWT token management with automatic refresh
- Secure storage for sensitive data
- Comprehensive error handling

### 🎤 Voice Recording
- Cross-platform audio recording
- Real-time waveform visualization
- Audio quality validation

### 🎭 Accent Twin Generation
- Integration with multiple TTS providers
- Voice comparison algorithms
- Phonetic analysis display

### 📊 Progress Tracking
- Visual charts and analytics
- Streak system and gamification
- Personalized recommendations

## Development Status

### ✅ Phase 1: Core Infrastructure (COMPLETE)
- [x] Project setup and configuration
- [x] Authentication system
- [x] Navigation and routing
- [x] Basic UI components
- [x] API integration layer

### 🔄 Phase 2: Feature Implementation (IN PROGRESS)
- [ ] Voice recording and analysis
- [ ] Accent twin generation UI
- [ ] Training session management
- [ ] Progress visualization
- [ ] Enhanced user experience

### 🚀 Phase 3: Advanced Features (PLANNED)
- [ ] Real-time audio processing
- [ ] Offline mode support
- [ ] Social features
- [ ] Advanced analytics
- [ ] Multi-language support

## Building for Production

### Android
```bash
flutter build apk --release
# or for App Bundle
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Architecture Principles

- **Clean Architecture**: Separation of concerns with clear layer boundaries
- **SOLID Principles**: Maintainable and scalable code structure
- **State Management**: Reactive programming with Riverpod
- **Error Handling**: Comprehensive error states and user feedback
- **Performance**: Optimized for smooth user experience

## API Endpoints

The app integrates with 15+ REST endpoints:

### Authentication (4 endpoints)
- POST `/api/auth/login/`
- POST `/api/auth/register/`
- POST `/api/auth/token/refresh/`
- GET `/api/auth/user/`

### Voice Analysis (6 endpoints)
- POST `/api/voice/analyze/`
- GET `/api/voice/analysis/{id}/`
- GET `/api/voice/analysis/`

### Accent Twin Generation (4 endpoints)
- POST `/api/voice/accent-twin/`
- GET `/api/voice/accent-twin/{id}/`
- GET `/api/voice/accent-twin/`

### Training & Progress (5 endpoints)
- POST `/api/training/session/`
- GET `/api/training/sessions/`
- GET `/api/training/progress/`

## License

This project is part of the Eloqi ecosystem - Revolutionary Accent Training Platform.

## Support

For support and questions:
- Check the API documentation at `http://localhost:8000/api/docs/`
- Review the Flutter documentation
- Contact the development team

---

**Eloqi Mobile** - Making accent training personal, intuitive, and effective. 🎭✨
