# Farmer

Full-stack Flutter & Node project

## Getting started

1. **Server**
   - Navigate to `server` and run `npm install` to install dependencies.
   - Start the API with `npm run start` or use the **Run Node Server** task.

2. **Client**
   - Navigate to `client` and run `flutter pub get` (usually happens automatically).
   - Use `flutter run` to launch the app or the **Run Flutter** task.

### VS Code helpers

* Tasks are defined in `.vscode/tasks.json`:
  * **Run Node Server** – starts the back end
  * **Run Flutter** – launches the mobile/desktop app
  * **Run Client & Server** – compound task that starts both in sequence

* A debug configuration for the server is available in `.vscode/launch.json`.
* Recommended extensions are listed in `.vscode/extensions.json`.

