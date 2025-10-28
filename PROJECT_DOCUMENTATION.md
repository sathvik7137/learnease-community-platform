# LearnEase Community Learning Platform - File Documentation

## 📚 Project Overview
**LearnEase** is an interactive community-driven learning platform built with Flutter and Dart. It features Java and DBMS courses with quizzes, fill-in-the-blank exercises, community contributions, and real-time content sharing via ngrok.

---

## 🏗️ Project Architecture

### **Client-Server Architecture**
```
┌─────────────────────┐
│   Flutter Web App   │ ← Frontend (User Interface)
│   (localhost:port)  │
└──────────┬──────────┘
           │ HTTP/REST API
           ▼
┌─────────────────────┐
│   Dart Server       │ ← Backend (API Server)
│   (localhost:8080)  │
└──────────┬──────────┘
           │ ngrok Tunnel
           ▼
┌─────────────────────┐
│   Public Internet   │ ← Accessible via ngrok
│ (*.ngrok-free.app)  │
└─────────────────────┘
```

---

## 📁 Core Project Files

### **Root Level Files**

#### `pubspec.yaml`
**Purpose:** Flutter project configuration and dependency management
**Contains:**
- Project metadata (name, version, description)
- Dependencies: `provider`, `shared_preferences`, `http`, `audioplayers`
- Asset declarations (images, fonts)
**For Professor:** This is like `package.json` in Node.js or `requirements.txt` in Python

#### `main.dart` (lib/main.dart)
**Purpose:** Application entry point
**Contains:**
- App initialization
- Theme configuration (light/dark mode)
- Navigation routing
- Provider setup for state management
**Key Features:**
```dart
- ThemeProvider (manages app theme)
- MaterialApp configuration
- Initial route to SplashScreen
```

---

## 🎨 Frontend Structure (lib/)

### **1. Screens (lib/screens/)**

#### `splash_screen.dart`
**Purpose:** Initial loading screen with app logo
**Duration:** 3 seconds
**Navigation:** Auto-navigates to home screen

#### `home_screen.dart` & `home_screen_enhanced.dart`
**Purpose:** Main dashboard of the application
**Features:**
- Display Java and DBMS course cards
- Quick access to quizzes and fill-in-the-blanks
- Navigation to community contributions
- Profile access
**UI Elements:** Course cards, icons, gradient backgrounds

#### `courses_screen.dart`
**Purpose:** Display list of available courses (Java, DBMS)
**Features:**
- Course cards with descriptions
- Navigation to course details
- Category-based filtering

#### `course_detail_screen.dart`
**Purpose:** Shows topics within a selected course
**Features:**
- List of course topics with icons
- Difficulty indicators
- Navigation to topic details
- Dynamic content loading

#### `topic_detail_screen.dart`
**Purpose:** Display detailed content for a specific topic
**Features:**
- Topic title and description
- Code examples with syntax highlighting
- Explanations and examples
- Navigation to related quizzes

#### `quiz_screen.dart` & `quiz_test_screen.dart`
**Purpose:** Interactive quiz interface
**Features:**
- Multiple-choice questions
- Timer functionality
- Progress indicator
- Score calculation
- Answer feedback (correct/incorrect)
**Navigation:** To `result_screen.dart` after completion

#### `result_screen.dart`
**Purpose:** Display quiz results
**Features:**
- Score display (percentage and fraction)
- Performance messages
- Option to retry or go home
- Achievement unlocking

#### `fill_blanks_screen.dart`
**Purpose:** List of fill-in-the-blank exercises
**Features:**
- Exercise cards grouped by category
- Difficulty levels
- Completed status tracking

#### `fill_blank_exercise_screen.dart`
**Purpose:** Interactive fill-in-the-blank exercise
**Features:**
- Text with blank spaces
- Input fields for answers
- Submit and check functionality
- Score calculation

#### `community_contributions_screen.dart`
**Purpose:** Display community-submitted content
**Features:**
- Filter by category (Java/DBMS)
- Filter by content type (Topic/Quiz/Fill Blank/Code Example)
- Real-time updates via server
- Display author information
**API Integration:** Fetches from `/api/contributions`

#### `my_contributions_screen.dart`
**Purpose:** User's personal contribution history
**Features:**
- List of user's submitted content
- Edit and delete functionality
- Contribution count
**Filter:** Shows only current user's contributions

