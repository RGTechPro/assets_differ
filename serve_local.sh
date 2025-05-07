#!/bin/bash

echo "🚀 Flutter Web Local Server"
echo "==============================="

# Check if the build/web directory exists
if [ ! -d "build/web" ]; then
  echo "⚠️  build/web directory not found!"
  echo "Building Flutter web application..."
  flutter build web
  
  if [ $? -ne 0 ]; then
    echo "❌ Flutter build failed. Please fix any issues and try again."
    exit 1
  fi
  
  echo "✅ Flutter web build completed successfully!"
else
  echo "✅ build/web directory found"
fi

# Find an available port (preferring 8000)
PORT=8000
while netstat -tuln | grep -q ":$PORT "; do
  echo "⚠️  Port $PORT is already in use."
  PORT=$((PORT+1))
done

echo "🌍 Starting server on http://localhost:$PORT"
echo "📂 Serving from $(pwd)/build/web"
echo "Press Ctrl+C to stop the server."
echo "==============================="

# Check if Python 3 is available
if command -v python3 &>/dev/null; then
  python3 -m http.server $PORT --directory build/web
# Check if Python is available and is Python 3
elif command -v python &>/dev/null && python --version 2>&1 | grep -q "Python 3"; then
  python -m http.server $PORT --directory build/web
# If none of the above, try using the npx http-server package as a fallback
elif command -v npx &>/dev/null; then
  echo "Python not found, using Node's http-server instead."
  npx http-server ./build/web -p $PORT -c-1
else
  echo "❌ Error: Could not find Python 3 or npm/npx."
  echo "Please install Python 3 or Node.js to run this script."
  exit 1
fi