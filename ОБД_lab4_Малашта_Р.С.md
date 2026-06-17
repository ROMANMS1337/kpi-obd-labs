Національний технічний університет України

«Київський політехнічний інститут»

Факультет інформатики та обчислювальної техніки

Кафедра обчислювальної техніки

ОРГАНВЗАЦІЯ БАЗ ДАНИХ

**Лабораторна робота №4**

« Аналітичні SQL-запити (OLAP) ».

Виконав:

студент групи ІО-з41

*Малашта Р. С.*

Залікова книжка № IO-4108

Перевірив

Київ-2026

### 1. Вступ

Цей аналітичний звіт містить 21 комплексний OLAP-запит до бази даних системи реєстрації студентів. На відміну від оперативних транзакцій (OLTP), аналітичні запити спрямовані на агрегацію великих масивів інформації, обчислення узагальненої статистики та пошук складних взаємозв'язків у структурі даних університету.

**База даних містить 8 основних таблиць:**

* faculty (факультети)
* department (кафедри)
* teacher (викладачі)
* student (студенти)
* course (курси)
* room (аудиторії)
* enrollment (реєстрації на курси)
* schedule (розклад занять)

### 2. РОЗДІЛ 1: Агрегаційні запити (GROUP BY, HAVING)

#### A-01. Загальна кількість студентів, викладачів та курсів

* **Мета запиту:** Сформувати базову кількісну метрику наповненості бази даних для швидкого аудиту системи одним запитом.
* **Логіка роботи:** Запит використовує агрегатну функцію COUNT(\*) окремо для кожної з чотирьох основних таблиць (student, teacher, course, enrollment) та об'єднує результати в єдину результуючу таблицю за допомогою оператора UNION ALL.
* **Очікуваний результат:** Таблиця з 4 рядків, що відображає актуальну кількість записів по кожній категорії.

SELECT 'Студентів' AS категорія, COUNT(\*) AS кількість FROM student
UNION ALL
SELECT 'Викладачів', COUNT(\*) FROM teacher
UNION ALL
SELECT 'Курсів', COUNT(\*) FROM course
UNION ALL
SELECT 'Реєстрацій', COUNT(\*) FROM enrollment;

#### A-02. Кількість студентів на кожній кафедрі

* **Мета запиту:** Визначити демографічний розподіл студентського контингенту за кафедрами.
* **Логіка роботи:** Запит виконує LEFT JOIN між таблицями department (ліва) та student (права). Групування відбувається за унікальними полями кафедри (department\_id, code, name). Функція COUNT(s.student\_id) підраховує кількість студентів. Використання LEFT JOIN гарантує, що кафедри без студентів також виведуться в списку зі значенням 0.
* **Очікуваний результат:** Список усіх кафедр із кількістю студентів, відсортований від найбільш чисельних до найменших.

SELECT
 d.code AS код\_кафедри,
 d.name AS назва\_кафедри,
 COUNT(s.student\_id) AS кількість\_студентів
FROM department d
LEFT JOIN student s ON s.department\_id = d.department\_id
GROUP BY d.department\_id, d.code, d.name
ORDER BY кількість\_студентів DESC;

#### A-03. Середня, мінімальна та максимальна оцінка по кожному курсу

* **Мета запиту:** Оцінити академічну складність навчальних дисциплін та успішність студентів.
* **Логіка роботи:** Виконує об'єднання таблиці course з таблицею реєстрацій enrollment за умовою, що статус курсу завершений (status = 'completed'). Обчислює загальну кількість оцінок (COUNT), середнє значення (AVG), мінімальний (MIN) та максимальний (MAX) бали для кожного курсу окремо через GROUP BY.
* **Очікуваний результат:** Статистична відомість по предметах, де виставлені оцінки, впорядкована за спаданням середнього балу.

SELECT
 c.code AS код\_курсу,
 c.title AS назва\_курсу,
 COUNT(e.enrollment\_id) AS кількість\_оцінок,
 ROUND(AVG(e.grade), 2) AS середня\_оцінка,
 MIN(e.grade) AS мінімальна,
 MAX(e.grade) AS максимальна
FROM course c
LEFT JOIN enrollment e ON e.course\_id = c.course\_id
 AND e.status = 'completed'
GROUP BY c.course\_id, c.code, c.title
ORDER BY середня\_оцінка DESC NULLS LAST;

#### A-04. Кількість курсів за кафедрою та середня кількість кредитів

