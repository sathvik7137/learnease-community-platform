# 🎓 LearnEase Community Learning Platform

<div align="center">

**An Interactive, Community-Driven Learning Platform built with Flutter + Dart**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-blue.svg)](https://dart.dev)

</div>

---

## 🌟 Overview

**LearnEase** is a full-stack learning platform that helps students learn **Java** and **DBMS** interactively through quizzes, fill-in-the-blanks, and user-contributed content.
Built using **Flutter** (frontend) and **Dart Shelf** (backend), it supports web and mobile platforms.

### ✨ Key Highlights

* 📚 Interactive courses (Java, DBMS)
* 👥 Community-driven content sharing
* 🧠 Quizzes & fill-in-the-blank exercises
* 🏆 Achievement & progress tracking
* 🌐 ngrok-powered public deployment
* ⚡ Offline support & responsive UI

---

## ⚙️ Setup Instructions

### Prerequisites

* Flutter SDK 3.x
* Dart SDK 3.x
* Git installed

### Steps to Run Locally

```bash
# Clone repo
git clone https://github.com/sathvik7137/learnease-community-platform.git
cd learnease-community-platform

# Install dependencies
flutter pub get
cd community_server && dart pub get && cd ..

# Run backend
dart run community_server/bin/server.dart

# Run frontend
flutter run -d chrome
```

---

## 🌐 Deployment with ngrok

1. Download [ngrok](https://ngrok.com/download)
2. Add your authtoken:

   ```bash
   ngrok config add-authtoken YOUR_TOKEN
   ```
3. Run your Dart server:

   ```bash
   dart run community_server/bin/server.dart
   ```
4. Start ngrok tunnel:

   ```bash
   ngrok http 8080
   ```
5. Access API via generated URL like:
   👉 `https://xyz123.ngrok-free.app`

---

## 🧩 API Overview

| Method | Endpoint                        | Description         |
| ------ | ------------------------------- | ------------------- |
| GET    | `/health`                       | Check server status |
| GET    | `/api/contributions`            | Get all content     |
| GET    | `/api/contributions/{category}` | Filter (java/dbms)  |
| POST   | `/api/contributions`            | Add new content     |
| PUT    | `/api/contributions/{id}`       | Update content      |
| DELETE | `/api/contributions/{id}`       | Remove content      |

---

## 🧱 Project Structure

```
learnease-community-platform/
├── lib/                    # Flutter frontend
│   ├── main.dart           # Entry point
│   ├── screens/            # UI screens
│   ├── models/             # Data models
│   └── services/           # API & logic
├── community_server/       # Backend server
│   ├── bin/server.dart     # REST API server
│   └── contributions.json  # Data storage
└── PROJECT_DOCUMENTATION.md
```

---

## 🛠️ Tech Stack

| Layer      | Technology         |
| ---------- | ------------------ |
| Frontend   | Flutter 3.x (Dart) |
| Backend    | Dart Shelf         |
| Database   | JSON file          |
| Deployment | ngrok tunnel       |

---

## 📱 Core Features

* 🧠 Learn Java & DBMS concepts
* 🧩 Take quizzes and coding exercises
* ✍️ Add & manage your own content
* 🏅 Track progress and achievements
* 🌗 Dark/light theme support

---

## 🚀 Architecture

```
Flutter Frontend ──> REST API ──> Dart Backend ──> ngrok Tunnel (Public)
```

---

## 🤝 Contributing

1. Fork the repo
2. Create a branch (`feature/new-feature`)
3. Commit & push your changes
4. Submit a Pull Request

---

## 📊 Quick Stats

* 🧾 15 UI screens
* 📦 5 data models
* 🔧 6 services
* 🌍 8 REST endpoints
* 💻 5000+ lines of code

---

## 📝 License

Open Source under the **MIT License**.

---

## 📧 Contact

* **Author:** [@sathvik7137](https://github.com/sathvik7137)
* **Repo:** [LearnEase Community Platform](https://github.com/sathvik7137/learnease-community-platform)
* **Issues:** [Report Here](https://github.com/sathvik7137/learnease-community-platform/issues)

---

<div align="center">

**Made with ❤️ using Flutter and Dart**
⭐ *Star this repo if you find it helpful!*

</div>

---


