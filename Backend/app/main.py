import sys
import traceback

try:
    from fastapi import FastAPI
    from app.core.database import engine, Base
    from app.models import User, Place, ImagePlaces, CommentPlaces, Favorites, ReportPlaces, Role, ImageStorage
    from app.routes import routes
    from fastapi.staticfiles import StaticFiles
    from fastapi.middleware.cors import CORSMiddleware

        Base.metadata.create_all(bind=engine)
        print("Database tables created successfully!")
        
        # Seed database
        from sqlalchemy.orm import sessionmaker
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
        db = SessionLocal()
        try:
            # Seed roles
            if db.query(Role).count() == 0:
                roles = [
                    Role(id=1, name="Пользователь"),
                    Role(id=2, name="Администратор"),
                    Role(id=3, name="Модератор")
                ]
                db.add_all(roles)
                db.commit()
                print("Roles seeded successfully!")

            # Seed statuses
            from app.models import Status
            if db.query(Status).count() == 0:
                statuses = [
                    Status(id=1, name="На модерации"),
                    Status(id=2, name="Одобрено"),
                    Status(id=3, name="Отклонено")
                ]
                db.add_all(statuses)
                db.commit()
                print("Statuses seeded successfully!")

            # Seed categories
            from app.models import Category
            if db.query(Category).count() == 0:
                categories = [
                    Category(id=1, name="Парки"),
                    Category(id=2, name="Музеи"),
                    Category(id=3, name="Кафе"),
                    Category(id=4, name="Развлечения"),
                    Category(id=5, name="Отели"),
                    Category(id=6, name="Пляжи"),
                    Category(id=7, name="Спорт"),
                    Category(id=8, name="Достопримечательности")
                ]
                db.add_all(categories)
                db.commit()
                print("Categories seeded successfully!")

            # Seed type_reports
            from app.models import TypeReport
            if db.query(TypeReport).count() == 0:
                type_reports = [
                    TypeReport(id=1, name="Спам"),
                    TypeReport(id=2, name="Несуществующее место"),
                    TypeReport(id=3, name="Некорректная информация"),
                    TypeReport(id=4, name="Нецензурный контент"),
                    TypeReport(id=5, name="Другое")
                ]
                db.add_all(type_reports)
                db.commit()
                print("TypeReports seeded successfully!")

            # Seed status_reports
            from app.models import StatusReport
            if db.query(StatusReport).count() == 0:
                status_reports = [
                    StatusReport(id=1, name="Новая"),
                    StatusReport(id=2, name="В процессе"),
                    StatusReport(id=3, name="Решена"),
                    StatusReport(id=4, name="Отклонена")
                ]
                db.add_all(status_reports)
                db.commit()
                print("StatusReports seeded successfully!")
        except Exception as e_seed:
            db.rollback()
            print("FAILED TO SEED DATABASE:")
            traceback.print_exc()
        finally:
            db.close()

    except Exception as e:
        print("FAILED TO CONNECT TO DATABASE OR CREATE TABLES:")
        traceback.print_exc()

    app = FastAPI(
        title="SPT API",
        description="API for SPT",
        version="1.0.0"
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origin_regex="https?://.*",
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(routes.router, prefix="/api")

    app.mount("/static", StaticFiles(directory="app/static"), name="static")

except Exception as e:
    print("FATAL ERROR DURING APP STARTUP:", flush=True)
    traceback.print_exc(file=sys.stdout)
    sys.stdout.flush()
    raise

if __name__ == "__main__":
    import uvicorn
    import os
    host = os.getenv("API_HOST", "0.0.0.0")
    port = int(os.getenv("API_PORT", "8000"))
    uvicorn.run(app, host=host, port=port)