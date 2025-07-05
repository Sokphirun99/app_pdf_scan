# PDF Scanner Pro 📱

A sophisticated, production-ready Flutter application for professional PDF scanning, document processing, and management. Built with advanced computer vision, ML Kit integration, and a modular architecture for maximum maintainability.

## ✨ Key Features

### 🔍 Advanced Document Scanning

- **AI-Powered Detection**: Real-time document edge detection using Google ML Kit
- **Smart Camera Controls**: Auto-focus, exposure control, and flash management
- **Multi-Page Scanning**: Batch scan multiple pages into single PDF
- **Image Enhancement**: Automatic perspective correction and quality optimization

### 📄 PDF Management

- **PDF Generation**: Convert scanned images to high-quality PDFs
- **Export Options**: Save, share, print, or preview generated documents
- **Quality Settings**: Configurable output quality (high/medium/low)
- **OCR Integration**: Text recognition from scanned documents

### 🎨 Modern UI/UX

- **Material Design 3**: Latest design system with dynamic theming
- **Dark/Light Mode**: Adaptive themes with smooth transitions
- **Responsive Layout**: Optimized for all screen sizes
- **Smooth Animations**: Professional transitions and micro-interactions

## 🚀 Quick Start

### Prerequisites

```bash
# Required versions
Flutter SDK: >=3.7.0
Dart SDK: >=3.7.0
Android Studio / VS Code
iOS Simulator / Android Emulator
```

### Installation

1. **Clone and Setup**

   ```bash
   git clone https://github.com/phirun/app_pdf_scan.git
   cd app_pdf_scan
   flutter pub get
   ```

2. **Run the App**

   ```bash
   # Debug mode
   flutter run
   
   # Specific platform
   flutter run -d ios
   flutter run -d android
   
   # Hot reload enabled by default
   ```

3. **Build for Production**

   ```bash
   # Android APK
   flutter build apk --release
   
   # Android App Bundle (for Play Store)
   flutter build appbundle --release
   
   # iOS (requires Xcode)
   flutter build ios --release
   
   # Install directly to device
   flutter install
   ```

## 🏗️ Modular Architecture

Our codebase follows a clean, modular architecture with clear separation of concerns:

```text
lib/
├── main.dart                          # App entry point & initialization
├── config/                           # Configuration & Settings
│   ├── navigation_config.dart        # App navigation structure
│   └── settings_config.dart          # Global app settings
├── controllers/                      # Business Logic Controllers
│   ├── pdf_scan_controller.dart      # PDF workflow management
│   └── scanner_controller.dart       # Camera & scanning logic
├── models/                          # Data Models & Structures
│   ├── pdf_export_models.dart       # PDF export configurations
│   ├── pdf_tool.dart               # Tool definitions & metadata
│   ├── scan_to_pdf_models.dart     # Scan workflow data models
│   └── screen_models.dart          # UI state management models
├── screens/                        # UI Screens & Views
│   ├── simple_main_screen.dart     # Modular main interface
│   ├── simple_scan_to_pdf_screen.dart # Streamlined scan workflow
│   ├── simple_settings_screen.dart  # Clean settings interface
│   ├── tab_screens.dart            # Individual tab implementations
│   ├── splash_screen.dart          # App initialization screen
│   ├── home_screen.dart            # Main dashboard
│   ├── tool_detail_screen.dart     # Tool-specific interfaces
│   ├── main_screen.dart            # Legacy main screen (reference)
│   ├── scan_to_pdf_screen.dart     # Legacy scan screen (reference)
│   └── advanced_scanner_screen.dart # Legacy scanner (reference)
├── services/                       # Core Business Services
│   ├── camera_service.dart         # Camera operations & management
│   ├── document_detection_service.dart # AI-powered edge detection
│   ├── pdf_generation_service.dart  # PDF creation & optimization
│   └── scan_service.dart           # Core scanning workflows
├── themes/                         # App Theming & Styling
│   └── app_themes.dart            # Material 3 theme definitions
└── widgets/                        # Reusable UI Components
    ├── pdf_scan_widgets.dart       # PDF scanning UI components
    ├── scanner_dialogs.dart        # Modal dialogs for scanner
    ├── settings_widgets.dart       # Settings interface components
    ├── theme_toggle_widget.dart    # Dark/light mode switcher
    ├── category_filter.dart        # Tool category filters
    ├── header_section.dart         # App header components
    └── tool_card.dart              # Tool grid card components
```

