from fastapi import APIRouter, HTTPException, Header
from models import ProfileModel
from database import get_supabase
import jwt, os
from dotenv import load_dotenv

load_dotenv()
router = APIRouter()


def get_user_from_token(token: str):
    try:
        return jwt.decode(
            token,
            os.getenv("JWT_SECRET"),
            algorithms=["HS256"]
        )
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired, please login again")
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")


# ── SAVE OR UPDATE HEALTH PROFILE ──
@router.post("/save")
def save_profile(data: ProfileModel, authorization: str = Header(...)):
    token = authorization.replace("Bearer ", "")
    user = get_user_from_token(token)

    supabase = get_supabase()

    profile_data = {
        "age": data.age,
        "gender": data.gender,
        "blood_group": data.blood_group,
        "weight": data.weight,
        "height": data.height,
        "existing_conditions": data.existing_conditions,
        "allergies": data.allergies
    }

    # Check if profile already exists
    existing = supabase.table("health_profiles")\
        .select("id")\
        .eq("user_id", user["id"])\
        .execute()

    if existing.data:
        # Update existing profile
        supabase.table("health_profiles")\
            .update(profile_data)\
            .eq("user_id", user["id"])\
            .execute()
        return {"message": "Health profile updated successfully!"}
    else:
        # Create new profile
        profile_data["user_id"] = user["id"]
        supabase.table("health_profiles")\
            .insert(profile_data)\
            .execute()
        return {"message": "Health profile created successfully!"}


# ── GET HEALTH PROFILE ──
@router.get("/get")
def get_profile(authorization: str = Header(...)):
    token = authorization.replace("Bearer ", "")
    user = get_user_from_token(token)

    supabase = get_supabase()
    result = supabase.table("health_profiles")\
        .select("*")\
        .eq("user_id", user["id"])\
        .execute()

    if not result.data:
        return {"profile": None, "message": "No profile found"}

    return {"profile": result.data[0]}


# ── DELETE HEALTH PROFILE ──
@router.delete("/delete")
def delete_profile(authorization: str = Header(...)):
    token = authorization.replace("Bearer ", "")
    user = get_user_from_token(token)

    supabase = get_supabase()
    supabase.table("health_profiles")\
        .delete()\
        .eq("user_id", user["id"])\
        .execute()

    return {"message": "Health profile deleted successfully"}
