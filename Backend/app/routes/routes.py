from fastapi import APIRouter, Depends, HTTPException
import urllib.error
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.schemas import UserBase, UserResponse, RoleCreate, RoleResponse, UserLogin, Token, PlaceCreate, PlaceResponse, StatusCreate, StatusResponse, CategoryCreate, CategoryResponse, ReportPlacesCreate, ReportPlacesResponse, TypeReportCreate, TypeReportResponse, FavoritesCreate, FavoritesResponse, CommentPlacesCreate, CommentPlacesResponse, UserUpdateMe, UserUpdateAdmin, PlaceUpdateMe, PlaceUpdateAdmin, PlaceCreateAdmin, RoleUpdate, CategoryUpdate, StatusUpdate, TypeReportUpdate, PlaceUpdateStatusModer, UserBanModer, CommentPlacesUpdate, FilterPlaceGet, UserRegister, PlaceSearchResponse, CommentWithAuthorResponse, RouteCreate, RouteUpdate, RouteResponse, RoutePathResponse, CommentRoutesCreate, CommentRoutesWithAuthorResponse
from app.crud import get_user_by_email, create_user_register, get_role, create_role, create_place, get_status, create_status, get_category, create_category, create_report_places, get_type_report, create_type_report, create_favorites, get_favorites_by_user, create_comment_places, get_comments_by_place, update_user, get_user, update_user, update_place, delete_image, delete_place, delete_user, delete_role, delete_category, delete_status, delete_report_places, update_role, update_category, update_status, update_type_report, delete_favorites, update_user_ban_moder, delete_comment_places, update_comment_places, get_place_filters, create_route, get_route, get_all_routes, update_route, delete_route, create_comment_route, get_comments_by_route, get_comment_route, delete_comment_route, build_route_path_response
from app.core.securety import create_access_token, verify_password, get_current_user, password_needs_rehash
from app.core.securety import get_password_hash
from app.models import Place, User, Role, Status, Category, ReportPlaces, TypeReport, Favorites, CommentPlaces, CommentRoutes, Route
from typing import List

router = APIRouter()

@router.post("/register", response_model=UserResponse)
def register_user(user: UserRegister, db: Session = Depends(get_db)):
    if len(user.first_name) > 50:
        raise HTTPException(status_code=400, detail="Вы ввели слишком много символов в имени")
    db_user = get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Пользователь с таким email уже существует")
    return create_user_register(db=db, user=user)

