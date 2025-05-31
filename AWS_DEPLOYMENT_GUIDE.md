# 🚀 AWS EC2 Deployment Guide - School Management System

This guide provides step-by-step instructions to deploy your PHP CodeIgniter School Management System on Amazon EC2.

## 📋 Prerequisites

- AWS Account with billing configured
- Basic understanding of SSH and command line
- Domain name (optional but recommended)

## 🏗️ Phase 1: AWS Infrastructure Setup

### 1.1 Create EC2 Instance

1. **Login to AWS Console** → Navigate to EC2 Dashboard
2. **Launch Instance**:
   - **Name**: `school-management-server`
   - **AMI**: Ubuntu Server 22.04 LTS (Free tier eligible)
   - **Instance Type**: 
     - Development: `t2.micro` (Free tier)
     - Production: `t3.medium` or `t3.large`
   - **Key Pair**: Create new or select existing
   - **Storage**: 20-50 GB gp3 SSD

### 1.2 Configure Security Groups

Create security group with these rules:

| Type  | Protocol | Port | Source    | Description |
|-------|----------|------|-----------|-------------|
| SSH   | TCP      | 22   | Your IP   | SSH Access  |
| HTTP  | TCP      | 80   | 0.0.0.0/0 | Web Traffic |
| HTTPS | TCP      | 443  | 0.0.0.0/0 | Secure Web  |

### 1.3 Elastic IP (Recommended)

1. Allocate Elastic IP address
2. Associate with your EC2 instance
3. Update DNS records if using custom domain

## 🔧 Phase 2: Server Setup

### 2.1 Connect to Instance

```bash
# Connect via SSH
ssh -i your-key.pem ubuntu@your-ec2-public-ip

# Update system
sudo apt update && sudo apt upgrade -y
```

### 2.2 Install Docker & Dependencies

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install additional tools
sudo apt install -y git htop curl wget unzip

# Logout and login again for Docker group changes
exit
```

### 2.3 Clone Repository

```bash
ssh -i your-key.pem ubuntu@your-ec2-public-ip

# Clone your repository
git clone <your-repository-url>
cd php_erp

# Make scripts executable
chmod +x deploy.sh backup.sh
```

## 🚀 Phase 3: Application Deployment

### 3.1 Deploy Application

```bash
# Run the deployment script
./deploy.sh
```

This script will:
- Create secure environment variables
- Set proper file permissions
- Build and start Docker containers
- Initialize the database
- Verify deployment

### 3.2 Verify Deployment

1. **Check Services**:
   ```bash
   docker-compose -f docker-compose.prod.yml ps
   ```

2. **View Logs**:
   ```bash
   docker-compose -f docker-compose.prod.yml logs -f
   ```

3. **Access Application**:
   - Open browser: `http://your-ec2-public-ip`
   - Login: `school@admin.com` / `12345`

## 🔒 Phase 4: Security & SSL Setup

### 4.1 Install Certbot for SSL

```bash
# Install Certbot
sudo apt install -y certbot

# Get SSL certificate (replace with your domain)
sudo certbot certonly --standalone -d your-domain.com

# Copy certificates to ssl directory
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem ssl/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem ssl/key.pem
sudo chown ubuntu:ubuntu ssl/*.pem
```

### 4.2 Enable HTTPS in Nginx

Edit `nginx.conf` and uncomment the HTTPS server block, then restart:

```bash
docker-compose -f docker-compose.prod.yml restart nginx
```

### 4.3 Security Checklist

- [ ] Change default admin password
- [ ] Update database passwords in `.env.prod`
- [ ] Configure firewall rules
- [ ] Enable fail2ban (optional)
- [ ] Regular security updates

## 💾 Phase 5: Backup & Monitoring

### 5.1 Setup Automated Backups

```bash
# Make backup script executable
chmod +x backup.sh

# Add to crontab (daily backup at 2 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * /home/ubuntu/php_erp/backup.sh") | crontab -
```

### 5.2 Monitoring Commands

```bash
# View application logs
docker-compose -f docker-compose.prod.yml logs -f app

# View database logs
docker-compose -f docker-compose.prod.yml logs -f db

# Monitor system resources
htop

# Check disk usage
df -h
```

## 🔧 Phase 6: Maintenance & Updates

### 6.1 Application Updates

```bash
# Pull latest code
git pull origin main

# Rebuild and restart
docker-compose -f docker-compose.prod.yml up -d --build
```

### 6.2 Database Maintenance

```bash
# Backup before maintenance
./backup.sh

# Access database
docker-compose -f docker-compose.prod.yml exec db mysql -u root -p school
```

### 6.3 SSL Certificate Renewal

```bash
# Renew certificates (Let's Encrypt)
sudo certbot renew

# Copy renewed certificates
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem ssl/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem ssl/key.pem
sudo chown ubuntu:ubuntu ssl/*.pem

# Restart nginx
docker-compose -f docker-compose.prod.yml restart nginx
```

## 📊 Cost Optimization

### EC2 Instance Sizing

| Usage Level | Instance Type | Monthly Cost* |
|-------------|---------------|---------------|
| Development | t2.micro      | $8-10         |
| Small School| t3.small      | $15-20        |
| Medium School| t3.medium     | $30-40        |
| Large School| t3.large      | $60-80        |

*Approximate costs, varies by region

### Storage Optimization

- Use gp3 volumes for better performance/cost ratio
- Implement log rotation
- Regular cleanup of old backups
- Consider S3 for file storage

## 🆘 Troubleshooting

### Common Issues

1. **500 Internal Server Error**:
   ```bash
   # Check application logs
   docker-compose -f docker-compose.prod.yml logs app
   
   # Check file permissions
   ls -la uploads/ application/logs/
   ```

2. **Database Connection Error**:
   ```bash
   # Check database status
   docker-compose -f docker-compose.prod.yml exec db mysql -u root -p school -e "SELECT 1"
   ```

3. **Out of Disk Space**:
   ```bash
   # Clean Docker
   docker system prune -a
   
   # Check large files
   du -sh /*
   ```

### Support Commands

```bash
# Restart all services
docker-compose -f docker-compose.prod.yml restart

# Full restart (with rebuild)
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d --build

# Emergency database backup
./backup.sh
```

## 📞 Production Checklist

Before going live:

- [ ] SSL certificate configured
- [ ] Default passwords changed
- [ ] Backup system tested
- [ ] Monitoring setup
- [ ] Security group properly configured
- [ ] Domain name configured (if applicable)
- [ ] User acceptance testing completed
- [ ] Performance testing done
- [ ] Documentation updated

## 📈 Scaling Considerations

For high-traffic schools:

1. **Load Balancer**: Use Application Load Balancer
2. **Database**: Consider RDS for managed MySQL
3. **File Storage**: Move uploads to S3
4. **CDN**: Use CloudFront for static assets
5. **Auto Scaling**: Configure auto scaling groups

---

**Support**: For issues during deployment, check logs and refer to the troubleshooting section above. 