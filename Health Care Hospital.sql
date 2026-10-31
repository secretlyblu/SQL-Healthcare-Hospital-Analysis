--Create database 
CREATE DATABASE SQL_Hospital_Encounters; 

-- Create Table 
CREATE TABLE Admissions (
      encounter_id	INT PRIMARY KEY,
      admission_date	DATE,
      admission_time	Time,
      patient_id	INT,
      gender	VARCHAR(15),
      age	INT,
      department	TEXT,
      admission_type	TEXT,
      primary_diagnosis	TEXT,
      insurance_type	TEXT,
      length_of_stay	INT,
      num_procedures	INT,
      total_charges	REAL,
      hospital_cost	REAL,
      insurance_paid	REAL,
      readmitted_30d TEXT
        );

--VIEW DATA
SELECT * FROM ADMISSIONS
LIMIT 10

SELECT COUNT(*) FROM  ADMISSIONS

--Result: 3000 rows which is what we expected.

--DATA CLEANING
-- IDENTIFYING NULL 
SELECT * FROM ADMISSIONS
WHERE encounter_id IS NULL
   or admission_date IS NULL
   or admission_time IS NULL
   or patient_id IS NULL
   or gender IS NULL
   or age IS NULL
   or department IS NULL
   or admission_type IS NULL
   or primary_diagnosis IS NULL
   or insurance_type IS NULL
   or length_of_stay IS NULL
   or num_procedures IS NULL
   or total_charges IS NULL
   or hospital_cost IS NULL
   or insurance_paid IS NULL
   or readmitted_30d IS NULL;
/*
Results: 32 rows that included NULL Values. 
4 columns Age, insurance_type, length_of_stay and total_charges each have 8 null values.
*/
-- Counting NULL values by column

SELECT count(*) filter (where age is null) AS "Age"
     FROM  ADMISSIONS ;
SELECT  count(*) filter (where insurance_type is null) AS "insurance_type"
     FROM  ADMISSIONS;
SELECT count(*) filter (where length_of_stay is null) AS "length_of_stay"
 FROM  ADMISSIONS ;
SELECT count(*) filter (where total_charges is null) AS "total_charges"
 FROM  ADMISSIONS ;


--Fix NULL Values 
-- rather than delete rows with Nulls we will look to fill it with existing data given that some patients have multiple records
--Fixing "Age" Column but looking up Patient_ID 

SELECT patient_id from ADMISSIONS
where age is null;

SELECT age from ADMISSIONS
where patient_id = 2265;
Update ADMISSIONS set age = 60 where patient_id = 2265 AND age is null;

SELECT age from ADMISSIONS where patient_id = 1089;
Update ADMISSIONS set age = 41 where patient_id = 1089 AND age is null;

SELECT age from ADMISSIONS where patient_id = 1243;
Update ADMISSIONS set age = 81 where patient_id = 1295  AND age is null;

SELECT age from ADMISSIONS where patient_id = 1295;
Update ADMISSIONS set age = 50 where patient_id = 1295  AND age is null;

SELECT age from ADMISSIONS where patient_id = 1371;
Update ADMISSIONS set age = 53 where patient_id = 1371  AND age is null;

SELECT age from ADMISSIONS where patient_id = 2244;
Update ADMISSIONS set age = 69 where patient_id = 2244  AND age is null;

--Deleting records with Null Values
Delete FROM ADMISSIONS
WHERE age IS NULL;

--Fixing "insurance_type" Column by looking up Patient_ID

SELECT insurance_type from ADMISSIONS where patient_id = 1344;
Update ADMISSIONS set insurance_type = 'Commercial' where patient_id = 1344 AND insurance_type is null;

SELECT insurance_type from ADMISSIONS where patient_id = 2082;
Update ADMISSIONS set insurance_type = 'Commercial' where patient_id = 2082 AND insurance_type is null;

SELECT insurance_type from ADMISSIONS where patient_id = 1818;
Update ADMISSIONS set insurance_type = 'Commercial' where patient_id = 1818 AND insurance_type is null;

SELECT insurance_type from ADMISSIONS where patient_id = 1963;
Update ADMISSIONS set insurance_type = 'Medicare' where patient_id = 1963 AND insurance_type is null;

SELECT insurance_type from ADMISSIONS where patient_id = 2226;
Update ADMISSIONS set insurance_type = 'Commercial' where patient_id = 2226 AND insurance_type is null;

