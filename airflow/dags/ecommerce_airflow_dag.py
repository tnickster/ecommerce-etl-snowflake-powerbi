# E-commerce ETL Pipeline - Apache Airflow DAG

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python_operator import PythonOperator
from airflow.operators.dummy_operator import DummyOperator
from airflow.utils.dates import days_ago
import pandas as pd
import requests
import os
import boto3
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# DAG Configuration
DEFAULT_ARGS = {
    'owner': 'data-team',
    'depends_on_past': False,
    'start_date': days_ago(1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

# Initialize DAG
dag = DAG(
    'ecommerce_etl_pipeline',
    default_args=DEFAULT_ARGS,
    description='E-commerce ETL Pipeline with embedded functions',
    schedule_interval='0 6 * * *',  # Daily at 6 AM UTC
    catchup=False,
    tags=['etl', 'ecommerce', 'functions']
)

# fetch_products.py function
def extract_products(**context):
    """Extract products data from FakeStore API"""
    # Create the extract/data directory to match your structure
    extract_dir = Path("extract/data")
    extract_dir.mkdir(parents=True, exist_ok=True)
    
    response = requests.get("https://fakestoreapi.com/products")
    products = response.json()
    
    df = pd.json_normalize(products)
    df.to_csv("extract/data/products.csv", index=False)
    
    print("Products extraction completed")
    return f"Extracted {len(df)} products"

# fetch_users.py function  
def extract_users(**context):
    """Extract users data from FakeStore API"""
    extract_dir = Path("extract/data")
    extract_dir.mkdir(parents=True, exist_ok=True)
    
    response = requests.get("https://fakestoreapi.com/users")
    users = response.json()
    
    df = pd.json_normalize(users)
    df.to_csv("extract/data/users.csv", index=False)
    
    print("Users extraction completed")
    return f"Extracted {len(df)} users"

# fetch_carts.py function
def extract_carts(**context):
    """Extract carts data from FakeStore API"""
    extract_dir = Path("extract/data")
    extract_dir.mkdir(parents=True, exist_ok=True)
    
    response = requests.get("https://fakestoreapi.com/carts")
    carts = response.json()
    
    df = pd.json_normalize(carts)
    df.to_csv("extract/data/carts.csv", index=False)
    
    print("Carts extraction completed")
    return f"Extracted {len(df)} carts"

# transform.ipynb function
def transform_data(**context):
    """Transform and clean data using your existing logic"""
    # Create transform/cleaned directory to match your structure
    cleaned_dir = Path("transform/cleaned")
    cleaned_dir.mkdir(parents=True, exist_ok=True)
    
    # existing path logic from transform.ipynb
    base_dir = Path().resolve()
    raw_dir = base_dir / "extract" / "data"
    transform_dir = base_dir / "transform" / "cleaned"
    
    processed_files = []
    
    for csv_file in raw_dir.glob("*.csv"):
        df = pd.read_csv(csv_file)
        
        # column standardization
        df.columns = (
            df.columns.str.strip()
            .str.lower()
            .str.replace(" ", "_")
            .str.replace(r"[^\w_]", "", regex=True)
        )
        
        # exact data cleaning
        df = df.drop_duplicates()
        df = df.dropna(how="all")
        
        # Save cleaned data
        cleaned_name = csv_file.stem + "_clean.csv"
        df.to_csv(transform_dir / cleaned_name, index=False)
        processed_files.append(cleaned_name)
        
        print(f"Processed {csv_file.name} -> {cleaned_name}")
    
    print("Data transformation completed")
    return f"Processed {len(processed_files)} files: {processed_files}"

# upload_cleaned.py function
def upload_to_s3(**context):
    """Upload cleaned data to S3 using your existing logic"""
    # Environment variables
    AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID")
    AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY") 
    AWS_REGION = os.getenv("AWS_REGION")
    S3_BUCKET_NAME = "ecommerce-cleaned-nick-v1"
    
    # S3 client setup
    s3 = boto3.client(
        "s3",
        aws_access_key_id=AWS_ACCESS_KEY_ID,
        aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
        region_name=AWS_REGION
    )
    
    # upload with correct paths
    base_dir = Path().resolve()
    cleaned_dir = base_dir / "transform" / "cleaned"
    uploaded_files = []
    
    if cleaned_dir.exists():
        csv_files = list(cleaned_dir.glob("*.csv"))
        print(f"Found {len(csv_files)} CSV files to upload")
        
        for csv_file in csv_files:
            s3_key = f"cleaned/{csv_file.name}"
            
            try:
                s3.upload_file(
                    Filename=str(csv_file),
                    Bucket=S3_BUCKET_NAME,
                    Key=s3_key
                )
                print(f"✅ Upload successful: {csv_file.name}")
                uploaded_files.append(csv_file.name)
            except Exception as e:
                print(f"❌ Upload failed for {csv_file.name}: {e}")
                raise
    
    print("S3 upload completed")
    return f"Uploaded {len(uploaded_files)} files: {uploaded_files}"

def load_to_snowflake(**context):
    """Load data to Snowflake using your existing SQL"""
    import subprocess
    
    # Environment variables for Snowflake
    snowflake_account = os.getenv("SNOWFLAKE_ACCOUNT")
    snowflake_user = os.getenv("SNOWFLAKE_USER")
    
    # Path to SQL script
    base_dir = Path().resolve()
    sql_file = base_dir / "sql" / "ddl" / "create_tables.sql"
    
    cmd = [
        "snowsql",
        "-a", snowflake_account,
        "-u", snowflake_user,
        "-d", "ECOMMERCE_DB",
        "-s", "RAW_DATA", 
        "-f", str(sql_file)
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print("Snowflake load completed successfully")
        return "Data loaded to Snowflake"
    except subprocess.CalledProcessError as e:
        print(f"Snowflake load failed: {e}")
        raise

# Define tasks
start_pipeline = DummyOperator(
    task_id='start_pipeline',
    dag=dag
)

extract_products_task = PythonOperator(
    task_id='extract_products',
    python_callable=extract_products,
    dag=dag
)

extract_users_task = PythonOperator(
    task_id='extract_users',
    python_callable=extract_users,
    dag=dag
)

extract_carts_task = PythonOperator(
    task_id='extract_carts',
    python_callable=extract_carts,
    dag=dag
)

transform_data_task = PythonOperator(
    task_id='transform_data',
    python_callable=transform_data,
    dag=dag
)

upload_s3_task = PythonOperator(
    task_id='upload_to_s3',
    python_callable=upload_to_s3,
    dag=dag
)

load_snowflake_task = PythonOperator(
    task_id='load_to_snowflake',
    python_callable=load_to_snowflake,
    dag=dag
)

end_pipeline = DummyOperator(
    task_id='end_pipeline',
    dag=dag
)

# Set task dependencies
start_pipeline >> [extract_products_task, extract_users_task, extract_carts_task] >> transform_data_task >> upload_s3_task >> load_snowflake_task >> end_pipeline