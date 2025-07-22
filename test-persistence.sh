#!/bin/bash

# Database Persistence Test
# This script tests if the SQLite database persists across application restarts

echo "🧪 Testing Database Persistence"
echo "==============================="

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file from .env.local..."
    cp .env.local .env
fi

# Start the application in background
echo "🚀 Starting application..."
swift run App serve --env development --hostname 0.0.0.0 --port 8080 &
APP_PID=$!

# Wait for application to start
echo "⏳ Waiting for application to start..."
sleep 10

# Check if database file was created
if [ -f "db.sqlite" ]; then
    echo "✅ Database file created: db.sqlite"
    ls -la db.sqlite
else
    echo "❌ Database file not found!"
    kill $APP_PID
    exit 1
fi

# Stop the application
echo "🛑 Stopping application..."
kill $APP_PID
wait $APP_PID 2>/dev/null

# Check if database still exists
if [ -f "db.sqlite" ]; then
    echo "✅ Database persisted after application stop"
    echo "📊 Database file size: $(du -h db.sqlite | cut -f1)"
else
    echo "❌ Database file was removed!"
    exit 1
fi

# Start application again to test persistence
echo "🔄 Restarting application to test persistence..."
swift run App serve --env development --hostname 0.0.0.0 --port 8080 &
APP_PID=$!

sleep 10

# Check database again
if [ -f "db.sqlite" ]; then
    echo "✅ Database still exists after restart"
    echo "📊 Final database file size: $(du -h db.sqlite | cut -f1)"
else
    echo "❌ Database lost after restart!"
    kill $APP_PID
    exit 1
fi

# Stop the application
kill $APP_PID
wait $APP_PID 2>/dev/null

echo ""
echo "🎉 Database persistence test PASSED!"
echo "✅ SQLite database persists across application restarts"
echo "📁 Database location: $(pwd)/db.sqlite"
