import sys
import os
import uuid
import base64
import urllib.request
import urllib.parse
import json

# Add parent dir to sys.path so we can import app modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), 'app')))

from sqlalchemy.orm import sessionmaker
from app.core.database import engine, SessionLocal
from app.models import Place, ImagePlaces, ImageStorage, User, Category, Status

# Fallback 1x1 transparent GIF base64 string (valid image)
FALLBACK_IMAGE_B64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="

def get_wikimedia_image_url(query):
    print(f"Searching Wikimedia Commons for: {query}")
    try:
        search_url = "https://commons.wikimedia.org/w/api.php?" + urllib.parse.urlencode({
            "action": "query",
            "list": "search",
            "srsearch": query,
            "srnamespace": "6",
            "format": "json"
        })
        req = urllib.request.Request(search_url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'})
        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode('utf-8'))
        
        results = data.get("query", {}).get("search", [])
        if not results:
            print(f"No Wikimedia Commons results for query: {query}")
            return None
        
        title = results[0]["title"]
        print(f"Found file title: {title}")
        
        info_url = "https://commons.wikimedia.org/w/api.php?" + urllib.parse.urlencode({
            "action": "query",
            "titles": title,
            "prop": "imageinfo",
            "iiprop": "url",
            "format": "json"
        })
        req = urllib.request.Request(info_url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode('utf-8'))
            
        pages = data.get("query", {}).get("pages", {})
        for page_id, page_info in pages.items():
            img_info = page_info.get("imageinfo", [])
            if img_info:
                url = img_info[0]["url"]
                print(f"Direct image URL: {url}")
                return url
    except Exception as e:
        print(f"Error fetching image URL for {query}: {e}")
    return None

def download_and_encode_image(url):
    if not url:
        return FALLBACK_IMAGE_B64
    try:
        print(f"Downloading image from: {url}")
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'})
        with urllib.request.urlopen(req, timeout=15) as response:
            img_data = response.read()
        
        encoded = base64.b64encode(img_data).decode('utf-8')
        # Guess mimetype based on URL extension
        ext = url.split('.')[-1].lower()
        mime = "image/jpeg"
        if ext in ["png", "gif", "webp"]:
            mime = f"image/{ext}"
        
        return f"data:{mime};base64,{encoded}"
    except Exception as e:
        print(f"Failed to download/encode image from {url}: {e}")
        return FALLBACK_IMAGE_B64

