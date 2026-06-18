from passlib.context import CryptContext
import hashlib
from jose import jwt
from datetime import datetime, timedelta
from dotenv import load_dotenv
import os
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.schemas import UserBase
from jose import JWTError

load_dotenv()

SECRET_KEY = os.getenv("SECRET_KEY", "VladimirLesnik")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "300"))
REFRESH_TOKEN_EXPIRE_MINUTES = int(os.getenv("REFRESH_TOKEN_EXPIRE_MINUTES", "60"))

security_scheme = HTTPBearer()

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
ENABLE_LEGACY_SHA256_PASSWORD_FALLBACK = os.getenv("ENABLE_LEGACY_SHA256_PASSWORD_FALLBACK", "false").lower() in {
    "1",
    "true",
    "yes",
    "on",
}

def hash_password_sha256(password: str):
    return hashlib.sha256(password.encode('utf-8')).hexdigest()

def get_password_hash(password: str):
    return pwd_context.hash(password)

def _verify_password_value(password_value: str, hashed_password: str):
    try:
        return pwd_context.verify(password_value, hashed_password)
    except Exception:
        return False

def verify_password(password: str, hashed_password: str):
    verified, _ = verify_password_and_needs_rehash(password, hashed_password)
    return verified

def verify_password_and_needs_rehash(password: str, hashed_password: str):
    if _verify_password_value(password, hashed_password):
        return True, False
    if ENABLE_LEGACY_SHA256_PASSWORD_FALLBACK and _verify_password_value(hash_password_sha256(password), hashed_password):
        return True, True
    return False, False

def password_needs_rehash(password: str, hashed_password: str):
    _, needs_rehash = verify_password_and_needs_rehash(password, hashed_password)
    return needs_rehash

def create_access_token(data: dict, expires_delta: timedelta | None = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def create_refresh_token(data: dict, expires_delta: timedelta | None = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def get_current_user(token: str = Depends(security_scheme), db: Session = Depends(get_db)):
    token = token.credentials
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    from app.crud import get_user_by_email
    user = get_user_by_email(db, email=email)
    if user is None:
        raise credentials_exception
    if user.banned:
        raise HTTPException(status_code=403, detail="Ваш аккаунт был заблокирован")
    return user
