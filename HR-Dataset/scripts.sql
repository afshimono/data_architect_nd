--Drop if Exists
DROP TABLE IF EXISTS EmployeeJob;
DROP TABLE IF EXISTS Employee;
DROP TABLE IF EXISTS Job;
DROP TABLE IF EXISTS Department;
DROP TABLE IF EXISTS Address;
DROP TABLE IF EXISTS Location;
DROP TABLE IF EXISTS City;
DROP TABLE IF EXISTS State;
DROP TABLE IF EXISTS Salary;
DROP TABLE IF EXISTS Education;

CREATE TABLE Job (
	JobID SERIAL, 
	Title Varchar(100), 
	PRIMARY KEY(JobID));

CREATE TABLE Salary (
	SalaryID SERIAL, 
	Amount Decimal, 
	PRIMARY KEY(SalaryID));

CREATE TABLE Education (
	EducationID SERIAL, 
	Title Varchar(100), 
	PRIMARY KEY(EducationID));

CREATE TABLE Department (
	DepartmentID SERIAL, 
	Name Varchar(100), 
	PRIMARY KEY(DepartmentID));


CREATE TABLE State (
	StateID SERIAL, 
	State Varchar(100),  
	PRIMARY KEY (StateID));

CREATE TABLE City (
	CityID SERIAL, 
	City Varchar(100),  
	StateID Integer REFERENCES State (StateID) , 
	PRIMARY KEY (CityID));

CREATE TABLE Location (
	LocationID SERIAL, 
	Location Varchar(100), 
	CityID Integer REFERENCES City (CityID) ,
	PRIMARY KEY (LocationID));

CREATE TABLE Address (
	AddressID SERIAL,
	Address Varchar(200), 
	LocationID Integer REFERENCES Location (LocationID), 
	PRIMARY KEY (AddressID));

CREATE TABLE Employee (
	EmployeeID SERIAL, 
	OldId Varchar(10), 
	Name Varchar(100), 
	Email Varchar(50), 
	HireDate DATE, 
	JobID Integer REFERENCES Job (JobID), 
	SalaryID Integer REFERENCES Salary (SalaryID), 
	ManagerID Integer REFERENCES Employee (EmployeeID), 
	DepartmentID Integer REFERENCES Department(DepartmentID), 
	AddressID Integer REFERENCES Address (AddressID), 
	EducationID Integer REFERENCES Education (EducationID), 
	PRIMARY KEY(EmployeeID));

CREATE TABLE EmployeeJob (
	EmployeeID Integer REFERENCES Employee (EmployeeID),
	JobId Integer REFERENCES Job (JobId),
	StartDate DATE,
	EndDate DATE,
	PRIMARY KEY (EmployeeID,JobId))

--Import Data From STG
INSERT INTO Job(Title) 
SELECT DISTINCT job_title FROM proj_stg;

INSERT INTO Department( Name ) 
SELECT DISTINCT department_nm FROM proj_stg;

INSERT INTO Salary(Amount)
SELECT DISTINCT salary FROM proj_stg;

INSERT INTO Education(Title)
SELECT DISTINCT education_lvl FROM proj_stg;

INSERT INTO State(State)
SELECT DISTINCT  state FROM proj_stg;

INSERT INTO City( City, StateID)
SELECT DISTINCT p.city, s.StateID 
FROM proj_stg p JOIN State s ON p.state=s.State;

INSERT INTO Location( Location, CityID )
SELECT DISTINCT p.location, c.CityID 
FROM proj_stg p JOIN City c ON p.city=c.City;

INSERT INTO Address(Address, LocationID)
SELECT DISTINCT  p.address, l.LocationID 
FROM proj_stg p JOIN Location l ON p.location=l.Location;

INSERT INTO Employee( Name, Email, HireDate, SalaryID, DepartmentID, AddressID, EducationID)
SELECT DISTINCT p.Emp_NM, p.Email, p.hire_dt, sal.SalaryID, d.DepartmentID, a.AddressID, e.EducationID
FROM proj_stg p 
  JOIN Department d on p.department_nm=d.Name 
  JOIN Address a ON p.address=a.Address 
  JOIN City c ON p.city=c.City 
  JOIN State s ON p.state=s.State
  JOIN Salary sal ON p.salary=sal.Amount
  JOIN Education e on p.education_lvl=e.Title;

INSERT INTO EmployeeJob(EmployeeID, JobID,StartDate, EndDate)
SELECT e.EmployeeID, j.JobID, p.start_dt, p.end_dt
FROM proj_stg p
	JOIN Employee e ON p.Email = e.Email
	JOIN Job j ON p.job_title = j.Title;

UPDATE Employee 
SET ManagerID = subq.EmployeeID
FROM (SELECT  p.Email AS Email, e.EmployeeID AS EmployeeID
		FROM proj_stg p
		JOIN Employee e ON p.manager = e.Name) AS subq
WHERE Employee.Email = subq.Email;


UPDATE EmployeeJob SET EndDate = NULL WHERE EXTRACT(YEAR FROM EndDate) >= 2100;

-- Question 1: Return a list of employees with Job Titles and Department Names
Select e.Name, ej.Title AS Job, d.Name AS Department
FROM Employee e
JOIN (SELECT ej.EmployeeID, j.Title
		FROM EmployeeJob ej JOIN Job j ON ej.JobID = j.JobID ) AS ej
	ON ej.EmployeeID = e.EmployeeID

JOIN Department d on e.DepartmentID = d.DepartmentID ;

-- Question 2: Insert Web Programmer as a new job title
INSERT INTO Job (Title) VALUES (â€˜Web Programmerâ€™);

-- Question 3: Correct the job title from web programmer to web developer
UPDATE Job SET Title = 'Web Developerâ€™' WHERE Title = 'Web Programmer';

--Question 4: Delete the job title Web Developer from the database
DELETE FROM Job WHERE Title = 'Web Developer';

-- Question 5: How many employees are in each department?
SELECT d.Name, COUNT(EmployeeID) 
FROM Employee e 
JOIN Department d 
ON e.DepartmentID = d.DepartmentID 
GROUP BY d.Name;


-- Question 6: Write a query that returns current and past jobs (include employee name, job title, department, manager name, start and end date for position) for employee Toni Lembeck.

SELECT DISTINCT e.Name, ej.Title, d.Name, e2.Name AS Manager, ej.StartDate, ej.EndDate
FROM Employee e
JOIN (SELECT ej.EmployeeID, j.Title, ej.StartDate, ej.EndDate
		FROM EmployeeJob ej JOIN Job j ON ej.JobID = j.JobID ) AS ej
	ON ej.EmployeeID = e.EmployeeID
JOIN Department d ON e.DepartmentID = d.DepartmentID
JOIN Employee e2 ON e2.EmployeeID = e.ManagerID 
WHERE e.Name = 'Toni Lembeck';

