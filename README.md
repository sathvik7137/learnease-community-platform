# 🎓 LearnEase Community Learning Platform

<div align="center">
  
  **An Interactive Community-Driven Learning Platform**
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-3.x-blue.svg)](https://dart.dev)
</div>

---

## 🌟 Overview

**LearnEase** is a modern, cross-platform learning application built with Flutter that combines interactive educational content with community-driven contributions. Students can learn Java and DBMS concepts through quizzes, fill-in-the-blank exercises, and share their own content with the community.

### Features

- ✅ **Interactive Learning** - Engaging quizzes and exercises
- ✅ **Community-Driven** - Users contribute and share content
- ✅ **Real-Time Sync** - Content updates across all users
- ✅ **Achievement System** - Gamified learning experience
- ✅ **Offline Support** - Works without internet connection
- ✅ **Cross-Platform** - Web, Android, iOS, Desktop

---

## 📥 Installation

### Prerequisites
- Flutter SDK 3.x or higher
- Dart SDK 3.x or higher
- Git

### Setup Steps

1. **Clone the Repository**
```bash
git clone https://github.com/yourusername/learnease-community-platform.git
cd learnease-community-platform
```

2. **Install Flutter Dependencies**
```bash
flutter pub get
```

3. **Install Server Dependencies**
```bash
cd community_server
dart pub get
cd ..
```

4. **Run the Application**

**Local Development:**
```bash
# Terminal 1: Start the server
cd community_server
dart run bin/server.dart

# Terminal 2: Run Flutter app
flutter run -d chrome
```

---

## 🌐 Deployment with ngrok

### Quick Start

1. **Download ngrok**:
```powershell
.\download_ngrok.ps1
```

2. **Configure authtoken** (get from https://dashboard.ngrok.com):
```powershell
.\ngrok.exe config add-authtoken YOUR_TOKEN
```

3. **Deploy**:
```powershell
.\deploy_ngrok.ps1
```

4. **Access Your App**:
   - Local: `http://localhost:PORT`
   - Public API: `https://xxxxx.ngrok-free.app`

---

## 📡 API Endpoints

### Base URL
- **Local**: `http://localhost:8080`
- **Public**: `https://your-ngrok-url.ngrok-free.app`

### Available Endpoints

```http
GET  /                              # API documentation
GET  /health                        # Health check
GET  /api/contributions             # Get all contributions
GET  /api/contributions/{category}  # Get by category (java/dbms)
POST /api/contributions             # Add new contribution
PUT  /api/contributions/{id}        # Update contribution
DELETE /api/contributions/{id}      # Delete contribution
```

---

## 📂 Project Structure

```
learnease-community-platform/
├── lib/
│   ├── main.dart                   # App entry point
│   ├── screens/                    # UI screens
│   ├── models/                     # Data models
│   ├── services/                   # Business logic & API
│   ├── widgets/                    # Reusable widgets
│   └── data/                       # Static content
├── community_server/
│   ├── bin/server.dart             # Dart HTTP server
│   └── contributions.json          # Data storage
├── assets/                         # Images and resources
├── deploy_ngrok.ps1                # Deployment automation
└── PROJECT_DOCUMENTATION.md        # Detailed documentation
```

---

## 🛠️ Technology Stack

- **Frontend**: Flutter 3.x, Dart, Provider (state management)
- **Backend**: Dart Shelf server, RESTful API
- **Storage**: JSON file-based persistence
- **Deployment**: ngrok for public access

---

## 📚 Documentation

For comprehensive documentation including:
- Detailed file explanations
- Architecture overview
- API documentation
- Deployment guide

See: [PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md)

---

## 🎯 Key Features

### Learning Features
- Interactive quizzes with instant feedback
- Fill-in-the-blank coding exercises
- Java and DBMS course content
- Code examples with syntax highlighting

### Community Features
- User-contributed content
- Real-time content synchronization
- Content management (add/edit/delete)
- Author attribution

### Gamification
- Achievement badges
- Progress tracking
- Learning statistics

---

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Open a Pull Request

---

## � Contributors

This project was made possible by the contributions of:

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/vardhan0811">
        <img src="https://github.com/vardhan0811.png" width="100px;" alt="Vardhan"/>
        <br />
        <sub><b>Vardhan</b></sub>
      </a>
      <br />
      <sub>Core Developer</sub>
    </td>
    <td align="center">
      <a href="https://github.com/sathvik7137">
        <img src="https://github.com/sathvik7137.png" width="100px;" alt="Sathvik"/>
        <br />
        <sub><b>Sathvik</b></sub>
      </a>
      <br />
      <sub>Project Lead</sub>
    </td>
    <td align="center">
      <a href="https://github.com/nishu-kumari-14">
        <img src="https://github.com/nishu-kumari-14.png" width="100px;" alt="Nishu Kumari"/>
        <br />
        <sub><b>Nishu Kumari</b></sub>
      </a>
      <br />
      <sub>UI/UX Designer</sub>
    </td>
    <td align="center">
      <a href="https://github.com/Ankith2422">
        <img src="https://github.com/Ankith2422.png" width="100px;" alt="Ankith"/>
        <br />
        <sub><b>Ankith</b></sub>
      </a>
      <br />
      <sub>Backend Developer</sub>
    </td>
    <td align="center">
      <a href="https://github.com/yourusername">
        <img src="https://avatars.githubusercontent.com/u/0?v=4" width="100px;" alt="Srivatsa"/>
        <br />
        <sub><b>Srivatsa</b></sub>
      </a>
      <br />
      <sub>Contributor</sub>
    </td>
  </tr>
</table>

---

## �📧 Contact

For questions or support, please open an issue on GitHub.

---

<div align="center">
  
  **Made with ❤️ using Flutter and Dart**
  
  ⭐ Star this repo if you find it helpful!
  
</div>
