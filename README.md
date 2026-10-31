# Hospital Encounters Analysis SQL Project

## Project Overview

**Project Title**: Hospital Encounters Analysis (Readmissions, Cost & Patient Flow)
**Level**: Beginner
**Database**: `SQL_Hospital_Encounters` (SQLite)
**Dataset**: Synthetic inpatient data (3,000 encounters, 2023-2024). No real patient information is used.

This project demonstrates SQL skills used by healthcare data analysts to clean, explore, and analyze hospital encounter data. A hospital wants to reduce costly 30-day readmissions and understand which departments, diagnoses, age groups, and payers drive cost and patient volume. The project covers database setup, data cleaning, exploratory data analysis (EDA), and business-driven SQL queries.

## Business Problem

Hospitals can be financially penalized for high 30-day readmission rates, and readmissions signal gaps in care quality. Leadership needs to know:

- Where are readmissions happening (department, diagnosis, age group)?
- Which departments and payers are the most or least profitable?
- When are patients arriving, so staffing can match demand?

## Objectives

1. **Set up a hospital encounters database**: Create and populate a table with the encounter data.
2. **Data Cleaning**: Identify null values, fill them where possible using a patient's other records, and remove records that cannot be reliably fixed.
3. **Exploratory Data Analysis (EDA)**: Understand volume, length of stay, and charges across departments.
4. **Business Analysis**: Use SQL to answer specific questions about readmissions, cost, payers, and admission trends.

## Dataset

| Column | Description |
|---|---|
| encounter_id | Unique ID for each hospital encounter (primary key) |
| admission_date | Date of admission |
| admission_time | Time of admission |
| patient_id | Patient identifier (patients can have multiple encounters) |
| gender | Patient gender |
| age | Patient age at admission |
| department | Admitting department (e.g., Cardiology, Oncology) |
| admission_type | Emergency, Urgent, or Elective |
| primary_diagnosis | Main diagnosis for the encounter |
| insurance_type | Medicare, Medicaid, Commercial, or Self-Pay |
| length_of_stay | Number of days admitted |
| num_procedures | Number of procedures performed |
| total_charges | Total amount billed |
| hospital_cost | Cost to the hospital to provide care |
| insurance_paid | Amount paid by the insurer |
| readmitted_30d | Whether the patient was readmitted within 30 days (Yes/No) |

## Project Structure

### 1. Database Setup

```sql
CREATE DATABASE SQL_Hospital_Encounters;

CREATE TABLE Admissions (
    encounter_id      INT PRIMARY KEY,
    admission_date    DATE,
    admission_time    TIME,
    patient_id        INT,
    gender            VARCHAR(15),
    age               INT,
    department        TEXT,
    admission_type    TEXT,
    primary_diagnosis TEXT,
    insurance_type    TEXT,
    length_of_stay    INT,
    num_procedures    INT,
    total_charges     REAL,
    hospital_cost     REAL,
    insurance_paid    REAL,
    readmitted_30d    TEXT
);
```

After importing the CSV, the record count was confirmed:

```sql
SELECT COUNT(*) FROM Admissions;
```

**Result**: 3,000 rows, as expected.

### 2. Data Cleaning

**Step 1: Identify null values**

```sql
SELECT * FROM Admissions
WHERE encounter_id IS NULL
   OR admission_date IS NULL
   OR admission_time IS NULL
   OR patient_id IS NULL
   OR gender IS NULL
   OR age IS NULL
   OR department IS NULL
   OR admission_type IS NULL
   OR primary_diagnosis IS NULL
   OR insurance_type IS NULL
   OR length_of_stay IS NULL
   OR num_procedures IS NULL
   OR total_charges IS NULL
   OR hospital_cost IS NULL
   OR insurance_paid IS NULL
   OR readmitted_30d IS NULL;
```

**Result**: 32 rows contained nulls. Four columns (`age`, `insurance_type`, `length_of_stay`, `total_charges`) each had 8 null values.

```sql
SELECT COUNT(*) FILTER (WHERE age IS NULL) AS age FROM Admissions;
SELECT COUNT(*) FILTER (WHERE insurance_type IS NULL) AS insurance_type FROM Admissions;
SELECT COUNT(*) FILTER (WHERE length_of_stay IS NULL) AS length_of_stay FROM Admissions;
SELECT COUNT(*) FILTER (WHERE total_charges IS NULL) AS total_charges FROM Admissions;
```

**Step 2: Fix nulls where possible**

Rather than deleting every row with a null, I filled values using the patient's other encounters, since many patients appear more than once.

*Age and insurance type:* look up the patient's other records, then update the null row.