SELECT insurance_type from ADMISSIONS where patient_id = 2305 ;
Update ADMISSIONS set insurance_type = 'Commercial' where patient_id = 2305  AND insurance_type is null;

SELECT insurance_type from ADMISSIONS where patient_id = 1097 ;
Update ADMISSIONS set insurance_type = 'Medicaid' where patient_id = 1097  AND insurance_type is null;

Delete FROM ADMISSIONS WHERE insurance_type IS NULL;

--Deleting null in "length_of_stay" because we cannot approximate
Delete FROM ADMISSIONS WHERE length_of_stay IS NULL;


--Fixing "total_charges" Column will be easy by summing hospital_cost  and  insurance_paid
Update ADMISSIONS set total_charges = hospital_cost + insurance_paid  
where total_charges is null;


---Data Exploration

-- department with the most admissions  
 select department, count(*) as Admittance from ADMISSIONS
 GROUP BY department
 ORDER BY Admittance desc
 limit 1;

 -- department with the longest avg stay
 select department, round(avg(length_of_stay)) as Stay_avg from ADMISSIONS
 GROUP BY department
 ORDER BY Stay_avg desc
 limit 1;

 -- Average total charge per encounter
   select round(avg(total_charges),2) from ADMISSIONS

  -- Average total charge per encounter by depart
   select department, round(avg(total_charges),2) from ADMISSIONS
   GROUP BY department;


---Data Analysis 

--What is the overall readmission rate and what is it by department?

select round(
  100.0 * count(*) filter (where readmitted_30d = 'Yes')/ count (*),2) AS Percent_Readmitted
FROM ADMISSIONS; 

select department, round(
100.0 * count(*) filter (where readmitted_30d = 'Yes')/ count (*),2) AS Percent_Readmitted
FROM ADMISSIONS
GROUP BY department;

--Which top 5 Diagnoses have the highest readmission rate?
select primary_diagnosis, round(
100.0 * count(*) filter (where readmitted_30d = 'Yes')/ count (*),2) AS Percent_Readmitted
FROM ADMISSIONS
GROUP BY primary_diagnosis
ORDER BY Percent_Readmitted  DESC
LIMIT 5;

--What is the average length of stay by admission type?
select admission_type, round(avg(length_of_stay)) AS Avg_Len_of_Stay
FROM ADMISSIONS
GROUP BY admission_type;

--What is the profit margin (charges minus cost) by department?
select department, round((total_charges - hospital_cost),2) As Profit_Margin
FROM ADMISSIONS
GROUP BY department;

--Which payer has the largest gap between charges and insurance paid?
select insurance_type, round(sum(total_charges - insurance_paid),2) As Gap
FROM ADMISSIONS
GROUP BY insurance_type
ORDER BY Gap Desc;

--Which age groups (CASE WHEN) are readmitted most?
SELECT
  CASE
    when age BETWEEN 18 and 34 then "18-34"
    when age BETWEEN 35 and 49 then "35-49"
    when age BETWEEN 50 and 64 then "50-64"
    when age BETWEEN 65 and 79 then "65-79"
    when age >= 80 then "80+"
  end as age_group, 
     round(
100.0 * count(*) filter (where readmitted_30d = 'Yes')/ count (*),2) AS Percent_Readmitted 
  From ADMISSIONS
  GROUP BY 1 --repeats case
  ORDER BY Percent_Readmitted desc;

--Who are the top 10 highest-cost patients?
select patient_id, sum(hospital_cost) As cost_to_care
FROM ADMISSIONS
GROUP BY patient_id
ORDER BY cost_to_care desc
limit 10;

--What is the busiest admission shift (morning, evening, overnight)?
select 
  case 
    when admission_time BETWEEN '07:00:00' AND '14:59:59' Then "Morning"
    when admission_time BETWEEN '15:00:00' AND '22:59:59' Then "Evening"
    Else "Overnight"
  End As 'Shifts', count(*) as Entries
    from ADMISSIONS
  GROUP BY 1 --repeats case
  ORDER BY Entries DESC; 

--What is the monthly admission trend, and which month is the peak each year (window function)?
WITH monthly AS (
    SELECT
        strftime('%Y', admission_date) AS year,
        strftime('%m', admission_date) AS month,
        COUNT(*) AS total_admissions
    FROM ADMISSIONS
    GROUP BY 1, 2
)
SELECT
    year,
    month,
    total_admissions,
    RANK() OVER (PARTITION BY year ORDER BY total_admissions DESC) AS rank_in_year
FROM monthly
ORDER BY year, month;

--end of project