* **Мета запиту:** Проаналізувати дидактичне навантаження та середню тривалість курсів (у кредитах ECTS) у розрізі кафедр.
* **Логіка роботи:** Об'єднує таблиці department та course через LEFT JOIN, групує дані за кафедрою та розраховує кількість закріплених курсів (COUNT), середній бал за кредитами (AVG) та сумарну кількість кредитів (SUM).
* **Очікуваний результат:** Аналітичний звіт щодо навчальних планів кафедр.

SELECT
 d.code AS код\_кафедри,
 d.name AS назва\_кафедри,
 COUNT(c.course\_id) AS кількість\_курсів,
 ROUND(AVG(c.credits), 1) AS середні\_кредити,
 SUM(c.credits) AS сума\_кредитів
FROM department d
LEFT JOIN course c ON c.department\_id = d.department\_id
GROUP BY d.department\_id, d.code, d.name
ORDER BY кількість\_курсів DESC;

#### A-05. Кафедри, де середня оцінка студентів вище 80 (HAVING)

* **Мета запиту:** Визначити академічно найуспішніші кафедри за підсумками завершених дисциплін.
* **Логіка роботи:** Послідовно з'єднує таблиці department → student → enrollment. Фільтрує реєстрації за статусом completed. Групує результати за кафедрами й за допомогою умови HAVING AVG(e.grade) > 80 відсікає підрозділи з нижчою середньою успішністю.
* **Очікуваний результат:** Список кафедр-лідерів із високим середнім балом студентів.

SELECT
 d.code AS код\_кафедри,
 d.name AS назва\_кафедри,
 COUNT(e.grade) AS кількість\_оцінок,
 ROUND(AVG(e.grade), 2) AS середня\_оцінка
FROM department d
JOIN student s ON s.department\_id = d.department\_id
JOIN enrollment e ON e.student\_id = s.student\_id
 AND e.status = 'completed'
GROUP BY d.department\_id, d.code, d.name
HAVING AVG(e.grade) > 80
ORDER BY середня\_оцінка DESC;

#### A-06. Курси з більш ніж 2 активними реєстраціями (HAVING + COUNT)

* **Мета запиту:** Виявити найбільш затребувані або масові курси в поточному семестрі.
* **Логіка роботи:** Об'єднує таблиці course та enrollment за умови status = 'active'. Групує за курсами й через HAVING COUNT(e.enrollment\_id) > 2 залишає в списку лише ті дисципліни, де зараз навчається більше двох студентів.
* **Очікуваний результат:** Список найпопулярніших активних курсів.

SELECT
 c.code AS код\_курсу,
 c.title AS назва\_курсу,
 COUNT(e.enrollment\_id) AS активних\_студентів
FROM course c
JOIN enrollment e ON e.course\_id = c.course\_id
 AND e.status = 'active'
GROUP BY c.course\_id, c.code, c.title
HAVING COUNT(e.enrollment\_id) > 2
ORDER BY активних\_студентів DESC;

#### A-07. Навантаження викладачів: кількість курсів та загальна кількість студентів

* **Мета запиту:** Оцінити трудомісткість роботи кожного викладача та структуру його взаємодії зі студентами.
* **Логіка роботи:** Поєднує таблиці teacher → course → enrollment. Використовує COUNT(DISTINCT c.course\_id) для точного підрахунку унікальних курсів, які читає викладач. Також рахує сумарну кількість реєстрацій (COUNT), окремо виділяючи активні та завершені за допомогою умовної агрегації COUNT(CASE WHEN...).
* **Очікуваний результат:** Сводна таблиця робочого навантаження викладачів.

SELECT
 t.last\_name || ' ' || t.first\_name AS викладач,
 t.position AS посада,
 COUNT(DISTINCT c.course\_id) AS кількість\_курсів,
 COUNT(e.enrollment\_id) AS загально\_реєстрацій,
 COUNT(CASE WHEN e.status = 'active' THEN 1 END) AS активних,
 COUNT(CASE WHEN e.status = 'completed' THEN 1 END) AS завершених
FROM teacher t
LEFT JOIN course c ON c.teacher\_id = t.teacher\_id
LEFT JOIN enrollment e ON e.course\_id = c.course\_id
GROUP BY t.teacher\_id, t.last\_name, t.first\_name, t.position
ORDER BY кількість\_курсів DESC, загально\_реєстрацій DESC;

### 3. РОЗДІЛ 2: Запити з JOIN

#### J-01. INNER JOIN: Повна інформація про реєстрації

