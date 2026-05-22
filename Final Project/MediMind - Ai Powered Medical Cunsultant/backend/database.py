from supabase import create_client, Client
from dotenv import load_dotenv
import os

load_dotenv()

def get_supabase() -> Client:
    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_KEY")
    if not url or not key:
        raise Exception("Supabase credentials missing in .env file")
    return create_client(url, key)
