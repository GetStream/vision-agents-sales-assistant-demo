# Sales Assistant
![Sales assistant running on MacOS demo](./gh_assets/screenshot.png)
Realtime meeting coach which lives on your desktop, sliently listening and providing realtiem gudiance for your conversations. Built by the [Vision Agents](https://github.com/GetStream/vision-agents) team at [Stream](https://getstream.io). This repo contains the frontend MacOs code, the accompanying backend server can be found under the [examples](https://github.com/GetStream/Vision-Agents/tree/main/examples) folder of the main Vision Agents repo. 

## API keys

- **Frontend** — This app uses [Stream](https://getstream.io) for real-time video and chat. Get a free Stream API key from the [Stream dashboard](https://getstream.io/try-for-free/).

- **Backend** — The Vision Agents backend lets you plug in any LLM you like (e.g. OpenAI, Gemini, Claude). Configure your chosen provider and its API keys in the backend; the frontend only talks to your agent server.

## Prerequisites

- **Flutter** — [Install Flutter](https://docs.flutter.dev/get-started/install) and ensure the macOS desktop target is enabled.
- **CocoaPods** — Required for the macOS runner. Install with:
  ```bash
  sudo gem install cocoapods
  ```
  Verify with `pod --version`.

## Backend

The app expects an agent server at `http://localhost:8000` that provides Stream auth tokens (e.g. `GET /auth/token?user_id=...`).

Run the backend from the [Vision Agents](https://github.com/GetStream/vision-agents) repo. Clone it and start one of the examples that runs an HTTP server (see the [examples](https://github.com/GetStream/vision-agents/tree/main/examples) directory). Ensure the server is listening on port 8000 before launching the app.

## Run locally

1. Start the Vision Agents backend (see above) so it is available at `http://localhost:8000`.

2. Install dependencies and CocoaPods:
   ```bash
   flutter pub get
   cd macos && pod install && cd ..
   ```

3. Run the app:
   ```bash
   flutter run -d macos
   ```
