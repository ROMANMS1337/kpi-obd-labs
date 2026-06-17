Національний технічний університет України

«Київський політехнічний інститут»

Факультет інформатики та обчислювальної техніки

Кафедра обчислювальної техніки

ОРГАНВЗАЦІЯ БАЗ ДАНИХ

**Лабораторна робота №3**

« Маніпулювання даними SQL (OLTP) ».

Виконав:

студент групи ІО-з41

*Малашта Р. С.*

Залікова книжка № IO-4108

Перевірив

Київ-2026

# **1. Вступ**

У цій лабораторній роботі реалізовано 21 OLTP-операцію (8 SELECT, 7 INSERT, 6 UPDATE, 6 DELETE) над базою даних системи реєстрації студентів. Кожен запит супроводжується описом мети, очікуваного результату та перевіркою через SELECT.

Передумова: схема та зразкові дані лаб. 2 вже завантажені в PostgreSQL. Усі запити виконуються послідовно — результат кожного наступного залежить від попереднього.

# **2. SELECT — отримання даних**

Запити SELECT не змінюють дані — вони лише читають їх. Використовуються для перевірки стану таблиць до та після DML-операцій, а також для отримання звітної інформації.

### **S-01. Усі студенти (базовий перегляд)**

|  |  |
| --- | --- |
| **Мета** | Переконатися, що таблиця student заповнена коректно після лаб. 2. |
| **Очікуваний результат** | 6 рядків: усі студенти з усіма полями. |
| **Результат** | Виконано успішно. 6 рядків повернуто. |

SELECT \*

FROM student

ORDER BY student\_id;

### **S-02. ПІБ та email студентів**

|  |  |
| --- | --- |
| **Мета** | Отримати контактну інформацію без зайвих полів. |
| **Очікуваний результат** | 6 рядків: student\_id, full\_name, email. |
| **Результат** | Виконано успішно. Конкатенація first\_name || ' ' || last\_name відпрацювала коректно. |

SELECT

student\_id,

first\_name || ' ' || last\_name AS full\_name,

email

FROM student

ORDER BY last\_name;

### **S-03. Студенти конкретної кафедри (WHERE + JOIN)**

|  |  |
| --- | --- |
| **Мета** | Знайти всіх студентів кафедри ПЗАС. |
| **Очікуваний результат** | 3 рядки: студенти з department.code = 'ПЗАС'. |
| **Результат** | Виконано успішно. JOIN між student та department по department\_id відпрацював коректно. |

SELECT

s.student\_id,

s.first\_name || ' ' || s.last\_name AS full\_name,

d.name AS department

FROM student s

JOIN department d ON s.department\_id = d.department\_id

WHERE d.code = 'ПЗАС'

ORDER BY s.last\_name;

### **S-04. Курси з кількістю кредитів > 3**

|  |  |
| --- | --- |
| **Мета** | Знайти дисципліни з великим навантаженням. |
| **Очікуваний результат** | 4 курси: DB-201, ADS-101, CA-102, OOP-201. |
| **Результат** | Виконано успішно. WHERE credits > 3 + ORDER BY credits DESC. |

SELECT course\_id, code, title, credits, semester

FROM course

WHERE credits > 3

ORDER BY credits DESC, semester;

### **S-05. Активні реєстрації студента**

|  |  |
| --- | --- |
| **Мета** | Перевірити поточне навантаження студента (id = 1). |
| **Очікуваний результат** | 2 активні реєстрації: курси DB-201 та ADS-101. |
| **Результат** | Виконано успішно. Фільтрація за student\_id = 1 AND status = 'active'. |

SELECT e.enrollment\_id, c.code AS course\_code,

c.title AS course\_title, e.enrolled\_at, e.status

FROM enrollment e

JOIN course c ON e.course\_id = c.course\_id

WHERE e.student\_id = 1 AND e.status = 'active'

ORDER BY e.enrolled\_at;

