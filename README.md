# PocketAI

PocketAI is a Flutter AI agent app built as a portfolio project to demonstrate LLM integration and tool-calling patterns, alongside my e-commerce and utility app work (Inspire Uplift, Pocket Tools, Sneaker Shop).

## What it does

PocketAI is a chat interface backed by Google's Gemini API. When a user asks something that requires live data or computation, the model doesn't guess — it emits a structured tool call, which PocketAI intercepts, executes, and feeds back to the model for a natural final answer.

Try:
- "What's the weather in Lahore?"
- "What's 45 * 12?"

## Architecture

- **State management:** `flutter_bloc` — classic Bloc pattern (`ChatEvent` → `ChatBloc` → `ChatState`), using `equatable` for state comparisons
- **LLM:** Gemini API (`gemini-1.5-flash`, free tier)
- **Tools:**
  - Weather — Open-Meteo API (free, no API key)
  - Calculator — `math_expressions` package (local, no network call)
- **Responsive UI:** `flutter_screenutil`
- **Agent loop:** `ChatBloc` sends the running conversation to Gemini. If the reply starts with `TOOL_CALL:weather:<city>` or `TOOL_CALL:calculate:<expr>`, the bloc parses it, runs the matching service, and sends the tool's result back to Gemini so it can phrase a natural response to the user.

## Project structure

```
lib/
  models/message_model.dart       # ChatMessage (user/ai sender)
  services/gemini_service.dart    # Gemini API calls + tool-calling system prompt
  services/weather_service.dart   # Open-Meteo geocode + current weather
  services/calculator_service.dart# Safe local math expression evaluation
  blocs/chat_event.dart           # SendMessageEvent
  blocs/chat_state.dart           # messages, isLoading, error
  blocs/chat_bloc.dart            # the agent loop
  screens/chat_screen.dart        # chat bubble UI
  main.dart                       # entry point, BlocProvider + ScreenUtilInit
```

## Setup

1. Get a free Gemini API key at https://ai.google.dev
2. Replace `YOUR_API_KEY_HERE` in `lib/services/gemini_service.dart`
3. `flutter pub get`
4. Run on a device or emulator

## Known limitations

- The Gemini API key is hardcoded in the client for this demo. **For a production app, never ship an API key in the client** — use a backend proxy or inject it as an environment variable at build time.
- No conversation persistence yet (in-memory only, resets on app restart).
- No response streaming yet — replies arrive as a single completion.

## Stack

| Layer | Choice | Why |
|---|---|---|
| LLM | Gemini 1.5 Flash | Free tier, fast |
| Weather | Open-Meteo | Free, no key required |
| Calculator | math_expressions | Local, no API cost |
| State management | flutter_bloc | Predictable event → state flow, testable |
| UI scaling | flutter_screenutil | Consistent responsive sizing |

---

Built by Dev Junaid as part of a Flutter portfolio alongside Pocket Tools and Sneaker Shop.