```sql
-- Find patients with a missing age
SELECT patient_id FROM Admissions WHERE age IS NULL;

-- Check the patient's other records, then fill the null
SELECT age FROM Admissions WHERE patient_id = 2265;
UPDATE Admissions SET age = 60 WHERE patient_id = 2265 AND age IS NULL;

-- Same approach for insurance type
SELECT insurance_type FROM Admissions WHERE patient_id = 1344;
UPDATE Admissions SET insurance_type = 'Commercial'
WHERE patient_id = 1344 AND insurance_type IS NULL;
```

*Total charges:* filled by combining `hospital_cost` and `insurance_paid`.

```sql
UPDATE Admissions
SET total_charges = hospital_cost + insurance_paid
WHERE total_charges IS NULL;
```

**Step 3: Delete records that cannot be reliably fixed**

Patients with only one encounter had no other record to pull from, and length of stay cannot be approximated.

```sql
DELETE FROM Admissions WHERE age IS NULL;
DELETE FROM Admissions WHERE insurance_type IS NULL;
DELETE FROM Admissions WHERE length_of_stay IS NULL;
```

### 3. Data Exploration

1. **Which department has the most admissions?**

```sql
SELECT department, COUNT(*) AS Admittance
FROM Admissions
GROUP BY department
ORDER BY Admittance DESC
LIMIT 1;
```

2. **Which department has the longest average stay?**

```sql
SELECT department, ROUND(AVG(length_of_stay)) AS Stay_avg
FROM Admissions
GROUP BY department
ORDER BY Stay_avg DESC
LIMIT 1;
```

3. **What is the average total charge per encounter?**

```sql
SELECT ROUND(AVG(total_charges), 2) FROM Admissions;
```

4. **What is the average total charge per encounter by department?**

```sql
SELECT department, ROUND(AVG(total_charges), 2)
FROM Admissions
GROUP BY department;
```

### 4. Data Analysis & Findings

1. **What is the overall readmission rate, and what is it by department?**

```sql
-- Overall
SELECT ROUND(100.0 * COUNT(*) FILTER (WHERE readmitted_30d = 'Yes') / COUNT(*), 2) AS Percent_Readmitted
FROM Admissions;

-- By department
SELECT department,
       ROUND(100.0 * COUNT(*) FILTER (WHERE readmitted_30d = 'Yes') / COUNT(*), 2) AS Percent_Readmitted
FROM Admissions
GROUP BY department;
```

2. **Which top 5 diagnoses have the highest readmission rate?**

```sql
SELECT primary_diagnosis,
       ROUND(100.0 * COUNT(*) FILTER (WHERE readmitted_30d = 'Yes') / COUNT(*), 2) AS Percent_Readmitted
FROM Admissions
GROUP BY primary_diagnosis
ORDER BY Percent_Readmitted DESC
LIMIT 5;
```

3. **What is the average length of stay by admission type?**

```sql
SELECT admission_type, ROUND(AVG(length_of_stay)) AS Avg_Len_of_Stay
FROM Admissions
GROUP BY admission_type;
```

4. **What is the profit margin (charges minus cost) by department?**

```sql
SELECT department, ROUND(SUM(total_charges - hospital_cost), 2) AS Profit_Margin
FROM Admissions
GROUP BY department
ORDER BY Profit_Margin DESC;
```

5. **Which payer has the largest gap between charges and insurance paid?**

```sql
SELECT insurance_type, ROUND(SUM(total_charges - insurance_paid), 2) AS Gap
FROM Admissions
GROUP BY insurance_type
ORDER BY Gap DESC;
```

6. **Which age groups are readmitted the most?** (CASE WHEN)

```sql
SELECT
    CASE
        WHEN age BETWEEN 18 AND 34 THEN '18-34'
        WHEN age BETWEEN 35 AND 49 THEN '35-49'
        WHEN age BETWEEN 50 AND 64 THEN '50-64'
        WHEN age BETWEEN 65 AND 79 THEN '65-79'
        WHEN age >= 80 THEN '80+'
    END AS age_group,
    ROUND(100.0 * COUNT(*) FILTER (WHERE readmitted_30d = 'Yes') / COUNT(*), 2) AS Percent_Readmitted
FROM Admissions
GROUP BY 1
ORDER BY Percent_Readmitted DESC;
```

7. **Who are the top 10 highest-cost patients?**

```sql
SELECT patient_id, SUM(hospital_cost) AS cost_to_care
FROM Admissions
GROUP BY patient_id
ORDER BY cost_to_care DESC
LIMIT 10;
```

8. **What is the busiest admission shift?**