### **S-06. Відомість з оцінками (CASE, JOIN)**

|  |  |
| --- | --- |
| **Мета** | Отримати перелік завершених курсів із буквеними оцінками ECTS. |
| **Очікуваний результат** | 2 рядки: Шевченко/DM-101/92.50/A, Левченко/DM-101/78.00/B. |
| **Результат** | Виконано успішно. CASE-вираз конвертував числові оцінки в літерні (A–F). |

SELECT s.last\_name || ' ' || s.first\_name AS student,

c.code, c.title, e.grade,

CASE

WHEN e.grade >= 90 THEN 'A'

WHEN e.grade >= 75 THEN 'B'

WHEN e.grade >= 60 THEN 'C'

WHEN e.grade >= 50 THEN 'D'

ELSE 'F'

END AS letter\_grade

FROM enrollment e

JOIN student s ON e.student\_id = s.student\_id

JOIN course c ON e.course\_id = c.course\_id

WHERE e.status = 'completed'

ORDER BY s.last\_name, c.code;

### **S-07. Розклад на понеділок (4-table JOIN)**

|  |  |
| --- | --- |
| **Мета** | Сформувати розклад на понеділок із назвами курсів, аудиторій та викладачів. |
| **Очікуваний результат** | 2 пари: DB-201 (18-1, 08:30) та OOP-201 (12-1, 10:20). |
| **Результат** | Виконано успішно. JOIN через 4 таблиці: schedule → course → room, teacher. |

SELECT sc.start\_time, sc.end\_time, c.title AS course,

r.number AS room, r.type AS room\_type,

t.last\_name || ' ' || t.first\_name AS teacher

FROM schedule sc

JOIN course c ON sc.course\_id = c.course\_id

JOIN room r ON sc.room\_id = r.room\_id

JOIN teacher t ON c.teacher\_id = t.teacher\_id

WHERE sc.day\_of\_week = 'Mon'

ORDER BY sc.start\_time;

![](data:image/png;base64...)

### **S-08. Наповненість курсів (GROUP BY, COUNT)**

|  |  |
| --- | --- |
| **Мета** | Підрахувати кількість студентів на кожному курсі за статусами. |
| **Очікуваний результат** | 6 рядків, курси з 0–3 реєстраціями. LEFT JOIN включає курси без реєстрацій. |
| **Результат** | Виконано успішно. CASE всередині COUNT() дозволив отримати статуси одним запитом. |

SELECT c.code, c.title,

COUNT(e.enrollment\_id) AS total\_enrollments,

COUNT(CASE WHEN e.status = 'active' THEN 1 END) AS active,

COUNT(CASE WHEN e.status = 'completed' THEN 1 END) AS completed,

COUNT(CASE WHEN e.status = 'dropped' THEN 1 END) AS dropped

FROM course c

LEFT JOIN enrollment e ON c.course\_id = e.course\_id

GROUP BY c.course\_id, c.code, c.title

ORDER BY total\_enrollments DESC;

# **3. INSERT — додавання нових записів**

INSERT-запити виконуються в порядку FK-залежностей: спочатку батьківські сутності (faculty, department), потім залежні (teacher, student, course), і нарешті асоціативні таблиці (enrollment, schedule).

### **I-01. Новий факультет**

|  |  |
| --- | --- |
| **Мета** | Розширити структуру університету — додати факультет менеджменту. |
| **Очікуваний результат** | Новий рядок у faculty з faculty\_id = 4. |
| **Результат** | Виконано успішно. SERIAL автоматично присвоїв faculty\_id = 4. |

INSERT INTO faculty (name, code)

VALUES ('Факультет менеджменту та маркетингу', 'ФМM');

-- Перевірка:

SELECT \* FROM faculty ORDER BY faculty\_id;

### **I-02. Нова кафедра (FK → faculty)**

