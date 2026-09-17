import os
import subprocess
import psycopg2

AWS_CLI = os.environ.get("AWS_CLI_PATH", r"C:\Users\user\AppData\Local\Programs\Amazon\AWSCLIV2\aws.exe")
HOST = os.environ.get("DB_HOST", "database-1.cluster-cxio24kemguz.eu-west-1.rds.amazonaws.com")
PORT = int(os.environ.get("DB_PORT", "5432"))
USER = os.environ.get("DB_USER", "postgres")
REGION = os.environ.get("AWS_REGION", "eu-west-1")
PROFILE = os.environ.get("AWS_PROFILE", "giftmart-admin")
PASSWORD = os.environ.get("DB_PASSWORD", "")
DB_NAME = os.environ.get("DB_NAME", "giftmart")

def get_auth_token():
    print(f"Generating IAM DB token for {USER}@{HOST}...")
    cmd = [
        AWS_CLI, "rds", "generate-db-auth-token",
        "--hostname", HOST,
        "--port", str(PORT),
        "--username", USER,
        "--region", REGION,
        "--profile", PROFILE
    ]
    res = subprocess.run(cmd, capture_output=True, text=True, check=True)
    return res.stdout.strip()

def run_migrations():
    token = get_auth_token()
    print("Connecting to postgres default database...")
    conn = psycopg2.connect(
        host=HOST,
        user=USER,
        password=token,
        dbname="postgres",
        port=PORT,
        sslmode="require",
        connect_timeout=15
    )
    conn.autocommit = True
    cur = conn.cursor()

    # 1. Update password for postgres user so password login also works
    try:
        cur.execute(f"ALTER USER {USER} WITH PASSWORD '{PASSWORD}';")
        print(f"Master password set for '{USER}'")
    except Exception as e:
        print(f"Warning setting password: {e}")

    # 2. Create giftmart database if not exists
    cur.execute(f"SELECT 1 FROM pg_database WHERE datname = '{DB_NAME}';")
    if not cur.fetchone():
        print(f"Creating database '{DB_NAME}'...")
        cur.execute(f"CREATE DATABASE {DB_NAME};")
        print(f"Database '{DB_NAME}' created successfully.")
    else:
        print(f"Database '{DB_NAME}' already exists.")

    cur.close()
    conn.close()

    # 3. Connect to giftmart database and apply migrations
    print(f"\nConnecting to '{DB_NAME}' database on AWS Aurora cluster...")
    token_giftmart = get_auth_token()
    conn_giftmart = psycopg2.connect(
        host=HOST,
        user=USER,
        password=token_giftmart,
        dbname=DB_NAME,
        port=PORT,
        sslmode="require",
        connect_timeout=15
    )
    conn_giftmart.autocommit = True
    cur_giftmart = conn_giftmart.cursor()

    schema_file = os.path.join(os.path.dirname(__file__), "setup_giftmart_db.sql")
    print(f"Reading consolidated schema from {schema_file}...")
    with open(schema_file, "r", encoding="utf-8") as f:
        sql_content = f.read()

    print("Applying schema DDL (12 migrations, zero seeds)...")
    cur_giftmart.execute(sql_content)
    print("Schema DDL applied successfully!")

    # 4. Verification: count tables
    cur_giftmart.execute("""
        SELECT count(*) 
        FROM information_schema.tables 
        WHERE table_schema = 'public';
    """)
    table_count = cur_giftmart.fetchone()[0]
    print(f"Total tables created in '{DB_NAME}': {table_count}")

    # List all created tables
    cur_giftmart.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public'
        ORDER BY table_name;
    """)
    tables = [r[0] for r in cur_giftmart.fetchall()]
    print("\nTables list:")
    for t in tables:
        print(f"  - {t}")

    cur_giftmart.close()
    conn_giftmart.close()
    print("\nMigration run finished successfully!")

if __name__ == "__main__":
    run_migrations()
