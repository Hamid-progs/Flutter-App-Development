from fastapi import APIRouter, HTTPException
from models import RegisterModel, LoginModel
from database import get_supabase
import bcrypt, jwt, os
from dotenv import load_dotenv

load_dotenv()
router = APIRouter()


# ── REGISTER ──
@router.post("/register")
def register(data: RegisterModel):
    supabase = get_supabase()

    # Check if email already exists
    existing = supabase.table("users")\
        .select("id")\
        .eq("email", data.email)\
        .execute()

    if existing.data:
        raise HTTPException(
            status_code=400,
            detail="Email already registered"
        )

    # Validate password length
    if len(data.password) < 6:
        raise HTTPException(
            status_code=400,
            detail="Password must be at least 6 characters"
        )

    # Hash password
    hashed = bcrypt.hashpw(
        data.password.encode(),
        bcrypt.gensalt()
    ).decode()

    # Insert new user
    supabase.table("users").insert({
        "name": data.name,
        "email": data.email,
        "password": hashed,
        "role": "user"
    }).execute()

    return {"message": "Account created successfully!"}


# ── LOGIN ──
@router.post("/login")
def login(data: LoginModel):
    supabase = get_supabase()

    # Find user by email
    result = supabase.table("users")\
        .select("*")\
        .eq("email", data.email)\
        .execute()

    if not result.data:
        raise HTTPException(
            status_code=404,
            detail="No account found with this email"
        )

    user = result.data[0]

    # Check password
    if not bcrypt.checkpw(
        data.password.encode(),
        user["password"].encode()
    ):
        raise HTTPException(
            status_code=401,
            detail="Incorrect password"
        )

    # Check if account is active
    if not user["is_active"]:
        raise HTTPException(
            status_code=403,
            detail="Your account has been disabled. Contact admin."
        )

    # Generate JWT token
    token = jwt.encode(
        {
            "id": user["id"],
            "role": user["role"],
            "name": user["name"]
        },
        os.getenv("JWT_SECRET"),
        algorithm="HS256"
    )

    return {
        "token": token,
        "role": user["role"],
        "name": user["name"],
        "email": user["email"],
        "message": "Login successful!"
    }