* **Мета:** Сформувати детальну інформаційну виписку про реєстрації для адміністративного контролю.
* **Логіка роботи:** Поєднує таблицю реєстрацій enrollment із сутностями student та course за допомогою класичного INNER JOIN. У вибірку потрапляють лише ті записи, де є повна відповідність між усіма таблицями.
* **Очікуваний результат:** Список студентів із назвами курсів, датами реєстрацій, статусами та оцінками.

SELECT
 s.student\_id,
 s.last\_name || ' ' || s.first\_name AS студент,
 c.code AS код\_курсу,
 c.title AS курс,
 c.credits AS кредити,
 e.enrolled\_at AS дата\_реєстрації,
 e.status AS статус,
 e.grade AS оцінка
FROM enrollment e
INNER JOIN student s ON s.student\_id = e.student\_id
INNER JOIN course c ON c.course\_id = e.course\_id
ORDER BY s.last\_name, c.code;

#### J-02. LEFT JOIN: Усі курси та їх розклад

* **Мета:** Проконтролювати планування занять та виявити курси, які ще не мають розкладу або аудиторій.
* **Логіка роботи:** Використовує послідовні LEFT JOIN від таблиці course до schedule та room. Це гарантує, що у фінальну вибірку потраплять абсолютно всі курси університету. Якщо для дисципліни немає занять у розкладі, відповідні поля аудиторії та часу будуть заповнені значеннями NULL.
* **Очікуваний результат:** Повний каталог курсів із детальним розкладом або порожніми полями планування занять.
* порожніми полями планування занять.

SELECT
 c.code AS код\_курсу,
 c.title AS курс,
 c.semester AS семестр,
 sc.day\_of\_week AS день,
 sc.start\_time AS початок,
 sc.end\_time AS кінець,
 r.number AS аудиторія,
 r.type AS тип\_аудиторії,
 r.capacity AS місць
FROM course c
LEFT JOIN schedule sc ON sc.course\_id = c.course\_id
LEFT JOIN room r ON r.room\_id = sc.room\_id
ORDER BY c.semester, c.code, sc.day\_of\_week, sc.start\_time;

#### J-03. RIGHT JOIN: Усі аудиторії та їх використання в розкладі

* **Мета:** Проаналізувати ефективність використання аудиторного фонду та знайти порожні кабінети.
* **Логіка роботи:** Запит використовує RIGHT JOIN між schedule та room. Це гарантує виведення абсолютно всіх кабінетів з таблиці room. Для аудиторій, де занять немає, поля розкладу (day\_of\_week, start\_time) та назви курсу будуть містити NULL.
* **Очікуваний результат:** Список аудиторій із прив'язаними до них парами або помітками про відсутність занять.

SELECT
 r.number AS аудиторія,
 r.type AS тип,
 r.capacity AS місць,
 sc.day\_of\_week AS день,
 sc.start\_time AS початок,
 c.title AS курс
FROM schedule sc
RIGHT JOIN room r ON r.room\_id = sc.room\_id
LEFT JOIN course c ON c.course\_id = sc.course\_id
ORDER BY r.number, sc.day\_of\_week, sc.start\_time;

#### J-04. FULL OUTER JOIN: Студенти та їх реєстрації

* **Мета:** Виявити дві протилежні аномалії цілісності даних: студентів, які не записалися на жоден курс, та можливі реєстрації, які втратили прив'язку до дійсних студентів.
* **Логіка роботи:** Поєднує таблиці student та enrollment через FULL OUTER JOIN. Механізм зберігає в результатах записи з обох таблиць, навіть якщо для них немає пари за критерієм student\_id.
* **Очікуваний результат:** Таблиця відповідності студентів та реєстрацій, де наявність NULL з будь-якої сторони вказує на відсутність взаємозв'язку.
* наявність NULL з будь-якої сторони вказує на відсутність взаємозв'язку.

SELECT
 s.student\_id,
 s.last\_name || ' ' || s.first\_name AS студент,
 e.enrollment\_id,
 e.status,
 e.grade
FROM student s
FULL OUTER JOIN enrollment e ON e.student\_id = s.student\_id
ORDER BY s.student\_id NULLS LAST, e.enrollment\_id;

#### J-05. Чотиритаблична агрегація: Повний розклад з усіма деталями

* **Мета:** Сформувати єдиний, детальний звіт з розкладу занять для студентського порталу.
* **Логіка роботи:** Запит послідовно поєднує п'ять таблиць через INNER JOIN: schedule → course → teacher → room → department. Додатково використано сортування днів тижня за логічним порядком через конструкцію CASE (від понеділка до суботи).
* **Очікуваний результат:** Хронологічний та логічний розклад занять університету з усіма супутніми даними.

