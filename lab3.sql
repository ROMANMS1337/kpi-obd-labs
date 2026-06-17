

-- ------------------------------------------------------------
-- S-01. Усі студенти (базовий перегляд)
-- Мета: переконатися, що таблиця student заповнена коректно.
-- ------------------------------------------------------------
SELECT *
FROM student
ORDER BY student_id;

-- ------------------------------------------------------------
-- S-02. Тільки потрібні стовпці: ПІБ та email студентів
-- Мета: отримати контактну інформацію без зайвих полів.
-- ------------------------------------------------------------
SELECT
    student_id,
    first_name || ' ' || last_name AS full_name,
    email
FROM student
ORDER BY last_name;

-- ------------------------------------------------------------
-- S-03. Студенти конкретної кафедри (фільтрація WHERE)
-- Мета: знайти всіх студентів кафедри ПЗАС (department_id = 1).
-- ------------------------------------------------------------
SELECT
    s.student_id,
    s.first_name || ' ' || s.last_name AS full_name,
    d.name AS department
FROM student s
JOIN department d ON s.department_id = d.department_id
WHERE d.code = 'ПЗАС'
ORDER BY s.last_name;

-- ------------------------------------------------------------
-- S-04. Курси з кількістю кредитів більше 3
-- Мета: знайти «важкі» дисципліни.
-- ------------------------------------------------------------
SELECT
    course_id,
    code,
    title,
    credits,
    semester
FROM course
WHERE credits > 3
ORDER BY credits DESC, semester;

-- ------------------------------------------------------------
-- S-05. Активні реєстрації конкретного студента
-- Мета: перевірити поточне навантаження студента (id = 1).
-- ------------------------------------------------------------
SELECT
    e.enrollment_id,
    c.code        AS course_code,
    c.title       AS course_title,
    e.enrolled_at,
    e.status
FROM enrollment e
JOIN course c ON e.course_id = c.course_id
WHERE e.student_id = 1
  AND e.status = 'active'
ORDER BY e.enrolled_at;

-- ------------------------------------------------------------
-- S-06. JOIN: студент + курс + оцінка (усі завершені реєстрації)
-- Мета: переглянути відомість із оцінками.
-- ------------------------------------------------------------
SELECT
    s.last_name || ' ' || s.first_name AS student,
    c.code   AS course_code,
    c.title  AS course_title,
    e.grade,
    CASE
        WHEN e.grade >= 90 THEN 'A'
        WHEN e.grade >= 75 THEN 'B'
        WHEN e.grade >= 60 THEN 'C'
        WHEN e.grade >= 50 THEN 'D'
        ELSE 'F'
    END AS letter_grade
FROM enrollment e
JOIN student s ON e.student_id = s.student_id
JOIN course  c ON e.course_id  = c.course_id
WHERE e.status = 'completed'
ORDER BY s.last_name, c.code;

-- ------------------------------------------------------------
-- S-07. Розклад на понеділок із назвами курсів та аудиторій
-- Мета: сформувати розклад для конкретного дня.
-- ------------------------------------------------------------
SELECT
    sc.start_time,
    sc.end_time,
    c.title       AS course,
    r.number      AS room,
    r.type        AS room_type,
    t.last_name || ' ' || t.first_name AS teacher
FROM schedule sc
JOIN course  c ON sc.course_id = c.course_id
JOIN room    r ON sc.room_id   = r.room_id
JOIN teacher t ON c.teacher_id = t.teacher_id
WHERE sc.day_of_week = 'Mon'
ORDER BY sc.start_time;

-- ------------------------------------------------------------
-- S-08. Кількість студентів на кожному курсі
-- Мета: перевірити наповненість курсів (агрегація).
-- ------------------------------------------------------------
SELECT
    c.code,
    c.title,
    COUNT(e.enrollment_id) AS total_enrollments,
    COUNT(CASE WHEN e.status = 'active'    THEN 1 END) AS active,
    COUNT(CASE WHEN e.status = 'completed' THEN 1 END) AS completed,
    COUNT(CASE WHEN e.status = 'dropped'   THEN 1 END) AS dropped
FROM course c
LEFT JOIN enrollment e ON c.course_id = e.course_id
GROUP BY c.course_id, c.code, c.title
ORDER BY total_enrollments DESC;




-- ------------------------------------------------------------
-- I-01. Додати новий факультет
-- Мета: розширити структуру університету.
-- ------------------------------------------------------------
INSERT INTO faculty (name, code)
VALUES ('Факультет менеджменту та маркетингу', 'ФМM');

-- Перевірка:
SELECT * FROM faculty ORDER BY faculty_id;

-- ------------------------------------------------------------
-- I-02. Додати нову кафедру на ФІОТ
-- Мета: додати кафедру, що підпорядковується факультету 1.
-- ------------------------------------------------------------
INSERT INTO department (name, code, faculty_id)
VALUES ('Кафедра інформаційної безпеки', 'ІБ', 1);

