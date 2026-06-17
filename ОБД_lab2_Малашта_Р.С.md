Національний технічний університет України

«Київський політехнічний інститут»

Факультет інформатики та обчислювальної техніки

Кафедра обчислювальної техніки

ОРГАНВЗАЦІЯ БАЗ ДАНИХ

**Лабораторна робота №2**

« Перетворення ER-діаграми на схему PostgreSQL ».

Виконав:

студент групи ІО-з41

*Малашта Р. С.*

Залікова книжка № IO-4108

Перевірив

Київ-2026

# **1. Огляд фінальної схеми**

На основі ER-діаграми, розробленої в лабораторній роботі №1, схема PostgreSQL містить 8 таблиць. Порядок створення відповідає залежностям зовнішніх ключів: спочатку батьківські таблиці, потім дочірні.

|  |  |  |  |
| --- | --- | --- | --- |
| **№** | **Таблиця** | **Первинний ключ** | **Зовнішні ключі** |
| 1 | **faculty** | faculty\_id (SERIAL) | — |
| 2 | **department** | department\_id (SERIAL) | faculty\_id → faculty |
| 3 | **teacher** | teacher\_id (SERIAL) | department\_id → department |
| 4 | **student** | student\_id (SERIAL) | department\_id → department |
| 5 | **course** | course\_id (SERIAL) | department\_id → department, teacher\_id → teacher |
| 6 | **room** | room\_id (SERIAL) | — |
| 7 | **enrollment** | enrollment\_id (SERIAL) | student\_id → student, course\_id → course |
| 8 | **schedule** | schedule\_id (SERIAL) | course\_id → course, room\_id → room |

# **2. Оператори CREATE TABLE**

## **2.1 Таблиця faculty**

Верхній рівень організаційної структури університету. Не має зовнішніх ключів.

|  |  |  |  |
| --- | --- | --- | --- |
| **Стовпець** | **Тип даних** | **Обмеження** | **Опис** |
| faculty\_id | SERIAL | PRIMARY KEY | Автоінкрементний ідентифікатор |
| name | VARCHAR(200) | NOT NULL | Повна назва факультету |
| code | VARCHAR(10) | NOT NULL UNIQUE | Скорочений код (напр. «ФІОТ») |

CREATE TABLE faculty (

faculty\_id SERIAL PRIMARY KEY,

name VARCHAR(200) NOT NULL,

code VARCHAR(10) NOT NULL UNIQUE

);

## **2.2 Таблиця department**

Підрозділ факультету. Зовнішній ключ faculty\_id посилається на faculty(faculty\_id). ON DELETE RESTRICT захищає від видалення факультету, якщо існують кафедри.

|  |  |  |  |
| --- | --- | --- | --- |
| **Стовпець** | **Тип даних** | **Обмеження** | **Опис** |
| department\_id | SERIAL | PRIMARY KEY | Автоінкрементний ідентифікатор |
| name | VARCHAR(200) | NOT NULL | Повна назва кафедри |
| code | VARCHAR(10) | NOT NULL UNIQUE | Скорочений код |
| faculty\_id | INTEGER | NOT NULL, FK → faculty | Факультет кафедри |

CREATE TABLE department (

department\_id SERIAL PRIMARY KEY,

name VARCHAR(200) NOT NULL,

code VARCHAR(10) NOT NULL UNIQUE,

faculty\_id INTEGER NOT NULL

REFERENCES faculty(faculty\_id) ON DELETE RESTRICT

);

## **2.3 Таблиця teacher**

Дані про викладачів. DEFAULT 'Асистент' для position спрощує вставку нових записів.

|  |  |  |  |
| --- | --- | --- | --- |
| **Стовпець** | **Тип даних** | **Обмеження** | **Опис** |
| teacher\_id | SERIAL | PRIMARY KEY | Автоінкрементний ідентифікатор |
| first\_name | VARCHAR(100) | NOT NULL | Ім'я |
| last\_name | VARCHAR(100) | NOT NULL | Прізвище |
| email | VARCHAR(200) | NOT NULL UNIQUE | Унікальна електронна адреса |
| position | VARCHAR(100) | NOT NULL DEFAULT 'Асистент' | Посада |
| department\_id | INTEGER | NOT NULL, FK → department | Кафедра |

