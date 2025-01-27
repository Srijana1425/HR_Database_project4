/*Create a DDL and DML SQL script capable of building the database I designed in the ERD*/	
	
CREATE TABLE Employee (
	emp_id CHARACTER VARYING(8) PRIMARY KEY,
	emp_nm CHARACTER VARYING(50),
	email CHARACTER VARYING(100),
	hire_dt DATE);


INSERT INTO Employee(emp_id, emp_nm, email, hire_dt)
SELECT DISTINCT emp_id, emp_nm, email, hire_dt FROM proj_stg;

			
CREATE TABLE Job (
	job_id SERIAL PRIMARY KEY,
	job_title CHARACTER VARYING(100));
			
INSERT INTO Job(job_title)
SELECT DISTINCT job_title FROM proj_stg;


CREATE TABLE Department (
	department_id SERIAL PRIMARY KEY,
	department_nm CHARACTER VARYING(50));
		
INSERT INTO Department(department_nm) 
SELECT DISTINCT department_nm FROM proj_stg;
			
CREATE TABLE Salary (
	salary_id SERIAL PRIMARY KEY,
	salary INTEGER);
			
INSERT INTO Salary(salary)
SELECT salary FROM proj_stg;

CREATE TABLE Location (
	location_id SERIAL PRIMARY KEY,
	location CHARACTER VARYING(50),
	state CHARACTER VARYING(2),
	city CHARACTER VARYING(50),
	address CHARACTER VARYING(100));
		
INSERT INTO Location(location, state, city, address)
SELECT DISTINCT location, state, city, address FROM proj_stg;

CREATE TABLE education_level (
	ed_id SERIAL PRIMARY KEY,
	education_level CHARACTER VARYING(50));
		
INSERT INTO education_level(education_level)
SELECT DISTINCT education_lvl FROM proj_stg;

CREATE TABLE Employment (
	emp_id CHARACTER VARYING(8), 
	location_id INTEGER, 
	department_id INTEGER, 
	salary_id INTEGER, 
	ed_id INTEGER, 
	job_id INTEGER,
	manager_id CHARACTER VARYING(8),
	start_dt DATE, 
	end_dt DATE);
	


CREATE VIEW manager 
AS SELECT a.emp_id AS manager_id, 
ps.manager AS manager_name
FROM proj_stg AS ps 
FULL JOIN (SELECT DISTINCT emp_id, emp_nm FROM proj_stg
WHERE emp_nm IN (SELECT DISTINCT manager FROM proj_stg)) AS a
ON ps.manager=a.emp_nm;


INSERT INTO Employment(emp_id, location_id, department_id, salary_id, ed_id, job_id, manager_id, start_dt, end_dt)
SELECT DISTINCT e.emp_id, l.location_id, d.department_id, s.salary_id, x.ed_id, j.job_id,m.manager_id, ps.start_dt, ps.end_dt
	FROM proj_stg AS ps
	JOIN employee AS e
	ON e.emp_id = ps.emp_id
	JOIN location AS l
	ON l.location = ps.location
	JOIN department AS d
	ON ps.department_nm = d.department_nm
	JOIN salary AS s
	ON s.salary = ps.salary
	JOIN education_level AS x
	ON x.education_level = ps.education_lvl
	JOIN job AS j 
	ON j.job_title = ps.job_title
	JOIN manager AS m
	ON ps.manager = m.manager_name;


		
ALTER TABLE Employment ADD FOREIGN KEY (emp_id) REFERENCES Employee(emp_id);
ALTER TABLE Employment ADD FOREIGN KEY (location_id) REFERENCES location(location_id);
ALTER TABLE Employment ADD FOREIGN KEY (ed_id) REFERENCES education_level(ed_id);
ALTER TABLE Employment ADD FOREIGN KEY (job_id) REFERENCES job(job_id);
ALTER TABLE Employment ADD FOREIGN KEY (department_id) REFERENCES department(department_id);
ALTER TABLE Employment ADD FOREIGN KEY (salary_id) REFERENCES salary(salary_id);
ALTER TABLE Employment ADD FOREIGN KEY (manager_id) REFERENCES Employee(emp_id);



--CRUD------------------
	
/*Question 1: Return a list of employees with Job Titles and Department Names*/
	