#### `add_content_screen.dart`
**Purpose:** Form to add new community content
**Features:**
- JSON input validation
- Content type selection (Topic/Quiz/Fill Blank/Code Example)
- Category selection (Java/DBMS)
- Real-time JSON validation
- Preview before submission
**API:** POST to `/api/contributions`

#### `profile_screen.dart` & `profile_screen_new.dart`
**Purpose:** User profile and achievements
**Features:**
- Username display/setup
- Statistics (quizzes completed, contributions made)
- Achievement badges
- Theme toggle (light/dark mode)
- Settings options

---

### **2. Models (lib/models/)**

#### `course.dart`
**Purpose:** Define course data structure
**Properties:**
```dart
- id: String (unique identifier)
- title: String (course name)
- description: String
- topics: List<Topic>
- category: CourseCategory (JAVA/DBMS)
```

#### `user_content.dart`
**Purpose:** Structure for community contributions
**Properties:**
```dart
- id: String
- authorName: String
- type: ContentType (topic/quiz/fillBlank/codeExample)
- category: CourseCategory (java/dbms)
- content: Map<String, dynamic> (JSON data)
- createdAt: DateTime
- updatedAt: DateTime
```
**Methods:** 
- `toJson()` - Serialize to JSON
- `fromJson()` - Deserialize from JSON

#### `achievement.dart`
**Purpose:** Define achievement/badge system
**Properties:**
```dart
- id: String
- title: String
- description: String
- icon: IconData
- isUnlocked: bool
- unlockedAt: DateTime?
```

#### `fill_blank.dart`
**Purpose:** Fill-in-the-blank exercise structure
**Properties:**
```dart
- id: String
- title: String
- text: String (with {} for blanks)
- answers: List<String>
- category: CourseCategory
- difficulty: Difficulty
```

#### `mock_models.dart`
**Purpose:** Sample data for testing and development
**Contains:** Mock courses, topics, quizzes, achievements

---

### **3. Services (lib/services/)**

#### `user_content_service.dart` ⭐ **KEY FILE**
**Purpose:** Manage all API communication with backend server
**API Endpoints:**
```dart
GET /api/contributions - Get all contributions
GET /api/contributions/{category} - Get by category
POST /api/contributions - Add new contribution
PUT /api/contributions/{id} - Update contribution
DELETE /api/contributions/{id} - Delete contribution
```
**Features:**
- HTTP requests with timeout handling
- Local caching (fallback when offline)
- Real-time updates via polling
- JSON validation
- Error handling

**Key Methods:**
```dart
- getAllContributions() - Fetch all content
- getContributionsByCategory(category) - Filter by category
- addContribution(content) - Submit new content
- updateContribution(id, content) - Edit existing
- deleteContribution(id) - Remove content
```

#### `theme_provider.dart`
**Purpose:** Manage app theme (light/dark mode)
**Uses:** Provider pattern for state management
**Persistence:** Saves theme preference locally

#### `achievement_service.dart`
**Purpose:** Track and unlock user achievements
**Features:**
- Check quiz completion achievements
- Check contribution achievements
- Badge unlocking system
- Local storage persistence

#### `local_storage.dart`
**Purpose:** Manage local data persistence
**Uses:** SharedPreferences plugin
**Stores:**
- User progress
- Quiz scores
- Theme preferences
- Username

#### `sound_service.dart`
**Purpose:** Play sound effects for user interactions
**Sounds:** Correct answer, wrong answer, achievement unlocked

#### `community_integration_service.dart`
**Purpose:** Bridge between local and server content
**Features:**
- Merge local mock data with server data
- Handle content synchronization
- Manage content filtering

---

### **4. Data (lib/data/)**

#### `course_content.dart`
**Purpose:** Static course content (topics, quizzes)
**Contains:**
- Java course topics and quizzes
- DBMS course topics and quizzes
- Topic descriptions and code examples
**Structure:**
```dart
- javaCourse: Course object
- dbmsCourse: Course object
- allCourses: List<Course>
```

#### `fill_blanks_data.dart`
**Purpose:** Fill-in-the-blank exercise data
**Contains:**
- Java exercises (OOP, Collections, Exception Handling)
- DBMS exercises (SQL, Normalization, Transactions)