|  |  |
| --- | --- |
| **Мета** | Додати кафедру інформаційної безпеки на ФІОТ (faculty\_id = 1). |
| **Очікуваний результат** | Новий рядок у department з department\_id = 6. |
| **Результат** | Виконано успішно. FK faculty\_id = 1 підтверджено. |

INSERT INTO department (name, code, faculty\_id)

VALUES ('Кафедра інформаційної безпеки', 'ІБ', 1);

### **I-03. Новий викладач (FK → department)**

|  |  |
| --- | --- |
| **Мета** | Зареєструвати доцента Яковенка на кафедрі ІБ. |
| **Очікуваний результат** | Новий рядок у teacher з teacher\_id = 6. |
| **Результат** | Виконано успішно. DEFAULT 'Асистент' замінено явним значенням 'Доцент'. |

INSERT INTO teacher (first\_name, last\_name, email, position, department\_id)

VALUES ('Андрій', 'Яковенко', 'yakovenko@kpi.ua', 'Доцент', 6);

### **I-04. Новий студент**

|  |  |
| --- | --- |
| **Мета** | Зарахувати Олексія Дяченка на кафедру ІБ. |
| **Очікуваний результат** | Новий рядок у student з student\_id = 7. |
| **Примітка** | CHECK chk\_student\_birth\_date перевірить: 2005-08-12 ≤ CURRENT\_DATE − 15 років ✓ |
| **Результат** | Виконано успішно. |

INSERT INTO student (first\_name, last\_name, birth\_date, email, phone, department\_id)

VALUES ('Олексій', 'Дяченко', '2005-08-12',

'dyachenko.o@student.kpi.ua', '+380661234567', 6);

### **I-05. Новий курс**

|  |  |
| --- | --- |
| **Мета** | Ввести дисципліну «Основи кібербезпеки» на кафедрі ІБ. |
| **Очікуваний результат** | Новий рядок у course з course\_id = 7. |
| **Результат** | Виконано успішно. credits = 4 (CHECK 1–10 ✓), semester = 5 (CHECK 1–12 ✓). |

INSERT INTO course (title, code, credits, semester, department\_id, teacher\_id)

VALUES ('Основи кібербезпеки', 'CS-301', 4, 5, 6, 6);

### **I-06. Реєстрація студента на курс + тест тригера**

|  |  |
| --- | --- |
| **Мета** | Записати студента 7 (Дяченка) на курс 7 (Кібербезпека). |
| **Тест тригера** | Студент 7 має 0 активних реєстрацій → тригер дозволяє INSERT. |
| **Очікуваний результат** | Новий рядок у enrollment, status = 'active'. |
| **Результат** | Виконано успішно. Тригер trg\_max\_enrollments не заблокував — ліміт не перевищено. |

INSERT INTO enrollment (student\_id, course\_id, enrolled\_at, status)

VALUES (7, 7, CURRENT\_DATE, 'active');

-- Тест порушення тригера (розкоментуйте, щоб побачити помилку):

-- INSERT INTO enrollment (student\_id, course\_id, ...) VALUES (1, 5, ...);

-- INSERT INTO enrollment (student\_id, course\_id, ...) VALUES (1, 6, ...);

-- (Студент 1 вже має 2 активних реєстрації; при 5 тригер поверне EXCEPTION)

![](data:image/png;base64...)

### **I-07. Нова аудиторія і запис розкладу**

|  |  |
| --- | --- |
| **Мета** | Додати аудиторію 45-2 (семінарна, 40 місць) і поставити курс CS-301 у четвер. |
| **Очікуваний результат** | Новий рядок у room (room\_id = 6) та у schedule (schedule\_id = 9). |
| **Результат** | Виконано успішно. UNIQUE uq\_room\_time: в аудиторії 45-2 у четвер о 08:30 ще нікого немає. |

INSERT INTO room (number, capacity, type)

VALUES ('45-2', 40, 'seminar');

INSERT INTO schedule (course\_id, room\_id, day\_of\_week, start\_time, end\_time)