SELECT e.emp_id, j.job_title, d.department_nm
	FROM employee AS e
	JOIN employment AS em
	ON e.emp_id = em.emp_id
	JOIN job AS j
	ON j.job_id = em.job_id
	JOIN department AS d
	ON d.department_id = em.department_id;


/*Question 2: Insert Web Programmer as a new job title*/

INSERT INTO job(job_title) VALUES ('Web Programmer');
SELECT * FROM job;

/*Question 3: Correct the job title from web programmer to web developer*/

UPDATE job SET job_title='Web Developer' WHERE job_title='Web Programmer';
SELECT * FROM job;

/*Question 4: Delete the job title Web Developer from the database*/

DELETE FROM job WHERE job_title='Web Developer';
SELECT * FROM job;

/*Question 5: How many employees are in each department?*/


SELECT d.department_nm, COUNT(e.emp_id)
	FROM department AS d
	JOIN employment AS em
	ON d.department_id = em.department_id
	JOIN employee AS e
	ON e.emp_id = em.emp_id
	GROUP BY d.department_nm;


/*Question 6: Write a query that returns current and past jobs (include employee name, job title, department, manager name, start and end date for position) for employee Toni Lembeck.*/

WITH sub AS (SELECT DISTINCT emp.emp_id AS manager_id, emp.emp_nm AS manager 
FROM employee AS emp
JOIN employment AS empl 
ON emp.emp_id = empl.manager_id)

SELECT DISTINCT e.emp_nm, j.job_title, d.department_nm, s.manager, em.start_dt, em.end_dt
	FROM employee AS e
	JOIN employment AS em
	ON e.emp_id = em.emp_id
	JOIN department AS d
	ON d.department_id = em.department_id
	JOIN sub AS s 
	ON s.manager_id = em.manager_id
	JOIN job AS j
	ON j.job_id = em.job_id
	WHERE e.emp_nm = 'Toni Lembeck';
	
------- STEP 4 Above and Beyond (OPTIONAL)-----

/*create a view table that returns all the attributes of the inistial excel file*/


CREATE VIEW Employeefullinfoview AS SELECT e.emp_id,
	e.emp_nm,
	e.email,
	e.hire_dt,
	j.job_title,
	s.salary,
	d.department_nm,
	sub.manager,
	em.start_dt,
	em.end_dt,
	l.location,
	l.address,
	l.city,
	l.state,
	edu.education_level
FROM employee AS e
JOIN employment AS em
ON e.emp_id = em.emp_id
JOIN salary AS s
ON s.salary_id = em.salary_id
JOIN location AS l
ON l.location_id = em.location_id
JOIN (SELECT DISTINCT emp.emp_id AS manager_id, emp.emp_nm AS manager 
FROM employee AS emp 
JOIN employment AS empl
ON emp.emp_id = empl.manager_id) AS sub 
ON sub.manager_id = em.manager_id
JOIN job AS j
ON j.job_id= j.job_id
JOIN department AS d
ON d.department_id=em.department_id
JOIN education_level AS edu
ON edu.ed_id = em.ed_id;

SELECT * FROM  Employeefullinfoview;
	
/*Create a stored procedure*/
CREATE OR REPLACE FUNCTION employee_info(empName CHARACTER VARYING)
RETURNS TABLE (
    emp_nm CHARACTER VARYING,
    job_title CHARACTER VARYING,
    department_nm CHARACTER VARYING,
    manager CHARACTER VARYING,
    start_dt DATE,
    end_dt DATE
)
LANGUAGE SQL
AS $BODY$
    SELECT 
        emp_nm, 
        job_title, 
        department_nm, 
        manager, 
        start_dt, 
        end_dt
    FROM 
        proj_stg
    WHERE 
        emp_nm = empName;
$BODY$;
SELECT * FROM employee_info('Toni Lembeck');

/* create user and privileges*/
	
-- Step 1: Create the NoMgr user with a password
CREATE USER NoMgr WITH PASSWORD 'password@123';

-- Step 2: Grant SELECT access to the necessary tables
GRANT SELECT ON Employee TO NoMgr;
GRANT SELECT ON Department TO NoMgr;
GRANT SELECT ON Location TO NoMgr;

-- Step 3: Revoke access to the salary table
REVOKE SELECT ON Salary FROM NoMgr;


