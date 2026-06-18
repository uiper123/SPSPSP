import sys
import os
import uuid
import base64
import urllib.request

# Add parent dir to sys.path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), 'app')))

from sqlalchemy.orm import sessionmaker
from app.core.database import SessionLocal
from app.models import Place, ImagePlaces, ImageStorage

def update_image():
    db = SessionLocal()
    try:
        place = db.query(Place).filter(Place.id == 7).first()
        if not place:
            print("Place with ID 7 not found!")
            return
            
        url = "https://upload.wikimedia.org/wikipedia/commons/d/d6/%D0%91%D1%8E%D1%81%D1%82_%D0%BB%D0%B5%D1%82%D1%87%D0%B8%D0%BA%D0%B0-%D0%BA%D0%BE%D1%81%D0%BC%D0%BE%D0%BD%D0%B0%D0%B2%D1%82%D0%B0_%D0%93%D0%B0%D0%B3%D0%B0%D1%80%D0%B8%D0%BD%D0%B0.jpg"
        print(f"Downloading Gagarin park image from: {url}")
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=15) as response:
            img_data = response.read()
            
        encoded = base64.b64encode(img_data).decode('utf-8')
        base64_img = f"data:image/jpeg;base64,{encoded}"
        
        # Delete old image association and storage if any
        old_imgs = db.query(ImagePlaces).filter(ImagePlaces.id_place == 7).all()
        for old in old_imgs:
            # Check if it was a fallback transparent image
            db.query(ImageStorage).filter(ImageStorage.id == old.image.split('/')[-1]).delete()
            db.delete(old)
        db.commit()
        
        # Store new image in ImageStorage
        file_id = str(uuid.uuid4())
        db_storage = ImageStorage(
            id=file_id,
            base64_data=base64_img
        )
        db.add(db_storage)
        db.commit()
        
        # Map Image to Place in ImagePlaces
        db_image = ImagePlaces(
            id_place=7,
            id_user=1,
            image=f"/api/images/{file_id}"
        )
        db.add(db_image)
        db.commit()
        print(f"Updated Gagarin park image successfully! ID: {file_id}")
    except Exception as e:
        db.rollback()
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    update_image()
