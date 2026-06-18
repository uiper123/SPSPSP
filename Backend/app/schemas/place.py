from pydantic import BaseModel, EmailStr, Field
from datetime import datetime
from typing import Optional
from decimal import Decimal
from typing import List

class PlaceBase(BaseModel):
    name: str
    description: Optional[str] = None
    address: Optional[str] = None
    coordinates: Optional[str] = None

class PlaceCreate(PlaceBase):
    images: Optional[List[str]] = []
    id_category: int

class PlaceCreateAdmin(PlaceBase):
    id_status: int = 1
    images: Optional[List[str]] = []
    id_category: int
    id_user: int

class PlaceUpdateMe(BaseModel):
    name: str | None = None
    description: str | None = None
    address: str | None = None
    coordinates: str | None = None
    images: Optional[List[str]] = None
    id_category: int | None = None

class PlaceUpdateAdmin(BaseModel):
    name: str | None = None
    description: str | None = None
    address: str | None = None
    coordinates: str | None = None
    id_status: int | None = None
    images: Optional[List[str]] = None
    id_category: int | None = None

class PlaceUpdateStatusModer(BaseModel):
    id_status: int

class PlaceResponse(PlaceBase):
    id: int
    id_user: int
    id_category: int
    id_status: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True


class PlaceImageCreate(BaseModel):
    id_place: int
    image: str

class PlaceImageResponse(BaseModel):
    id: int
    id_place: int
    image: str
    
    class Config:
        from_attributes = True


class FilterPlaceGet(BaseModel):
    id_category: int | None = None
    id_status: int | None = None
    rating: int | None = None
    country: str | None = None
    region: str | None = None
    city: str | None = None
    id: int | None = None
    name: str | None = None
    distance: float | None = None
    latitude: float | None = None
    longitude: float | None = None
    

class PlaceCategoryCreate(BaseModel):
    name: str

class PlaceCategoryResponse(BaseModel):
    id: int
    name: str
    
    class Config:
        from_attributes = True

class StatusCreate(BaseModel):
    name: str

class StatusResponse(BaseModel):
    id: int
    name: str
    
    class Config:
        from_attributes = True

class StatusUpdate(BaseModel):
    name: str | None = None

class CategoryCreate(BaseModel):
    name: str

class CategoryUpdate(BaseModel):
    name: str | None = None

class CategoryResponse(BaseModel):
    id: int
    name: str
    
    class Config:
        from_attributes = True


class ReportPlacesCreate(BaseModel):
    id_place: int
    id_user: int 
    report: str
    id_type_report: int

class ReportPlacesResponse(BaseModel):
    id: int 
    id_place: int
    id_user: int 
    report: str
    id_type_report: int
    created_at: datetime
    
    class Config:
        from_attributes = True

class TypeReportCreate(BaseModel):
    name: str

class TypeReportUpdate(BaseModel):
    name: str | None = None

class TypeReportResponse(BaseModel):
    id: int
    name: str
    
    class Config:
        from_attributes = True


class CommentPlacesCreate(BaseModel):
    id_place: int
    estimation: int = Field(..., ge=1, le=5)
    comment: str

class CommentPlacesResponse(BaseModel):
    id: int
    id_place: int
    id_user: int
    estimation: int
    comment: str
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

class CommentPlacesUpdate(BaseModel):
    estimation: int | None = Field(default=None, ge=1, le=5)
    comment: str | None = None

class CommentWithAuthorResponse(BaseModel):
    id: int
    id_place: int
    id_user: int
    estimation: int
    comment: str
    author_name: str = ""
    author_avatar: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class PlaceSearchResponse(BaseModel):
    id: int
    name: str
    description: str | None = ""
    image: str | None = ""
    images: List[str] = []
    location: str | None = ""
    coordinates: str | None = ""
    type: str | None = ""
    status: str | None = ""
    id_user: int
    author_name: str | None = ""
    author_avatar: Optional[str] = None
    average_rating: float = 0.0
    
    class Config:
        from_attributes = True


class RoutePlaceItem(BaseModel):
    id: int
    name: str
    image: str = ""
    location: str = ""
    coordinates: str = ""
    position: int

    class Config:
        from_attributes = True


class RouteCreate(BaseModel):
    name: str
    description: Optional[str] = None
    place_ids: List[int]


class RouteUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    place_ids: Optional[List[int]] = None


class RouteResponse(BaseModel):
    id: int
    id_user: int
    name: str
    description: Optional[str] = None
    author_name: str = ""
    author_avatar: Optional[str] = None
    average_rating: float = 0.0
    places: List[RoutePlaceItem] = []
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class RoutePathPoint(BaseModel):
    lat: float
    lng: float


class RoutePathResponse(BaseModel):
    route_id: int
    provider: str = "osrm"
    distance_meters: float = 0.0
    duration_seconds: float = 0.0
    points: List[RoutePathPoint] = []


class CommentRoutesCreate(BaseModel):
    id_route: int
    estimation: int = Field(..., ge=1, le=5)
    comment: str


class CommentRoutesResponse(BaseModel):
    id: int
    id_route: int
    id_user: int
    estimation: int
    comment: str
    created_at: datetime

    class Config:
        from_attributes = True


class CommentRoutesWithAuthorResponse(BaseModel):
    id: int
    id_route: int
    id_user: int
    estimation: int
    comment: str
    author_name: str = ""
    author_avatar: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True
