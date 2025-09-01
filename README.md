# Apache Superset 6.0.0rc1 Docker Setup

Complete production-ready Apache Superset setup using Docker Compose.

## Architecture

- **Apache Superset 6.0.0rc1**: Web application
- **PostgreSQL 16**: Metadata database
- **Redis 7**: Caching and Celery broker
- **Celery Workers**: Async task processing

## Quick Start

### 1. Configure Environment

Update passwords in `.env`:
```bash
# Generate secure SECRET_KEY
openssl rand -base64 42

# Edit .env and update:
# - POSTGRES_PASSWORD
# - SUPERSET_SECRET_KEY (use generated key above)
# - ADMIN_PASSWORD
```

### 2. Start Superset

```bash
docker compose up -d
```

### 3. Access Superset

- **URL**: http://localhost:8088
- **Username**: `admin` (or your `ADMIN_USERNAME`)
- **Password**: Value from `ADMIN_PASSWORD` in `.env`

## Environment Configuration

Key variables in `.env`:

| Variable | Description | Default |
|----------|-------------|---------|
| `POSTGRES_PASSWORD` | Database password | **Required** |
| `SUPERSET_SECRET_KEY` | Flask secret key | **Required** |
| `ADMIN_PASSWORD` | Admin user password | **Required** |
| `SUPERSET_PORT` | Web UI port | 8088 |
| `SUPERSET_LOAD_EXAMPLES` | Load sample data | no |

## Management Commands

### Service Control
```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f

# Restart specific service
docker compose restart superset
```

### User Management
```bash
# Create new admin user
docker exec superset_app superset fab create-admin \
  --username newuser \
  --firstname First \
  --lastname Last \
  --email user@example.com \
  --password password

# Reset password
docker exec superset_app superset fab reset-password \
  --username admin \
  --password newpassword
```

### Database Operations
```bash
# Run database migrations
docker exec superset_app superset db upgrade

# Load example data
docker exec superset_app superset load-examples
```

## Health Checks

- **Superset**: http://localhost:8088/health
- **Database**: `docker exec superset_db pg_isready`
- **Redis**: `docker exec superset_cache redis-cli ping`

## Backup & Restore

### Backup Database
```bash
docker exec superset_db pg_dump -U superset superset | gzip > superset_backup.sql.gz
```

### Restore Database
```bash
gunzip -c superset_backup.sql.gz | docker exec -i superset_db psql -U superset superset
```

## Troubleshooting

### Common Issues

1. **Login fails**
   ```bash
   # Check if admin user exists
   docker exec superset_app superset fab list-users
   
   # Create admin user if missing
   docker exec superset_app superset fab create-admin \
     --username admin --firstname Admin --lastname User \
     --email admin@example.com --password your_password
   ```

2. **Database connection errors**
   ```bash
   # Check database status
   docker compose ps postgres
   
   # View database logs
   docker compose logs postgres
   ```

3. **Services not starting**
   ```bash
   # Check all service status
   docker compose ps
   
   # View all logs
   docker compose logs
   ```

## Production Notes

- Change all default passwords in `.env`
- Use strong `SUPERSET_SECRET_KEY` (generate with `openssl rand -base64 42`)
- Set up SSL/TLS with reverse proxy (nginx, traefik)
- Configure database backups
- Monitor resource usage and scale workers as needed
- Set up external monitoring (Prometheus/Grafana)

## Volumes

- `postgres_data`: PostgreSQL database files
- `redis_data`: Redis persistence
- `superset_home`: Superset configuration and logs

## Support

- [Official Documentation](https://superset.apache.org/docs/intro)
- [GitHub Issues](https://github.com/apache/superset/issues)
- [Community Slack](https://apache-superset.slack.com)