CREATE TABLE teacher (

teacher\_id SERIAL PRIMARY KEY,

first\_name VARCHAR(100) NOT NULL,

last\_name VARCHAR(100) NOT NULL,

email VARCHAR(200) NOT NULL UNIQUE,

position VARCHAR(100) NOT NULL DEFAULT 'Асистент',

department\_id INTEGER NOT NULL

REFERENCES department(department\_id) ON DELETE RESTRICT

);

## **2.4 Таблиця student**

Особові дані студента. Обмеження chk\_student\_birth\_date гарантує, що вік студента не менше 15 років.

|  |  |  |  |
| --- | --- | --- | --- |
| **Стовпець** | **Тип даних** | **Обмеження** | **Опис** |
| student\_id | SERIAL | PRIMARY KEY | Автоінкрементний ідентифікатор |
| first\_name | VARCHAR(100) | NOT NULL | Ім'я |
| last\_name | VARCHAR(100) | NOT NULL | Прізвище |
| birth\_date | DATE | NOT NULL, CHECK ≥ 15 р. | Дата народження |
| email | VARCHAR(200) | NOT NULL UNIQUE | Електронна адреса |
| phone | VARCHAR(20) | NULLABLE | Номер телефону |
| department\_id | INTEGER | NOT NULL, FK → department | Кафедра |

CREATE TABLE student (

student\_id SERIAL PRIMARY KEY,

first\_name VARCHAR(100) NOT NULL,

last\_name VARCHAR(100) NOT NULL,

birth\_date DATE NOT NULL,

email VARCHAR(200) NOT NULL UNIQUE,

phone VARCHAR(20),

department\_id INTEGER NOT NULL

REFERENCES department(department\_id) ON DELETE RESTRICT,

CONSTRAINT chk\_student\_birth\_date

CHECK (birth\_date <= CURRENT\_DATE - INTERVAL '15 years')

);

## **2.5 Таблиця course**

Навчальна дисципліна. CHECK-обмеження забезпечують допустимий діапазон кредитів (1–10) та семестру (1–12).

|  |  |  |  |
| --- | --- | --- | --- |
| **Стовпець** | **Тип даних** | **Обмеження** | **Опис** |
| course\_id | SERIAL | PRIMARY KEY | Автоінкрементний ідентифікатор |
| title | VARCHAR(200) | NOT NULL | Назва дисципліни |
| code | VARCHAR(20) | NOT NULL UNIQUE | Код курсу |
| credits | INTEGER | NOT NULL, CHECK 1–10 | Кількість кредитів ECTS |
| semester | INTEGER | NOT NULL, CHECK 1–12 | Номер семестру |
| department\_id | INTEGER | NOT NULL, FK → department | Відповідальна кафедра |
| teacher\_id | INTEGER | NOT NULL, FK → teacher | Відповідальний викладач |

CREATE TABLE course (

course\_id SERIAL PRIMARY KEY,

title VARCHAR(200) NOT NULL,

code VARCHAR(20) NOT NULL UNIQUE,

credits INTEGER NOT NULL

CONSTRAINT chk\_course\_credits CHECK (credits BETWEEN 1 AND 10),

semester INTEGER NOT NULL

CONSTRAINT chk\_course\_semester CHECK (semester BETWEEN 1 AND 12),

department\_id INTEGER NOT NULL

REFERENCES department(department\_id) ON DELETE RESTRICT,

teacher\_id INTEGER NOT NULL

REFERENCES teacher(teacher\_id) ON DELETE RESTRICT

);

## **2.6 Таблиця room**

Фізичні приміщення університету. Тип аудиторії обмежений переліком: lecture, lab, seminar.

|  |  |  |  |
| --- | --- | --- | --- |
| **Стовпець** | **Тип даних** | **Обмеження** | **Опис** |
| room\_id | SERIAL | PRIMARY KEY | Автоінкрементний ідентифікатор |
| number | VARCHAR(20) | NOT NULL UNIQUE | Номер аудиторії |
| capacity | INTEGER | NOT NULL, CHECK > 0 | Кількість місць |
| type | VARCHAR(20) | NOT NULL DEFAULT 'lecture', CHECK IN (…) | Тип аудиторії |

CREATE TABLE room (

room\_id SERIAL PRIMARY KEY,

number VARCHAR(20) NOT NULL UNIQUE,

capacity INTEGER NOT NULL

CONSTRAINT chk\_room\_capacity CHECK (capacity > 0),

type VARCHAR(20) NOT NULL DEFAULT 'lecture'

CONSTRAINT chk\_room\_type

CHECK (type IN ('lecture', 'lab', 'seminar'))

);

