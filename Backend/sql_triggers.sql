DELIMITER $$

DROP TRIGGER IF EXISTS before_comment_places_insert$$
CREATE TRIGGER before_comment_places_insert
BEFORE INSERT ON comment_places
FOR EACH ROW
BEGIN
    IF NEW.estimation IS NOT NULL AND (NEW.estimation < 1 OR NEW.estimation > 5) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ошибка валидации: Оценка места должна быть от 1 до 5.';
    END IF;
END$$

DROP TRIGGER IF EXISTS before_comment_places_update$$
CREATE TRIGGER before_comment_places_update
BEFORE UPDATE ON comment_places
FOR EACH ROW
BEGIN
    IF NEW.estimation IS NOT NULL AND (NEW.estimation < 1 OR NEW.estimation > 5) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ошибка валидации: Оценка места должна быть от 1 до 5.';
    END IF;
END$$

DROP TRIGGER IF EXISTS before_comment_routes_insert$$
CREATE TRIGGER before_comment_routes_insert
BEFORE INSERT ON comment_routes
FOR EACH ROW
BEGIN
    IF NEW.estimation IS NOT NULL AND (NEW.estimation < 1 OR NEW.estimation > 5) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ошибка валидации: Оценка маршрута должна быть от 1 до 5.';
    END IF;
END$$

DROP TRIGGER IF EXISTS before_comment_routes_update$$
CREATE TRIGGER before_comment_routes_update
BEFORE UPDATE ON comment_routes
FOR EACH ROW
BEGIN
    IF NEW.estimation IS NOT NULL AND (NEW.estimation < 1 OR NEW.estimation > 5) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ошибка валидации: Оценка маршрута должна быть от 1 до 5.';
    END IF;
END$$

DROP TRIGGER IF EXISTS before_users_delete$$
CREATE TRIGGER before_users_delete
BEFORE DELETE ON users
FOR EACH ROW
BEGIN
    DECLARE active_places_count INT DEFAULT 0;
    DECLARE active_routes_count INT DEFAULT 0;

    SELECT COUNT(*) INTO active_places_count
    FROM places
    WHERE id_user = OLD.id;

    SELECT COUNT(*) INTO active_routes_count
    FROM routes
    WHERE id_user = OLD.id;

    IF active_places_count > 0 OR active_routes_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Удаление невозможно: пользователь имеет активные места или маршруты.';
    END IF;
END$$

DELIMITER ;