VALUES (7, 6, 'Thu', '08:30', '10:05');

# **4. UPDATE — оновлення існуючих даних**

Кожен UPDATE-запит має явний WHERE-критерій, що обмежує зміни конкретними рядками. Перед кожним UPDATE наведено SELECT для перевірки поточного стану, після — SELECT для підтвердження змін.

### **U-01. Оновити email студента**

|  |  |
| --- | --- |
| **Мета** | Студент Харченко (id = 3) змінив email-адресу. |
| **Рядки до зміни** | 1 рядок: student\_id = 3. |
| **Очікуваний результат** | email змінено з kharchenko.d@student.kpi.ua на kharchenko.dmitro@student.kpi.ua. |
| **Результат** | Виконано успішно. UNIQUE по email не порушено — нова адреса унікальна. |

-- Перевірка ПЕРЕД:

SELECT student\_id, email FROM student WHERE student\_id = 3;

UPDATE student

SET email = 'kharchenko.dmitro@student.kpi.ua'

WHERE student\_id = 3;

-- Перевірка ПІСЛЯ:

SELECT student\_id, email FROM student WHERE student\_id = 3;

### **U-02. Виставити оцінку та завершити курс**

|  |  |
| --- | --- |
| **Мета** | Закрити курс «Дискретна математика» для студента 1: виставити 88.00, статус → completed. |
| **Примітка** | Обидва поля оновлюються одним UPDATE — обмеження chk\_grade\_only\_if\_completed задоволено, бо status і grade змінюються одночасно. |
| **Очікуваний результат** | status = 'completed', grade = 88.00. |
| **Результат** | Виконано успішно. |

UPDATE enrollment

SET status = 'completed',

grade = 88.00

WHERE student\_id = 1

AND course\_id = 4;

### **U-03. Масове переведення студентів між кафедрами**

|  |  |
| --- | --- |
| **Мета** | Переведення студентів з кафедри ОТ (id=2) на кафедру ІБ (id=6) — реорганізація. |
| **Рядки до зміни** | 1 рядок: студент Харченко (раніше на ОТ). |
| **Безпека** | Перед UPDATE виконано SELECT для перегляду рядків, що будуть змінені. |
| **Результат** | Виконано успішно. Зовнішній ключ department\_id = 6 існує → порушень немає. |

-- Перевірка ПЕРЕД:

SELECT student\_id, first\_name, last\_name, department\_id

FROM student WHERE department\_id = 2;

UPDATE student

SET department\_id = 6

WHERE department\_id = 2;

### **U-04. Зменшити місткість аудиторії**

|  |  |
| --- | --- |
| **Мета** | Аудиторія 18-1 після ремонту вміщує 100 осіб замість 120. |
| **Очікуваний результат** | capacity: 120 → 100. |
| **Результат** | Виконано успішно. CHECK chk\_room\_capacity (> 0) задоволено. |

UPDATE room

SET capacity = 100

WHERE number = '18-1';

### **U-05. Оновити кредити та семестр курсу**

|  |  |
| --- | --- |
| **Мета** | Оновлений навчальний план: DB-201 перенесено на семестр 4, кредити збільшено до 5. |
| **Очікуваний результат** | credits: 4 → 5, semester: 3 → 4. |
| **Результат** | Виконано успішно. Обидва CHECK-обмеження задоволені. |

UPDATE course

SET credits = 5,

semester = 4

WHERE code = 'DB-201';

### **U-06. Позначити реєстрацію як dropped**

|  |  |
| --- | --- |
| **Мета** | Студент 2 відрахувався з курсу CA-102 (course\_id = 3). |
| **Очікуваний результат** | status: 'active' → 'dropped'. grade залишається NULL. |
| **Примітка** | CHECK chk\_grade\_only\_if\_completed: grade IS NULL → дозволено для будь-якого статусу. |
| **Результат** | Виконано успішно. |

UPDATE enrollment

SET status = 'dropped'

WHERE student\_id = 2

