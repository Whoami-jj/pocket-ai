# 🤖 PocketAI

**PocketAI** is a Flutter-based AI assistant that provides conversational AI with built-in tools for **mathematical calculations** and **weather updates**.

Built with **Flutter + Dart + BLoC state management**, PocketAI is designed with a clean, responsive, and modern chat interface.

---

## ✨ Features

* 🤖 AI-powered conversational chat
* 🧮 Mathematical calculations
* 🌤️ Weather updates
* 💬 Interactive chat interface
* 🌓 Light & Dark theme
* 📱 Responsive Flutter UI
* ⚡ Fast API-based responses
* 🔐 Environment-based API configuration

---

## 🛠️ Tech Stack

| Technology             | Purpose                     |
| :--------------------- | :-------------------------- |
| **Flutter**            | Cross-platform UI framework |
| **Dart**               | Programming language        |
| **BLoC / Cubit**       | State management            |
| **Gemini API**         | AI-powered responses        |
| **HTTP**               | API communication           |
| **Flutter ScreenUtil** | Responsive UI               |
| **flutter_dotenv**     | Environment configuration   |

### State Management

PocketAI uses **BLoC/Cubit** for predictable and scalable state management.

```text
BLoC / Cubit
├── ChatBloc
└── ThemeCubit
```

---

## 🏗️ Architecture

The project follows a simple separation of responsibilities:

```text
lib/
│
├── blocs/
│   ├── chat_bloc.dart
│   ├── chat_event.dart
│   ├── chat_state.dart
│   └── theme_cubit.dart
│
├── models/
│   └── message_model.dart
│
├── screens/
│   └── chat_screen.dart
│
├── services/
│   ├── calculator_service.dart
│   ├── gemini_service.dart
│   └── weather_service.dart
│
└── main.dart
```

---

## 🧮 Calculator

PocketAI can process mathematical questions and use its calculator functionality to calculate expressions.

Example:

```text
What is 125 × 48?
```

---

## 🌤️ Weather

PocketAI can recognize weather-related questions and retrieve weather information for a requested location.

Example:

```text
What's the weather in Lahore?
```

---

## 🚀 Getting Started

### Prerequisites

Make sure you have installed:

* Flutter SDK
* Dart SDK
* Android Studio / Xcode
* Git

### Clone the repository

```bash
git clone https://github.com/Whoami-jj/pocket-ai.git
cd pocket-ai
```

### Install dependencies

```bash
flutter pub get
```

---

## 🔑 Environment Configuration

Create a `.env` file in the project root:

```env
GEMINI_API_KEY=your_gemini_api_key
```

The `.env` file is ignored by Git and should **never be committed**.

> ⚠️ For production applications, API credentials should ideally be handled through a secure backend rather than embedded in a client application.

---

## ▶️ Run the App

```bash
flutter run
```

For web:

```bash
flutter run -d chrome
```

For Windows:

```bash
flutter run -d windows
```

---

## 🧪 Testing

Run tests:

```bash
flutter test
```

Run static analysis:

```bash
flutter analyze
```

---

## 📱 Supported Platforms

Flutter allows PocketAI to target:

* Android
* iOS
* Web
* Windows
* macOS
* Linux

---

## 📊 Project Status

🚧 **Active Development**

PocketAI is currently under development, with plans for additional AI capabilities, improvements, and tools.

---

## 🤝 Contributing

Contributions and suggestions are welcome.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Commit your changes
5. Push the branch
6. Open a Pull Request

---

## 📄 License

License information will be added as the project develops.

---

### Built with ❤️ using Flutter & Dart
