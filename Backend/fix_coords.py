import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), 'app')))

from app.core.database import SessionLocal
from app.models import Place

# Verified correct coordinates from Nominatim + aroundus.com + maptons.com + 2gis
corrections = {
    # Found by Nominatim: lat=53.7572546, lon=87.1208754
    "Новокузнецкий драматический театр": "53.757255, 87.120875",
    # Found by Nominatim: lat=53.7510855, lon=87.1250764
    "Парк культуры и отдыха им. Ю. А. Гагарина": "53.751086, 87.125076",
    # Found by aroundus.com - exact location of monument
    "Монумент «Память шахтерам Кузбасса»": "55.374200, 86.078300",
    # Found by Nominatim: 51, Советский проспект, Кемерово
    "Кемеровский областной краеведческий музей": "55.356122, 86.080145",
    # Found by maptons.com - ул. Кирова 62
    "Новокузнецкий художественный музей": "53.757183, 87.147512",
}

db = SessionLocal()
try:
    for name, coords in corrections.items():
        place = db.query(Place).filter(Place.name == name).first()
        if place:
            old = place.coordinates
            place.coordinates = coords
            db.commit()
            print(f"OK: '{name}'")
            print(f"    {old} -> {coords}")
        else:
            print(f"NOT FOUND: '{name}'")
    print("\nDone!")
except Exception as e:
    db.rollback()
    print(f"Error: {e}")
finally:
    db.close()
