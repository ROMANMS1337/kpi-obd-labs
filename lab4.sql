-- =====================================================================
-- ЛАБОРАТОРНА РОБОТА №4: АНАЛІТИЧНІ SQL-ЗАПИТИ (OLAP)
-- Система реєстрації студентів
-- КПІ ім. Ігоря Сікорського · 2026
-- =====================================================================

-- =====================================================================
-- ГРУПА А: АГРЕГАЦІЯ ТА ГРУПУВАННЯ (Мінімум 4 запити за ТЗ)
-- =====================================================================

-- ---------------------------------------------------------------------
-- AG-01. Середній бал та кількість успішно завершених курсів для кожного студента
-- Мета: виявити успішність студентів та їхнє реальне навчальне навантаження.
-- Використовує: AVG, COUNT, GROUP BY, ORDER BY.
-- ---------------------------------------------------------------------
SELECT 
    s.student_id,
    s.last_name || ' ' || s.first_name AS student_name,
    COUNT(e.enrollment_id) AS completed_courses_count,
    ROUND(AVG(e.grade), 2) AS average_grade
FROM student s
JOIN enrollment e ON s.student_id = e.student_id
WHERE e.status = 'completed'
GROUP BY s.student_id, s.last_name, s.first_name
ORDER BY average_grade DESC;


-- ---------------------------------------------------------------------
-- AG-02. Кількість студентів на кафедрах з фільтрацією за мінімальним обсягом
-- Мета: знайти популярні кафедри, де навчається більше ніж 1 студент.
-- Використовує: COUNT, GROUP BY, HAVING.
-- ---------------------------------------------------------------------
SELECT 
    d.department_id,
    d.code AS department_code,
    d.name AS department_name,
    COUNT(s.student_id) AS total_students
FROM department d
LEFT JOIN student s ON d.department_id = s.department_id
GROUP BY d.department_id, d.code, d.name
HAVING COUNT(s.student_id) > 1
ORDER BY total_students DESC;


-- ---------------------------------------------------------------------
-- AG-03. Статистика місткості аудиторій за їхніми типами
-- Мета: проаналізувати фонд аудиторій університету для планування масових лекцій.
-- Використовує: MIN, MAX, AVG, SUM, GROUP BY.
-- ---------------------------------------------------------------------
SELECT 
    type AS room_type,
    COUNT(*) AS total_rooms,
    MIN(capacity) AS min_capacity,
    MAX(capacity) AS max_capacity,
    ROUND(AVG(capacity), 1) AS avg_capacity,
    SUM(capacity) AS total_capacity
FROM room
GROUP BY type
ORDER BY total_capacity DESC;


-- ---------------------------------------------------------------------
-- AG-04. Сумарний обсяг кредитів ECTS, що викладаються кожною кафедрою
-- Мета: оцінити академічне навантаження на кожну кафедру.
-- Використовує: SUM, GROUP BY, ORDER BY.
-- ---------------------------------------------------------------------
SELECT 
    d.code AS department_code,
    d.name AS department_name,
    SUM(c.credits) AS total_credits_offered,
    COUNT(c.course_id) AS total_courses
FROM department d
JOIN course c ON d.department_id = c.department_id
GROUP BY d.department_id, d.code, d.name
ORDER BY total_credits_offered DESC;


-- =====================================================================
-- ГРУПА Б: РІЗНІ ТИПИ JOIN-ів (Мінімум 3 запити за ТЗ)
-- =====================================================================

-- ---------------------------------------------------------------------
-- JN-01. INNER JOIN: Повний розклад занять із викладачами та аудиторіями
-- Мета: сформувати деталізовану сітку розкладу для студентського кабінету.
-- ---------------------------------------------------------------------
SELECT 
    sc.day_of_week,
    sc.start_time,
    sc.end_time,
    c.code AS course_code,
    c.title AS course_title,
    r.number AS room_number,
    t.last_name || ' ' || t.first_name AS teacher_name
