import pandas as pd
import requests
import os

os.makedirs("data", exist_ok=True)

response = requests.get("https://fakestoreapi.com/users")
products = response.json()

df = pd.json_normalize(products)
df = df.to_csv("data/users.csv", index = False)

print("nigga it works")