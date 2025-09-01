#!/usr/bin/env python3
"""
DuckDB Extension Installer for Apache Superset
Installs core and community extensions in the uv environment
"""

import duckdb
import traceback
import os


def install_extensions():
    """Install DuckDB extensions for Superset"""
    conn = None
    temp_db = '/tmp/install_extensions.duckdb'
    
    try:
        print("🦆 Installing DuckDB extensions...")
        conn = duckdb.connect(temp_db)
        
        # Core extensions
        core_extensions = ['spatial', 'httpfs', 'json', 'parquet']
        for ext in core_extensions:
            try:
                conn.execute(f'INSTALL {ext}')
                conn.execute(f'LOAD {ext}')
                print(f'✓ {ext} extension installed')
            except Exception as e:
                print(f'⚠ {ext} extension failed: {e}')
        
        # Community extensions
        community_extensions = ['h3']
        for ext in community_extensions:
            try:
                conn.execute(f'INSTALL {ext} FROM community')
                conn.execute(f'LOAD {ext}')
                print(f'✓ {ext} extension installed from community')
            except Exception as e:
                print(f'⚠ {ext} extension failed: {e}')
                print(f'  {ext} will need to be loaded manually in Superset')
        
    except Exception as e:
        print(f'❌ Extension installation error: {e}')
        traceback.print_exc()
        
    finally:
        if conn:
            conn.close()
        try:
            os.remove(temp_db)
        except:
            pass
            
    print("🎉 DuckDB extension installation completed")


if __name__ == '__main__':
    install_extensions()