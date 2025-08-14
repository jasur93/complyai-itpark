#!/bin/bash

# Quick Development Deployment for Comply AI
# This script sets up a minimal development environment

echo "🚀 Quick Development Setup for Comply AI..."

# Create basic .env file
cat > .env << EOF
# Development Environment
NODE_ENV=development
PORT=3001

# Database (using local PostgreSQL or Docker)
DB_HOST=localhost
DB_PORT=5432
DB_NAME=comply_ai
DB_USER=postgres
DB_PASSWORD=password

# JWT Secret (development only)
JWT_SECRET=dev-secret-key-not-for-production

# Optional API Keys (add your own)
OPENAI_API_KEY=your-openai-key-here
TELEGRAM_BOT_TOKEN=your-telegram-token-here
EIMZO_API_KEY=your-eimzo-key-here

# Frontend URL
FRONTEND_URL=http://localhost:3000
EOF

echo "✅ Environment file created"

# Start database with Docker
echo "🐘 Starting PostgreSQL database..."
docker run -d \
  --name comply-ai-dev-db \
  -e POSTGRES_DB=comply_ai \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=password \
  -p 5432:5432 \
  postgres:15-alpine

echo "⏳ Waiting for database to be ready..."
sleep 10

# Install backend dependencies
echo "📦 Installing backend dependencies..."
cd backend
npm install

# Start backend in development mode
echo "🚀 Starting backend server..."
npm run dev &
BACKEND_PID=$!

cd ..

# Install frontend dependencies
echo "📦 Installing frontend dependencies..."
cd frontend
npm install

# Start frontend in development mode
echo "🚀 Starting frontend server..."
npm run dev &
FRONTEND_PID=$!

cd ..

echo ""
echo "🎉 Development environment is starting up!"
echo ""
echo "📋 Access Information:"
echo "   Frontend: http://localhost:3000"
echo "   Backend API: http://localhost:3001"
echo "   Database: localhost:5432"
echo ""
echo "🔧 To stop the servers:"
echo "   kill $BACKEND_PID $FRONTEND_PID"
echo "   docker stop comply-ai-dev-db"
echo ""
echo "⏳ Servers are starting... Please wait a moment and then visit http://localhost:3000"

# Keep script running
wait