## 📱 App Flow & Navigation

### Primary Screens

1. **Splash Screen** → App initialization with branding
2. **Main Screen** → Bottom navigation with 4 tabs
3. **Home Tab** → PDF tools grid with categories
4. **Scanner Tab** → Document scanning interface
5. **Settings Tab** → App configuration options

### Scanner Workflow

```text
Home → Tool Selection → Camera Preview → Document Detection → 
Capture → Image Review → Multi-page Option → PDF Generation → 
Export Options (Save/Share/Print/Preview)
```

## 🔧 Technical Stack

### Core Technologies

- **Framework**: Flutter 3.7+
- **Language**: Dart 3.7+
- **UI Toolkit**: Material Design 3
- **State Management**: StatefulWidget + Provider pattern

### Key Dependencies

```yaml
dependencies:
  # Core Flutter
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  
  # PDF & Document Processing
  image_picker: ^1.0.4          # Image selection
  camera: ^0.10.5+5              # Camera access
  pdf: ^3.10.4                   # PDF generation
  printing: ^5.11.0              # PDF printing
  path_provider: ^2.1.1          # File system access
  path: ^1.8.3                   # Path manipulation
  share_plus: ^7.2.1             # File sharing
  
  # Permissions & Device Info
  permission_handler: ^11.0.1    # Runtime permissions
  device_info_plus: ^9.1.0       # Device information
  
  # AI & ML
  google_mlkit_text_recognition: ^0.11.0  # OCR capabilities
  
  # State & UI
  provider: ^6.1.0               # State management
```

## 🎯 Development Guidelines

### Code Organization

- **Models**: Data structures and business entities
- **Services**: Pure business logic, no UI dependencies
- **Controllers**: Coordinate between services and UI
- **Widgets**: Reusable UI components
- **Screens**: Full-screen UI implementations
- **Config**: App-wide configuration and constants

### Best Practices

- ✅ **Separation of Concerns**: Each layer has single responsibility
- ✅ **Dependency Injection**: Services are injected where needed
- ✅ **Error Handling**: Comprehensive error handling throughout
- ✅ **Type Safety**: Strong typing with null safety
- ✅ **Code Quality**: Flutter analyze with zero warnings
- ✅ **Modern APIs**: Latest Flutter/Dart patterns and APIs

## 🔍 Advanced Features

### Document Detection AI

- Real-time edge detection using Google ML Kit
- Perspective correction algorithms
- Automatic document boundary recognition
- Quality assessment and optimization

### PDF Generation Engine

- Multi-page PDF compilation
- Configurable quality settings
- Metadata and annotations support
- Optimized file size management

### Camera Integration

- Advanced camera controls
- Auto-focus and exposure management
- Flash control for low-light scanning
- Preview with overlay guidance

## 🧪 Testing & Quality

```bash
# Run tests
flutter test

# Code analysis
flutter analyze

# Format code
dart format lib/

# Check for outdated dependencies
flutter pub outdated
```

## 📦 Building & Distribution

### Development Build

```bash
flutter run --debug
```

### Release Builds

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

### Code Signing (iOS)

```bash
# Ensure proper provisioning profiles
flutter build ios --release --codesign
```

## 🤝 Contributing

1. **Fork** the repository
2. **Create** feature branch (`git checkout -b feature/amazing-feature`)
3. **Follow** the modular architecture patterns
4. **Write** tests for new functionality
5. **Ensure** `flutter analyze` passes with zero issues
6. **Submit** pull request with detailed description

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) for details.

## 👨‍💻 Author

### Phirun

- GitHub: [@Sokphirun99](https://github.com/Sokphirun99)
- Email: [Your Email]

---

### 🚀 Built with Flutter • Made with ❤️ by Phirun
