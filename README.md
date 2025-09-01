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
openssl rand -hex 16

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
- Use strong `SUPERSET_SECRET_KEY` (generate with `openssl rand -hex 16`)
- Set up SSL/TLS with reverse proxy (nginx, traefik)
- Configure database backups
- Monitor resource usage and scale workers as needed
- Set up external monitoring (Prometheus/Grafana)

## Database Drivers

This setup includes comprehensive database driver support:

- **Microsoft SQL Server**: `pyodbc`, `pymssql`
- **Snowflake**: `snowflake-sqlalchemy`
- **MySQL/MariaDB**: `PyMySQL`
- **Amazon Redshift**: `sqlalchemy-redshift`
- **Google BigQuery**: `pybigquery`
- **ClickHouse**: `clickhouse-sqlalchemy`
- **Elasticsearch**: `elasticsearch-dbapi`
- **Apache Druid**: `pydruid`
- **Databricks**: `databricks-sql-connector`
- **DuckDB**: `duckdb-engine>=0.17.0` with spatial extensions
- **Google Sheets**: `shillelagh[gsheetsapi]`

## Using DuckDB with Spatial Data

### Configure DuckDB Connection

1. Go to **Settings** → **Database Connections**
2. Click **+ Database** → Select **DuckDB**
3. Set **SQLALCHEMY URI** to one of:
   - `duckdb:///:memory:` (in-memory database)
   - `duckdb:///app/superset_home/mydb.duckdb` (persistent file)
   - `duckdb:///path/to/your/database.duckdb`

4. In **Advanced** tab, set **Engine Parameters**:
   ```json
   {
     "connect_args": {
       "config": {
         "threads": 16
       }
     }
   }
   ```

### Spatial Queries

DuckDB spatial extensions are pre-installed in this setup. You can immediately run spatial queries:

```sql
-- Create spatial points
SELECT ST_Point(1, 2) as point;

-- Calculate areas
SELECT ST_Area(ST_MakeEnvelope(0, 0, 1, 1)) as area;

-- Distance calculations
SELECT ST_Distance(ST_Point(0, 0), ST_Point(3, 4)) as distance;

-- Reading Parquet files with spatial data
SELECT 
    names.primary as name,
    ST_X(geometry) as longitude,
    ST_Y(geometry) as latitude   
FROM read_parquet('s3://overturemaps-us-west-2/release/2024-12-18.0/theme=places/type=place/*', 
    filename=true, hive_partitioning=1)
WHERE categories.primary = 'pizza_restaurant'
  AND bbox.xmin BETWEEN -75 AND -73 
  AND bbox.ymin BETWEEN 40 AND 41;
```

### Available DuckDB Extensions

Pre-installed extensions:
- **spatial**: PostGIS-compatible spatial operations
- **httpfs**: HTTP/S3 file system access
- **json**: JSON processing functions
- **parquet**: Optimized Parquet file reading

### DuckDB Best Practices

1. **Performance**: Use `threads` parameter to optimize query performance
2. **Memory**: DuckDB efficiently handles large datasets in memory
3. **File Formats**: Parquet files provide best performance for analytics
4. **Spatial Data**: Use spatial extensions for GIS operations
5. **Cloud Storage**: Access files directly from S3/HTTP with httpfs extension

## Volumes

- `postgres_data`: PostgreSQL database files
- `redis_data`: Redis persistence
- `superset_home`: Superset configuration and logs

## Support

- [Official Documentation](https://superset.apache.org/docs/intro)
- [GitHub Issues](https://github.com/apache/superset/issues)
- [Community Slack](https://apache-superset.slack.com)
- [DuckDB Documentation](https://duckdb.org/docs/)