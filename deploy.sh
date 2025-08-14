#!/bin/bash

# Comply AI Deployment Script
# This script deploys the complete Comply AI system using Docker Compose

set -e

echo "🚀 Starting Comply AI Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    print_status "Creating .env file..."
    cat > .env << EOF
# Database Configuration
DB_PASSWORD=comply_ai_secure_password_$(date +%s)

# JWT Secret (change in production)
JWT_SECRET=your-super-secret-jwt-key-$(openssl rand -hex 32)

# API Keys (add your actual keys)
OPENAI_API_KEY=your-openai-api-key-here
TELEGRAM_BOT_TOKEN=your-telegram-bot-token-here
EIMZO_API_KEY=your-eimzo-api-key-here

# Environment
NODE_ENV=production
EOF
    print_success ".env file created. Please update it with your actual API keys."
fi

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p backend/storage/reports
mkdir -p backend/storage/uploads
mkdir -p backend/logs
mkdir -p nginx/ssl

# Stop existing containers
print_status "Stopping existing containers..."
docker-compose down --remove-orphans

# Build and start services
print_status "Building and starting services..."
docker-compose up --build -d

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 30

# Check service health
print_status "Checking service health..."

# Check database
if docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
    print_success "Database is ready"
else
    print_error "Database is not ready"
fi

# Check backend
if curl -f http://localhost:3001/health > /dev/null 2>&1; then
    print_success "Backend API is ready"
else
    print_warning "Backend API might not be ready yet"
fi

# Check frontend
if curl -f http://localhost:3000 > /dev/null 2>&1; then
    print_success "Frontend is ready"
else
    print_warning "Frontend might not be ready yet"
fi

# Show running containers
print_status "Running containers:"
docker-compose ps

# Show logs
print_status "Recent logs:"
docker-compose logs --tail=20

print_success "🎉 Comply AI deployment completed!"
echo ""
echo "📋 Access Information:"
echo "   Frontend: http://localhost:3000"
echo "   Backend API: http://localhost:3001"
echo "   Database: localhost:5432"
echo ""
echo "🔧 Management Commands:"
echo "   View logs: docker-compose logs -f [service_name]"
echo "   Stop services: docker-compose down"
echo "   Restart services: docker-compose restart"
echo "   Update services: docker-compose up --build -d"
echo ""
echo "⚠️  Important:"
echo "   1. Update your .env file with actual API keys"
echo "   2. Configure SSL certificates for production"
echo "   3. Set up proper backup procedures"
echo "   4. Monitor logs regularly"