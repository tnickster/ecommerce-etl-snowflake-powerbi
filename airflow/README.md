# Airflow Automation for E-commerce ETL Pipeline

This directory contains Apache Airflow automation for the e-commerce data pipeline, enabling production-ready scheduling and orchestration.

## Overview

The Airflow DAG automates the complete ETL workflow:
1. **Extract** data from FakeStore API endpoints (parallel execution)
2. **Transform** data using pandas for cleaning and standardization  
3. **Load** processed data to AWS S3
4. **Import** data into Snowflake data warehouse

## Quick Setup

### 1. Install Airflow and Dependencies
```bash
# Install Airflow (from project root)
pip install -r airflow/requirements.txt

# Alternative: Install specific version
pip install apache-airflow==2.7.3
```

### 2. Initialize Airflow Database
```bash
# Set Airflow home directory
export AIRFLOW_HOME=~/airflow

# Initialize the database
airflow db init

# Create admin user
airflow users create \
    --username admin \
    --firstname Admin \
    --lastname User \
    --role Admin \
    --email admin@example.com \
    --password admin
```

### 3. Configure Environment Variables
Set these variables in your shell profile (`.bashrc`, `.zshrc`, or `.bash_profile`):

```bash
# AWS Configuration
export AWS_ACCESS_KEY_ID=your_aws_access_key
export AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key
export AWS_REGION=us-east-1

# Snowflake Configuration  
export SNOWFLAKE_ACCOUNT=your_account.region.snowflakecomputing.com
export SNOWFLAKE_USER=your_username
export SNOWFLAKE_PASSWORD=your_password
export SNOWFLAKE_DATABASE=ECOMMERCE_DB
export SNOWFLAKE_SCHEMA=RAW_DATA
export SNOWFLAKE_WAREHOUSE=COMPUTE_WH
```

**Important**: Restart your terminal or run `source ~/.bashrc` after adding these variables.

### 4. Deploy the DAG
```bash
# Copy DAG file to Airflow DAGs directory
cp airflow/dags/ecommerce_etl_dag.py ~/airflow/dags/

# Verify DAG is recognized
airflow dags list | grep ecommerce
```

### 5. Start Airflow Services
```bash
# Start the web server (in one terminal)
airflow webserver --port 8080

# Start the scheduler (in another terminal)  
airflow scheduler
```

### 6. Access Airflow UI
- Open browser to http://localhost:8080
- Login with credentials: **admin** / **admin**
- Navigate to the DAGs page
- Find "ecommerce_etl_pipeline" and toggle it ON

## DAG Configuration

### Schedule
- **Default**: Daily execution at 6:00 AM UTC
- **Cron Expression**: `0 6 * * *`
- **Customizable**: Edit `schedule_interval` in the DAG file

### Task Dependencies
```
start_pipeline
     ↓
[extract_products, extract_users, extract_carts] (parallel)
     ↓
transform_data
     ↓
upload_to_s3
     ↓
load_to_snowflake
     ↓
end_pipeline
```

### Retry Configuration
- **Retries**: 1 attempt on failure
- **Retry Delay**: 5 minutes
- **Email Notifications**: Disabled by default

## DAG Features

### Automated Directory Creation
The DAG automatically creates required directories:
- `extract/data/` for raw CSV files
- `transform/cleaned/` for processed data

### Error Handling
- **API failures**: Proper error logging and task failure
- **S3 upload errors**: Detailed error messages with file names
- **Snowflake errors**: Database connection and SQL execution errors

### Task Outputs
Each task returns meaningful information:
- **Extract tasks**: Number of records extracted per endpoint
- **Transform task**: Files processed and row counts
- **Upload task**: Successfully uploaded files
- **Load task**: Confirmation of Snowflake data loading

## Monitoring and Troubleshooting

### View Task Logs
1. Go to Airflow UI (http://localhost:8080)
2. Click on the DAG "ecommerce_etl_pipeline"
3. Click on any task instance
4. Click "Log" tab to view detailed execution logs

### Manual Task Testing
```bash
# Test individual tasks
airflow tasks test ecommerce_etl_pipeline extract_products 2024-01-01
airflow tasks test ecommerce_etl_pipeline transform_data 2024-01-01

# Test entire DAG run
airflow dags test ecommerce_etl_pipeline 2024-01-01
```

### Common Issues and Solutions

#### 1. DAG Not Appearing
```bash
# Check if DAG file has syntax errors
python ~/airflow/dags/ecommerce_etl_dag.py

# Refresh DAGs in UI or restart scheduler
```

#### 2. Environment Variables Not Found
```bash
# Verify variables are set
echo $AWS_ACCESS_KEY_ID
echo $SNOWFLAKE_ACCOUNT

# If empty, check your shell profile and restart terminal
```

#### 3. Permission Errors
```bash
# Ensure Airflow has write permissions
chmod 755 ~/airflow/dags/
chmod 644 ~/airflow/dags/ecommerce_etl_dag.py
```

#### 4. Database Connection Issues
- Verify Snowflake credentials are correct
- Check network connectivity to Snowflake
- Ensure SnowSQL is installed and configured

## Customization Options

### Change Schedule
Edit the DAG file and modify:
```python
schedule_interval='0 6 * * *'  # Daily at 6 AM UTC

# Other examples:
# schedule_interval='0 */4 * * *'    # Every 4 hours
# schedule_interval='0 6 * * 1'      # Weekly on Monday
# schedule_interval=None             # Manual trigger only
```

### Add Email Notifications
Update the DAG configuration:
```python
DEFAULT_ARGS = {
    'email_on_failure': True,
    'email_on_retry': False,
    'email': ['your.email@company.com']
}
```

### Modify S3 Bucket
Update the bucket name in the DAG:
```python
S3_BUCKET_NAME = "your-custom-bucket-name"
```

### Add Data Validation
Extend the DAG with additional tasks for data quality checks.

## Production Deployment

### Docker Deployment
For containerized deployment, create a `Dockerfile`:
```dockerfile
FROM apache/airflow:2.7.3

COPY airflow/requirements.txt .
RUN pip install -r requirements.txt

COPY airflow/dags/ /opt/airflow/dags/
```

### Cloud Deployment Options
- **AWS MWAA** (Managed Workflows for Apache Airflow)
- **Google Cloud Composer**
- **Azure Data Factory** (alternative orchestration)

### Security Best Practices
- Use Airflow Variables or Connections for sensitive data
- Enable authentication and RBAC
- Use encrypted connections for databases
- Regularly rotate credentials

## File Structure
```
airflow/
├── dags/
│   └── ecommerce_etl_dag.py     # Main DAG file
├── requirements.txt             # Python dependencies
└── README.md                    # This file
```

## Dependencies

### Required Python Packages
- `apache-airflow==2.7.3`
- `pandas==2.1.4`
- `requests==2.31.0`
- `boto3==1.34.0`
- `python-dotenv==1.0.0`

### External Tools
- **SnowSQL**: For Snowflake data loading
- **AWS CLI**: For S3 operations (optional)

## Support

For issues specific to the Airflow automation:
1. Check the task logs in Airflow UI
2. Verify environment variables are set correctly
3. Test individual components manually
4. Review the main project documentation

For general pipeline issues, refer to the main project [README.md](../README.md).

---

**Note**: This automation setup is designed for development and small-scale production use. For enterprise deployment, consider using managed Airflow services with proper monitoring, alerting, and security configurations.
