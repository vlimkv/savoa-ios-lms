# SAVOA iOS Client

A native iOS application designed for the **SAVOA** wellness ecosystem. This project serves as a mobile LMS (Learning Management System) client, delivering secure video courses, audio meditations, and progress tracking via a RESTful API.

## 🛠 Tech Stack

* **Language:** Swift 6.0
* **UI Framework:** SwiftUI
* **Architecture:** MVVM + Clean Architecture
* **Concurrency:** Swift Concurrency (Async/Await)
* **Networking:** URLSession (Protocol-oriented wrapper)
* **Storage:** Keychain (Security), UserDefaults (Settings)
* **Backend Interface:** Python (FastAPI)

## 🏗 Architecture & Modules

The project follows strict separation of concerns to ensure scalability:

* `Core/`: Low-level networking, storage protocols, and extensions.
* `Models/`: Codable structs matching the FastAPI JSON response.
* `Services/`: Business logic (Auth, Course Management, Progress Sync).
* `ViewModels/`: State management and UI logic.
* `Views/`: Declarative SwiftUI components.

## 🔒 Security Features

Leveraging cybersecurity best practices (BSc background):
* **Secure Storage:** Auth tokens and sensitive user data are encrypted via **Apple Keychain**.
* **Endpoint Protection:** API configuration is decoupled from the codebase to prevent credential leaks.
* **Transport Security:** Strict adherence to iOS App Transport Security (ATS) standards.

## 🚀 Key Functionality

1.  **Dynamic Content Engine:** Real-time fetching of course modules and lessons.
2.  **Custom Media Player:**
    * Video streaming with custom controls.
    * Background audio playback for meditations (AVAudioSession).
3.  **State Management:** Global app state handling for user sessions and course progress.

## 📦 Installation

1.  Clone the repository:
    ```bash
    git clone [https://github.com/AlimkhanSlambek/savoa-ios-lms.git](https://github.com/AlimkhanSlambek/savoa-ios-lms.git)
    ```
2.  Open `SAVOA.xcodeproj` in Xcode 15+.
3.  **Important:** Create `APIEndpoints.swift` in `Core/Network/` and set your base URL:
    ```swift
    static let baseURL = "[https://api.your-domain.com](https://api.your-domain.com)"
    ```
4.  Build and Run (⌘+R).

---

**Author:** Alimkhan Slambek  
*Full-Stack Product Engineer (MSc CS, BSc Cybersecurity)*
