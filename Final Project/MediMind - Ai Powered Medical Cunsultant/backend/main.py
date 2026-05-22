from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import auth, chat, admin, profile

app = FastAPI(
    title="MediMind API",
    description="AI Doctor App Backend - Human Welfare Project",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"]
)

app.include_router(auth.router,    prefix="/api/auth")
app.include_router(chat.router,    prefix="/api/chat")
app.include_router(admin.router,   prefix="/api/admin")
app.include_router(profile.router, prefix="/api/profile")

@app.get("/")
def root():
    return {
        "app": "MediMind API",
        "status": "running",
        "version": "1.0.0"
    }
