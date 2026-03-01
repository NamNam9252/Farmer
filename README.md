# Farmer

Full-stack Flutter & Node project

## Getting started

1. **Server**
   - Navigate to `server` and run `npm install` to install dependencies.
   - Start the API with `npm run start` or use the **Run Node Server** task.

2. **Client**
   - Navigate to `client` and run `flutter pub get` (usually happens automatically).
   - Use `flutter run` to launch the app or the **Run Flutter** task.

### Clone and run the project

 - to clone the repo 

```
git clone https://github.com/NamNam9252/Farmer.git
```
 - to run 

```
./run
```

### folder structre till now 

```
S:\Farmer
├── client
│   ├── analysis_options.yaml
│   ├── android
│   │   ├── app
│   │   │   ├── build.gradle.kts
│   │   │   └── src
│   │   ├── build.gradle.kts
│   │   ├── client_android.iml
│   │   ├── gradle
│   │   │   └── wrapper
│   │   ├── gradle.properties
│   │   ├── gradlew
│   │   ├── gradlew.bat
│   │   ├── local.properties
│   │   └── settings.gradle.kts
│   ├── client.iml
│   ├── ios
│   │   ├── Flutter
│   │   ├── Runner
│   │   ├── Runner.xcodeproj
│   │   ├── Runner.xcworkspace
│   │   └── RunnerTests
│   ├── lib
│   │   └── main.dart
│   ├── linux
│   │   ├── CMakeLists.txt
│   │   ├── flutter
│   │   └── runner
│   ├── macos
│   │   ├── Flutter
│   │   ├── Runner
│   │   ├── Runner.xcodeproj
│   │   ├── Runner.xcworkspace
│   │   └── RunnerTests
│   ├── pubspec.lock
│   ├── pubspec.yaml
│   ├── README.md
│   ├── test
│   │   └── widget_test.dart
│   ├── web
│   │   ├── favicon.png
│   │   ├── icons
│   │   ├── index.html
│   │   └── manifest.json
│   └── windows
│       ├── CMakeLists.txt
│       ├── flutter
│       └── runner
├── README.md
├── run.bat
└── server
    ├── index.ts
    ├── lib
    │   └── prisma.ts
    ├── package-lock.json
    ├── package.json
    ├── prisma
    │   └── schema.prisma
    ├── prisma.config.ts
    ├── src
    ├── tests
    │   └── prisma.script.ts
    └── tsconfig.json
```

* A debug configuration for the server is available in `.vscode/launch.json`.
* Recommended extensions are listed in `.vscode/extensions.json`.

