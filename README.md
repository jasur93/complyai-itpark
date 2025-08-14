# Comply AI - AI-Powered Compliance System

🤖 **Automated reporting, auditing, and early violation alerts for IT Park resident companies**

## 🌟 Features

- **AI Report Generator** - One-click IT Park-formatted reports
- **Real-Time Audit Monitor** - Anomaly detection and risk scoring
- **E-Signature Integration** - Business trip reports and compliance documents
- **Early Warning Alerts** - Telegram/Email notifications
- **Virtual Assistant** - 24/7 compliance guidance
- **Multi-system Integration** - 1C, QuickBooks, ERP connections

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   React Frontend │    │  Node.js Backend │    │  PostgreSQL DB  │
│   (Port 3000)    │◄──►│   (Port 3001)    │◄──►│   (Port 5432)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌─────────────────┐              │
         └──────────────►│   Redis Cache   │◄─────────────┘
                        │   (Port 6379)   │
                        └─────────────────┘
```

## 🚀 Quick Deployment

### Prerequisites

- Docker & Docker Compose
- Git
- 4GB+ RAM
- 10GB+ disk space

### 1. Clone Repository

```bash
git clone <your-repo-url>
cd comply-ai
```

### 2. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit with your API keys
nano .env
```

### 3. Deploy with One Command

```bash
# Make deploy script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

### 4. Access Your Application

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:3001
- **API Docs**: http://localhost:3001/api-docs

## 🔧 Manual Deployment

### Backend Setup

```bash
cd backend
npm install
npm run dev
```

### Frontend Setup

```bash
cd frontend
npm install
npm run dev
```

### Database Setup

```bash
# Start PostgreSQL
docker run -d \
  --name comply-ai-db \
  -e POSTGRES_DB=comply_ai \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=password \
  -p 5432:5432 \
  postgres:15-alpine

# Run migrations
npm run migrate
```

## 📋 Environment Variables

Create a `.env` file in the root directory:

```env
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=comply_ai
DB_USER=postgres
DB_PASSWORD=your_secure_password

# JWT
JWT_SECRET=your_super_secret_jwt_key

# AI Services
OPENAI_API_KEY=your_openai_api_key

# Notifications
TELEGRAM_BOT_TOKEN=your_telegram_bot_token

# E-Signature
EIMZO_API_KEY=your_eimzo_api_key

# Environment
NODE_ENV=production
```

## 🔐 Security Configuration

### 1. SSL/TLS Setup

```bash
# Generate SSL certificates
mkdir -p nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/comply-ai.key \
  -out nginx/ssl/comply-ai.crt
```

### 2. Firewall Configuration

```bash
# Allow only necessary ports
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 22/tcp
ufw enable
```

## 📊 Monitoring & Maintenance

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend
```

### Database Backup

```bash
# Create backup
docker-compose exec postgres pg_dump -U postgres comply_ai > backup.sql

# Restore backup
docker-compose exec -T postgres psql -U postgres comply_ai < backup.sql
```

### Update Application

```bash
# Pull latest changes
git pull origin main

# Rebuild and restart
docker-compose up --build -d
```

## 🧪 Testing

### Run Backend Tests

```bash
cd backend
npm test
```

### Run Frontend Tests

```bash
cd frontend
npm test
```

### API Testing

```bash
# Health check
curl http://localhost:3001/health

# Test authentication
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'
```

## 🔧 Development

### Project Structure

```
comply-ai/
├── backend/                 # Node.js API server
│   ├── src/
│   │   ├── controllers/     # Route controllers
│   │   ├── models/          # Database models
│   │   ├── services/        # Business logic
│   │   ├── middleware/      # Express middleware
│   │   └── routes/          # API routes
│   └── Dockerfile
├── frontend/                # React application
│   ├── src/
│   │   ├── components/      # React components
│   │   ├── pages/           # Page components
│   │   ├── hooks/           # Custom hooks
│   │   └── services/        # API services
│   └── Dockerfile
├── docs/                    # Documentation
├── docker-compose.yml       # Container orchestration
└── deploy.sh               # Deployment script
```

### Adding New Features

1. **Backend API Endpoint**:
   ```bash
   # Create controller
   touch backend/src/controllers/newFeatureController.js

   # Create route
   touch backend/src/routes/newFeature.js

   # Add to main app
   # Edit backend/src/app.js
   ```

2. **Frontend Component**:
   ```bash
   # Create component
   touch frontend/src/components/NewFeature.tsx

   # Create page
   touch frontend/src/pages/NewFeaturePage.tsx

   # Add route
   # Edit frontend/src/App.tsx
   ```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📞 Support

- **Documentation**: [Wiki](link-to-wiki)
- **Issues**: [GitHub Issues](link-to-issues)
- **Email**: support@comply-ai.com
- **Telegram**: @comply-ai-support

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- OpenAI for GPT-4 integration
- IT Park administration for requirements
- React and Node.js communities
- All contributors and testers

---

**Made with ❤️ for IT Park resident companies**