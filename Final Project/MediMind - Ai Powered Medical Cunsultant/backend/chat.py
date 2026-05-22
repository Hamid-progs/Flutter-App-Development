from fastapi import APIRouter, HTTPException, Header
from models import ChatModel
from database import get_supabase
import httpx, jwt, os
from dotenv import load_dotenv

load_dotenv()
router = APIRouter()

SYSTEM_PROMPT = """
You are MediMind, a compassionate and knowledgeable AI medical assistant
built for human welfare, especially for people in Pakistan who may not
have easy access to doctors.

YOUR CORE RESPONSIBILITIES:
- Listen carefully to patient symptoms
- Suggest possible conditions in simple language
- Give practical home remedy advice for minor issues
- Always tell patients when they MUST see a real doctor
- Support both English and Urdu languages naturally
- Be warm, calm and empathetic in every response

STRICT MEDICAL RULES:
- NEVER claim to replace a real doctor
- NEVER prescribe specific medication doses
- ALWAYS recommend emergency services for:
  chest pain, difficulty breathing, stroke symptoms, severe bleeding
- NEVER give advice that could cause harm

RESPONSE FORMAT — always follow this exact structure:

🔍 Possible Cause:
- [most likely cause]
- [second possibility if any]

💊 Home Remedies:
- [remedy 1]
- [remedy 2]
- [remedy 3]

⚠️ Warning Signs — See Doctor If:
- [sign 1]
- [sign 2]

📋 My Recommendation:
[One clear sentence: rest at home / visit clinic / go to emergency]

FORMATTING RULES:
- Maximum 150 words total
- Always use bullet points — never long paragraphs
- Use the emoji headers exactly as shown above
- Maximum 3 bullet points per section
- Keep each bullet point to one short sentence
- Always end with the 📋 Recommendation section

Remember: You are helping vulnerable people who may be scared.
Be their trusted health companion. Keep it simple and clear.
"""


def get_user_from_token(token: str):
    try:
        return jwt.decode(
            token,
            os.getenv("JWT_SECRET"),
            algorithms=["HS256"]
        )
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=401,
            detail="Token expired, please login again"
        )
    except Exception as e:
        print("TOKEN ERROR:", str(e))
        raise HTTPException(
            status_code=401,
            detail="Invalid token"
        )


# ── SEND MESSAGE TO GROQ AI ──
@router.post("/send")
async def send_message(
    data: ChatModel,
    authorization: str = Header(...)
):
    token = authorization.replace("Bearer ", "")
    user = get_user_from_token(token)

    print(f"✅ User {user['id']} sending message: {data.message}")

    supabase = get_supabase()

    # Get user health profile for personalized advice
    try:
        profile = supabase.table("health_profiles")\
            .select("*")\
            .eq("user_id", user["id"])\
            .execute()
    except Exception as e:
        print("Profile fetch error:", str(e))
        profile = None

    # Build personalized patient context if profile exists
    patient_context = ""
    if profile and profile.data:
        p = profile.data[0]
        patient_context = f"""
Patient profile:
- Age: {p.get('age', 'not provided')}
- Gender: {p.get('gender', 'not provided')}
- Blood group: {p.get('blood_group', 'not provided')}
- Weight: {p.get('weight', 'not provided')} kg
- Height: {p.get('height', 'not provided')} cm
- Existing conditions: {p.get('existing_conditions', 'none')}
- Allergies: {p.get('allergies', 'none')}

Please consider this profile when giving health advice.
"""

    # ── Call Groq API ──
    groq_key = os.getenv('GROQ_API_KEY')
    print(f"🔑 Groq key starts with: {groq_key[:15] if groq_key else 'NOT FOUND'}")

    if not groq_key:
        raise HTTPException(
            status_code=500,
            detail="Groq API key not configured"
        )

    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                "https://api.groq.com/openai/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {groq_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": "openai/gpt-oss-120b",
                    "messages": [
                        {
                            "role": "system",
                            "content": SYSTEM_PROMPT
                        },
                        {
                            "role": "user",
                            "content": f"{patient_context}\nPatient says: {data.message}"
                        }
                    ],
                    "max_tokens": 1024,
                    "temperature": 0.7
                }
            )

        print(f"📡 Groq response status: {response.status_code}")

        if response.status_code != 200:
            print(f"❌ Groq error: {response.text}")
            raise HTTPException(
                status_code=500,
                detail=f"Groq AI error: {response.text}"
            )

    except httpx.TimeoutException:
        print("❌ Groq request timed out")
        raise HTTPException(
            status_code=500,
            detail="AI service timed out. Please try again."
        )
    except httpx.ConnectError:
        print("❌ Cannot connect to Groq")
        raise HTTPException(
            status_code=500,
            detail="Cannot connect to AI service. Check internet."
        )
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Unexpected error: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Unexpected error: {str(e)}"
        )

    ai_reply = response.json()["choices"][0]["message"]["content"]
    print(f"✅ AI replied successfully")

    # ── Auto detect severity ──
    severity = "low"
    high_keywords = [
        "emergency", "immediately", "hospital", "ambulance",
        "critical", "urgent", "call 115", "life-threatening"
    ]
    medium_keywords = [
        "doctor", "consult", "clinic", "appointment",
        "soon", "within 24", "visit"
    ]

    if any(word in ai_reply.lower() for word in high_keywords):
        severity = "high"
    elif any(word in ai_reply.lower() for word in medium_keywords):
        severity = "medium"

    # ── Save to Supabase ──
    try:
        supabase.table("consultations").insert({
            "user_id": user["id"],
            "symptoms": data.message,
            "ai_response": ai_reply,
            "severity": severity
        }).execute()
        print("✅ Consultation saved to Supabase")
    except Exception as e:
        print(f"⚠️ Failed to save consultation: {str(e)}")

    return {
        "reply": ai_reply,
        "severity": severity
    }


# ── GET CONSULTATION HISTORY ──
@router.get("/history")
def get_history(authorization: str = Header(...)):
    token = authorization.replace("Bearer ", "")
    user = get_user_from_token(token)

    supabase = get_supabase()
    result = supabase.table("consultations")\
        .select("*")\
        .eq("user_id", user["id"])\
        .order("created_at", desc=True)\
        .execute()

    return {"consultations": result.data}


# ── DELETE A SINGLE CONSULTATION ──
@router.delete("/history/{consultation_id}")
def delete_consultation(
    consultation_id: int,
    authorization: str = Header(...)
):
    token = authorization.replace("Bearer ", "")
    user = get_user_from_token(token)

    supabase = get_supabase()
    supabase.table("consultations")\
        .delete()\
        .eq("id", consultation_id)\
        .eq("user_id", user["id"])\
        .execute()

    return {"message": "Consultation deleted successfully"}