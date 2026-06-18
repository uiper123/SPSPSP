from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func
from app.models import User, Role, Place, ImagePlaces, Category, CommentPlaces, Status, ReportPlaces, TypeReport, Favorites, Route, RoutePlaces, CommentRoutes
from app.schemas import UserRegister, RoleCreate, RoleUpdate, PlaceCreate, PlaceCreateAdmin, PlaceImageCreate, PlaceCategoryCreate, CommentPlacesCreate, CommentPlacesUpdate, UserUpdateAdmin, UserUpdateMe, PlaceUpdateAdmin, PlaceUpdateMe, PlaceUpdateStatusModer, StatusCreate, StatusUpdate, CategoryCreate, CategoryUpdate, TypeReportCreate, TypeReportUpdate, ReportPlacesCreate, FavoritesCreate, FilterPlaceGet, PlaceSearchResponse, UserBanModer, RouteCreate, RouteUpdate, RouteResponse, RoutePlaceItem, RoutePathPoint, RoutePathResponse, CommentRoutesCreate
from app.core.securety import get_password_hash
import base64
import uuid
import os
import binascii
from datetime import datetime
import json
import urllib.parse
import urllib.request


def get_role(db: Session, role_id: int):
    return db.query(Role).filter(Role.id == role_id).first()

def create_role(db: Session, role: RoleCreate):
    db_role = Role(
        name=role.name
    )
    db.add(db_role)
    db.commit()
    db.refresh(db_role)
    return db_role

def delete_role(db: Session, role_id: int):
    try:
        db_role = get_role(db, role_id)
        if not db_role:
            return None
        db.query(Role).filter(Role.id == role_id).delete()
        db.commit()
    except Exception as e:
        db.rollback()
        return None
    return db_role

def update_role(db: Session, role: RoleUpdate, role_id: int):
    db_role = get_role(db, role_id)
    if not db_role:
        return None
    db_role.name = role.name
    db.commit()
    db.refresh(db_role)
    return db_role

def get_user(db: Session, user_id: int):
    return db.query(User).filter(User.id == user_id).first()

def get_user_by_email(db: Session, email: str):
    return db.query(User).filter(User.email == email).first()

def get_users(db: Session, skip: int = 0, limit: int = 10):
    return db.query(User).offset(skip).limit(limit).all()