## **2.7 Таблиця enrollment**

Асоціативна сутність, що реалізує зв'язок M:N між student і course. Містить кілька важливих обмежень:

* UNIQUE (student\_id, course\_id) — студент не може двічі записатися на один курс.
* CHECK (grade BETWEEN 0 AND 100) — оцінка в шкалі ECTS.
* CHECK (grade IS NULL OR status = 'completed') — оцінка можлива лише для завершених курсів.
* Тригер trg\_max\_enrollments — не дає перевищити ліміт 5 активних реєстрацій на студента.

|  |  |  |  |
| --- | --- | --- | --- |
| **Стовпець** | **Тип даних** | **Обмеження** | **Опис** |
| enrollment\_id | SERIAL | PRIMARY KEY | Автоінкрементний ідентифікатор |
| student\_id | INTEGER | NOT NULL, FK → student | Студент |
| course\_id | INTEGER | NOT NULL, FK → course | Курс |
| enrolled\_at | DATE | NOT NULL DEFAULT TODAY | Дата реєстрації |
| status | VARCHAR(10) | NOT NULL DEFAULT 'active', CHECK IN (…) | Статус |
| grade | NUMERIC(5,2) | NULLABLE, CHECK 0–100 | Оцінка ECTS |

CREATE TABLE enrollment (

enrollment\_id SERIAL PRIMARY KEY,

student\_id INTEGER NOT NULL

REFERENCES student(student\_id) ON DELETE CASCADE,

course\_id INTEGER NOT NULL

REFERENCES course(course\_id) ON DELETE RESTRICT,

enrolled\_at DATE NOT NULL DEFAULT CURRENT\_DATE,

status VARCHAR(10) NOT NULL DEFAULT 'active'

CONSTRAINT chk\_enrollment\_status

CHECK (status IN ('active', 'completed', 'dropped')),

grade NUMERIC(5,2)

CONSTRAINT chk\_enrollment\_grade

CHECK (grade BETWEEN 0 AND 100),

CONSTRAINT uq\_enrollment\_student\_course

UNIQUE (student\_id, course\_id),

CONSTRAINT chk\_grade\_only\_if\_completed

CHECK (grade IS NULL OR status = 'completed')

);

-- Тригер: максимум 5 активних реєстрацій на студента

CREATE OR REPLACE FUNCTION check\_max\_enrollments()

RETURNS TRIGGER AS $$

BEGIN

IF (SELECT COUNT(\*) FROM enrollment

WHERE student\_id = NEW.student\_id AND status = 'active') >= 5

THEN

RAISE EXCEPTION 'Студент % вже має 5 активних реєстрацій', NEW.student\_id;

END IF;

RETURN NEW;

END;

$$ LANGUAGE plpgsql;

CREATE TRIGGER trg\_max\_enrollments

BEFORE INSERT ON enrollment

FOR EACH ROW EXECUTE FUNCTION check\_max\_enrollments();

## **2.8 Таблиця schedule**

Розклад занять. UNIQUE (room\_id, day\_of\_week, start\_time) гарантує, що одна аудиторія не може бути зайнята двічі в один і той самий час. CHECK (end\_time > start\_time) забороняє некоректні часові інтервали.

|  |  |  |  |
| --- | --- | --- | --- |
| **Стовпець** | **Тип даних** | **Обмеження** | **Опис** |
| schedule\_id | SERIAL | PRIMARY KEY | Автоінкрементний ідентифікатор |
| course\_id | INTEGER | NOT NULL, FK → course | Курс |
| room\_id | INTEGER | NOT NULL, FK → room | Аудиторія |
| day\_of\_week | VARCHAR(3) | NOT NULL, CHECK IN (…) | День тижня |
| start\_time | TIME | NOT NULL | Час початку |
| end\_time | TIME | NOT NULL, CHECK > start | Час закінчення |

CREATE TABLE schedule (

schedule\_id SERIAL PRIMARY KEY,

course\_id INTEGER NOT NULL

REFERENCES course(course\_id) ON DELETE CASCADE,

room\_id INTEGER NOT NULL

REFERENCES room(room\_id) ON DELETE RESTRICT,

day\_of\_week VARCHAR(3) NOT NULL

CONSTRAINT chk\_schedule\_day

CHECK (day\_of\_week IN ('Mon','Tue','Wed','Thu','Fri','Sat')),

start\_time TIME NOT NULL,

end\_time TIME NOT NULL,

CONSTRAINT chk\_schedule\_time CHECK (end\_time > start\_time),

CONSTRAINT uq\_room\_time UNIQUE (room\_id, day\_of\_week, start\_time)

);