places_to_seed = [
    {
        "name": "Кузнецкая крепость",
        "description": "Уникальный памятник военно-инженерного искусства начала XIX века, построенный по указу Павла I. Единственная каменная крепость в Сибири, откуда открывается живописный вид на Новокузнецк.",
        "address": "Новокузнецк, проезд Крепостной, 1",
        "coordinates": "53.774431, 87.168752",
        "id_category": 8,  # Достопримечательности
        "search_query": "Кузнецкая крепость"
    },
    {
        "name": "Монумент «Память шахтерам Кузбасса»",
        "description": "Величественный памятник работы Эрнста Неизвестного, посвященный тяжелому труду горняков. Скульптура шахтера с горящим сердцем установлена на высоком холму на территории музея «Красная Горка».",
        "address": "Кемерово, Красная Горка, ул. Сосновый Бор, 1",
        "coordinates": "55.370845, 86.064561",
        "id_category": 8,  # Достопримечательности
        "search_query": "Memory of Kuzbass Miners"
    },
    {
        "name": "Музей-заповедник «Красная Горка»",
        "description": "Музейный комплекс под открытым небом на месте открытия Кузнецкого угольного бассейна. Включает памятники индустриального наследия, дом управляющего АИК «Кузбасс» и экспозиции о шахтерском быте.",
        "address": "Кемерово, ул. Халева, 1",
        "coordinates": "55.371281, 86.063756",
        "id_category": 2,  # Музеи
        "search_query": "Красная Горка Кемерово"
    },
    {
        "name": "Кемеровский областной краеведческий музей",
        "description": "Один из старейших музеев Сибири. Славится уникальной палеонтологической коллекцией, включающей скелеты динозавров (пситтакозавров сибирских), найденных в селе Шестаково Кемеровской области.",
        "address": "Кемерово, Советский пр., 51",
        "coordinates": "55.353381, 86.082729",
        "id_category": 2,  # Музеи
        "search_query": "Кемеровский краеведческий музей"
    },
    {
        "name": "Парк Чудес",
        "description": "Центральный парк культуры и отдыха в Кемерове. Здесь расположены современные аттракционы, колесо обозрения, тенистые аллеи, уютные кафе и живописная набережная реки Томь.",
        "address": "Кемерово, ул. Кирова, 4",
        "coordinates": "55.357112, 86.083424",
        "id_category": 1,  # Парки
        "search_query": "Парк чудес Кемерово"
    },
    {
        "name": "Новокузнецкий драматический театр",
        "description": "Один из крупнейших и старейших центров театральной культуры в Сибири, основанный в 1932 году. Расположен в монументальном классическом здании в центре Новокузнецка.",
        "address": "Новокузнецк, Металлургов пр., 28",
        "coordinates": "53.758064, 87.126389",
        "id_category": 8,  # Достопримечательности
        "search_query": "Новокузнецкий драматический театр"
    },
    {
        "name": "Парк культуры и отдыха им. Ю. А. Гагарина",
        "description": "Просторный парк в центре Новокузнецка. Популярен среди горожан для прогулок и активного отдыха. На территории расположены аттракционы, спортивные площадки и Новокузнецкий планетарий.",
        "address": "Новокузнецк, ул. Спартака, 5",
        "coordinates": "53.754712, 87.136294",
        "id_category": 1,  # Парки
        "search_query": "Парк Гагарина Новокузнецк"
    },
    {
        "name": "Новокузнецкий художественный музей",
        "description": "Первый художественный музей в Кузбассе. Обладает богатой коллекцией русского искусства конца XIX-XX веков, сибирского авангарда и старинных православных икон.",
        "address": "Новокузнецк, ул. Кирова, 62",
        "coordinates": "53.760124, 87.121458",
        "id_category": 2,  # Музеи
        "search_query": "Новокузнецкий художественный музей"
    }
]

def seed():
    db = SessionLocal()
    try:
        # Check if user with ID 1 exists
        user = db.query(User).filter(User.id == 1).first()
        if not user:
            print("User with ID 1 not found! Seeding cancelled.")
            return

        # Seed categories if they don't exist
        existing_cats = db.query(Category).count()
        if existing_cats == 0:
            print("Categories table is empty, seeding categories...")
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

        # Seed statuses if they don't exist
        existing_statuses = db.query(Status).count()
        if existing_statuses == 0:
            print("Statuses table is empty, seeding statuses...")
            statuses = [
                Status(id=1, name="На модерации"),
                Status(id=2, name="Одобрено"),
                Status(id=3, name="Отклонено")
            ]
            db.add_all(statuses)
            db.commit()

        for item in places_to_seed:
            print("-" * 50)
            # Check if place already exists
            existing_place = db.query(Place).filter(Place.name == item["name"]).first()
            if existing_place:
                print(f"Place '{item['name']}' already exists. Skipping.")
                continue

            # Fetch image URL
            img_url = get_wikimedia_image_url(item["search_query"])
            if not img_url and item["search_query"] == "Memory of Kuzbass Miners":
                # Retry with another query
                img_url = get_wikimedia_image_url("Monument to Miners in Kemerovo")
            
            # Download and base64-encode image
            base64_img = download_and_encode_image(img_url)

            # Insert Place
            place = Place(
                name=item["name"],
                description=item["description"],
                address=item["address"],
                coordinates=item["coordinates"],
                id_category=item["id_category"],
                id_user=1,
                id_status=2  # Approved status
            )
            db.add(place)
            db.commit()
            db.refresh(place)
            print(f"Inserted Place: {place.name} (ID: {place.id})")

            # Store Image in ImageStorage
            file_id = str(uuid.uuid4())
            db_storage = ImageStorage(
                id=file_id,
                base64_data=base64_img
            )
            db.add(db_storage)
            db.commit()

            # Map Image to Place in ImagePlaces
            db_image = ImagePlaces(
                id_place=place.id,
                id_user=1,
                image=f"/api/images/{file_id}"
            )
            db.add(db_image)
            db.commit()
            print(f"Associated image: /api/images/{file_id} with Place ID {place.id}")

        print("Seeding completed successfully!")
    except Exception as e:
        db.rollback()
        print(f"Error seeding database: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    seed()