---

### **5. Widgets (lib/widgets/)**

#### `achievement_popup.dart`
**Purpose:** Show achievement unlock animation
**Features:**
- Popup modal with animation
- Achievement details display
- Confetti effect (optional)

#### `custom_loading.dart`
**Purpose:** Custom loading spinner
**Features:**
- Animated circular progress indicator
- Optional message display
- Consistent styling

#### `username_setup_dialog.dart`
**Purpose:** First-time username setup
**Features:**
- Input validation
- Save to local storage
- Required before making contributions

---

## 🖥️ Backend Structure (community_server/)

### `bin/server.dart` ⭐ **KEY FILE**
**Purpose:** Dart HTTP server for community content
**Technology:** Shelf framework (Dart's Express.js equivalent)
**Port:** 8080

**API Endpoints:**

1. **GET /** - API documentation (HTML page)
   - Shows available endpoints
   - Server status
   - Total contributions count

2. **GET /health** - Health check
   - Returns: "Community Server is running!"

3. **GET /api/contributions** - Get all contributions
   - Returns: JSON array of all contributions

4. **GET /api/contributions/{category}** - Get by category
   - Parameters: category (java or dbms)
   - Returns: Filtered contributions

5. **POST /api/contributions** - Add new contribution
   - Body: JSON with contribution data
   - Auto-generates: serverId, serverCreatedAt
   - Saves to: `contributions.json`

6. **PUT /api/contributions/{id}** - Update contribution
   - Parameters: id (contribution ID)
   - Body: Updated JSON data
   - Preserves: serverId, serverCreatedAt

7. **DELETE /api/contributions/{id}** - Delete contribution
   - Parameters: id (contribution ID)

8. **GET /api/contributions/stream** - Real-time updates (SSE)
   - Server-Sent Events for live updates

**Features:**
- CORS enabled (allows web access)
- Request logging middleware
- In-memory storage + file persistence
- JSON file backup (`contributions.json`)
- Auto-incrementing IDs

**Code Structure:**
```dart
Router setup → Define endpoints → CORS middleware → Start server
```

### `contributions.json`
**Purpose:** Persistent storage for contributions
**Format:** JSON array of contribution objects
**Auto-managed:** Created and updated by server

### `pubspec.yaml` (community_server/)
**Purpose:** Server dependencies
**Dependencies:**
- `shelf` - HTTP server framework
- `shelf_router` - Routing
- `shelf_cors_headers` - CORS support

---

## 🌐 Deployment Files

### `deploy_ngrok.ps1` ⭐ **KEY FILE**
**Purpose:** PowerShell script for automated ngrok deployment
**Features:**
- Check ngrok installation
- Configure authtoken
- Start Dart server
- Start ngrok tunnel
- Show deployment status

**Usage:**
```powershell
.\deploy_ngrok.ps1
```

**What it does:**
1. Verifies ngrok.exe exists
2. Prompts for authtoken (if not configured)
3. Starts community server
4. Creates public tunnel
5. Displays ngrok URL

### `deploy_ngrok.bat`
**Purpose:** Batch file wrapper for PowerShell script
**For:** Easy execution without PowerShell knowledge

### `download_ngrok.ps1`
**Purpose:** Download ngrok automatically
**Features:**
- Downloads ngrok for Windows
- Extracts to project folder
- Shows installation status

### `check_ngrok.ps1`
**Purpose:** Check ngrok tunnel status
**Features:**
- Display active tunnel URL
- Show server status
- Connection verification

### `deploy_ngrok.md`
**Purpose:** Complete documentation for ngrok deployment
**Contains:**
- Setup instructions
- Troubleshooting guide
- API usage examples
- Configuration tips

---

## 🛠️ Configuration Files

### `.gitignore`
**Purpose:** Exclude files from Git
**Excludes:**
- Build artifacts
- IDE files
- ngrok.exe
- contributions.json
- Dependencies

### `analysis_options.yaml`
**Purpose:** Dart/Flutter linter rules
**Configures:** Code quality rules and warnings

### `README.md`
**Purpose:** Project documentation (create this)
**Should contain:**
- Project description
- Setup instructions
- API documentation
- Screenshots

---

## 📱 Platform-Specific Files

### `android/` folder
**Purpose:** Android app configuration
**Key files:**
- `app/build.gradle.kts` - Build configuration
- `AndroidManifest.xml` - App permissions and metadata
- `src/main/kotlin/` - Kotlin main activity

### `ios/` folder
**Purpose:** iOS app configuration
**Key files:**
- `Runner.xcodeproj` - Xcode project
- `Info.plist` - App configuration
- `AppDelegate.swift` - iOS app entry point

### `web/` folder
**Purpose:** Web app configuration
**Key files:**
- `index.html` - Entry HTML file
- `manifest.json` - PWA manifest
- `icons/` - App icons

### `windows/`, `linux/`, `macos/` folders
**Purpose:** Desktop platform configurations
**Contains:** CMake build files and native code

---

## 🎯 Key Features Explanation

### **1. Community Contributions System**
- Users can submit content (topics, quizzes, code examples)
- Content stored on Dart server
- Real-time synchronization
- Author attribution
- Edit/Delete own contributions

### **2. Offline Support**
- Local caching using SharedPreferences
- Fallback to cached data when server unavailable
- Auto-sync when online

### **3. Achievement System**
- Unlock badges for completing quizzes
- Unlock badges for making contributions
- Persistent achievement tracking

### **4. Theme System**
- Light and dark mode
- Persistent theme preference
- Smooth transitions

### **5. Public Deployment**
- ngrok creates public HTTPS URL
- Share with anyone
- No complex server setup needed
- Free tier available

---

## 🔄 Data Flow

### **Adding a Contribution:**
```
User → add_content_screen.dart → user_content_service.dart → 
POST /api/contributions → server.dart → contributions.json → 
Response → Update UI
```

### **Viewing Contributions:**
```
User → community_contributions_screen.dart → 
user_content_service.dart → GET /api/contributions → 
server.dart → contributions.json → Response → Display in UI
```

### **Taking a Quiz:**
```
User → courses_screen.dart → course_detail_screen.dart → 
quiz_screen.dart → answer questions → result_screen.dart → 
achievement_service.dart → Check for new achievements → 
achievement_popup.dart
```

---

## 📊 Technology Stack

### **Frontend:**
- **Flutter 3.x** - UI framework
- **Dart** - Programming language
- **Provider** - State management
- **HTTP** - API communication
- **SharedPreferences** - Local storage

### **Backend:**
- **Dart** - Programming language
- **Shelf** - HTTP server framework
- **Shelf Router** - Routing
- **CORS** - Cross-origin support

### **Deployment:**
- **ngrok** - Public tunnel service
- **PowerShell** - Automation scripts

---

## 🎓 Professor Presentation Points

### **1. Architecture:**
"This is a client-server application with a Flutter frontend and Dart backend, connected via REST API. We use ngrok for public deployment."

### **2. Key Innovation:**
"Community-driven learning - users can contribute content that becomes part of the platform, creating a collaborative learning environment."

### **3. Technical Highlights:**
- Cross-platform (Web, Android, iOS, Desktop)
- Real-time data synchronization
- Offline-first architecture
- Clean code architecture (MVC pattern)
- RESTful API design

### **4. User Features:**
- Interactive quizzes with instant feedback
- Fill-in-the-blank exercises
- Achievement/badge system
- Theme customization
- Community content sharing

### **5. Deployment:**
"Using ngrok, we can instantly deploy the server and make it publicly accessible without complex cloud setup, perfect for demonstrations and testing."

---

## 📝 File Count Summary

- **Screens:** 15 files
- **Models:** 5 files
- **Services:** 6 files
- **Widgets:** 3 files
- **Data:** 2 files
- **Server:** 1 main file
- **Deployment Scripts:** 4 files
- **Total LOC:** ~5000+ lines

---

## 🚀 Quick Start Guide

```bash
# 1. Install dependencies
flutter pub get
cd community_server && dart pub get

# 2. Start server
cd community_server
dart run bin/server.dart

# 3. Deploy with ngrok
.\deploy_ngrok.ps1

# 4. Run Flutter app
flutter run -d chrome
```

---

**This documentation covers all major files in the LearnEase project. Use this to explain the architecture, features, and technical decisions to your professor.**
