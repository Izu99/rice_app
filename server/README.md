# Rice Mill ERP Backend

A comprehensive multi-tenant Rice Mill ERP backend API built with Node.js, Express, and MongoDB. Features offline-first synchronization, advanced stock management, transaction processing, and comprehensive reporting.

## 🚀 Features

### Core Functionality
- **Multi-tenant Architecture**: Complete company isolation with secure data separation
- **Offline-First Design**: Full synchronization capabilities for mobile apps
- **Advanced Stock Management**: Weighted average pricing, low-stock alerts
- **Transaction Processing**: Buy/sell operations with automatic stock updates
- **Comprehensive Reporting**: Dashboard analytics, financial reports, performance metrics
- **Audit Logging**: Complete security and activity tracking

### Security & Performance
- **JWT Authentication**: Secure token-based authentication with role management
- **Rate Limiting**: Protection against abuse with configurable limits
- **Input Validation**: Comprehensive validation and sanitization
- **Data Encryption**: Password hashing with bcrypt, data protection
- **CORS Protection**: Configurable cross-origin resource sharing

### Business Features
- **Customer Management**: Balance tracking, transaction history
- **Milling Operations**: Paddy processing with efficiency calculations
- **Payment Processing**: Partial payments, balance management
- **Purchase Management**: Supplier tracking, payment reconciliation
- **Paddy Type Management**: Quality grades, yield characteristics

## 🛠️ Tech Stack

- **Runtime**: Node.js (>=14.0.0)
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose ODM
- **Authentication**: JSON Web Tokens (JWT)
- **Security**: Helmet, CORS, Rate Limiting, Input Sanitization
- **Validation**: Express Validator
- **Process Management**: PM2 (Production)

## 📋 Prerequisites

- Node.js >= 14.0.0
- MongoDB >= 4.4
- npm >= 6.0.0

## 🚀 Quick Start

### 1. Clone and Install

```bash
# Clone the repository
git clone https://github.com/your-org/rice-mill-erp-backend.git
cd rice-mill-erp-backend

# Install dependencies
npm install
```

### 2. Environment Setup

```bash
# Copy environment configuration
cp .env.example .env

# Edit .env with your settings
nano .env
```

**Required Environment Variables:**
```env
NODE_ENV=development
PORT=5000
MONGODB_URI=mongodb://localhost:27017/rice_mill_erp
JWT_SECRET=your-super-secret-jwt-key-minimum-32-characters
SUPER_ADMIN_EMAIL=superadmin@ricemill.com
SUPER_ADMIN_PASSWORD=SuperSecure@123
SUPER_ADMIN_NAME=Super Administrator
```

### 3. Generate Secure JWT Secret

```bash
# Generate a secure JWT secret
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### 4. Start MongoDB

```bash
# Using Docker
docker run -d -p 27017:27017 --name mongodb mongo:latest

# Or using local MongoDB installation
mongod
```

### 5. Run the Application

```bash
# Development mode (with auto-restart)
npm run dev

# Production mode
npm start
```

The API will be available at `http://localhost:5000/api`

## 📖 API Documentation

### Base URL
```
http://localhost:5000/api
```

### Authentication
All business endpoints require JWT authentication. Include the token in the Authorization header:
```
Authorization: Bearer <your-jwt-token>
```

### Key Endpoints

#### Authentication
- `POST /auth/login` - User login
- `POST /auth/refresh-token` - Refresh JWT token
- `POST /auth/forgot-password` - Request password reset
- `POST /auth/reset-password` - Reset password

#### Super Admin
- `GET /admin/dashboard` - System dashboard
- `GET /admin/companies` - Company management
- `POST /admin/companies` - Create company

#### Business Operations
- `GET /customers` - Customer management
- `GET /stock` - Stock management
- `POST /transactions/buy` - Purchase transactions
- `POST /transactions/sell` - Sales transactions
- `GET /reports/dashboard` - Dashboard analytics

### Response Format

**Success Response:**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... },
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

**Error Response:**
```json
{
  "success": false,
  "message": "Error description",
  "errors": [
    {
      "field": "email",
      "message": "Email is required",
      "value": ""
    }
  ],
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

### HTTP Status Codes

| Code | Status | Description |
|------|--------|-------------|
| 200 | OK | Request successful |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Validation error or malformed request |
| 401 | Unauthorized | Missing or invalid authentication token |
| 403 | Forbidden | Insufficient permissions for the operation |
| 404 | Not Found | Requested resource not found |
| 409 | Conflict | Resource conflict (e.g., duplicate data) |
| 422 | Unprocessable Entity | Validation failed |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `NODE_ENV` | Environment mode | `development` | Yes |
| `PORT` | Server port | `5000` | Yes |
| `MONGODB_URI` | MongoDB connection string | - | Yes |
| `JWT_SECRET` | JWT signing secret | - | Yes |
| `JWT_EXPIRE` | JWT expiration time | `24h` | No |
| `SUPER_ADMIN_EMAIL` | Super admin email | - | Yes |
| `SUPER_ADMIN_PASSWORD` | Super admin password | - | Yes |
| `FRONTEND_URL` | Frontend URL for CORS | - | Production |

### Database Indexes

The application automatically creates optimized indexes for:
- User authentication and company isolation
- Transaction queries and reporting
- Stock management and stock tracking
- Audit logging and security monitoring

## 🧪 Testing

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run with coverage
npm run test:coverage
```

## 🚀 Deployment

### PM2 Configuration

Create `ecosystem.config.js`:

```javascript
module.exports = {
  apps: [{
    name: 'rice-mill-erp',
    script: 'src/server.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 5000
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 5000
    }
  }]
};
```

### Production Commands

```bash
# Start with PM2
npm run pm2:start

# View logs
npm run pm2:logs

# Monitor processes
npm run pm2:monit

# Restart application
npm run pm2:restart
```

### Docker Deployment

```dockerfile
FROM node:16-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 5000

CMD ["npm", "start"]
```

## 🔒 Security

### Implemented Security Measures

- **Helmet**: Security headers
- **Rate Limiting**: API abuse protection
- **Input Sanitization**: XSS and NoSQL injection prevention
- **CORS**: Configurable cross-origin policies
- **JWT**: Secure token-based authentication
- **Password Hashing**: bcrypt with salt rounds
- **Audit Logging**: Complete activity tracking

### Security Best Practices

1. **Change default credentials** in production
2. **Use strong JWT secrets** (minimum 32 characters)
3. **Enable HTTPS** in production
4. **Regular security updates** of dependencies
5. **Monitor logs** for suspicious activities
6. **Implement backup strategies**

## 📊 Monitoring & Logging

### Application Logs

- Request/response logging with performance metrics
- Error tracking with detailed stack traces
- Security event logging
- Database connection monitoring

### Health Checks

```bash
# Health check endpoint
GET /api/health

# Database health check
GET /api/health/db
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow ESLint configuration
- Write comprehensive tests
- Update documentation
- Use conventional commit messages
- Maintain code coverage above 80%

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue on GitHub
- Check the documentation
- Review the API documentation

## 📋 Changelog

### Version 1.0.0
- Initial release with complete ERP functionality
- Multi-tenant architecture
- Offline-first synchronization
- Comprehensive business logic
- Production-ready security

---

**Built with ❤️ for Rice Mill management efficiency**
