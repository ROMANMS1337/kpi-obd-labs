
-- -----------------------------------------------------------
-- 1. FACULTY (Факультет)
-- -----------------------------------------------------------
CREATE TABLE faculty (
    faculty_id   SERIAL          PRIMARY KEY,
    name         VARCHAR(200)    NOT NULL,
    code         VARCHAR(10)     NOT NULL UNIQUE
);

-- -----------------------------------------------------------
-- 2. DEPARTMENT (Кафедра)
-- -----------------------------------------------------------
CREATE TABLE department (
    department_id   SERIAL          PRIMARY KEY,
    name            VARCHAR(200)    NOT NULL,
    code            VARCHAR(10)     NOT NULL UNIQUE,
    faculty_id      INTEGER         NOT NULL
        REFERENCES faculty(faculty_id)
        ON DELETE RESTRICT
);

-- -----------------------------------------------------------
-- 3. TEACHER (Викладач)
-- -----------------------------------------------------------
CREATE TABLE teacher (
    teacher_id      SERIAL          PRIMARY KEY,
    first_name      VARCHAR(100)    NOT NULL,
    last_name       VARCHAR(100)    NOT NULL,
    email           VARCHAR(200)    NOT NULL UNIQUE,
    position        VARCHAR(100)    NOT NULL
        DEFAULT 'Асистент',
    department_id   INTEGER         NOT NULL
        REFERENCES department(department_id)
        ON DELETE RESTRICT
);

-- -----------------------------------------------------------
-- 4. STUDENT (Студент)
-- -----------------------------------------------------------
CREATE TABLE student (
    student_id      SERIAL          PRIMARY KEY,
    first_name      VARCHAR(100)    NOT NULL,
    last_name       VARCHAR(100)    NOT NULL,
    birth_date      DATE            NOT NULL,
    email           VARCHAR(200)    NOT NULL UNIQUE,
    phone           VARCHAR(20),
    department_id   INTEGER         NOT NULL
        REFERENCES department(department_id)
        ON DELETE RESTRICT,
    CONSTRAINT chk_student_birth_date
        CHECK (birth_date <= CURRENT_DATE - INTERVAL '15 years')
);

-- -----------------------------------------------------------
-- 5. COURSE (Навчальний курс)
-- -----------------------------------------------------------
CREATE TABLE course (
    course_id       SERIAL          PRIMARY KEY,
    title           VARCHAR(200)    NOT NULL,
    code            VARCHAR(20)     NOT NULL UNIQUE,
    credits         INTEGER         NOT NULL
        CONSTRAINT chk_course_credits CHECK (credits BETWEEN 1 AND 10),
    semester        INTEGER         NOT NULL
        CONSTRAINT chk_course_semester CHECK (semester BETWEEN 1 AND 12),
    department_id   INTEGER         NOT NULL
        REFERENCES department(department_id)
        ON DELETE RESTRICT,
    teacher_id      INTEGER         NOT NULL
        REFERENCES teacher(teacher_id)
        ON DELETE RESTRICT
);

-- -----------------------------------------------------------
-- 6. ROOM (Аудиторія)
-- -----------------------------------------------------------
CREATE TABLE room (
    room_id     SERIAL          PRIMARY KEY,
    number      VARCHAR(20)     NOT NULL UNIQUE,
    capacity    INTEGER         NOT NULL
        CONSTRAINT chk_room_capacity CHECK (capacity > 0),
    type        VARCHAR(20)     NOT NULL DEFAULT 'lecture'
        CONSTRAINT chk_room_type
            CHECK (type IN ('lecture', 'lab', 'seminar'))
);

-- -----------------------------------------------------------
-- 7. ENROLLMENT (Реєстрація — асоціативна сутність M:N)
-- -----------------------------------------------------------
CREATE TABLE enrollment (
    enrollment_id   SERIAL          PRIMARY KEY,
    student_id      INTEGER         NOT NULL
        REFERENCES student(student_id)
        ON DELETE CASCADE,
    course_id       INTEGER         NOT NULL
        REFERENCES course(course_id)
        ON DELETE RESTRICT,
    enrolled_at     DATE            NOT NULL DEFAULT CURRENT_DATE,
    status          VARCHAR(10)     NOT NULL DEFAULT 'active'
        CONSTRAINT chk_enrollment_status
            CHECK (status IN ('active', 'completed', 'dropped')),
    grade           NUMERIC(5,2)
        CONSTRAINT chk_enrollment_grade CHECK (grade BETWEEN 0 AND 100),
    -- Унікальний пара (студент, курс): не можна записатися двічі
    CONSTRAINT uq_enrollment_student_course
        UNIQUE (student_id, course_id),
    -- Оцінка має сенс лише для завершених курсів
    CONSTRAINT chk_grade_only_if_completed
        CHECK (grade IS NULL OR status = 'completed')
);

