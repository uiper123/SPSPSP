from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional

class UserBase(BaseModel):
    email: EmailStr
    first_name: str
    last_name: str
    patronymic: Optional[str] = None
    avatar: Optional[str] = None

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserRegister(BaseModel):
    email: EmailStr
    password: str
    first_name: str

class UserResponse(UserBase):
    id: int
    id_role: int
    banned: bool = False
    created_at: datetime
    avatar: Optional[str] = None
    
    class Config:
        from_attributes = True

class UserUpdateMe(BaseModel):
    avatar: str | None = None
    password: str | None = None
    first_name: str | None = None
    patronymic: str | None = None
    last_name: str | None = None
    email: EmailStr | None = None

    class Config:
        from_attributes = True

class UserUpdateAdmin(BaseModel):
    id_role: int | None = None
    banned: bool | None = None
    avatar: str | None = None
    password: str | None = None
    first_name: str | None = None
    patronymic: str | None = None
    last_name: str | None = None
    email: EmailStr | None = None
    
    class Config:
        from_attributes = True

class UserBanModer(BaseModel):
    banned: bool

class RoleBase(BaseModel):
    name: str

class RoleCreate(RoleBase):
    id: int

class RoleUpdate(BaseModel):
    name: str | None = None

class RoleResponse(RoleBase):
    id: int
    
    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

class FavoritesBase(BaseModel):
    id_user: int
    id_place: Optional[int] = None
    id_route: Optional[int] = None

class FavoritesCreate(FavoritesBase):
    pass

class FavoritesResponse(FavoritesBase):
    id: int
    
    class Config:
        from_attributes = True
