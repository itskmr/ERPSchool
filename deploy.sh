#!/bin/bash

# School Management System - AWS EC2 Deployment Script
# Run this script on your EC2 instance

set -e  # Exit on any error

echo "🚀 Starting School Management System Deployment..."

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please don't run this script as root"
    exit 1
fi

# Create environment file if it doesn't exist
if [ ! -f .env.prod ]; then
    echo "📝 Creating environment file..."
    cat > .env.prod << EOF
# Production Environment Variables
MYSQL_PASSWORD=$(openssl rand -base64 32)
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
EOF
    echo "✅ Environment file created with random passwords"
fi

# Set proper permissions
echo "🔐 Setting proper permissions..."
sudo chmod 600 .env.prod
sudo chown ubuntu:ubuntu .env.prod

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p uploads
mkdir -p application/logs
mkdir -p ssl
sudo chown -R www-data:www-data uploads application/logs || echo "Warning: www-data user not found, will be handled by Docker"

# Build and start services
echo "🐳 Building and starting Docker services..."
docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d --build

# Wait for database to be ready
echo "⏳ Waiting for database to initialize..."
sleep 30

# Check if services are running
echo "🔍 Checking service status..."
docker-compose -f docker-compose.prod.yml ps

# Test database connection
echo "🗄️ Testing database connection..."
docker-compose -f docker-compose.prod.yml exec -T db mysql -u root -p$(grep MYSQL_ROOT_PASSWORD .env.prod | cut -d '=' -f2) school -e "SELECT 'Database is ready' as status;"

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Access your application at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "2. Default admin login: school@admin.com / 12345"
echo "3. Configure SSL certificate for HTTPS"
echo "4. Set up domain name if needed"
echo "5. Configure backups"
echo ""
echo "🔧 Useful commands:"
echo "  - View logs: docker-compose -f docker-compose.prod.yml logs -f"
echo "  - Restart services: docker-compose -f docker-compose.prod.yml restart"
echo "  - Stop services: docker-compose -f docker-compose.prod.yml down"
echo "" 