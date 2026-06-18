"""
Скрипт миграции изображений из БД (таблица image_storage) в файлы на диске.

Что делает:
1. Читает все записи из image_storage (id → base64_data)
2. Декодирует base64 → сохраняет как файл в app/static/images/{id}.jpg
3. Обновляет пути в image_places: /api/images/{id} → /static/images/{id}.jpg
4. Обновляет пути в users.avatar: /api/images/{id} → /static/images/{id}.jpg
5. После успешной миграции удаляет записи из image_storage

Безопасно запускать повторно — пропускает уже обработанные файлы.

Использование:
  cd Backend
  python migrate_images.py
"""

import os
import sys
import base64

# Ensure imports work
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from dotenv import load_dotenv
load_dotenv()

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import urllib.parse

DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")

encoded_password = urllib.parse.quote_plus(DB_PASSWORD) if DB_PASSWORD else ""
DATABASE_URL = f"mysql+pymysql://{DB_USER}:{encoded_password}@{DB_HOST}:{DB_PORT}/{DB_NAME}?charset=utf8mb4"

engine = create_engine(DATABASE_URL)
Session = sessionmaker(bind=engine)

IMAGES_DIR = os.path.join("app", "static", "images")
os.makedirs(IMAGES_DIR, exist_ok=True)


def migrate():
    db = Session()
    try:
        # 1. Получаем все записи из image_storage
        rows = db.execute(text("SELECT id, base64_data FROM image_storage")).fetchall()
        total = len(rows)
        print(f"Найдено {total} изображений в image_storage")

        migrated = 0
        skipped = 0
        errors = 0

        for i, row in enumerate(rows):
            img_id = row[0]
            b64_data = row[1]
            
            file_path = os.path.join(IMAGES_DIR, f"{img_id}.jpg")
            static_path = f"/static/images/{img_id}.jpg"
            api_path = f"/api/images/{img_id}"

            # Пропускаем если файл уже существует
            if os.path.exists(file_path):
                skipped += 1
                # Всё равно обновляем пути в БД
                db.execute(
                    text("UPDATE image_places SET image = :new_path WHERE image = :old_path"),
                    {"new_path": static_path, "old_path": api_path}
                )
                db.execute(
                    text("UPDATE users SET avatar = :new_path WHERE avatar = :old_path"),
                    {"new_path": static_path, "old_path": api_path}
                )
                continue

            # Декодируем base64
            try:
                data = b64_data
                if "," in data:
                    data = data.split(",", 1)[1]
                
                missing_padding = len(data) % 4
                if missing_padding:
                    data += "=" * (4 - missing_padding)
                
                img_bytes = base64.b64decode(data)
                
                # Сохраняем файл
                with open(file_path, "wb") as f:
                    f.write(img_bytes)
                
                # Обновляем пути в БД
                db.execute(
                    text("UPDATE image_places SET image = :new_path WHERE image = :old_path"),
                    {"new_path": static_path, "old_path": api_path}
                )
                db.execute(
                    text("UPDATE users SET avatar = :new_path WHERE avatar = :old_path"),
                    {"new_path": static_path, "old_path": api_path}
                )
                
                migrated += 1
                
                if (i + 1) % 10 == 0:
                    db.commit()
                    print(f"  [{i+1}/{total}] Мигрировано: {migrated}, пропущено: {skipped}, ошибок: {errors}")
                    
            except Exception as e:
                errors += 1
                print(f"  ОШИБКА при обработке {img_id}: {e}")
        
        db.commit()
        
        print(f"\n{'='*50}")
        print(f"Миграция завершена!")
        print(f"  Мигрировано:  {migrated}")
        print(f"  Пропущено:    {skipped}")
        print(f"  Ошибок:       {errors}")
        print(f"  Всего:        {total}")
        
        if errors == 0 and migrated + skipped == total:
            print(f"\nВсе изображения успешно перенесены на диск.")
            print(f"Таблицу image_storage можно очистить командой:")
            print(f"  TRUNCATE TABLE image_storage;")
            print(f"\nНО СНАЧАЛА перезапусти сервер с новым кодом!")
        
    except Exception as e:
        db.rollback()
        print(f"Критическая ошибка: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    migrate()