Because a hospital runs 24/7, the shifts cover the full day with no gaps:

- **Morning**: 7:00 AM to 2:59 PM
- **Evening**: 3:00 PM to 10:59 PM
- **Overnight**: 11:00 PM to 6:59 AM

```sql
SELECT
    CASE
        WHEN admission_time BETWEEN '07:00:00' AND '14:59:59' THEN 'Morning'
        WHEN admission_time BETWEEN '15:00:00' AND '22:59:59' THEN 'Evening'
        ELSE 'Overnight'
    END AS Shifts,
    COUNT(*) AS Entries
FROM Admissions
GROUP BY 1
ORDER BY Entries DESC;
```

9. **What is the monthly admission trend, and which month is the peak each year?** (window function)

```sql
WITH monthly AS (
    SELECT
        strftime('%Y', admission_date) AS year,
        strftime('%m', admission_date) AS month,
        COUNT(*) AS total_admissions
    FROM Admissions
    GROUP BY 1, 2
)
SELECT
    year,
    month,
    total_admissions,
    RANK() OVER (PARTITION BY year ORDER BY total_admissions DESC) AS rank_in_year
FROM monthly
ORDER BY year, month;
```

## Findings

*(Placeholder values: replace with your actual results.)*

- **Overall Readmission Rate**: The hospital's 30-day readmission rate is **[X]%**, with **[Department]** the highest at **[X]%** and **[Department]** the lowest at **[X]%**.
- **High-Risk Diagnoses**: **[Diagnosis 1]**, **[Diagnosis 2]**, and **[Diagnosis 3]** have the highest readmission rates, ranging from **[X]%** to **[X]%**.
- **Age Groups**: Patients aged **[age group]** are readmitted most often at **[X]%**, compared with **[X]%** for the **[age group]** group.
- **Length of Stay**: **[Admission type]** admissions have the longest average stay at **[X]** days.
- **Profitability**: **[Department]** generates the highest margin at **$[X]**, while **[Department]** generates the lowest at **$[X]**.
- **Payer Gap**: **[Insurance type]** has the largest gap between charges and insurance paid at **$[X]**.
- **High-Cost Patients**: The top 10 patients account for **$[X]** in hospital cost, with patient **[ID]** the highest at **$[X]**.
- **Admission Shifts**: The **[shift]** shift is the busiest with **[X]** admissions, followed by **[shift]** and **[shift]**.
- **Admission Trends**: Admissions peaked in **[month]** in 2023 and **[month]** in 2024.

## Reports

- **Readmission Summary**: Readmission rates by department, diagnosis, and age group.
- **Financial Summary**: Profit margin by department and charge-to-payment gap by insurer.
- **Operations Summary**: Length of stay by admission type, shift volume, and monthly admission trends.

## Recommendations

*(Placeholder: update after reviewing your findings.)*

1. Target discharge planning and follow-up care for **[high-risk diagnoses]** and **[high-risk age group]** patients to reduce readmissions.
2. Review pricing and reimbursement for **[payer]** to close the gap between charges and payments.
3. Align staffing with the **[busiest shift]** and **[peak months]** to match patient demand.

## Assumptions & Limitations

- The data is **synthetic** and created for portfolio purposes, so findings do not reflect a real hospital.
- Missing ages and insurance types were filled from the same patient's other encounters. Records with no other encounter, or with a missing length of stay, were deleted.
- Missing `total_charges` were estimated as `hospital_cost + insurance_paid`.
- Age groups and admission shifts are analyst-defined ranges, documented above.
- Readmission rates are shown as percentages rather than raw counts so groups of different sizes can be compared fairly.

## Conclusion

This project walks through the core SQL workflow of a healthcare data analyst: database setup, null handling, exploratory analysis, and business-driven queries using aggregation, CASE WHEN, and window functions. The results can help a hospital focus readmission prevention efforts, understand departmental and payer profitability, and plan staffing around patient demand.

## How to Use

1. **Clone the Repository**: Clone this project from GitHub.
2. **Set Up the Database**: Create the `Admissions` table with the script above and import `hospital_encounters.csv`.
3. **Run the Queries**: Use the queries in the project's `.sql` file to reproduce the analysis.
4. **Explore and Modify**: Adjust the age groups, shifts, or filters to answer additional questions.

## Tools Used

- SQL (SQLite)
- GitHub

## Author - [Your Name]

This project is part of my data analytics portfolio, showcasing SQL skills for healthcare and health tech analyst roles. Feel free to reach out with questions or feedback.

- **LinkedIn**: [Add your link]
- **GitHub**: [Add your link]
