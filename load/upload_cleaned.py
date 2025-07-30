from pathlib import Path
import boto3
import os
from dotenv import load_dotenv

load_dotenv()

# Environment variables
AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY") 
AWS_REGION = os.getenv("AWS_REGION")  # us-east-1
S3_BUCKET_NAME = "ecommerce-cleaned-nick-v1"

# S3 client
s3 = boto3.client(
    "s3",
    aws_access_key_id=AWS_ACCESS_KEY_ID,
    aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
    region_name=AWS_REGION
)

# Upload files
base_dir = Path(__file__).resolve().parent.parent  # Go up to project root
cleaned_dir = base_dir / "transform" / "cleaned"   # Then navigate to transform/cleaned

print(f"Looking for CSV files in: {cleaned_dir}")
print(f"Directory exists: {cleaned_dir.exists()}")

if cleaned_dir.exists():
    csv_files = list(cleaned_dir.glob("*.csv"))
    print(f"Found {len(csv_files)} CSV files: {[f.name for f in csv_files]}")
    
    for csv_file in csv_files:
        s3_key = f"cleaned/{csv_file.name}"
        
        try:
            s3.upload_file(
                Filename=str(csv_file),
                Bucket=S3_BUCKET_NAME,
                Key=s3_key
            )
            print(f"Upload successful: {csv_file.name}")
        except Exception as e:
            print(f"Upload failed for {csv_file.name}: {e}")
else:
    print("Directory 'transform/cleaned' not found!")