# **3. Зразкові дані (INSERT INTO)**

Вставка виконується в порядку залежностей: спочатку батьківські таблиці, потім дочірні. Кожна таблиця містить від 3 до 12 рядків.

## **3.1 faculty — 3 рядки**

INSERT INTO faculty (name, code) VALUES

('Факультет інформатики та обчислювальної техніки', 'ФІОТ'),

('Фізико-математичний факультет', 'ФМФ'),

('Факультет електроенергетики та автоматики', 'ФЕА');

## **3.2 department — 5 рядків**

INSERT INTO department (name, code, faculty\_id) VALUES

('Кафедра програмного забезпечення автоматизованих систем', 'ПЗАС', 1),

('Кафедра обчислювальної техніки', 'ОТ', 1),

('Кафедра прикладної математики', 'ПМ', 2),

('Кафедра вищої математики', 'ВМ', 2),

('Кафедра автоматики та управління', 'АУ', 3);

## **3.3 teacher — 5 рядків**

INSERT INTO teacher (first\_name, last\_name, email, position, department\_id) VALUES

('Ірина', 'Коваленко', 'kovalenko@kpi.ua', 'Доцент', 1),

('Петро', 'Мельник', 'melnyk@kpi.ua', 'Профессор', 1),

('Оксана', 'Сидоренко', 'sydorenko@kpi.ua', 'Асистент', 2),

('Василь', 'Петренко', 'petrenko@kpi.ua', 'Доцент', 3),

('Наталія', 'Бондаренко', 'bondarenko@kpi.ua', 'Профессор', 4);

## **3.4 student — 6 рядків**

INSERT INTO student (first\_name, last\_name, birth\_date, email, phone, department\_id) VALUES

('Роман', 'Шевченко', '2005-03-15', 'shevchenko.r@student.kpi.ua', '+380501234567', 1),

('Аліна', 'Мороз', '2004-07-22', 'moroz.a@student.kpi.ua', '+380671234567', 1),

('Дмитро', 'Харченко', '2004-11-08', 'kharchenko.d@student.kpi.ua', NULL, 2),

('Катерина', 'Левченко', '2005-01-30', 'levchenko.k@student.kpi.ua', '+380931234567', 3),

('Іван', 'Гончаренко', '2003-09-14', 'goncharenko.i@student.kpi.ua','+380501112233', 1),

('Тетяна', 'Кравченко', '2005-05-20', 'kravchenko.t@student.kpi.ua', NULL, 4);

## **3.5 course — 6 рядків**

INSERT INTO course (title, code, credits, semester, department\_id, teacher\_id) VALUES

('Бази даних', 'DB-201', 4, 3, 1, 1),

('Алгоритми та структури даних', 'ADS-101', 5, 2, 1, 2),

('Комп''ютерна архітектура', 'CA-102', 4, 2, 2, 3),

('Дискретна математика', 'DM-101', 3, 1, 3, 4),

('Об''єктно-орієнтоване програмування','OOP-201', 4, 3, 1, 1),

('Теорія ймовірностей', 'PT-201', 3, 4, 4, 5);

## **3.6 room — 5 рядків**

INSERT INTO room (number, capacity, type) VALUES

('18-1', 120, 'lecture'),

('18-3', 30, 'lab'),

('36-2', 80, 'lecture'),

('36-4', 25, 'seminar'),

('12-1', 60, 'lecture');

## **3.7 enrollment — 12 рядків**

INSERT INTO enrollment (student\_id, course\_id, enrolled\_at, status, grade) VALUES

(1, 1, '2025-02-01', 'active', NULL),

(1, 2, '2025-02-01', 'active', NULL),

(1, 4, '2025-02-01', 'completed', 92.50),

(2, 1, '2025-02-03', 'active', NULL),

(2, 3, '2025-02-03', 'active', NULL),

(3, 2, '2025-02-02', 'active', NULL),

(3, 5, '2025-02-02', 'active', NULL),

(4, 4, '2025-02-05', 'completed', 78.00),

(4, 6, '2025-02-05', 'active', NULL),

(5, 1, '2025-02-01', 'active', NULL),

(5, 3, '2025-02-01', 'active', NULL),

(6, 6, '2025-02-06', 'dropped', NULL);

