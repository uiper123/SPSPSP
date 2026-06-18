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

coordinates_updates = {
    "Кузнецкая крепость": "53.774212, 87.182495",
    "Монумент «Память шахтерам Кузбасса»": "55.373972, 86.078441",
    "Музей-заповедник «Красная Горка»": "55.375501, 86.071729",
    "Кемеровский областной краеведческий музей": "55.354847, 86.081989",
    "Парк Чудес": "55.364744, 86.074611",
    "Новокузнецкий драматический театр": "53.758369, 87.126462",
    "Парк культуры и отдыха им. Ю. А. Гагарина": "53.753889, 87.121111",
    "Новокузнецкий художественный музей": "53.757753, 87.126078"
}

def update_places():
    db = SessionLocal()
    try:
        # Step 1: Update coordinates
        print("Updating coordinates...")
        for name, coords in coordinates_updates.items():
            place = db.query(Place).filter(Place.name == name).first()
            if place:
                old_coords = place.coordinates
                place.coordinates = coords
                db.commit()
                print(f"Updated '{name}': {old_coords} -> {coords}")
            else:
                print(f"Place '{name}' not found!")

        # Step 2: Re-download and update image for Kuznetsk Fortress (id=1 or by name)
        fortress = db.query(Place).filter(Place.name == "Кузнецкая крепость").first()
        if fortress:
            print("-" * 50)
            url = "https://upload.wikimedia.org/wikipedia/commons/c/c4/Kuznetsk_fortress_001.jpg"
            print(f"Downloading image for Kuznetsk Fortress from: {url}")
            try:
                # Use standard urllib request with headers
                req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'})
                with urllib.request.urlopen(req, timeout=20) as response:
                    img_data = response.read()
                
                encoded = base64.b64encode(img_data).decode('utf-8')
                base64_img = f"data:image/jpeg;base64,{encoded}"
                
                # Delete old image mappings and storage for this place
                old_imgs = db.query(ImagePlaces).filter(ImagePlaces.id_place == fortress.id).all()
                for old in old_imgs:
                    image_id = old.image.split('/')[-1]
                    db.query(ImageStorage).filter(ImageStorage.id == image_id).delete()
                    db.delete(old)
                db.commit()

                # Save new image to ImageStorage
                file_id = str(uuid.uuid4())
                db_storage = ImageStorage(
                    id=file_id,
                    base64_data=base64_img
                )
                db.add(db_storage)
                db.commit()

                # Create mapping in ImagePlaces
                db_image = ImagePlaces(
                    id_place=fortress.id,
                    id_user=1,
                    image=f"/api/images/{file_id}"
                )
                db.add(db_image)
                db.commit()
                print(f"Successfully updated image for Kuznetsk Fortress! New Image ID: {file_id}")
            except Exception as img_err:
                print(f"Error downloading image: {img_err}")
        else:
            print("Kuznetsk Fortress place not found for image update!")

    except Exception as e:
        db.rollback()
        print(f"General error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    update_places()
