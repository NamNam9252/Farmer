@echo off
echo Starting Backend ...
start "Server" cmd /k "cd server && npm run dev"

echo Starting Frontend ...
start "Server" cmd /k "cd client && flutter run"

echo Both are starting in separate windows.