-- Перевірка:
SELECT d.department_id, d.name, d.code, f.name AS faculty
FROM department d
JOIN faculty f ON d.faculty_id = f.faculty_id
ORDER BY d.department_id;

-- ------------------------------------------------------------
-- I-03. Додати нового викладача
-- Мета: зареєструвати нового співробітника кафедри ІБ (id=6).
-- ------------------------------------------------------------
INSERT INTO teacher (first_name, last_name, email, position, department_id)
VALUES ('Андрій', 'Яковенко', 'yakovenko@kpi.ua', 'Доцент', 6);

-- Перевірка:
SELECT teacher_id, first_name || ' ' || last_name AS full_name, position, department_id
FROM teacher
ORDER BY teacher_id;

-- ------------------------------------------------------------
-- I-04. Зарахувати нового студента
-- Мета: зареєструвати студента, що вступив на кафедру ІБ.
-- ------------------------------------------------------------
INSERT INTO student (first_name, last_name, birth_date, email, phone, department_id)
VALUES ('Олексій', 'Дяченко', '2005-08-12', 'dyachenko.o@student.kpi.ua', '+380661234567', 6);

-- Перевірка:
SELECT student_id, first_name || ' ' || last_name AS full_name, birth_date, email
FROM student
ORDER BY student_id;

-- ------------------------------------------------------------
-- I-05. Додати новий курс
-- Мета: ввести дисципліну «Кібербезпека» на кафедрі ІБ.
-- ------------------------------------------------------------
INSERT INTO course (title, code, credits, semester, department_id, teacher_id)
VALUES ('Основи кібербезпеки', 'CS-301', 4, 5, 6, 6);

-- Перевірка:
SELECT course_id, code, title, credits, semester
FROM course
ORDER BY course_id;

-- ------------------------------------------------------------
-- I-06. Зареєструвати студента на курс (ENROLLMENT)
-- Мета: записати нового студента (id=7) на курс (id=7 «Кібербезпека»).
-- Тест тригера: якщо у студента вже 5 активних реєстрацій — буде помилка.
-- ------------------------------------------------------------
INSERT INTO enrollment (student_id, course_id, enrolled_at, status)
VALUES (7, 7, CURRENT_DATE, 'active');

-- Перевірка:
SELECT e.enrollment_id, s.last_name, c.title, e.status, e.enrolled_at
FROM enrollment e
JOIN student s ON e.student_id = s.student_id
JOIN course  c ON e.course_id  = c.course_id
WHERE e.student_id = 7;

-- ------------------------------------------------------------
-- I-07. Додати нову аудиторію та заняття в розклад
-- ------------------------------------------------------------
INSERT INTO room (number, capacity, type)
VALUES ('45-2', 40, 'seminar');

INSERT INTO schedule (course_id, room_id, day_of_week, start_time, end_time)
VALUES (7, 6, 'Thu', '08:30', '10:05');

-- Перевірка:
SELECT sc.schedule_id, c.title, r.number, sc.day_of_week, sc.start_time, sc.end_time
FROM schedule sc
JOIN course c ON sc.course_id = c.course_id
JOIN room   r ON sc.room_id   = r.room_id
ORDER BY sc.schedule_id;




-- ------------------------------------------------------------
-- U-01. Оновити email студента
-- Мета: студент змінив адресу електронної пошти.
-- Безпека: WHERE за student_id — змінюється рівно 1 рядок.
-- ------------------------------------------------------------
-- Перевірка ПЕРЕД:
SELECT student_id, email FROM student WHERE student_id = 3;

UPDATE student
SET email = 'kharchenko.dmitro@student.kpi.ua'
WHERE student_id = 3;

-- Перевірка ПІСЛЯ:
SELECT student_id, email FROM student WHERE student_id = 3;

-- ------------------------------------------------------------
-- U-02. Виставити оцінку та змінити статус реєстрації
-- Мета: закрити курс «Дискретна математика» для студента 1.
-- Логіка: спочатку статус → completed, потім виставляємо grade
--   (обмеження chk_grade_only_if_completed вимагає цього порядку
--    або оновлення в одному операторі).
-- ------------------------------------------------------------
-- Перевірка ПЕРЕД:
SELECT enrollment_id, student_id, course_id, status, grade
FROM enrollment
WHERE student_id = 1 AND course_id = 4;

UPDATE enrollment
SET status = 'completed',
    grade  = 88.00
WHERE student_id = 1
  AND course_id  = 4;

-- Перевірка ПІСЛЯ:
SELECT enrollment_id, status, grade
FROM enrollment
WHERE student_id = 1 AND course_id = 4;

-- ------------------------------------------------------------
-- U-03. Масове оновлення: перевести кількох студентів
--       з однієї кафедри на іншу (кафедра ОТ → кафедра ІБ)
-- Мета: імітувати переведення групи студентів.
-- Безпека: спочатку перевіряємо SELECT, потім UPDATE.
-- ------------------------------------------------------------
-- Перевірка ПЕРЕД (які студенти на кафедрі ОТ = id 2):
SELECT student_id, first_name || ' ' || last_name AS name, department_id
FROM student
WHERE department_id = 2;

