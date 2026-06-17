from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, Text, DateTime, DECIMAL
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.core.database import Base

class Role(Base):
    __tablename__ = "roles"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), nullable=False)

    users = relationship("User", back_populates="role")

class Category(Base):
    __tablename__ = "categories"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), nullable=False)

    places = relationship("Place", back_populates="category")

class Status(Base):
    __tablename__ = "statuses"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), nullable=False)

    places = relationship("Place", back_populates="status")

class TypeReport(Base):
    __tablename__ = "type_reports"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), nullable=False)

    reports = relationship("ReportPlaces", back_populates="type_report")


class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    id_role = Column(Integer, ForeignKey("roles.id"), nullable=False)
    email = Column(String(255), unique=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    first_name = Column(String(50), nullable=False)
    last_name = Column(String(50), nullable=False)
    patronymic = Column(String(50), nullable=True)
    banned = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    avatar = Column(Text, nullable=True)

    role = relationship("Role", back_populates="users")
    places = relationship("Place", back_populates="user")
    favorites = relationship("Favorites", back_populates="user")
    images = relationship("ImagePlaces", back_populates="user")
    routes = relationship("Route", back_populates="user")

class Place(Base):
    __tablename__ = "places"
    
    id = Column(Integer, primary_key=True, index=True)
    id_user = Column(Integer, ForeignKey("users.id"), nullable=False)
    id_category = Column(Integer, ForeignKey("categories.id"), nullable=False)
    id_status = Column(Integer, ForeignKey("statuses.id"), nullable=False)
    name = Column(String(50), nullable=False)
    description = Column(String(255), nullable=True)
    address = Column(String(255), nullable=True)
    coordinates = Column(String(255), nullable=True) 
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    user = relationship("User", back_populates="places")
    category = relationship("Category", back_populates="places")
    status = relationship("Status", back_populates="places")
    images = relationship("ImagePlaces", back_populates="place")
    comments = relationship("CommentPlaces", back_populates="place")

class ImagePlaces(Base):
    __tablename__ = "image_places"
    
    id = Column(Integer, primary_key=True, index=True)
    id_place = Column(Integer, ForeignKey("places.id"), nullable=False)
    id_user = Column(Integer, ForeignKey("users.id"), nullable=False)
    image = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now()) 

    place = relationship("Place", back_populates="images")
    user = relationship("User", back_populates="images")

class CommentPlaces(Base):
    __tablename__ = "comment_places"
    
    id = Column(Integer, primary_key=True, index=True)
    id_place = Column(Integer, ForeignKey("places.id"), nullable=False)
    id_user = Column(Integer, ForeignKey("users.id"), nullable=False)
    estimation = Column(Integer, nullable=True)
    comment = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    place = relationship("Place", back_populates="comments")
   

class Favorites(Base):
    __tablename__ = "favorites" 
    
    id = Column(Integer, primary_key=True, index=True)
    id_place = Column(Integer, ForeignKey("places.id"), nullable=True)
    id_route = Column(Integer, ForeignKey("routes.id"), nullable=True)
    id_user = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="favorites")
    route = relationship("Route", back_populates="favorites")


class ReportPlaces(Base):
    __tablename__ = "report_places"
    
    id = Column(Integer, primary_key=True, index=True)
    id_place = Column(Integer, ForeignKey("places.id"), nullable=False)
    id_user = Column(Integer, ForeignKey("users.id"), nullable=False)
    id_type_report = Column(Integer, ForeignKey("type_reports.id"), nullable=False)
    report = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    type_report = relationship("TypeReport", back_populates="reports")


class StatusReport(Base):
    __tablename__ = "status_reports"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), nullable=False)

class Route(Base):
    __tablename__ = "routes"

    id = Column(Integer, primary_key=True, index=True)
    id_user = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    user = relationship("User", back_populates="routes")
    places = relationship("RoutePlaces", back_populates="route", order_by="RoutePlaces.position", cascade="all, delete-orphan")
    comments = relationship("CommentRoutes", back_populates="route", cascade="all, delete-orphan")
    favorites = relationship("Favorites", back_populates="route")


class RoutePlaces(Base):
    __tablename__ = "route_places"

    id = Column(Integer, primary_key=True, index=True)
    id_route = Column(Integer, ForeignKey("routes.id"), nullable=False)
    id_place = Column(Integer, ForeignKey("places.id"), nullable=False)
    position = Column(Integer, nullable=False)

    route = relationship("Route", back_populates="places")
    place = relationship("Place")


class CommentRoutes(Base):
    __tablename__ = "comment_routes"

    id = Column(Integer, primary_key=True, index=True)
    id_route = Column(Integer, ForeignKey("routes.id"), nullable=False)
    id_user = Column(Integer, ForeignKey("users.id"), nullable=False)
    estimation = Column(Integer, nullable=True)
    comment = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    route = relationship("Route", back_populates="comments")


class ImageStorage(Base):
    __tablename__ = "image_storage"
    id = Column(String(50), primary_key=True, index=True)
    base64_data = Column(Text(int(4294967295)), nullable=False)