AND course\_id = 3;

# **5. DELETE — видалення даних**

DELETE-запити виконуються з явним WHERE. Окремо демонструється поведінка ON DELETE CASCADE (видалення студента → видалення його реєстрацій) та ON DELETE RESTRICT (спроба видалити аудиторію, що використовується → помилка).

### **D-01. Видалити скасовану реєстрацію**

|  |  |
| --- | --- |
| **Мета** | Прибрати dropped-запис студента 6 — він більше не потрібний. |
| **Рядки до видалення** | 1 рядок: enrollment де student\_id = 6 AND status = 'dropped'. |
| **Очікуваний результат** | Після видалення SELECT повертає 0 рядків. |
| **Результат** | Виконано успішно. |

DELETE FROM enrollment

WHERE student\_id = 6 AND status = 'dropped';

-- Перевірка (має повернути 0 рядків):

SELECT \* FROM enrollment WHERE student\_id = 6 AND status = 'dropped';

### **D-02. Скасувати заняття в розкладі**

|  |  |
| --- | --- |
| **Мета** | Скасувати лабораторне заняття курсу ADS-101 у четвер. |
| **Рядки до видалення** | 1 рядок: schedule де course\_id = 2 AND day\_of\_week = 'Thu'. |
| **Результат** | Виконано успішно. Інші записи розкладу для ADS-101 (вівторок) збережені. |

DELETE FROM schedule

WHERE course\_id = 2 AND day\_of\_week = 'Thu';

-- Перевірка (має залишитися 1 рядок — вівторок):

SELECT \* FROM schedule WHERE course\_id = 2;

### **D-03. Видалити студента + CASCADE**

|  |  |
| --- | --- |
| **Мета** | Видалити студента Дяченка (id = 7) і перевірити, що CASCADE видалив його реєстрації. |
| **FK-поведінка** | enrollment.student\_id REFERENCES student ON DELETE CASCADE — реєстрації видаляються автоматично. |
| **Очікуваний результат** | student\_id = 7: 0 рядків у student та 0 рядків у enrollment. |
| **Результат** | Виконано успішно. CASCADE спрацював — реєстрація на CS-301 видалена разом зі студентом. |

-- Реєстрації ПЕРЕД видаленням студента:

SELECT enrollment\_id, student\_id, course\_id FROM enrollment WHERE student\_id = 7;

DELETE FROM student WHERE student\_id = 7;

-- Перевірка: студент видалений

SELECT \* FROM student WHERE student\_id = 7;

-- Перевірка: CASCADE — реєстрації також видалені

SELECT \* FROM enrollment WHERE student\_id = 7;

![](data:image/png;base64...)

### **D-04. Тест ON DELETE RESTRICT + правильний порядок видалення**

|  |  |
| --- | --- |
| **Мета** | Видалити аудиторію 45-2 (room\_id = 6). |
| **Тест RESTRICT** | Пряме видалення room\_id = 6 неможливе, бо вона присутня у schedule. PostgreSQL поверне ERROR: violates foreign key constraint. |
| **Правильний порядок** | Спочатку видаляємо записи розкладу (schedule), потім — саму аудиторію (room). |
| **Результат** | Виконано успішно при правильному порядку. RESTRICT захистив від випадкового видалення даних. |

-- НЕПРАВИЛЬНО — спричинить помилку FK (розкоментуйте, щоб побачити):

-- DELETE FROM room WHERE room\_id = 6;

-- ERROR: update or delete on table "room" violates foreign key constraint

-- ПРАВИЛЬНО: спочатку видаляємо дочірні записи

DELETE FROM schedule WHERE room\_id = 6;

DELETE FROM room WHERE room\_id = 6;

-- Перевірка:

SELECT \* FROM room WHERE room\_id = 6;

# **6. Підсумок виконаних операцій**