SELECT
 sc.day\_of\_week AS день,
 sc.start\_time AS початок,
 sc.end\_time AS кінець,
 c.code AS код\_курсу,
 c.title AS курс,
 c.credits AS кредити,
 t.last\_name || ' ' || t.first\_name AS викладач,
 t.position AS посада,
 r.number AS аудиторія,
 r.type AS тип\_аудиторії,
 r.capacity AS місць,
 d.code AS кафедра
FROM schedule sc
INNER JOIN course c ON c.course\_id = sc.course\_id
INNER JOIN teacher t ON t.teacher\_id = c.teacher\_id
INNER JOIN room r ON r.room\_id = sc.room\_id
INNER JOIN department d ON d.department\_id = c.department\_id
ORDER BY
 CASE sc.day\_of\_week
 WHEN 'Mon' THEN 1 WHEN 'Tue' THEN 2 WHEN 'Wed' THEN 3
 WHEN 'Thu' THEN 4 WHEN 'Fri' THEN 5 WHEN 'Sat' THEN 6
 END,
 sc.start\_time;

#### J-06. CROSS JOIN: Матриця «студент × курс» (теоретичні можливості реєстрації)

* **Мета:** Проаналізувати теоретичну матрицю можливих реєстрацій студентів на всі курси ВНЗ та визначити їхній статус.
* **Логіка роботи:** Виконує перехресне множення (CROSS JOIN) таблиць student та course. Після цього робиться LEFT JOIN до enrollment для перевірки наявності реального зв'язку та виводиться текстовий статус через оператор CASE.
* **Очікуваний результат:** Матриця можливостей реєстрації для планування майбутніх потоків студентів.

SELECT
 s.last\_name || ' ' || s.first\_name AS студент,
 c.code AS код\_курсу,
 c.title AS курс,
 CASE WHEN e.enrollment\_id IS NOT NULL THEN 'Зареєстрований'
 ELSE 'Не зареєстрований'
 END AS статус\_реєстрації
FROM student s
CROSS JOIN course c
LEFT JOIN enrollment e ON e.student\_id = s.student\_id
 AND e.course\_id = c.course\_id
ORDER BY s.last\_name, c.code;

### 4. РОЗДІЛ 3: Запити з підзапитами

#### P-01. Підзапит у WHERE: Студенти з оцінками вище середнього показника

* **Мета:** Знайти студентів-відмінників, які отримали за конкретний курс бал, що перевищує середній бал усіх завершених реєстрацій в університеті.
* **Логіка роботи:** У секції WHERE використовується некорельований підзапит SELECT AVG(grade) FROM enrollment WHERE status = 'completed'. Основний запит фільтрує результати, порівнюючи оцінку кожного студента з цим числом.
* **Очікуваний результат:** Список студентів та їхніх контактів.

SELECT
 s.student\_id,
 s.last\_name || ' ' || s.first\_name AS студент,
 s.email
FROM student s
WHERE s.student\_id IN (
 SELECT e.student\_id
 FROM enrollment e
 WHERE e.status = 'completed'
 AND e.grade > (
 SELECT AVG(grade)
 FROM enrollment
 WHERE status = 'completed'
 )
)
ORDER BY s.last\_name;

#### P-02. Підзапит у SELECT: Кількість активних реєстрацій для кожного студента

* **Мета:** Розрахувати завантаження студентів без використання групувань GROUP BY у головній секції запиту.
* **Логіка роботи:** Для кожного рядка студента в основному запиті запускаються два незалежні підзапити в секції SELECT, які обчислюють кількість активних (status = 'active') та загальну кількість реєстрацій студента.
* **Очікуваний результат:** Список студентів із зазначенням їхнього поточного завантаження.

SELECT
 s.student\_id,
 s.last\_name || ' ' || s.first\_name AS студент,
 (SELECT COUNT(\*)
 FROM enrollment e
 WHERE e.student\_id = s.student\_id
 AND e.status = 'active') AS активних\_реєстрацій,
 (SELECT COUNT(\*)
 FROM enrollment e
 WHERE e.student\_id = s.student\_id) AS всього\_реєстрацій
FROM student s
ORDER BY активних\_реєстрацій DESC, s.last\_name;

#### P-03. Підзапит у HAVING: Кафедри, де середня оцінка вища за загальну середню

