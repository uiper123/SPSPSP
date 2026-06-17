import sys
import traceback

try:
    from fastapi import FastAPI
    from app.core.database import engine, Base
    from app.models import User, Place, ImagePlaces, CommentPlaces, Favorites, ReportPlaces, Role, ImageStorage
    from app.routes import routes
    from fastapi.staticfiles import StaticFiles
    from fastapi.middleware.cors import CORSMiddleware

    try:
        Base.metadata.create_all(bind=engine)
        print("Database tables created successfully!")
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