-- Обмеження: максимум 5 активних реєстрацій на студента
-- Реалізується через функцію та тригер:
CREATE OR REPLACE FUNCTION check_max_enrollments()
RETURNS TRIGGER AS $$
BEGIN
    IF (
        SELECT COUNT(*)
        FROM enrollment
        WHERE student_id = NEW.student_id
          AND status = 'active'
    ) >= 5 THEN
        RAISE EXCEPTION
            'Студент % вже має 5 активних реєстрацій (максимум)',
            NEW.student_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_max_enrollments
    BEFORE INSERT ON enrollment
    FOR EACH ROW
    EXECUTE FUNCTION check_max_enrollments();

-- -----------------------------------------------------------
-- 8. SCHEDULE (Розклад)
-- -----------------------------------------------------------
CREATE TABLE schedule (
    schedule_id     SERIAL          PRIMARY KEY,
    course_id       INTEGER         NOT NULL
        REFERENCES course(course_id)
        ON DELETE CASCADE,
    room_id         INTEGER         NOT NULL
        REFERENCES room(room_id)
        ON DELETE RESTRICT,
    day_of_week     VARCHAR(3)      NOT NULL
        CONSTRAINT chk_schedule_day
            CHECK (day_of_week IN ('Mon','Tue','Wed','Thu','Fri','Sat')),
    start_time      TIME            NOT NULL,
    end_time        TIME            NOT NULL,
    CONSTRAINT chk_schedule_time
        CHECK (end_time > start_time),
    -- Одна аудиторія не може мати два заняття в той самий час і день
    CONSTRAINT uq_room_time
        UNIQUE (room_id, day_of_week, start_time)
);



-- 1. FACULTY
INSERT INTO faculty (name, code) VALUES
    ('Факультет інформатики та обчислювальної техніки', 'ФІОТ'),
    ('Фізико-математичний факультет',                  'ФМФ'),
    ('Факультет електроенергетики та автоматики',      'ФЕА');

-- 2. DEPARTMENT
INSERT INTO department (name, code, faculty_id) VALUES
    ('Кафедра програмного забезпечення автоматизованих систем', 'ПЗАС', 1),
    ('Кафедра обчислювальної техніки',                          'ОТ',   1),
    ('Кафедра прикладної математики',                           'ПМ',   2),
    ('Кафедра вищої математики',                                'ВМ',   2),
    ('Кафедра автоматики та управління',                        'АУ',   3);

-- 3. TEACHER
INSERT INTO teacher (first_name, last_name, email, position, department_id) VALUES
    ('Ірина',   'Коваленко',  'kovalenko@kpi.ua',  'Доцент',    1),
    ('Петро',   'Мельник',    'melnyk@kpi.ua',     'Профессор', 1),
    ('Оксана',  'Сидоренко',  'sydorenko@kpi.ua',  'Асистент',  2),
    ('Василь',  'Петренко',   'petrenko@kpi.ua',   'Доцент',    3),
    ('Наталія', 'Бондаренко', 'bondarenko@kpi.ua', 'Профессор', 4);

-- 4. STUDENT
INSERT INTO student (first_name, last_name, birth_date, email, phone, department_id) VALUES
    ('Роман',    'Шевченко',  '2005-03-15', 'shevchenko.r@student.kpi.ua', '+380501234567', 1),
    ('Аліна',    'Мороз',     '2004-07-22', 'moroz.a@student.kpi.ua',      '+380671234567', 1),
    ('Дмитро',   'Харченко',  '2004-11-08', 'kharchenko.d@student.kpi.ua', NULL,            2),
    ('Катерина', 'Левченко',  '2005-01-30', 'levchenko.k@student.kpi.ua',  '+380931234567', 3),
    ('Іван',     'Гончаренко','2003-09-14', 'goncharenko.i@student.kpi.ua','+380501112233', 1),
    ('Тетяна',   'Кравченко', '2005-05-20', 'kravchenko.t@student.kpi.ua', NULL,            4);

