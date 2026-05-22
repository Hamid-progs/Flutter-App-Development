from pydantic import BaseModel
from typing import Optional

class RegisterModel(BaseModel):
    name: str
    email: str
    password: str

class LoginModel(BaseModel):
    email: str
    password: str

class ChatModel(BaseModel):
    message: str

class ProfileModel(BaseModel):
    age: Optional[int] = None
    gender: Optional[str] = None
    blood_group: Optional[str] = None
    weight: Optional[float] = None
    height: Optional[float] = None
    existing_conditions: Optional[str] = None
    allergies: Optional[str] = None

class ToggleUserModel(BaseModel):
    is_active: bool
