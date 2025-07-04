# PDF Tools Pro 📱

A beautiful, modern mobile application for professional PDF management and editing, built with Flutter. Inspired by iLovePDF with a personalized blue gradient color scheme.

## ✨ Features

### 🛠️ PDF Tools
- **Organize**: Merge PDF, Split PDF, Organize PDF
- **Convert**: PDF ↔ Word/Excel/PowerPoint, PDF ↔ JPG
- **Edit**: Edit PDF, Sign PDF, Watermark, Rotate PDF
- **Security**: Unlock PDF, Protect PDF
- **Optimize**: Compress PDF
- **Create**: Scan to PDF, OCR PDF

### 🎨 Design Features
- **Modern UI**: Clean, professional interface with gradient designs
- **Personalized Colors**: Custom blue gradient theme (#1E40AF, #059669, #7C3AED)
- **Responsive Design**: Optimized for mobile devices
- **Smooth Animations**: Beautiful transitions and splash screen
- **Bottom Navigation**: Easy access to Tools, Favorites, Recent, and Settings

### 📱 App Structure
- **Splash Screen**: Animated intro with gradient background
- **Home Screen**: Grid of PDF tools with category filtering
- **Tool Detail Screens**: Individual interfaces for each PDF tool
- **Navigation**: Bottom tab bar with 4 main sections

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.7.0 or later)
- Dart SDK
- Android Studio / VS Code
- Android device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/pdf-tools-pro.git
   cd pdf-tools-pro
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 🎯 Tech Stack

- **Framework**: Flutter
- **Language**: Dart
- **UI**: Material Design with custom theming
- **Typography**: Poppins font family
- **Architecture**: StatefulWidget with clean code structure

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  google_fonts: ^6.1.0
  file_picker: ^8.0.0+1
  path_provider: ^2.1.1
  pdf: ^3.10.7
  printing: ^5.12.0
  image: ^4.1.3
  image_picker: ^1.0.4
  share_plus: ^7.2.1
  permission_handler: ^11.1.0
```

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/
│   ├── splash_screen.dart    # Animated splash screen
│   ├── main_screen.dart      # Bottom navigation container
│   ├── home_screen.dart      # PDF tools grid
│   └── tool_detail_screen.dart # Individual tool screens
├── widgets/
│   ├── tool_card.dart        # PDF tool card component
│   ├── header_section.dart   # Hero section with branding
│   └── category_filter.dart  # Category filter chips
└── models/
    └── pdf_tool.dart         # PDF tool data model
```

## 🎨 Color Scheme

- **Primary**: Deep Blue (#1E40AF)
- **Secondary**: Emerald Green (#059669)
- **Accent**: Purple (#7C3AED)
- **Supporting**: Teal, Indigo, Violet, Amber, and more

## 🔧 Configuration

### Android NDK
This project uses Android NDK 27.0.12077973 for compatibility with all plugins.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📞 Support

For support and questions:
- Create an issue on GitHub
- Email: support@pdftoolspro.com

## 🙏 Acknowledgments

- Inspired by iLovePDF's excellent PDF tools
- Flutter team for the amazing framework
- Google Fonts for beautiful typography
- Material Design for UI guidelines

---

**Made with ❤️ using Flutter**

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
