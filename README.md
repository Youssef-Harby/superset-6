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

   **Option A: Spatial only (recommended)**
   ```json
   {
     "connect_args": {
       "config": {
         "threads": 16
       },
       "preload_extensions": ["spatial"]
     }
   }
   ```
   
   **Option B: Try H3 preloading with unsigned extensions allowed**
   ```json
   {
     "connect_args": {
       "config": {
         "threads": 16,
         "allow_unsigned_extensions": true
       },
       "preload_extensions": ["spatial", "h3"]
     }
   }
   ```
   
   **Note**: Option B is experimental - if it fails, use Option A and load H3 manually.

### Spatial Queries

DuckDB spatial extensions are pre-installed in this setup. You can immediately run spatial queries:

```sql
-- Spatial operations (always available)
SELECT ST_Point(1, 2) as point;
SELECT ST_Area(ST_MakeEnvelope(0, 0, 1, 1)) as area;
SELECT ST_Distance(ST_Point(0, 0), ST_Point(3, 4)) as distance;

-- Now H3 functions work
SELECT h3_latlng_to_cell(37.7887987, -122.3931578, 9) as h3_index;
SELECT h3_cell_to_lat(h3_latlng_to_cell(37.7887987, -122.3931578, 9)) as latitude;
SELECT h3_cell_to_lng(h3_latlng_to_cell(37.7887987, -122.3931578, 9)) as longitude;
SELECT h3_cell_to_latlng(h3_latlng_to_cell(37.7887987, -122.3931578, 9)) as lat_lng;
SELECT h3_cell_to_boundary_wkt(h3_latlng_to_cell(37.7887987, -122.3931578, 9)) as boundary;

-- Combined spatial and H3 queries
SELECT 
    names.primary as name,
    ST_X(geometry) as longitude,
    ST_Y(geometry) as latitude,
    h3_latlng_to_cell(ST_Y(geometry), ST_X(geometry), 9) as h3_index
FROM read_parquet('s3://overturemaps-us-west-2/release/2024-12-18.0/theme=places/type=place/*', 
    filename=true, hive_partitioning=1)
WHERE categories.primary = 'pizza_restaurant'
  AND bbox.xmin BETWEEN -75 AND -73 
  AND bbox.ymin BETWEEN 40 AND 41;
```

### Available DuckDB Extensions

**Core Extensions (preload automatically):**
- **spatial**: PostGIS-compatible spatial operations (ST_Point, ST_Area, ST_Distance, etc.)

**Community Extensions (manual load required):**
- **h3**: Uber H3 hexagonal hierarchical geospatial indexing system

### Using H3 Extension

Since H3 is a community extension, you must load it manually in each SQL Lab session:

**Step 1: Load H3 extension (run once per session)**
```sql
INSTALL h3 FROM community;
LOAD h3;
```

**Step 2: Use H3 functions**
```sql
SELECT h3_latlng_to_cell(37.7749, -122.4194, 9) as h3_index;
```

**Important Notes:**
- H3 extension is pre-installed during Docker build but must be `LOAD`ed per session
- Community extensions cannot be included in `preload_extensions`
- The `INSTALL` command will be fast since H3 is already downloaded
- You only need to run `INSTALL h3 FROM community; LOAD h3;` once per SQL Lab session

### DuckDB Best Practices

1. **Performance**: Use `threads` parameter to optimize query performance
2. **Core Extensions**: Only include core extensions in `preload_extensions: ["spatial"]`
3. **Community Extensions**: Load H3 manually with `INSTALL h3 FROM community; LOAD h3;`
4. **Memory**: DuckDB efficiently handles large datasets in memory
5. **File Formats**: Parquet files provide best performance for analytics
6. **Spatial Data**: Combine spatial and H3 functions for advanced geospatial analytics

## Volumes

- `postgres_data`: PostgreSQL database files
- `redis_data`: Redis persistence
- `superset_home`: Superset configuration and logs

## Support

- [Official Documentation](https://superset.apache.org/docs/intro)
- [GitHub Issues](https://github.com/apache/superset/issues)
- [Community Slack](https://apache-superset.slack.com)
- [DuckDB Documentation](https://duckdb.org/docs/)