def create_user_register(db: Session, user: UserRegister):
    hashed_password = get_password_hash(user.password)
    db_user = User(
        email=user.email,
        hashed_password=hashed_password,
        first_name=user.first_name,
        last_name="Unknown",
        patronymic=None,
        id_role=1,
        banned=False,
        avatar=None
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


def update_user(db: Session, user: UserUpdateAdmin | UserUpdateMe, id_user: int):
    db_user = get_user(db, id_user)
    if not db_user:
        return None
    update_data = user.dict(exclude_unset=True)
    for key, value in update_data.items():
        if key == "password" and value is not None:
            value = get_password_hash(value)
        if key == "updated_at" and value is not None:
            value = datetime.fromisoformat(value)
        if key == "avatar" and value is not None:
            value = save_image_avatar(db, value)
        setattr(db_user, key, value)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


def delete_user(db: Session, user_id: int):
    db_user = get_user(db, user_id)
    if not db_user:
        return None
    has_places = db.query(Place).filter(Place.id_user == user_id).first() is not None
    has_routes = db.query(Route).filter(Route.id_user == user_id).first() is not None
    if has_places or has_routes:
        return None
    db.query(CommentPlaces).filter(CommentPlaces.id_user == user_id).delete()
    db.query(CommentRoutes).filter(CommentRoutes.id_user == user_id).delete()
    db.query(ReportPlaces).filter(ReportPlaces.id_user == user_id).delete()
    db.query(Favorites).filter(Favorites.id_user == user_id).delete()
    db.query(User).filter(User.id == user_id).delete()
    db.commit()
    return db_user

def update_user_ban_moder(db: Session, user: UserBanModer, id_user: int):
    db_user = get_user(db, id_user)
    if not db_user:
        return None
    db_user.banned = user.banned
    
    if user.banned:
        db_places = db.query(Place).filter(Place.id_user == id_user).all()
        for place in db_places:
            delete_place(db, place.id)
        db.query(CommentPlaces).filter(CommentPlaces.id_user == id_user).delete()
        
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def create_place(db: Session, place: PlaceCreate | PlaceCreateAdmin, id_user: int):
    statust_id = getattr(place, "id_status", 1)
    db_place = Place(
        name=place.name,
        description=place.description,
        address=place.address,
        coordinates=place.coordinates,
        id_category=place.id_category,
        id_user=id_user,
        id_status=statust_id,
        created_at=func.now(),
        updated_at=func.now()
    )
    db.add(db_place)
    db.commit()
    db.refresh(db_place)

    if (place.images):
        for image in place.images:
            saved_path = save_image(db, image)
            if not saved_path:
                continue
            db_image = ImagePlaces(
                id_place=db_place.id,
                id_user=db_place.id_user,
                image=saved_path
            )
            db.add(db_image)
            db.commit()
            db.refresh(db_place)
    return db_place

def update_place(db: Session, place: PlaceUpdateMe | PlaceUpdateAdmin | PlaceUpdateStatusModer, id_place: int):
    db_place = get_place(db, id_place)
    if not db_place:
        return None
    update_data = place.dict(exclude_unset=True)
    for key, value in update_data.items():
        if key == "updated_at" and value is not None:
            value = datetime.fromisoformat(value)
        if key == "images" and value is not None:
            existing_images = db.query(ImagePlaces).filter(ImagePlaces.id_place == db_place.id).all()
            existing_paths = [img.image for img in existing_images]
            
            new_paths = []
            for img_str in value:
                if img_str.startswith('/static/'):
                    if img_str in existing_paths:
                        new_paths.append(img_str)
                else:
                    saved_path = save_image(db, img_str)
                    if saved_path:
                        new_paths.append(saved_path)
            
            for img in existing_images:
                if img.image not in new_paths:
                    relative_path = img.image.lstrip("/")
                    file_path = os.path.join("app", relative_path)
                    if os.path.exists(file_path):
                        try:
                            os.remove(file_path)
                        except:
                            pass
                    db.delete(img)
            
            for path in new_paths:
                if path not in existing_paths:
                    db_image = ImagePlaces(
                        id_place=db_place.id,
                        id_user=db_place.id_user,
                        image=path
                    )
                    db.add(db_image)
            
            db.commit()
            db.refresh(db_place)
            continue
        setattr(db_place, key, value)
    db.add(db_place)
    db.commit()
    db.refresh(db_place)
    return db_place

def _save_base64_to_disk(base64_image: str) -> str:
    """Декодирует base64 и сохраняет как файл. Возвращает путь /static/images/{id}.jpg"""
    file_id = str(uuid.uuid4())
    images_dir = os.path.join("app", "static", "images")
    os.makedirs(images_dir, exist_ok=True)

    data = base64_image
    if "," in data:
        data = data.split(",", 1)[1]
    missing_padding = len(data) % 4
    if missing_padding:
        data += "=" * (4 - missing_padding)

    img_bytes = base64.b64decode(data)
    file_path = os.path.join(images_dir, f"{file_id}.jpg")
    with open(file_path, "wb") as f:
        f.write(img_bytes)

    return f'/static/images/{file_id}.jpg'

def save_image(db: Session, base64_image: str):
    return _save_base64_to_disk(base64_image)

def save_image_avatar(db: Session, base64_image: str):
    return _save_base64_to_disk(base64_image)

def create_place_image(db: Session, place_image: PlaceImageCreate):
    db_place_image = ImagePlaces(
        id_place=place_image.id_place,
        image=place_image.image,
        id_user=place_image.id_user
    )
    db.add(db_place_image)
    db.commit()
    db.refresh(db_place_image)
    return db_place_image

def delete_place(db: Session, place_id: int):
    db_place = db.query(Place).filter(Place.id == place_id).first()
    if not db_place:
        return None
    db_images = db.query(ImagePlaces).filter(ImagePlaces.id_place == place_id).all()
    for image in db_images:
        relative_path = image.image.lstrip("/")
        file_path = os.path.join("app", relative_path)
        if os.path.exists(file_path):
            os.remove(file_path)
    db.query(ImagePlaces).filter(ImagePlaces.id_place == place_id).delete()
    db.query(CommentPlaces).filter(CommentPlaces.id_place == place_id).delete()
    db.query(ReportPlaces).filter(ReportPlaces.id_place == place_id).delete()
    db.query(Favorites).filter(Favorites.id_place == place_id).delete()
    db.delete(db_place)
    db.commit()
    return db_place

def get_place_filters(db: Session, place: FilterPlaceGet):
    query = db.query(Place).options(
        joinedload(Place.images),
        joinedload(Place.comments),
        joinedload(Place.category),
        joinedload(Place.user),
        joinedload(Place.status),
    )
    
    if place.id is not None:
        query = query.filter(Place.id == place.id)
    if place.id_category is not None:
        query = query.filter(Place.id_category == place.id_category)
    if place.id_status is not None:
        query = query.filter(Place.id_status == place.id_status)
    elif place.id is None:
        query = query.filter(Place.id_status == 2)
    if place.country is not None:
        query = query.filter(Place.address.ilike(f"%{place.country}%"))
    if place.region is not None:
        query = query.filter(Place.address.ilike(f"%{place.region}%"))
    if place.city is not None:
        query = query.filter(Place.address.ilike(f"%{place.city}%"))
    if place.name is not None and place.name.strip():
        query = query.filter(Place.name.ilike(f"%{place.name}%"))
        
    places = query.all()
    
    if place.distance is not None and place.latitude is not None and place.longitude is not None:
        import math
        filtered_places = []
        for p in places:
            if not p.coordinates or ',' not in p.coordinates:
                continue
            try:
                p_lat_str, p_lng_str = p.coordinates.split(',')
                p_lat = float(p_lat_str.strip())
                p_lng = float(p_lng_str.strip())
                
                R = 6371.0 
                
                dlat = math.radians(p_lat - place.latitude)
                dlng = math.radians(p_lng - place.longitude)
                
                a = math.sin(dlat / 2)**2 + math.cos(math.radians(place.latitude)) * \
                    math.cos(math.radians(p_lat)) * math.sin(dlng / 2)**2
                c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
                d = R * c
                
                if d <= place.distance:
                    filtered_places.append(p)
            except (ValueError, TypeError):
                continue
        places = filtered_places
    
    if place.rating is not None:
        filtered_places = []
        for p in places:
            if not p.comments:
                continue
            total = sum(c.estimation for c in p.comments if c.estimation is not None)
            avg_rating = total / len(p.comments)
            if avg_rating >= place.rating:
                filtered_places.append(p)
        places = filtered_places
        
    mapped_places = []
    for p in places:
        all_images = [img.image for img in p.images] if p.images else []
        avg_rating = 0.0
        if p.comments:
            ratings = [c.estimation for c in p.comments if c.estimation is not None]
            if ratings:
                avg_rating = round(sum(ratings) / len(ratings), 1)
        mapped_places.append(PlaceSearchResponse(
            id=p.id,
            name=p.name,
            description=p.description or "",
            image=all_images[0] if len(all_images) > 0 else "",
            images=all_images,
            location=p.address or "",
            coordinates=str(p.coordinates) if p.coordinates else "",
            type=p.category.name if p.category else "",
            status=p.status.name if p.status else "",
            id_user=p.id_user,
            author_name=f"{p.user.first_name} {p.user.last_name}" if p.user else "",
            author_avatar=p.user.avatar if p.user else None,
            average_rating=avg_rating
        ))
    return mapped_places

def delete_image(db: Session, image_id: int, id_user: int):
    db_image = db.query(ImagePlaces).filter(ImagePlaces.id == image_id, ImagePlaces.id_user == id_user).first()
    if not db_image:
        return None
    relative_path = db_image.image.lstrip("/")
    file_path = os.path.join("app", relative_path)
    if os.path.exists(file_path):
        os.remove(file_path)
    db.delete(db_image)
    db.commit()
    return db_image

def get_place(db: Session, place_id: int):
    return db.query(Place).filter(Place.id == place_id).first()

def get_places(db: Session, skip: int = 0, limit: int = 10):
    return db.query(Place).offset(skip).limit(limit).all()

def get_status(db: Session, status_id: int):
    return db.query(Status).filter(Status.id == status_id).first()

def get_statuses(db: Session, skip: int = 0, limit: int = 10):
    return db.query(Status).offset(skip).limit(limit).all()

def create_status(db: Session, status: StatusCreate):
    db_status = Status(
        name=status.name
    )
    db.add(db_status)
    db.commit()
    db.refresh(db_status)
    return db_status

def delete_status(db: Session, status_id: int):
    try:
        db_status = get_status(db, status_id)
        if not db_status:
            return None
        db.delete(db_status)
        db.commit()
        return db_status
    except Exception as e:
        db.rollback()
        return None

def update_status(db: Session, status: StatusUpdate, status_id: int):
    db_status = get_status(db, status_id)
    if not db_status:
        return None
    db_status.name = status.name
    db.commit()
    db.refresh(db_status)
    return db_status

def get_category(db: Session, category_id: int):
    return db.query(Category).filter(Category.id == category_id).first()

def get_categories(db: Session, skip: int = 0, limit: int = 10):
    return db.query(Category).offset(skip).limit(limit).all()

def create_category(db: Session, category: CategoryCreate):
    db_category = Category(
        name=category.name
    )
    db.add(db_category)
    db.commit()
    db.refresh(db_category)
    return db_category

def delete_category(db: Session, category_id: int):
    try:
        db_categorys = get_category(db, category_id)
        if not db_categorys:
            return None
        db.query(Category).filter(Category.id == category_id).delete()
        db.commit()
    except Exception as e:
        db.rollback()
        return None
    return db_categorys

def update_category(db: Session, category: CategoryUpdate, category_id: int):
    db_category = get_category(db, category_id)
    if not db_category:
        return None
    db_category.name = category.name
    db.commit()
    db.refresh(db_category)
    return db_category

def create_report_places(db: Session, report_places: ReportPlacesCreate, id_user: int):
    db_report_places = ReportPlaces(
        id_place=report_places.id_place,
        id_user=id_user,
        id_type_report=report_places.id_type_report,
        report=report_places.report
    )
    db.add(db_report_places)
    db.commit()
    db.refresh(db_report_places)
    return db_report_places

def get_report_place(db: Session, report_places_id: int):
    return db.query(ReportPlaces).filter(ReportPlaces.id == report_places_id).first()

def get_report_places(db: Session, skip: int = 0, limit: int = 10):
    return db.query(ReportPlaces).offset(skip).limit(limit).all()

def delete_report_places(db: Session, report_places_id: int):
    try:
        db_report_places = get_report_place(db, report_places_id)
        if not db_report_places:
            return None
        db.delete(db_report_places)
        db.commit()
    except Exception as e:
        db.rollback()
        return None
    return db_report_places

def get_type_report(db: Session, type_report_id: int):
    return db.query(TypeReport).filter(TypeReport.id == type_report_id).first()

def get_type_reports(db: Session, skip: int = 0, limit: int = 10):
    return db.query(TypeReport).offset(skip).limit(limit).all()

def create_type_report(db: Session, type_report: TypeReportCreate):
    db_type_report = TypeReport(
        name=type_report.name
    )
    db.add(db_type_report)
    db.commit()
    db.refresh(db_type_report)
    return db_type_report

def update_type_report(db: Session, type_report: TypeReportUpdate, type_report_id: int):
    db_type_report = get_type_report(db, type_report_id)
    if not db_type_report:
        return None
    db_type_report.name = type_report.name
    db.commit()
    db.refresh(db_type_report)
    return db_type_report

def delete_type_report(db: Session, type_report_id: int):
    try:
        db_type_report = get_type_report(db, type_report_id)
        if not db_type_report:
            return None
        db.delete(db_type_report)
        db.commit()
    except Exception as e:
        db.rollback()
        return None
    return db_type_report

def create_favorites(db: Session, favorites: FavoritesCreate, id_user: int):
    db_favorites = Favorites(
        id_user=id_user,
        id_place=favorites.id_place
    )
    db.add(db_favorites)
    db.commit()
    db.refresh(db_favorites)
    return db_favorites

def delete_favorites(db: Session, favorites_id: int):
    try:
        db_favorites = get_favorites(db, favorites_id)
        if not db_favorites:
            return None
        db.delete(db_favorites)
        db.commit()
    except Exception as e:
        db.rollback()
        return None
    return db_favorites

def get_favorites_by_user(db: Session, id_user: int):
    return db.query(Favorites).filter(Favorites.id_user == id_user).all()

def create_comment_places(db: Session, comment_places: CommentPlacesCreate, id_user: int):
    db_comment_places = CommentPlaces(
        id_place=comment_places.id_place,
        id_user=id_user,
        estimation=comment_places.estimation,
        comment=comment_places.comment
    )
    db.add(db_comment_places)
    db.commit()
    db.refresh(db_comment_places)
    return db_comment_places

def get_comments_by_place(db: Session, id_place: int):
    return db.query(CommentPlaces).filter(CommentPlaces.id_place == id_place).all()

def delete_comment_places(db: Session, comment_places_id: int):
    try:
        db_comment_places = get_comment_places(db, comment_places_id)
        if not db_comment_places:
            return None
        db.delete(db_comment_places)
        db.commit()
    except Exception as e:
        db.rollback()
        return None
    return db_comment_places

def update_comment_places(db: Session, comment_places: CommentPlacesUpdate, comment_places_id: int):
    db_comment_places = get_comment_places(db, comment_places_id)
    if not db_comment_places:
        return None
    if (comment_places.estimation is not None):
        db_comment_places.estimation = comment_places.estimation
    if (comment_places.comment is not None):
        db_comment_places.comment = comment_places.comment
    db.commit()
    db.refresh(db_comment_places)
    return db_comment_places


def _build_route_response(db: Session, route: Route) -> RouteResponse:
    user = route.user if route.user else db.query(User).filter(User.id == route.id_user).first()
    author_name = f"{user.first_name} {user.last_name}" if user else ""
    author_avatar = user.avatar if user else None

    places_items = []
    for rp in route.places:
        place = rp.place
        if not place:
            continue
        all_images = [img.image for img in place.images] if place.images else []
        places_items.append(RoutePlaceItem(
            id=place.id,
            name=place.name,
            image=all_images[0] if all_images else "",
            location=place.address or "",
            coordinates=str(place.coordinates) if place.coordinates else "",
            position=rp.position,
        ))

    avg_rating = 0.0
    if route.comments:
        ratings = [c.estimation for c in route.comments if c.estimation is not None]
        if ratings:
            avg_rating = round(sum(ratings) / len(ratings), 1)

    return RouteResponse(
        id=route.id,
        id_user=route.id_user,
        name=route.name,
        description=route.description,
        author_name=author_name,
        author_avatar=author_avatar,
        average_rating=avg_rating,
        places=places_items,
        created_at=route.created_at,
        updated_at=route.updated_at,
    )


def create_route(db: Session, route: RouteCreate, id_user: int) -> RouteResponse:
    db_route = Route(
        id_user=id_user,
        name=route.name,
        description=route.description,
    )
    db.add(db_route)
    db.commit()
    db.refresh(db_route)

    for position, place_id in enumerate(route.place_ids, start=1):
        rp = RoutePlaces(id_route=db_route.id, id_place=place_id, position=position)
        db.add(rp)
    db.commit()
    db.refresh(db_route)

    return _build_route_response(db, db_route)


def get_route(db: Session, route_id: int):
    return db.query(Route).filter(Route.id == route_id).first()


def get_all_routes(db: Session):
    return db.query(Route).options(
        joinedload(Route.user),
        joinedload(Route.places).joinedload(RoutePlaces.place).joinedload(Place.images),
        joinedload(Route.comments),
    ).order_by(Route.created_at.desc()).all()


def _parse_route_coordinate(raw_coordinates: str | None):
    if raw_coordinates is None:
        return None
    try:
        parts = raw_coordinates.split(",")
        if len(parts) != 2:
            return None
        lat = float(parts[0].strip())
        lng = float(parts[1].strip())
        return (lat, lng)
    except (TypeError, ValueError):
        return None


def build_route_path_response(route: Route) -> RoutePathResponse | None:
    route_places = sorted(route.places, key=lambda item: item.position)
    osrm_coordinates = []
    for route_place in route_places:
        if route_place.place is None:
            continue
        parsed = _parse_route_coordinate(route_place.place.coordinates)
        if parsed is None:
            continue
        lat, lng = parsed
        osrm_coordinates.append(f"{lng},{lat}")

    if len(osrm_coordinates) < 2:
        return None

    osrm_base_url = os.getenv("OSRM_BASE_URL", "https://router.project-osrm.org")
    coordinates_query = ";".join(osrm_coordinates)
    query = urllib.parse.urlencode(
        {
            "overview": "full",
            "geometries": "geojson",
            "steps": "false",
        }
    )
    request_url = f"{osrm_base_url.rstrip('/')}/route/v1/driving/{coordinates_query}?{query}"

    request = urllib.request.Request(
        request_url,
        headers={
            "User-Agent": "Spotfynder/1.0",
            "Accept": "application/json",
        }
    )

    with urllib.request.urlopen(request, timeout=10) as response:
        payload = json.loads(response.read().decode("utf-8"))

    routes = payload.get("routes")
    if not routes:
        return None

    best_route = routes[0]
    geometry = best_route.get("geometry", {})
    geometry_coordinates = geometry.get("coordinates", [])
    if not geometry_coordinates:
        return None

    points = []
    for coordinate in geometry_coordinates:
        if not isinstance(coordinate, list) or len(coordinate) < 2:
            continue
        lng, lat = coordinate[0], coordinate[1]
        points.append(RoutePathPoint(lat=lat, lng=lng))

    if len(points) < 2:
        return None

    return RoutePathResponse(
        route_id=route.id,
        distance_meters=float(best_route.get("distance", 0.0)),
        duration_seconds=float(best_route.get("duration", 0.0)),
        points=points,
    )


def update_route(db: Session, route: RouteUpdate, route_id: int) -> RouteResponse:
    db_route = get_route(db, route_id)
    if not db_route:
        return None
    if route.name is not None:
        db_route.name = route.name
    if route.description is not None:
        db_route.description = route.description
    if route.place_ids is not None:
        db.query(RoutePlaces).filter(RoutePlaces.id_route == route_id).delete()
        for position, place_id in enumerate(route.place_ids, start=1):
            rp = RoutePlaces(id_route=route_id, id_place=place_id, position=position)
            db.add(rp)
    db.commit()
    db.refresh(db_route)
    return _build_route_response(db, db_route)


def delete_route(db: Session, route_id: int):
    db_route = get_route(db, route_id)
    if not db_route:
        return None
    db.query(Favorites).filter(Favorites.id_route == route_id).delete()
    db.delete(db_route)
    db.commit()
    return db_route


def create_comment_route(db: Session, comment: CommentRoutesCreate, id_user: int):
    db_comment = CommentRoutes(
        id_route=comment.id_route,
        id_user=id_user,
        estimation=comment.estimation,
        comment=comment.comment,
    )
    db.add(db_comment)
    db.commit()
    db.refresh(db_comment)
    return db_comment


def get_comments_by_route(db: Session, id_route: int):
    return db.query(CommentRoutes).filter(CommentRoutes.id_route == id_route).all()


def get_comment_route(db: Session, comment_id: int):
    return db.query(CommentRoutes).filter(CommentRoutes.id == comment_id).first()


def delete_comment_route(db: Session, comment_id: int):
    db_comment = get_comment_route(db, comment_id)
    if not db_comment:
        return None
    db.delete(db_comment)
    db.commit()
    return db_comment