UPDATE student
SET department_id = 6
WHERE department_id = 2;

-- Перевірка ПІСЛЯ:
SELECT student_id, first_name || ' ' || last_name AS name, department_id
FROM student
WHERE department_id IN (2, 6)
ORDER BY department_id, student_id;

-- ------------------------------------------------------------
-- U-04. Змінити місткість аудиторії (ремонт — зменшили місця)
-- ------------------------------------------------------------
-- Перевірка ПЕРЕД:
SELECT room_id, number, capacity FROM room WHERE number = '18-1';

UPDATE room
SET capacity = 100
WHERE number = '18-1';

-- Перевірка ПІСЛЯ:
SELECT room_id, number, capacity FROM room WHERE number = '18-1';

-- ------------------------------------------------------------
-- U-05. Змінити кількість кредитів курсу та семестр
-- Мета: навчальний план оновлено — курс DB-201 перенесено.
-- ------------------------------------------------------------
UPDATE course
SET credits  = 5,
    semester = 4
WHERE code = 'DB-201';

-- Перевірка:
SELECT code, title, credits, semester FROM course WHERE code = 'DB-201';

-- ------------------------------------------------------------
-- U-06. Позначити реєстрацію як dropped
-- Мета: студент 2 відрахувався з курсу CA-102 (course_id = 3).
-- ------------------------------------------------------------
-- Перевірка ПЕРЕД:
SELECT enrollment_id, status FROM enrollment
WHERE student_id = 2 AND course_id = 3;

UPDATE enrollment
SET status = 'dropped'
WHERE student_id = 2 AND course_id = 3;

-- Перевірка ПІСЛЯ:
SELECT enrollment_id, status FROM enrollment
WHERE student_id = 2 AND course_id = 3;




-- ------------------------------------------------------------
-- D-01. Видалити dropped-реєстрацію студента 6
-- Мета: прибрати скасований запис, що більше не потрібен.
-- ------------------------------------------------------------
-- Перевірка ПЕРЕД:
SELECT * FROM enrollment WHERE student_id = 6 AND status = 'dropped';

DELETE FROM enrollment
WHERE student_id = 6
  AND status     = 'dropped';

-- Перевірка ПІСЛЯ (має повернути 0 рядків):
SELECT * FROM enrollment WHERE student_id = 6 AND status = 'dropped';

-- ------------------------------------------------------------
-- D-02. Видалити конкретний запис з розкладу
-- Мета: скасувати заняття курсу ADS-101 (course_id=2) у четвер.
-- ------------------------------------------------------------
-- Перевірка ПЕРЕД:
SELECT * FROM schedule WHERE course_id = 2 AND day_of_week = 'Thu';

DELETE FROM schedule
WHERE course_id    = 2
  AND day_of_week  = 'Thu';

-- Перевірка ПІСЛЯ:
SELECT * FROM schedule WHERE course_id = 2;

-- ------------------------------------------------------------
-- D-03. Видалити студента та перевірити CASCADE
-- Мета: видалити студента Дяченка (id=7) і переконатися,
--       що його реєстрація також видалена (ON DELETE CASCADE).
-- ------------------------------------------------------------
-- Перевірка реєстрацій ПЕРЕД:
SELECT enrollment_id, student_id, course_id FROM enrollment WHERE student_id = 7;

DELETE FROM student WHERE student_id = 7;

-- Перевірка: студент видалений
SELECT * FROM student WHERE student_id = 7;

-- Перевірка: реєстрації також видалені (CASCADE спрацював)
SELECT * FROM enrollment WHERE student_id = 7;

-- ------------------------------------------------------------
-- D-04. Видалити аудиторію (тест ON DELETE RESTRICT)
-- Мета: спробувати видалити аудиторію, що використовується
--       в розкладі — PostgreSQL має заборонити це (RESTRICT).
-- ------------------------------------------------------------

DELETE FROM schedule WHERE room_id = 6;
DELETE FROM room    WHERE room_id  = 6;

-- Перевірка:
SELECT * FROM room WHERE room_id = 6;




-- Зведена таблиця кількості рядків після всіх операцій:
SELECT 'faculty'    AS tbl, COUNT(*) AS rows FROM faculty    UNION ALL
SELECT 'department',         COUNT(*)        FROM department UNION ALL
SELECT 'teacher',            COUNT(*)        FROM teacher    UNION ALL
SELECT 'student',            COUNT(*)        FROM student    UNION ALL
SELECT 'course',             COUNT(*)        FROM course     UNION ALL
SELECT 'room',               COUNT(*)        FROM room       UNION ALL
SELECT 'enrollment',         COUNT(*)        FROM enrollment UNION ALL
SELECT 'schedule',           COUNT(*)        FROM schedule;