-- 5. COURSE
INSERT INTO course (title, code, credits, semester, department_id, teacher_id) VALUES
    ('Бази даних',                     'DB-201',  4, 3, 1, 1),
    ('Алгоритми та структури даних',   'ADS-101', 5, 2, 1, 2),
    ('Комп''ютерна архітектура',       'CA-102',  4, 2, 2, 3),
    ('Дискретна математика',           'DM-101',  3, 1, 3, 4),
    ('Об''єктно-орієнтоване програмування', 'OOP-201', 4, 3, 1, 1),
    ('Теорія ймовірностей',            'PT-201',  3, 4, 4, 5);

-- 6. ROOM
INSERT INTO room (number, capacity, type) VALUES
    ('18-1', 120, 'lecture'),
    ('18-3',  30, 'lab'),
    ('36-2',  80, 'lecture'),
    ('36-4',  25, 'seminar'),
    ('12-1',  60, 'lecture');

-- 7. ENROLLMENT
INSERT INTO enrollment (student_id, course_id, enrolled_at, status, grade) VALUES
    (1, 1, '2025-02-01', 'active',    NULL),
    (1, 2, '2025-02-01', 'active',    NULL),
    (1, 4, '2025-02-01', 'completed', 92.50),
    (2, 1, '2025-02-03', 'active',    NULL),
    (2, 3, '2025-02-03', 'active',    NULL),
    (3, 2, '2025-02-02', 'active',    NULL),
    (3, 5, '2025-02-02', 'active',    NULL),
    (4, 4, '2025-02-05', 'completed', 78.00),
    (4, 6, '2025-02-05', 'active',    NULL),
    (5, 1, '2025-02-01', 'active',    NULL),
    (5, 3, '2025-02-01', 'active',    NULL),
    (6, 6, '2025-02-06', 'dropped',   NULL);

-- 8. SCHEDULE
INSERT INTO schedule (course_id, room_id, day_of_week, start_time, end_time) VALUES
    (1, 1, 'Mon', '08:30', '10:05'),
    (1, 2, 'Wed', '10:20', '11:55'),
    (2, 3, 'Tue', '08:30', '10:05'),
    (2, 2, 'Thu', '10:20', '11:55'),
    (3, 1, 'Wed', '13:30', '15:05'),
    (4, 4, 'Fri', '08:30', '10:05'),
    (5, 5, 'Mon', '10:20', '11:55'),
    (6, 3, 'Tue', '13:30', '15:05');



-- Перевірка кількості рядків у кожній таблиці
SELECT 'faculty'    AS tbl, COUNT(*) FROM faculty    UNION ALL
SELECT 'department',         COUNT(*) FROM department UNION ALL
SELECT 'teacher',            COUNT(*) FROM teacher    UNION ALL
SELECT 'student',            COUNT(*) FROM student    UNION ALL
SELECT 'course',             COUNT(*) FROM course     UNION ALL
SELECT 'room',               COUNT(*) FROM room       UNION ALL
SELECT 'enrollment',         COUNT(*) FROM enrollment UNION ALL
SELECT 'schedule',           COUNT(*) FROM schedule;

-- Студенти з їх кафедрами та факультетами
SELECT
    s.student_id,
    s.first_name || ' ' || s.last_name AS full_name,
    d.name AS department,
    f.name AS faculty
FROM student s
JOIN department d ON s.department_id = d.department_id
JOIN faculty    f ON d.faculty_id    = f.faculty_id
ORDER BY s.student_id;

-- Які курси та у яких аудиторіях
SELECT
    c.title       AS course,
    r.number      AS room,
    sc.day_of_week,
    sc.start_time,
    sc.end_time
FROM schedule sc
JOIN course c ON sc.course_id = c.course_id
JOIN room   r ON sc.room_id   = r.room_id
ORDER BY sc.day_of_week, sc.start_time;

-- Реєстрації з оцінками
SELECT
    s.last_name || ' ' || s.first_name AS student,
    c.title  AS course,
    e.status,
    e.grade
FROM enrollment e
JOIN student s ON e.student_id = s.student_id
JOIN course  c ON e.course_id  = c.course_id
ORDER BY s.last_name, c.title;