* **Мета:** Порівняти якість навчання на кожній кафедрі з загальноуніверситетським рівнем.
* **Логіка роботи:** Запит групує дані за кафедрами. У секції HAVING значення середньої оцінки кафедри AVG(e.grade) порівнюється з результатом підзапиту, який вираховує загальну середню оцінку серед усіх оцінок у базі.
* **Очікуваний результат:** Список успішних кафедр із середнім балом вище норми.

SELECT
 d.code AS код\_кафедри,
 d.name AS назва\_кафедри,
 ROUND(AVG(e.grade), 2) AS середня\_оцінка\_кафедри
FROM department d
JOIN student s ON s.department\_id = d.department\_id
JOIN enrollment e ON e.student\_id = s.student\_id
 AND e.status = 'completed'
GROUP BY d.department\_id, d.code, d.name
HAVING AVG(e.grade) > (
 SELECT AVG(grade)
 FROM enrollment
 WHERE status = 'completed'
)
ORDER BY середня\_оцінка\_кафедри DESC;

#### P-04. Підзапит у FROM (похідна таблиця): Рейтинг студентів за середньою оцінкою

* **Мета:** Побудувати рейтинговий список студентів на основі їхнього середнього балу.
* **Логіка роботи:** Підзапит у секції FROM формує тимчасову похідну таблицю ranked, де обчислюється середній бал та кількість курсів для кожного студента. Головний запит бере ці готові дані та застосовує аналітичну віконну функцію RANK() OVER (ORDER BY average\_grade DESC).
* **Очікуваний результат:** Упорядкована рейтингова таблиця студентів.

SELECT
 ranked.student\_id,
 ranked.студент,
 ranked.середня\_оцінка,
 ranked.кількість\_курсів,
 RANK() OVER (ORDER BY ranked.середня\_оцінка DESC) AS рейтинг
FROM (
 SELECT
 s.student\_id,
 s.last\_name || ' ' || s.first\_name AS студент,
 ROUND(AVG(e.grade), 2) AS середня\_оцінка,
 COUNT(e.enrollment\_id) AS кількість\_курсів
 FROM student s
 JOIN enrollment e ON e.student\_id = s.student\_id
 AND e.status = 'completed'
 GROUP BY s.student\_id, s.last\_name, s.first\_name
) AS ranked
ORDER BY рейтинг;

#### P-05. Підзапит EXISTS: Курси, на які є хоча б 1 активна реєстрація

* **Мета:** Швидко відібрати предмети, які реально викладаються в поточному семестрі.
* **Логіка роботи:** Використовує швидкий оператор EXISTS. Для кожного курсу підзапит перевіряє наявність хоча б одного запису в enrollment зі статусом active.
* **Очікуваний результат:** Список активних навчальних дисциплін.

SELECT
 c.course\_id,
 c.code,
 c.title,
 c.credits,
 c.semester
FROM course c
WHERE EXISTS (
 SELECT 1
 FROM enrollment e
 WHERE e.course\_id = c.course\_id
 AND e.status = 'active'
)
ORDER BY c.semester, c.code;

#### P-06. Підзапит NOT EXISTS: Курси без жодного запису в розкладі

* **Мета:** Провести аудит розкладу та знайти курси, які були додані до програми, але не мають занять у розкладі.
* **Логіка роботи:** Використовує оператор NOT EXISTS. Підзапит шукає зв'язок між курсом та таблицею schedule. Якщо збігів не знайдено, курс виводиться в фінальному списку.
* **Очікуваний результат:** Перелік курсів, які не мають занять у сітці розкладу.

SELECT
 c.code,
 c.title,
 c.semester,
 d.name AS кафедра
FROM course c
JOIN department d ON d.department\_id = c.department\_id
WHERE NOT EXISTS (
 SELECT 1
 FROM schedule sc
 WHERE sc.course\_id = c.course\_id
)
ORDER BY c.semester, c.code;

### 5. РОЗДІЛ 4: Комбіновані аналітичні запити

SELECT
 f.code AS факультет,
 f.name AS назва\_факультету,
 COUNT(DISTINCT d.department\_id) AS кафедр,
 COUNT(DISTINCT s.student\_id) AS студентів,
 COUNT(DISTINCT c.course\_id) AS курсів,
 COUNT(DISTINCT t.teacher\_id) AS викладачів,
 ROUND(AVG(e.grade), 2) AS середня\_оцінка