FROM schedule sc
INNER JOIN course c ON sc.course_id = c.course_id
INNER JOIN room r ON sc.room_id = r.room_id
INNER JOIN teacher t ON c.teacher_id = t.teacher_id
ORDER BY 
    CASE sc.day_of_week
        WHEN 'Mon' THEN 1
        WHEN 'Tue' THEN 2
        WHEN 'Wed' THEN 3
        WHEN 'Thu' THEN 4
        WHEN 'Fri' THEN 5
        WHEN 'Sat' THEN 6
        ELSE 7
    END, 
    sc.start_time;


-- ---------------------------------------------------------------------
-- JN-02. LEFT JOIN: Аналіз активності кафедр у створенні курсів
-- Мета: знайти кафедри-«пасивісти», які не пропонують жодного навчального курсу.
-- ---------------------------------------------------------------------
SELECT 
    d.code AS department_code,
    d.name AS department_name,
    COUNT(c.course_id) AS courses_count
FROM department d
LEFT JOIN course c ON d.department_id = c.department_id
GROUP BY d.department_id, d.code, d.name
ORDER BY courses_count ASC;


-- ---------------------------------------------------------------------
-- JN-03. FULL OUTER JOIN: Співставлення курсів та записів у розкладі
-- Мета: знайти «забуті» курси, для яких немає пар, та записи розкладу без курсів.
-- ---------------------------------------------------------------------
SELECT 
    c.course_id,
    c.code AS course_code,
    c.title AS course_title,
    sc.schedule_id,
    sc.day_of_week,
    sc.start_time
FROM course c
FULL OUTER JOIN schedule sc ON c.course_id = sc.course_id
ORDER BY c.course_id, sc.schedule_id;


-- =====================================================================
-- ГРУПА В: ПІДЗАПИТИ (SUBQUERIES) (Мінімум 3 запити за ТЗ)
-- =====================================================================

-- ---------------------------------------------------------------------
-- SQ-01. Підзапит у WHERE: Студенти з оцінками вище середнього показника по ВНЗ
-- Мета: знайти академічну еліту університету.
-- ---------------------------------------------------------------------
SELECT 
    s.student_id,
    s.last_name || ' ' || s.first_name AS student_name,
    c.title AS course_title,
    e.grade
FROM enrollment e
JOIN student s ON e.student_id = s.student_id
JOIN course c ON e.course_id = c.course_id
WHERE e.status = 'completed'
  AND e.grade > (
      SELECT AVG(grade) 
      FROM enrollment 
      WHERE status = 'completed'
  )
ORDER BY e.grade DESC;


-- ---------------------------------------------------------------------
-- SQ-02. Підзапит у SELECT: Перелік курсів із динамічним підрахунком реєстрацій
-- Мета: вивести загальну інформацію про предмети разом з показником популярності.
-- ---------------------------------------------------------------------
SELECT 
    c.course_id,
    c.code AS course_code,
    c.title AS course_title,
    c.credits,
    (
        SELECT COUNT(*) 
        FROM enrollment e 
        WHERE e.course_id = c.course_id 
          AND e.status = 'active'
    ) AS active_enrollments_count
FROM course c
ORDER BY active_enrollments_count DESC, c.title;


-- ---------------------------------------------------------------------
-- SQ-03. Підзапит у HAVING: Кафедри, де кількість студентів вища за середню по вузу
-- Мета: виявити найбільш завантажені напрямки підготовки для оптимізації фінансування.
-- ---------------------------------------------------------------------
SELECT 
    d.code AS department_code,
    d.name AS department_name,
    COUNT(s.student_id) AS student_count
FROM department d
JOIN student s ON d.department_id = s.department_id
GROUP BY d.department_id, d.code, d.name
HAVING COUNT(s.student_id) > (
    -- Підзапит рахує середню кількість студентів на одну кафедру серед усіх наявних кафедр
    SELECT AVG(dept_student_count)
    FROM (
        SELECT COUNT(student_id) AS dept_student_count
        FROM department dept
        LEFT JOIN student stud ON dept.department_id = stud.department_id
        GROUP BY dept.department_id
    ) AS sub
)
ORDER BY student_count DESC;