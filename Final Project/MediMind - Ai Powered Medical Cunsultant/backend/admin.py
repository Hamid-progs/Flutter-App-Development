from fastapi import APIRouter, HTTPException, Header
from database import get_supabase
import jwt, os
from dotenv import load_dotenv

load_dotenv()
router = APIRouter()


def get_admin_from_token(token: str):
    try:
        payload = jwt.decode(
            token,
            os.getenv("JWT_SECRET"),
            algorithms=["HS256"]
        )
        if payload["role"] != "admin":
            raise HTTPException(
                status_code=403,
                detail="Admin access only"
            )
        return payload
    except HTTPException:
        raise
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")


# ── GET ALL USERS ──
@router.get("/users")
def get_all_users(authorization: str = Header(...)):
    token = authorization.replace("Bearer ", "")
    get_admin_from_token(token)

    supabase = get_supabase()
    result = supabase.table("users")\
        .select("id, name, email, role, is_active, created_at")\
        .order("created_at", desc=True)\
        .execute()

    return {"users": result.data}


# ── GET SINGLE USER DETAILS ──
@router.get("/users/{user_id}")
def get_user(user_id: int, authorization: str = Header(...)):
    token = authorization.replace("Bearer ", "")
    get_admin_from_token(token)

    supabase = get_supabase()

    user = supabase.table("users")\
        .select("id, name, email, role, is_active, created_at")\
        .eq("id", user_id)\
        .execute()

    if not user.data:
        raise HTTPException(status_code=404, detail="User not found")

    profile = supabase.table("health_profiles")\
        .select("*")\
        .eq("user_id", user_id)\
        .execute()

    return {
        "user": user.data[0],
        "health_profile": profile.data[0] if profile.data else None
    }


# ── ENABLE OR DISABLE USER ──
@router.put("/users/{user_id}/toggle")
def toggle_user(user_id: int, authorization: str = Header(...)):
    token = authorization.replace("Bearer ", "")
    admin = get_admin_from_token(token)

    supabase = get_supabase()

    # Get current user status
    result = supabase.table("users")\
        .select("is_active, role")\
        .eq("id", user_id)\
        .execute()

    if not result.data:
        raise HTTPException(status_code=404, detail="User not found")

    # Prevent disabling another admin
    if result.data[0]["role"] == "admin":
        raise HTTPException(
            status_code=400,
            detail="Cannot disable an admin account"
        )

    new_status = not result.data[0]["is_active"]

    supabase.table("users")\
        .update({"is_active": new_status})\
        .eq("id", user_id)\
        .execute()

    # Log admin action
    supabase.table("admin_logs").insert({
        "admin_id": admin["id"],
        "action": f"User {'enabled' if new_status else 'disabled'}",
        "target_user_id": user_id
    }).execute()

    return {
        "message": f"User {'enabled' if new_status else 'disabled'} successfully",
        "is_active": new_status
    }


# ── DELETE USER ──
@router.delete("/users/{user_id}")
def delete_user(user_id: int, authorization: str = Header(...)):
    token = authorization.replace("Bearer ", "")
    admin = get_admin_from_token(token)

    supabase = get_supabase()

    # Prevent deleting admin accounts
    result = supabase.table("users")\
        .select("role")\
        .eq("id", user_id)\
        .execute()

    if not result.data:
        raise HTTPException(status_code=404, detail="User not found")

    if result.data[0]["role"] == "admin":
        raise HTTPException(
            status_code=400,
            detail="Cannot delete an admin account"
        )

    supabase.table("users")\
        .delete()\
        .eq("id", user_id)\
        .execute()

    # Log admin action
    supabase.table("admin_logs").insert({
        "admin_id": admin["id"],
        "action": "User deleted",
        "target_user_id": user_id
    }).execute()

    return {"message": "User deleted successfully"}


# ── GET ALL CONSULTATIONS (chat logs) ──
@router.get("/consultations")
def get_all_consultations(authorization: str = Header(...)):
    token = authorization.replace("Bearer ", "")
    get_admin_from_token(token)

    supabase = get_supabase()
    result = supabase.table("consultations")\
        .select("*, users(name, email)")\
        .order("created_at", desc=True)\
        .execute()

    return {"consultations": result.data}


# ── GET APP STATISTICS ──
@router.get("/stats")
def get_stats(authorization: str = Header(...)):
    token = authorization.replace("Bearer ", "")
    get_admin_from_token(token)

    supabase = get_supabase()

    total_users = supabase.table("users")\
        .select("id")\
        .eq("role", "user")\
        .execute()

    active_users = supabase.table("users")\
        .select("id")\
        .eq("role", "user")\
        .eq("is_active", True)\
        .execute()

    total_consultations = supabase.table("consultations")\
        .select("id")\
        .execute()

    high_severity = supabase.table("consultations")\
        .select("id")\
        .eq("severity", "high")\
        .execute()

    return {
        "total_users": len(total_users.data),
        "active_users": len(active_users.data),
        "total_consultations": len(total_consultations.data),
        "high_severity_cases": len(high_severity.data)
    }


# ── GET ADMIN LOGS ──
@router.get("/logs")
def get_admin_logs(authorization: str = Header(...)):
    token = authorization.replace("Bearer ", "")
    get_admin_from_token(token)

    supabase = get_supabase()
    result = supabase.table("admin_logs")\
        .select("*, users(name, email)")\
        .order("created_at", desc=True)\
        .execute()

    return {"logs": result.data}