|  |  |  |  |  |
| --- | --- | --- | --- | --- |
| **Код** | **Тип** | **Таблиця(и)** | **Опис** | **Результат** |
| **S-01** | SELECT | student | Усі студенти | Успішно |
| **S-02** | SELECT | student | ПІБ та email | Успішно |
| **S-03** | SELECT | student, department | Студенти кафедри ПЗАС | Успішно |
| **S-04** | SELECT | course | Курси > 3 кредити | Успішно |
| **S-05** | SELECT | enrollment, course | Активні реєстрації студента 1 | Успішно |
| **S-06** | SELECT | enrollment + JOIN | Відомість з оцінками + CASE | Успішно |
| **S-07** | SELECT | 4 таблиці | Розклад на понеділок | Успішно |
| **S-08** | SELECT | course, enrollment | Наповненість курсів (GROUP BY) | Успішно |
| **I-01** | INSERT | faculty | Новий факультет ФММ | Успішно |
| **I-02** | INSERT | department | Нова кафедра ІБ | Успішно |
| **I-03** | INSERT | teacher | Новий викладач Яковенко | Успішно |
| **I-04** | INSERT | student | Новий студент Дяченко | Успішно |
| **I-05** | INSERT | course | Новий курс CS-301 | Успішно |
| **I-06** | INSERT | enrollment | Реєстрація + перевірка тригера | Успішно |
| **I-07** | INSERT | room, schedule | Нова аудиторія 45-2 + заняття | Успішно |
| **U-01** | UPDATE | student | Email студента 3 | Успішно |
| **U-02** | UPDATE | enrollment | Оцінка + completed для студ.1/курс 4 | Успішно |
| **U-03** | UPDATE | student | Переведення студентів ОТ → ІБ | Успішно |
| **U-04** | UPDATE | room | Місткість аудиторії 18-1 | Успішно |
| **U-05** | UPDATE | course | Кредити та семестр DB-201 | Успішно |
| **U-06** | UPDATE | enrollment | Статус → dropped для студ.2/курс 3 | Успішно |
| **D-01** | DELETE | enrollment | Видалення dropped-запису студ.6 | Успішно |
| **D-02** | DELETE | schedule | Скасування заняття ADS-101/четвер | Успішно |
| **D-03** | DELETE | student + CASCADE | Видалення студ.7 + авто-CASCADE enrollment | Успішно |
| **D-04** | DELETE | schedule + room | RESTRICT-тест + правильний порядок видалення аудиторії | Успішно |

# **7. Фінальний стан таблиць**

Після виконання всіх операцій кількість рядків у таблицях змінилася порівняно зі станом після лаб. 2:

SELECT 'faculty' AS tbl, COUNT(\*) AS rows FROM faculty UNION ALL

SELECT 'department', COUNT(\*) FROM department UNION ALL

SELECT 'teacher', COUNT(\*) FROM teacher UNION ALL

SELECT 'student', COUNT(\*) FROM student UNION ALL

SELECT 'course', COUNT(\*) FROM course UNION ALL

SELECT 'room', COUNT(\*) FROM room UNION ALL

SELECT 'enrollment', COUNT(\*) FROM enrollment UNION ALL

SELECT 'schedule', COUNT(\*) FROM schedule;

![](data:image/png;base64...)

|  |  |  |  |
| --- | --- | --- | --- |
| **Таблиця** | **Після лаб. 2** | **Після лаб. 3** | **Зміни** |
| **faculty** | 3 | 4 | +1 (I-01) |
| **department** | 5 | 6 | +1 (I-02) |
| **teacher** | 5 | 6 | +1 (I-03) |
| **student** | 6 | 6 | +1 (I-04), −1 (D-03) |
| **course** | 6 | 7 | +1 (I-05) |
| **room** | 5 | 5 | +1 (I-07), −1 (D-04) |
| **enrollment** | 12 | 11 | +1 (I-06), −2 (D-01, D-03 CASCADE) |
| **schedule** | 8 | 7 | +1 (I-07), −2 (D-02, D-04) |