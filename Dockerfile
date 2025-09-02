FROM apache/superset:6.0.0rc1

# Switch to root to install packages
USER root

# Create data directory and install system dependencies
RUN mkdir -p /app/data && chown -R superset:superset /app/data

# Install ODBC drivers for MS SQL Server support
RUN apt-get update && apt-get install -y \
    unixodbc \
    unixodbc-dev \
    && rm -rf /var/lib/apt/lists/*

# Install essential database drivers
RUN /app/docker/pip-install.sh \
    pyodbc \
    pymssql \
    snowflake-sqlalchemy \
    PyMySQL \
    sqlalchemy-redshift \
    pybigquery \
    clickhouse-sqlalchemy \
    elasticsearch-dbapi \
    pydruid \
    databricks-sql-connector \
    duckdb \
    duckdb-engine \
    psycopg2-binary \
    "shillelagh[gsheetsapi]"

# Copy extension installer script
COPY load_ext.py /tmp/load_ext.py

# Pre-install DuckDB extensions in uv environment  
RUN . /app/.venv/bin/activate && python /tmp/load_ext.py && rm /tmp/load_ext.py

# Switch back to superset user  
USER superset