## **3.8 schedule — 8 рядків**

INSERT INTO schedule (course\_id, room\_id, day\_of\_week, start\_time, end\_time) VALUES

(1, 1, 'Mon', '08:30', '10:05'),

(1, 2, 'Wed', '10:20', '11:55'),

(2, 3, 'Tue', '08:30', '10:05'),

(2, 2, 'Thu', '10:20', '11:55'),

(3, 1, 'Wed', '13:30', '15:05'),

(4, 4, 'Fri', '08:30', '10:05'),

(5, 5, 'Mon', '10:20', '11:55'),

(6, 3, 'Tue', '13:30', '15:05');

# **4. Перевірні запити**

Після виконання всіх INSERT рекомендується запустити наступні запити для перевірки цілісності даних.

## **4.1 Кількість рядків у кожній таблиці**

SELECT 'faculty' AS tbl, COUNT(\*) FROM faculty UNION ALL

SELECT 'department', COUNT(\*) FROM department UNION ALL

SELECT 'teacher', COUNT(\*) FROM teacher UNION ALL

SELECT 'student', COUNT(\*) FROM student UNION ALL

SELECT 'course', COUNT(\*) FROM course UNION ALL

SELECT 'room', COUNT(\*) FROM room UNION ALL

SELECT 'enrollment', COUNT(\*) FROM enrollment UNION ALL

SELECT 'schedule', COUNT(\*) FROM schedule;

![](data:image/png;base64...)

## **4.2 Студенти з кафедрами та факультетами**

SELECT s.student\_id,

s.first\_name || ' ' || s.last\_name AS full\_name,

d.name AS department,

f.name AS faculty

FROM student s

JOIN department d ON s.department\_id = d.department\_id

JOIN faculty f ON d.faculty\_id = f.faculty\_id

ORDER BY s.student\_id;

## **4.3 Розклад з назвами курсів та аудиторій**

SELECT c.title AS course, r.number AS room,

sc.day\_of\_week, sc.start\_time, sc.end\_time

FROM schedule sc

JOIN course c ON sc.course\_id = c.course\_id

JOIN room r ON sc.room\_id = r.room\_id

ORDER BY sc.day\_of\_week, sc.start\_time;

## **4.4 Реєстрації з оцінками**

SELECT s.last\_name || ' ' || s.first\_name AS student,

c.title AS course, e.status, e.grade

FROM enrollment e

JOIN student s ON e.student\_id = s.student\_id

JOIN course c ON e.course\_id = c.course\_id

ORDER BY s.last\_name, c.title;

![](data:image/png;base64...)

# **5. Підсумок обмежень та припущень**

## **5.1 Ключові обмеження**

|  |  |  |
| --- | --- | --- |
| **Таблиця** | **Обмеження** | **Зміст** |
| student | chk\_student\_birth\_date | Вік студента ≥ 15 років |
| course | chk\_course\_credits | Кредити від 1 до 10 |
| course | chk\_course\_semester | Семестр від 1 до 12 |
| room | chk\_room\_capacity | Місткість > 0 |
| room | chk\_room\_type | Тип: lecture / lab / seminar |
| enrollment | uq\_enrollment\_student\_course | Студент не може двічі записатися на курс |
| enrollment | chk\_enrollment\_grade | Оцінка від 0 до 100 |
| enrollment | chk\_grade\_only\_if\_completed | Оцінка тільки при статусі completed |
| enrollment | trg\_max\_enrollments (тригер) | Максимум 5 активних реєстрацій на студента |
| schedule | uq\_room\_time | Аудиторія не зайнята двічі в один час |
| schedule | chk\_schedule\_time | end\_time > start\_time |
| schedule | chk\_schedule\_day | День: Mon/Tue/Wed/Thu/Fri/Sat |

## **5.2 Важливі припущення**

* ON DELETE RESTRICT на більшості FK — видалення батьківського запису забороняється, якщо існують дочірні (захист від випадкового знищення даних).
* ON DELETE CASCADE в enrollment(student\_id) — при видаленні студента всі його реєстрації видаляються автоматично.
* Тригер реалізовано на рівні бази даних, а не додатку — це гарантує виконання правила незалежно від клієнта.
* SERIAL (= INTEGER + SEQUENCE) обрано замість IDENTITY для сумісності зі старими версіями PostgreSQL (≥ 9.6).
* Оцінка зберігається як NUMERIC(5,2), а не REAL чи FLOAT, щоб уникнути проблем з округленням.