@router.get("/users", response_model=list[UserResponse])
def get_users(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.id_role != 2 and current_user.id_role != 3:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    return db.query(User).all()

@router.get("/users/me", response_model=UserResponse)
def get_users_me(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    return get_user(db=db, user_id=current_user.id)

@router.put("/users/me", response_model=UserResponse)
def update_users_me(user: UserUpdateMe, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    return update_user(db=db, user=user, id_user=current_user.id)

@router.put("/users/{id}", response_model=UserResponse)
def update_users(id: int, user: UserUpdateAdmin, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.id_role != 2:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    db_user = db.query(User).filter(User.id == id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")
    return update_user(db=db, user=user, id_user=id)

@router.delete("/users/{id}")
def delete_users(id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.id_role != 2:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    db_user = db.query(User).filter(User.id == id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")
    return delete_user(db=db, user_id=id)

@router.put("/users/ban/{id}", response_model=UserResponse)
def update_users_ban_admin(id: int, user: UserBanModer, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.id_role != 2 and current_user.id_role != 3:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    db_user = db.query(User).filter(User.id == id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")
    
    if current_user.id_role == 3:
        if db_user.id_role == 2 or db_user.id_role == 3:
            raise HTTPException(status_code=403, detail="Модератор может банить только обычных пользователей")
            
    return update_user_ban_moder(db=db, user=user, id_user=id)

@router.post("/role", response_model=RoleResponse)
def create_roles(role: RoleCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.id_role != 2:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    db_role = get_role(db, role_id=role.id)
    if db_role:
        raise HTTPException(status_code=400, detail="Роль с таким id уже существует")
    return create_role(db=db, role=role)

@router.get("/roles", response_model=list[RoleResponse])
def get_roles(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.id_role != 2:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    return db.query(Role).all()

@router.delete("/roles/{id}")
def delete_roles(id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.id_role != 2:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    db_role = db.query(Role).filter(Role.id == id).first()
    if not db_role:
        raise HTTPException(status_code=404, detail="Роль не найдена")
    delete_roless = delete_role(db=db, role_id=id)
    if not delete_roless:
        raise HTTPException(status_code=400, detail="Не удалось удалить роль")
    return delete_roless

@router.put("/roles/{id}", response_model=RoleResponse)
def update_roles(id: int, role: RoleUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.id_role != 2:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    db_role = db.query(Role).filter(Role.id == id).first()
    if not db_role:
        raise HTTPException(status_code=404, detail="Роль не найдена")
    return update_role(db=db, role=role, id_role=id)

@router.post("/login", response_model=Token)
def login_access_token(user: UserLogin, db: Session = Depends(get_db)):
    db_user = get_user_by_email(db, email=user.email)
    if not db_user or not verify_password(user.password, db_user.hashed_password):
        raise HTTPException(status_code=400, detail="Неверный email или пароль")    
    if password_needs_rehash(user.password, db_user.hashed_password):
        db_user.hashed_password = get_password_hash(user.password)
        db.add(db_user)
        db.commit()
    access_token = create_access_token(data={"sub": db_user.email})
    return {"access_token": access_token, "token_type": "bearer"}



@router.post("/place")
def create_new_place(place: PlaceCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    if len(place.name) > 50:
        raise HTTPException(status_code=400, detail="Вы ввели слишком много символов в названии места")
    if place.description and len(place.description) > 255:
        raise HTTPException(status_code=400, detail="Вы ввели слишком много символов в описании места")
    if place.address and len(place.address) > 255:
        raise HTTPException(status_code=400, detail="Вы ввели слишком много символов в адресе места")
    try:
        return create_place(db=db, place=place, id_user=current_user.id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"{type(e).__name__}: {str(e)}")

@router.post("/place/admin")
def create_new_place_admin(place: PlaceCreateAdmin, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    if current_user.id_role != 2:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    try:
        return create_place(db=db, place=place, id_user=place.id_user)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"{type(e).__name__}: {str(e)}")

@router.get("/places", response_model=list[PlaceResponse])
def get_places(db: Session = Depends(get_db)):
    return db.query(Place).all()


@router.put("/place/{id}", response_model=PlaceResponse)
def update_new_place_admin(id: int, place: PlaceUpdateAdmin, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.id_role != 2:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    db_place = db.query(Place).filter(Place.id == id).first()
    if not db_place:
        raise HTTPException(status_code=404, detail="Место не найдено")
    return update_place(db=db, place=place, id_place=id)

@router.put("/place/me/{id}", response_model=PlaceResponse)
def update_new_place_me(id: int, place: PlaceUpdateMe, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    if place.name and len(place.name) > 50:
        raise HTTPException(status_code=400, detail="Вы ввели слишком много символов в названии места")
    if place.description and len(place.description) > 255:
        raise HTTPException(status_code=400, detail="Вы ввели слишком много символов в описании места")
    if place.address and len(place.address) > 255:
        raise HTTPException(status_code=400, detail="Вы ввели слишком много символов в адресе места")
    db_place = db.query(Place).filter(Place.id == id).first()
    if not db_place:
        raise HTTPException(status_code=404, detail="Место не найдено")
    if current_user.id != db_place.id_user:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    return update_place(db=db, place=place, id_place=id)

@router.put("/place/status/{id}", response_model=PlaceResponse)
def update_new_place_status_moder(id: int, place: PlaceUpdateStatusModer, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.id_role != 3 and current_user.id_role != 2:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    db_place = db.query(Place).filter(Place.id == id).first()
    if not db_place:
        raise HTTPException(status_code=404, detail="Место не найдено")
    return update_place(db=db, place=place, id_place=id)


@router.delete("/place/me/{place_id}")
def delete_new_place_me(place_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    db_place = db.query(Place).filter(Place.id == place_id).first()
    if not db_place:
        raise HTTPException(status_code=404, detail="Место не найдено")
    if current_user.id != db_place.id_user:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    delete_place(db=db, place_id=place_id)
    return {"message": "Место успешно удалено"}

@router.delete("/place/{place_id}")
def delete_new_place_admin(place_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    db_place = db.query(Place).filter(Place.id == place_id).first()
    if not db_place:
        raise HTTPException(status_code=404, detail="Место не найдено")
    if current_user.id_role != 2 and current_user.id_role != 3:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    delete_place(db=db, place_id=place_id)
    return {"message": "Место успешно удалено"}

@router.delete("/place/image/{image_id}")
def delete_new_image(image_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    db_image = db.query(ImagePlaces).filter(ImagePlaces.id == image_id).first()
    if not db_image:
        raise HTTPException(status_code=404, detail="Место не найдено")
    if current_user.id != db_image.id_user:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    delete_image(db=db, image_id=image_id, id_user=current_user.id)
    return {"message": "Изображение успешно удалено"}


@router.get("/places/filter", response_model=list[PlaceSearchResponse])
def get_places_filter(place: FilterPlaceGet = Depends(), db: Session = Depends(get_db)):
    return get_place_filters(db=db, place=place)

@router.get("/places/me", response_model=list[PlaceSearchResponse])
def get_my_places(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    places = db.query(Place).filter(Place.id_user == current_user.id).all()
    result = []
    for p in places:
        all_images = [img.image for img in p.images] if p.images else []
        avg_rating = 0.0
        if p.comments:
            ratings = [c.estimation for c in p.comments if c.estimation is not None]
            if ratings:
                avg_rating = round(sum(ratings) / len(ratings), 1)
        result.append(PlaceSearchResponse(
            id=p.id,
            name=p.name,
            description=p.description or "",
            image=all_images[0] if all_images else "",
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
    return result

@router.post("/status", response_model=StatusResponse)
def create_new_status(status: StatusCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    if current_user.id_role != 2:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    return create_status(db=db, status=status)

@router.get("/statuses", response_model=list[StatusResponse])
def get_statuses(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    return db.query(Status).all()

@router.delete("/status/{id}")
def delete_new_status(id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    if current_user.id_role != 2:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    db_status = db.query(Status).filter(Status.id == id).first()
    if not db_status:
        raise HTTPException(status_code=404, detail="Статус не найден")
    delete_statuss = delete_status(db=db, status_id=id)
    if not delete_statuss:
        raise HTTPException(status_code=400, detail="Не удалось удалить статус")
    return delete_statuss

@router.put("/status/{id}", response_model=StatusResponse)
def update_new_status(id: int, status: StatusUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    if current_user.id_role != 2:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    db_status = db.query(Status).filter(Status.id == id).first()
    if not db_status:
        raise HTTPException(status_code=404, detail="Статус не найден")
    return update_status(db=db, status=status, id_status=id)

@router.post("/category", response_model=CategoryResponse)
def create_new_category(category: CategoryCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    if current_user.id_role != 2:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    return create_category(db=db, category=category)

@router.get("/categories", response_model=list[CategoryResponse])
def get_categories(db: Session = Depends(get_db)):
    return db.query(Category).all()

@router.delete("/categories/{id}")
def delete_categories(id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.id_role != 2:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    db_category = db.query(Category).filter(Category.id == id).first()
    if not db_category:
        raise HTTPException(status_code=404, detail="Категория не найдена")
    delete_categoryss = delete_category(db=db, category_id=id)
    if not delete_categoryss:
        raise HTTPException(status_code=400, detail="Не удалось удалить категорию")
    return delete_categoryss

@router.put("/category/{id}", response_model=CategoryResponse)
def update_new_category(id: int, category: CategoryUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    if current_user.id_role != 2:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    db_category = db.query(Category).filter(Category.id == id).first()
    if not db_category:
        raise HTTPException(status_code=404, detail="Категория не найдена")
    return update_category(db=db, category=category, id_category=id)

@router.post("/report_places", response_model=ReportPlacesResponse)
def create_new_report_places(report_places: ReportPlacesCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    return create_report_places(db=db, report_places=report_places, id_user=current_user.id)

@router.get("/report_places", response_model=list[ReportPlacesResponse])
def get_report_places(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    if current_user.id_role != 2 and current_user.id_role != 3:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    return db.query(ReportPlaces).all()

@router.delete("/report_places/{id}")
def delete_report_places_by_id(id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.id_role != 2 and current_user.id_role != 3:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    db_report_places = db.query(ReportPlaces).filter(ReportPlaces.id == id).first()
    if not db_report_places:
        raise HTTPException(status_code=404, detail="Жалоба не найдена")
    delete_report_placess = delete_report_places(db=db, report_places_id=id)
    if not delete_report_placess:
        raise HTTPException(status_code=400, detail="Не удалось удалить жалобу")
    return delete_report_placess


@router.post("/type_report", response_model=TypeReportResponse)
def create_new_type_report(type_report: TypeReportCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    if current_user.id_role != 2:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    return create_type_report(db=db, type_report=type_report)

@router.put("/type_report/{id}", response_model=TypeReportResponse)
def update_new_type_report(id: int, type_report: TypeReportUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    if current_user.id_role != 2:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    db_type_report = db.query(TypeReport).filter(TypeReport.id == id).first()
    if not db_type_report:
        raise HTTPException(status_code=404, detail="Тип жалобы не найден")
    return update_type_report(db=db, type_report=type_report, id_type_report=id)

@router.delete("/type_report/{id}")
def delete_type_report(id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.id_role != 2:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    db_type_report = db.query(TypeReport).filter(TypeReport.id == id).first()
    if not db_type_report:
        raise HTTPException(status_code=404, detail="Тип жалобы не найден")
    delete_type_reports = delete_type_report(db=db, type_report_id=id)
    if not delete_type_reports:
        raise HTTPException(status_code=400, detail="Не удалось удалить тип жалобы")
    return delete_type_reports

@router.get("/type_report", response_model=list[TypeReportResponse])
def get_type_report(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    return db.query(TypeReport).all()

@router.post("/favorites", response_model=FavoritesResponse)
def create_new_favorites(favorites: FavoritesCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    return create_favorites(db=db, favorites=favorites, id_user=current_user.id)

@router.get("/favorites", response_model=List[FavoritesResponse])
def get_favorites(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    return db.query(Favorites).all()

@router.delete("/favorites/{id}")
def delete_favorites_by_id(id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    db_favorites = db.query(Favorites).filter(Favorites.id == id).first()
    if not db_favorites:
        raise HTTPException(status_code=404, detail="Избранное не найдено")
    if db_favorites.id_user != current_user.id:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    delete_favoritess = delete_favorites(db=db, favorites_id=id)
    if not delete_favoritess:
        raise HTTPException(status_code=400, detail="Не удалось удалить избранное")
    return delete_favoritess

@router.get("/favorites/me", response_model=list[PlaceSearchResponse])
def get_favorites_me(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    user_favorites = db.query(Favorites).filter(Favorites.id_user == current_user.id).all()
    place_ids = [f.id_place for f in user_favorites]
    if not place_ids:
        return []
    places = db.query(Place).filter(Place.id.in_(place_ids)).all()
    result = []
    for p in places:
        all_images = [img.image for img in p.images] if p.images else []
        avg_rating = 0.0
        if p.comments:
            ratings = [c.estimation for c in p.comments if c.estimation is not None]
            if ratings:
                avg_rating = round(sum(ratings) / len(ratings), 1)
        result.append(PlaceSearchResponse(
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
    return result

@router.get("/favorites/check")
def check_favorite(id_place: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    fav = db.query(Favorites).filter(
        Favorites.id_user == current_user.id,
        Favorites.id_place == id_place
    ).first()
    return {"is_favorite": fav is not None, "favorite_id": fav.id if fav else None}

@router.post("/favorites/toggle")
def toggle_favorite(favorites: FavoritesCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    existing = db.query(Favorites).filter(
        Favorites.id_user == current_user.id,
        Favorites.id_place == favorites.id_place
    ).first()
    if existing:
        db.delete(existing)
        db.commit()
        return {"status": "removed", "is_favorite": False}
    new_fav = Favorites(id_user=current_user.id, id_place=favorites.id_place)
    db.add(new_fav)
    db.commit()
    return {"status": "added", "is_favorite": True}


@router.post("/comment_places", response_model=CommentPlacesResponse)
def create_new_comment_places(comment_places: CommentPlacesCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    import datetime
    last_comment = db.query(CommentPlaces).filter(CommentPlaces.id_user == current_user.id).order_by(CommentPlaces.created_at.desc()).first()
    if last_comment and last_comment.created_at:
        now = datetime.datetime.now(datetime.timezone.utc)
        created = last_comment.created_at
        if created.tzinfo is None:
            created = created.replace(tzinfo=datetime.timezone.utc)
        if (now - created).total_seconds() < 60:
            raise HTTPException(status_code=429, detail="Защита от спама: подождите 1 минуту перед отправкой следующего комментария")
    return create_comment_places(db=db, comment_places=comment_places, id_user=current_user.id)

@router.get("/comment_places", response_model=list[CommentWithAuthorResponse])
def get_comment_places(id_place: int, db: Session = Depends(get_db)):
    comments = db.query(CommentPlaces).filter(CommentPlaces.id_place == id_place).all()
    result = []
    for c in comments:
        user = db.query(User).filter(User.id == c.id_user).first()
        author = f"{user.first_name} {user.last_name}" if user else ""
        result.append(CommentWithAuthorResponse(
            id=c.id,
            id_place=c.id_place,
            id_user=c.id_user,
            estimation=c.estimation,
            comment=c.comment,
            author_name=author,
            author_avatar=user.avatar if user else None,
            created_at=c.created_at,
        ))
    return result

@router.delete("/comment_places/{id}")
def delete_comment_places_by_id(id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    db_comment_places = db.query(CommentPlaces).filter(CommentPlaces.id == id).first()
    if not db_comment_places:
        raise HTTPException(status_code=404, detail="Комментарий не найден")
    if db_comment_places.id_user != current_user.id and current_user.id_role != 2:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    delete_comment_placess = delete_comment_places(db=db, comment_places_id=id)
    if not delete_comment_placess:
        raise HTTPException(status_code=400, detail="Не удалось удалить комментарий")
    return delete_comment_placess



@router.put("/comment_places/{id}", response_model=CommentPlacesResponse)
def update_comment_places_by_id(id: int, comment_places: CommentPlacesUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    db_comment_places = db.query(CommentPlaces).filter(CommentPlaces.id == id).first()
    if not db_comment_places:
        raise HTTPException(status_code=404, detail="Комментарий не найден")
    if db_comment_places.id_user != current_user.id:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    return update_comment_places(db=db, comment_places=comment_places, comment_places_id=id)

@router.get("/type_reports", response_model=list[TypeReportResponse])
def get_type_reports_list(db: Session = Depends(get_db)):
    return db.query(TypeReport).all()

@router.get("/images/{image_id}")
def serve_image(image_id: str, db: Session = Depends(get_db)):
    from app.models import ImageStorage
    from fastapi.responses import Response
    import base64
    
    db_img = db.query(ImageStorage).filter(ImageStorage.id == image_id).first()
    if not db_img:
        raise HTTPException(status_code=404, detail="Image not found")
        
    b64_data = db_img.base64_data
    if "," in b64_data:
        b64_data = b64_data.split(",")[1]
        
    missing_padding = len(b64_data) % 4
    if missing_padding:
        b64_data += '=' * (4 - missing_padding)
        
    try:
        img_bytes = base64.b64decode(b64_data)
        return Response(content=img_bytes, media_type="image/jpeg")
    except Exception:
        raise HTTPException(status_code=500, detail="Failed to decode image")


def _route_place_ids(route: Route) -> list[int]:
    return [route_place.id_place for route_place in route.places]


def _has_same_route(db: Session, place_ids: list[int], route_id: int | None = None) -> bool:
    routes = db.query(Route).all()
    for db_route in routes:
        if route_id is not None and db_route.id == route_id:
            continue
        if _route_place_ids(db_route) == place_ids:
            return True
    return False


def _validate_route_data(db: Session, name: str | None, place_ids: list[int] | None, route_id: int | None = None):
    if name is not None:
        stripped_name = name.strip()
        if not stripped_name:
            raise HTTPException(status_code=400, detail="Введите название маршрута")
        if len(stripped_name) > 100:
            raise HTTPException(status_code=400, detail="Название маршрута слишком длинное")
    if place_ids is None:
        return
    if len(place_ids) < 2:
        raise HTTPException(status_code=400, detail="Маршрут должен содержать минимум два места")
    if len(place_ids) != len(set(place_ids)):
        raise HTTPException(status_code=400, detail="В маршруте не должно быть одинаковых мест")
    existing_places_count = db.query(Place).filter(
        Place.id.in_(place_ids),
        Place.id_status == 2
    ).count()
    if existing_places_count != len(place_ids):
        raise HTTPException(status_code=400, detail="Все места маршрута должны быть одобрены")
    if _has_same_route(db, place_ids, route_id):
        raise HTTPException(status_code=400, detail="Такой маршрут уже существует")


@router.post("/route", response_model=RouteResponse)
def create_new_route(route: RouteCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    route.name = route.name.strip()
    if route.description is not None:
        route.description = route.description.strip()
    _validate_route_data(db, route.name, route.place_ids)
    return create_route(db=db, route=route, id_user=current_user.id)


@router.get("/routes", response_model=list[RouteResponse])
def get_routes(db: Session = Depends(get_db)):
    routes = get_all_routes(db=db)
    from app.crud import _build_route_response
    return [_build_route_response(db, r) for r in routes]


@router.get("/routes/me", response_model=list[RouteResponse])
def get_my_routes(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    routes = db.query(Route).filter(Route.id_user == current_user.id).order_by(Route.created_at.desc()).all()
    from app.crud import _build_route_response
    return [_build_route_response(db, r) for r in routes]


@router.get("/route/{route_id}", response_model=RouteResponse)
def get_one_route(route_id: int, db: Session = Depends(get_db)):
    db_route = get_route(db=db, route_id=route_id)
    if not db_route:
        raise HTTPException(status_code=404, detail="Маршрут не найден")
    from app.crud import _build_route_response
    return _build_route_response(db, db_route)


@router.get("/route/{route_id}/path", response_model=RoutePathResponse)
def get_route_path(route_id: int, db: Session = Depends(get_db)):
    db_route = get_route(db=db, route_id=route_id)
    if not db_route:
        raise HTTPException(status_code=404, detail="Маршрут не найден")
    try:
        route_path = build_route_path_response(db_route)
    except urllib.error.URLError:
        raise HTTPException(status_code=502, detail="Не удалось получить маршрут по дорогам")
    except Exception:
        raise HTTPException(status_code=502, detail="Не удалось получить маршрут по дорогам")
    if route_path is None:
        raise HTTPException(status_code=400, detail="Не удалось построить маршрут по дорогам")
    return route_path


@router.put("/route/{route_id}", response_model=RouteResponse)
def update_existing_route(route_id: int, route: RouteUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    db_route = get_route(db=db, route_id=route_id)
    if not db_route:
        raise HTTPException(status_code=404, detail="Маршрут не найден")
    if db_route.id_user != current_user.id and current_user.id_role != 2:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    if route.name is not None:
        route.name = route.name.strip()
    if route.description is not None:
        route.description = route.description.strip()
    _validate_route_data(db, route.name, route.place_ids, route_id)
    return update_route(db=db, route=route, route_id=route_id)


@router.delete("/route/{route_id}")
def delete_existing_route(route_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    db_route = get_route(db=db, route_id=route_id)
    if not db_route:
        raise HTTPException(status_code=404, detail="Маршрут не найден")
    if db_route.id_user != current_user.id and current_user.id_role != 2:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    delete_route(db=db, route_id=route_id)
    return {"message": "Маршрут успешно удалён"}


@router.post("/comment_routes", response_model=CommentRoutesWithAuthorResponse)
def create_new_comment_route(comment: CommentRoutesCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    import datetime
    last = db.query(CommentRoutes).filter(CommentRoutes.id_user == current_user.id).order_by(CommentRoutes.created_at.desc()).first()
    if last and last.created_at:
        now = datetime.datetime.now(datetime.timezone.utc)
        created = last.created_at
        if created.tzinfo is None:
            created = created.replace(tzinfo=datetime.timezone.utc)
        if (now - created).total_seconds() < 60:
            raise HTTPException(status_code=429, detail="Защита от спама: подождите 1 минуту перед отправкой следующего комментария")
    db_comment = create_comment_route(db=db, comment=comment, id_user=current_user.id)
    user = db.query(User).filter(User.id == current_user.id).first()
    return CommentRoutesWithAuthorResponse(
        id=db_comment.id,
        id_route=db_comment.id_route,
        id_user=db_comment.id_user,
        estimation=db_comment.estimation,
        comment=db_comment.comment,
        author_name=f"{user.first_name} {user.last_name}" if user else "",
        author_avatar=user.avatar if user else None,
        created_at=db_comment.created_at,
    )


@router.get("/comment_routes", response_model=list[CommentRoutesWithAuthorResponse])
def get_route_comments(id_route: int, db: Session = Depends(get_db)):
    comments = get_comments_by_route(db=db, id_route=id_route)
    result = []
    for c in comments:
        user = db.query(User).filter(User.id == c.id_user).first()
        result.append(CommentRoutesWithAuthorResponse(
            id=c.id,
            id_route=c.id_route,
            id_user=c.id_user,
            estimation=c.estimation,
            comment=c.comment,
            author_name=f"{user.first_name} {user.last_name}" if user else "",
            author_avatar=user.avatar if user else None,
            created_at=c.created_at,
        ))
    return result


@router.delete("/comment_routes/{comment_id}")
def delete_route_comment(comment_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    db_comment = get_comment_route(db=db, comment_id=comment_id)
    if not db_comment:
        raise HTTPException(status_code=404, detail="Комментарий не найден")
    if db_comment.id_user != current_user.id and current_user.id_role != 2:
        raise HTTPException(status_code=403, detail="Недостаточно прав")
    delete_comment_route(db=db, comment_id=comment_id)
    return {"message": "Комментарий удалён"}


@router.post("/favorites/toggle_route")
def toggle_favorite_route(id_route: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    from app.models import Favorites
    existing = db.query(Favorites).filter(
        Favorites.id_user == current_user.id,
        Favorites.id_route == id_route
    ).first()
    if existing:
        db.delete(existing)
        db.commit()
        return {"is_favorite": False}
    new_fav = Favorites(id_user=current_user.id, id_route=id_route)
    db.add(new_fav)
    db.commit()
    return {"is_favorite": True}


@router.get("/favorites/check_route")
def check_favorite_route(id_route: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    from app.models import Favorites
    fav = db.query(Favorites).filter(
        Favorites.id_user == current_user.id,
        Favorites.id_route == id_route
    ).first()
    return {"is_favorite": fav is not None}


@router.get("/favorites/my_routes", response_model=list[RouteResponse])
def get_my_favorite_routes(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user:
        raise HTTPException(status_code=401, detail="Необходимо авторизоваться")
    from app.models import Favorites, Route
    from app.crud import _build_route_response
    favs = db.query(Favorites).filter(
        Favorites.id_user == current_user.id,
        Favorites.id_route != None
    ).all()
    result = []
    for fav in favs:
        route = db.query(Route).filter(Route.id == fav.id_route).first()
        if route:
            result.append(_build_route_response(db, route))
    return result
