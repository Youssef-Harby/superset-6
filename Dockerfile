FROM apache/superset:6.0.0rc1

# Switch to root to install packages
USER root

# Create data directory
RUN mkdir -p /app/data && chown -R superset:superset /app/data

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
    "duckdb-engine>=0.17.0" \
    "shillelagh[gsheetsapi]"

# Pre-install DuckDB extensions in uv environment  
RUN . /app/.venv/bin/activate && python -c "\
import duckdb; \
conn = duckdb.connect('/tmp/install_extensions.duckdb'); \
conn.execute('INSTALL spatial'); \
conn.execute('LOAD spatial'); \
conn.execute('INSTALL httpfs'); \
conn.execute('LOAD httpfs'); \
conn.execute('INSTALL h3 FROM community'); \
conn.execute('LOAD h3'); \
print('DuckDB extensions installed in uv environment'); \
conn.close(); \
import os; os.remove('/tmp/install_extensions.duckdb')"

# Switch back to superset user  
USER superset