FROM faculty f
LEFT JOIN department d ON d.faculty\_id = f.faculty\_id
LEFT JOIN student s ON s.department\_id = d.department\_id
LEFT JOIN course c ON c.department\_id = d.department\_id
LEFT JOIN teacher t ON t.department\_id = d.department\_id
LEFT JOIN enrollment e ON e.student\_id = s.student\_id
 AND e.status = 'completed'
GROUP BY f.faculty\_id, f.code, f.name
ORDER BY студентів DESC;

#### C-02. Топ-3 курси за кількістю реєстрацій

SELECT
 c.code,
 c.title,
 c.credits,
 t.last\_name || ' ' || t.first\_name AS викладач,
 d.name AS кафедра,
 COUNT(e.enrollment\_id) AS всього\_реєстрацій,
 COUNT(CASE WHEN e.status = 'active' THEN 1 END) AS активних,
 COUNT(CASE WHEN e.status = 'completed' THEN 1 END) AS завершених,
 COUNT(CASE WHEN e.status = 'dropped' THEN 1 END) AS відрахованих
FROM course c
JOIN teacher t ON t.teacher\_id = c.teacher\_id
JOIN department d ON d.department\_id = c.department\_id
LEFT JOIN enrollment e ON e.course\_id = c.course\_id
GROUP BY c.course\_id, c.code, c.title, c.credits,
 t.last\_name, t.first\_name, d.name
ORDER BY всього\_реєстрацій DESC
LIMIT 3;

#### C-03. Розподіл оцінок за буквеною шкалою ECTS

SELECT
 CASE
 WHEN e.grade >= 90 THEN 'A (90–100)'
 WHEN e.grade >= 75 THEN 'B (75–89)'
 WHEN e.grade >= 60 THEN 'C (60–74)'
 WHEN e.grade >= 50 THEN 'D (50–59)'
 ELSE 'F (0–49)'
 END AS літерна\_оцінка,
 COUNT(\*) AS кількість,
 ROUND(COUNT(\*) \* 100.0 /
 SUM(COUNT(\*)) OVER (), 1) AS відсоток
FROM enrollment e
WHERE e.status = 'completed'
 AND e.grade IS NOT NULL
GROUP BY
 CASE
 WHEN e.grade >= 90 THEN 'A (90–100)'
 WHEN e.grade >= 75 THEN 'B (75–89)'
 WHEN e.grade >= 60 THEN 'C (60–74)'
 WHEN e.grade >= 50 THEN 'D (50–59)'
 ELSE 'F (0–49)'
 END
ORDER BY літерна\_оцінка;

#### C-04. Завантаженість аудиторій

SELECT
 r.number AS аудиторія,
 r.type AS тип,
 r.capacity AS місць,
 COUNT(sc.schedule\_id) AS пар\_на\_тиждень,
 ROUND(COUNT(sc.schedule\_id) \* 100.0 /
 NULLIF((SELECT COUNT(\*) FROM schedule), 0), 1) AS відсоток\_від\_усіх\_пар
FROM room r
LEFT JOIN schedule sc ON sc.room\_id = r.room\_id
GROUP BY r.room\_id, r.number, r.type, r.capacity
ORDER BY пар\_на\_тиждень DESC;

### 5. Фінальний стан таблиць та підтвердження тестування

Після успішного виконання твого повного аналітичного скрипту в pgAdmin, усі OLAP-запити відпрацювали без жодної помилки.

**Доказ успішного виконання запитів та цілісності даних (знімок екрану pgAdmin):**

*Малюнок 4. Результат підрахунку кількості рядків у базі даних після успішного виконання транзакцій.*

#### Порівняльна таблиця структури бази даних

| **Таблиця** | **Обсяг після Лаб. 2** | **Обсяг після Лаб. 3** | **Характер аналітичних змін** |
| --- | --- | --- | --- |
| **faculty** | 3 | 4 | Додався новий аналітичний факультет ФММ |
| **department** | 5 | 6 | Створено кафедру інформаційної безпеки «ІБ» |
| **teacher** | 5 | 6 | Зареєстровано нового доцента кафедри ІБ |
| **student** | 6 | 6 | Тимчасовий баланс за рахунок видалення студента №7 |
| **course** | 6 | 7 | Новий аналітичний курс «Основи кібербезпеки» |
| **room** | 5 | 5 | Тимчасовий баланс за рахунок видалення кабінету №6 |
| **enrollment** | 12 | 11 | Зміна кількості через каскадне видалення студента №7 |
| **schedule** | 8 | 7 | Поточна кількість запланованих занять у розкладі |