# EC2 Instance Management Guide

## 📝 Table of Contents
1. [Updating Code on Server](#updating-code-on-server)
2. [Shutting Down Instance](#shutting-down-instance)
3. [Starting Instance](#starting-instance)
4. [Backup Procedures](#backup-procedures)
5. [Cost Management](#cost-management)

---

## 🔄 Updating Code on Server

### Method 1: Quick Update (Recommended)
When you've made code changes and pushed to GitHub:

```bash
# SSH into your EC2
ssh -i your-key.pem ubuntu@13.203.219.244

# Navigate to project
cd ~/Smart-Agriculture-Nutrition

# Pull latest changes
git pull origin main

# Rebuild and restart containers
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d --build

# Check status
docker-compose -f docker-compose.prod.yml ps

# View logs to ensure everything started correctly
docker-compose -f docker-compose.prod.yml logs -f
```

### Method 2: Using Deploy Script
For fresh deployment or major changes:

```bash
# SSH into your EC2
ssh -i your-key.pem ubuntu@13.203.219.244

# Run deploy script (it will pull latest code automatically)
cd ~/Smart-Agriculture-Nutrition
./scripts/deploy.sh
```

### Method 3: Update Without Downtime
For minor updates without stopping the service:

```bash
# Pull latest code
git pull origin main

# Build new image
docker-compose -f docker-compose.prod.yml build app

# Rolling restart (minimal downtime)
docker-compose -f docker-compose.prod.yml up -d --no-deps --build app
```

---

## 🛑 Shutting Down Instance

### Option 1: Stop Instance (Recommended - Saves Money)
**Use this when you don't need the server for a while**

#### Via AWS Console:
1. Go to EC2 Dashboard
2. Select your instance
3. Click "Instance State" → "Stop Instance"
4. Confirm the action

#### Via AWS CLI:
```bash
aws ec2 stop-instances --instance-ids i-your-instance-id
```

**Important Notes:**
- ✅ **Billing stops** for compute (you still pay for storage)
- ✅ **Data is preserved** on EBS volume
- ✅ **Private IP may change** when restarted
- ✅ **Public IP will change** unless using Elastic IP

### Option 2: Terminate Instance (Permanent Deletion)
**⚠️ WARNING: This permanently deletes everything!**

#### Via AWS Console:
1. Go to EC2 Dashboard
2. Select your instance
3. Click "Instance State" → "Terminate Instance"
4. Type "terminate" to confirm

#### Via AWS CLI:
```bash
aws ec2 terminate-instances --instance-ids i-your-instance-id
```

**This will:**
- ❌ **Delete all data** (unless EBS is configured to persist)
- ❌ **Cannot be undone**
- ✅ **Billing stops completely**

---

## 🚀 Starting Instance

### After Stopping (Not Terminating):

#### Via AWS Console:
1. Go to EC2 Dashboard
2. Select your stopped instance
3. Click "Instance State" → "Start Instance"
4. Wait for status checks to pass
5. Note the new public IP (if not using Elastic IP)

#### Via AWS CLI:
```bash
aws ec2 start-instances --instance-ids i-your-instance-id
```

### After Starting, Restart Your Application:
```bash
# SSH with new IP (if changed)
ssh -i your-key.pem ubuntu@new-public-ip

# Start Docker containers
cd ~/Smart-Agriculture-Nutrition
docker-compose -f docker-compose.prod.yml up -d

# Verify everything is running
docker-compose -f docker-compose.prod.yml ps
```

---

## 💾 Backup Procedures

### Before Major Updates:
```bash
# Backup database
docker exec agriculture-postgres pg_dump -U agriculture_user smart_agriculture_nutrition > backup_$(date +%Y%m%d).sql

# Backup entire project
tar -czf smart-agri-backup-$(date +%Y%m%d).tar.gz ~/Smart-Agriculture-Nutrition

# Copy to S3 (optional)
aws s3 cp backup_$(date +%Y%m%d).sql s3://your-bucket/backups/
```

### Create EBS Snapshot:
1. Go to EC2 → Volumes
2. Select your volume
3. Actions → Create Snapshot
4. Add description and tags

---

## 💰 Cost Management

### To Save Money:

#### 1. **Stop Instance When Not in Use**
```bash
# Stop instance (via AWS Console or CLI)
aws ec2 stop-instances --instance-ids i-your-instance-id
```
- Saves ~$15-30/month for t2.small

#### 2. **Use Scheduled Start/Stop**
Create Lambda functions to automatically start/stop:
- Start at 9 AM on weekdays
- Stop at 6 PM on weekdays
- Keep stopped on weekends

#### 3. **Use Elastic IP (Optional)**
Prevents IP changes when stopping/starting:
```bash
# Allocate Elastic IP
aws ec2 allocate-address

# Associate with instance
aws ec2 associate-address --instance-id i-xxx --public-ip x.x.x.x
```
Cost: ~$3.60/month when instance is stopped

#### 4. **Monitor Usage**
- Set up billing alerts
- Use AWS Cost Explorer
- Review CloudWatch metrics

---

## 🔧 Common Management Commands

### Check Application Status:
```bash
# View running containers
docker ps

# Check application logs
docker logs agriculture-app --tail 100

# Check database logs
docker logs agriculture-postgres --tail 50

# View resource usage
docker stats
```

### Restart Services:
```bash
# Restart all services
docker-compose -f docker-compose.prod.yml restart

# Restart specific service
docker-compose -f docker-compose.prod.yml restart app

# Stop all services
docker-compose -f docker-compose.prod.yml down

# Start all services
docker-compose -f docker-compose.prod.yml up -d
```

### Clean Up Docker:
```bash
# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune

# Remove everything unused
docker system prune -a
```

---

## 📋 Quick Reference

| Action             | Command                                                                                                 |
| ------------------ | ------------------------------------------------------------------------------------------------------- |
| **Update Code**    | `git pull && docker-compose -f docker-compose.prod.yml up -d --build`                                   |
| **Stop Services**  | `docker-compose -f docker-compose.prod.yml down`                                                        |
| **Start Services** | `docker-compose -f docker-compose.prod.yml up -d`                                                       |
| **View Logs**      | `docker-compose -f docker-compose.prod.yml logs -f`                                                     |
| **Stop EC2**       | AWS Console → Stop Instance                                                                             |
| **Start EC2**      | AWS Console → Start Instance                                                                            |
| **Backup DB**      | `docker exec agriculture-postgres pg_dump -U agriculture_user smart_agriculture_nutrition > backup.sql` |

---

## 🚨 Emergency Procedures

### If Application Crashes:
```bash
# Check what went wrong
docker-compose -f docker-compose.prod.yml logs --tail 100

# Restart everything
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d

# If still issues, rebuild
docker-compose -f docker-compose.prod.yml down
docker system prune -a
docker-compose -f docker-compose.prod.yml up -d --build
```

### If Can't SSH:
1. Check Security Group (port 22 open?)
2. Check instance status in AWS Console
3. Reboot instance from AWS Console
4. Check if IP changed (if not using Elastic IP)

---

## 📞 Support

For issues:
1. Check application logs first
2. Verify Security Groups
3. Ensure Docker is running
4. Check disk space: `df -h`
5. Check memory: `free -m`
