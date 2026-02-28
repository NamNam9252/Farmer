@echo off
echo Starting Backend ...
start "Server" cmd /k "cd server && npm i &&npm run dev"

echo Starting Frontend ...
start "client" cmd /k "cd client && flutter pub get && flutter run"

echo Both are starting in separate windows.