# E-commerce Data Pipeline: FakeStore API to Snowflake

A comprehensive data engineering and analytics pipeline that extracts e-commerce data from the FakeStore API, transforms it using pandas, stores it in Amazon S3, and loads it into Snowflake for business intelligence analysis.

## Architecture Overview

```
FakeStore API → Python ETL → Amazon S3 → Snowflake → Power BI Dashboard
```

This pipeline implements a modern ELT (Extract, Load, Transform) pattern with complete business intelligence capabilities:

- **Data Extraction**: Automated retrieval from FakeStore API endpoints (products, users, carts)
- **Transformation**: Data cleaning and normalization using pandas
- **Storage**: Processed data stored in Amazon S3 buckets
- **Warehousing**: Structured data loaded into Snowflake tables
- **Analytics**: SQL-based business intelligence and Power BI visualizations

## Business Intelligence Dashboard

> **Status**: Dashboard development in progress. Business insights and visualizations will be uploaded soon.

### Planned Analysis Areas:

**Revenue Analysis** *(Implementing Soon)*
- Product category revenue performance analysis
- Premium vs budget product customer satisfaction correlation
- Customer revenue contribution segmentation

**Customer Behavior Insights** *(Coming Soon)*
- Shopping cart size optimization analysis
- Geographic market opportunity assessment
- Customer lifetime value segmentation patterns

**Product Performance Metrics** *(In Development)*
- Product quality rating analysis across categories
- Price-to-rating correlation studies
- Cross-category purchasing pattern identification

### Dashboard Views:
> **Note**: Interactive dashboard visualizations currently in development. Screenshots and comprehensive analysis will be uploaded upon completion.

**Planned Dashboard Pages:**
- **Executive Overview**: KPI summary, revenue metrics, customer counts
- **Product Performance**: Category analysis, top performers, price vs quality insights  
- **Customer Analytics**: Lifetime value, geographic distribution, shopping behavior
- **Shopping Trends**: Time-based patterns, seasonal analysis, cart optimization
- **Data Quality**: Pipeline monitoring, data validation metrics

### Business Recommendations:
> ** Business insights and strategic recommendations will be published following dashboard completion and data analysis.**

*Interactive Power BI dashboard and detailed business insights coming soon - check back for updates!*

## Project Structure

```
├── extract/
│   ├── data/                    # Raw CSV files from API extraction
│   ├── fetch_products.py        # Extract product catalog data
│   ├── fetch_users.py           # Extract user/customer data
│   └── fetch_carts.py           # Extract shopping cart data
├── transform/
│   ├── cleaned/                 # Processed CSV files ready for upload
│   └── transform.ipynb          # Jupyter notebook for data cleaning
├── load/
│   └── upload_cleaned.py        # S3 upload script using boto3
├── sql/
│   ├── ddl/
│   │   └── create_tables.sql    # Snowflake table creation scripts
│   └── queries/
│       └── analytics.sql        # Business intelligence queries
├── dashboards/                  # Power BI dashboard files (coming soon)
│   ├── screenshots/             # Dashboard screenshots
│   ├── reports/                 # Exported dashboard files
│   └── insights/                # Business insights documentation
├── requirements.txt             # Python dependencies
├── .gitignore                   # Git ignore file
└── README.md                    # Project documentation
```

## 🔧 Tech Stack

- **Cloud Platform**: Amazon Web Services (AWS)
- **Storage**: Amazon S3
- **Data Warehouse**: Snowflake
- **Programming Language**: Python 3.13
- **Data Processing**: pandas, requests
- **Infrastructure**: boto3 for AWS integration
- **Visualization**: Power BI (in development)

## Data Sources

The pipeline extracts data from three main FakeStore API endpoints:
- **Products**: Product catalog with pricing, categories, and ratings (20 products)
- **Users**: Customer information including demographics and addresses (10 users)
- **Carts**: Shopping cart data with purchase history and product quantities (7 carts)

## Key Features

- **E-commerce Data Integration**: Complete product, user, and cart data extraction
- **Automated Data Cleaning**: pandas-based transformation with column standardization
- **AWS S3 Integration**: Secure cloud storage with boto3
- **Scalable Architecture**: Designed for easy extension to additional API endpoints
- **Data Quality**: Duplicate removal and null value handling
- **Business Intelligence**: 15+ analytical queries for insights generation
- **Professional Documentation**: Complete setup and usage instructions

## Getting Started

### Prerequisites
- Python 3.13+
- AWS Account with S3 access
- Snowflake account with warehouse, database, and schema privileges
- FakeStore API access (free, no auth required)
- SnowSQL CLI tool installed

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/ecommerce-etl-pipeline.git
cd ecommerce-etl-pipeline
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Set up environment variables:
```bash
# Create .env file with your AWS and Snowflake credentials
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=us-east-1

# Snowflake connection details
SNOWFLAKE_ACCOUNT=your_account.region
SNOWFLAKE_USER=your_username  
SNOWFLAKE_PASSWORD=your_password
SNOWFLAKE_DATABASE=ECOMMERCE_DB
SNOWFLAKE_SCHEMA=RAW_DATA
SNOWFLAKE_WAREHOUSE=COMPUTE_WH
```

