# E-commerce ETL Pipeline Environment Variables
# Copy this file to .env and replace with your actual values

# AWS Configuration
AWS_ACCESS_KEY_ID=your_aws_access_key_here
AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key_here
AWS_REGION=us-east-1

# S3 Bucket
S3_BUCKET_NAME=ecommerce-cleaned-your-name-v1

# Snowflake Configuration
SNOWFLAKE_ACCOUNT=your_account.region.snowflakecomputing.com
SNOWFLAKE_USER=your_username
SNOWFLAKE_PASSWORD=your_password
SNOWFLAKE_DATABASE=ECOMMERCE_DB
SNOWFLAKE_SCHEMA=RAW_DATA
SNOWFLAKE_WAREHOUSE=COMPUTE_WH