4. Create S3 bucket:
```bash
aws s3 mb s3://your-bucket-name
```

5. Set up Snowflake tables:
```bash
snowsql -a your_account -u your_username -d ECOMMERCE_DB -s RAW_DATA -f sql/ddl/create_tables.sql
```

## Pipeline Workflow

### 1. Data Extraction
```python
# Extract products data
python extract/fetch_products.py

# Extract users data  
python extract/fetch_users.py

# Extract carts data
python extract/fetch_carts.py
```
Each script connects to the FakeStore API, retrieves JSON data, normalizes it using pandas, and saves as CSV files.

### 2. Data Transformation
The transformation process handles:
- **Column Standardization**: Converts column names to lowercase, replaces spaces with underscores
- **Data Cleaning**: Removes duplicates and empty rows
- **Quality Validation**: Ensures data integrity before upload
- **File Output**: Creates cleaned CSV files ready for upload

### 3. S3 Upload
```python
python load/upload_cleaned.py
```
Uses boto3 to upload cleaned CSV files to S3 with proper error handling and logging.

### 4. Snowflake Integration
```sql
-- Load data from S3 to Snowflake
COPY INTO products_table FROM @s3_stage/products_clean.csv FILE_FORMAT = csv_format;
COPY INTO users_table FROM @s3_stage/users_clean.csv FILE_FORMAT = csv_format;  
COPY INTO carts_table FROM @s3_stage/carts_clean.csv FILE_FORMAT = csv_format;
```

### 5. Business Intelligence Analysis
Run analytical queries to generate insights:
```bash
snowsql -a your_account -u your_username -d ECOMMERCE_DB -s RAW_DATA -f sql/queries/analytics.sql
```

## Sample Analytics Queries

### Product Performance Analysis
```sql
-- Category performance with revenue potential
SELECT 
    category,
    COUNT(*) as product_count,
    ROUND(AVG(price), 2) as avg_price,
    ROUND(AVG(rating_rate), 2) as avg_rating,
    SUM(rating_count) as total_reviews
FROM products_table 
GROUP BY category
ORDER BY avg_rating DESC, avg_price DESC;
```

### Customer Lifetime Value
```sql
-- Top customers by revenue potential
WITH customer_revenue AS (
    SELECT 
        c.userid,
        u.name_firstname || ' ' || u.name_lastname as customer_name,
        COUNT(c.id) as total_orders,
        SUM(ARRAY_SIZE(PARSE_JSON(c.products))) as total_items_purchased
    FROM carts_table c
    JOIN users_table u ON c.userid = u.id
    GROUP BY c.userid, customer_name
)
SELECT * FROM customer_revenue
ORDER BY total_items_purchased DESC;
```

## Key Implementation Details

### Data Transformation Logic
```python
# Column standardization and cleaning
df.columns = (
    df.columns.str.strip()
    .str.lower()
    .str.replace(" ", "_")
    .str.replace(r"[^\w_]", "", regex=True)
)

# Data quality improvements
df = df.drop_duplicates()
df = df.dropna(how="all")
```

### AWS S3 Integration
```python
s3 = boto3.client(
    "s3",
    aws_access_key_id=AWS_ACCESS_KEY_ID,
    aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
    region_name=AWS_REGION
)

s3.upload_file(
    Filename=str(csv_file),
    Bucket=S3_BUCKET_NAME,
    Key=f"cleaned/{csv_file.name}"
)
```

## Monitoring and Validation

### Data Quality Checks
```bash
# Verify data loading success
snowsql -a your_account -u your_username -d ECOMMERCE_DB -s RAW_DATA -q "
SELECT 'products' as table_name, COUNT(*) as row_count FROM products_table
UNION ALL  
SELECT 'users' as table_name, COUNT(*) as row_count FROM users_table
UNION ALL
SELECT 'carts' as table_name, COUNT(*) as row_count FROM carts_table;
"
```

### Pipeline Monitoring
- **Data validation**: Automated checks for data quality and completeness
- **Error handling**: Comprehensive logging and retry mechanisms
- **Performance tracking**: Query execution times and data processing metrics

## Future Enhancements

- **Automation**: Implement Apache Airflow for scheduled pipeline execution
- **Real-time Processing**: Add streaming capabilities with Kafka/Kinesis
- **Advanced Analytics**: Machine learning models for customer segmentation
- **Additional Data Sources**: Extend to other e-commerce APIs
- **dbt Integration**: Add data modeling and transformation layers
- **Monitoring Dashboard**: Real-time pipeline health monitoring

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

**Nicholas Tarazi** - nicholas.tarazi7@gmail.com  
**Project Link**: https://github.com/tnickster/ecommerce-etl-pipeline  
**LinkedIn**: https://www.linkedin.com/in/nicholas-tarazi/ 
