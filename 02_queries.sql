
CREATE DATABASE noshowguard;

USE noshowguard;


CREATE TABLE clinics (
    clinic_id VARCHAR(5) PRIMARY KEY,
    clinic_name VARCHAR(40) NOT NULL,
    city VARCHAR(20) NOT NULL,
    tier VARCHAR(10),
    latitude DECIMAL(8,4),
    longitude DECIMAL(8,4),
    temp_c DECIMAL(5,1)
);


CREATE TABLE appointments (
    appointment_id VARCHAR(8) PRIMARY KEY,
    patient_id VARCHAR(8) NOT NULL,
    clinic_id VARCHAR(5) NOT NULL,
    booked_on DATE,
    appt_date DATE,
    age INT,
    gender VARCHAR(1),
    distance_km DECIMAL(5,1),
    fee_inr INT,
    booking_channel VARCHAR(10),
    visit_type VARCHAR(12),
    reminder_sent VARCHAR(3),
    prior_no_shows INT,
    status VARCHAR(10),
    lead_days INT,
    no_show INT,

    FOREIGN KEY (clinic_id)
    REFERENCES clinics(clinic_id)
);


SHOW TABLES;


CREATE TABLE appointments (
    appointment_id VARCHAR(8) PRIMARY KEY,
    patient_id VARCHAR(8) NOT NULL,
    clinic_id VARCHAR(5) NOT NULL,
    booked_on DATE,
    appt_date DATE,
    age INT,
    gender VARCHAR(1),
    distance_km DECIMAL(5,1),
    fee_inr INT,
    booking_channel VARCHAR(10),
    visit_type VARCHAR(12),
    reminder_sent VARCHAR(3),
    prior_no_shows INT,
    status VARCHAR(10),
    lead_days INT,
    no_show INT,
    FOREIGN KEY (clinic_id)
    REFERENCES clinics(clinic_id)
);

-- -- -- -- -- -- -- - - - - -

SELECT
    c.clinic_name,
    c.city,
    COUNT(*) AS appointments,
    SUM(a.no_show) AS no_shows,
    ROUND(
        100.0 * SUM(a.no_show) / COUNT(*),
        1
    ) AS no_show_pct

FROM appointments a

JOIN clinics c
ON a.clinic_id = c.clinic_id

GROUP BY
    c.clinic_name,
    c.city



ORDER BY no_show_pct DESC;



-- =====================================
-- CARELOOP CLINICS - NO-SHOW GUARD
-- PART 2: SQL ANALYSIS
-- =====================================

USE noshowguard;


-- TASK 2.1: DUPLICATE PRIMARY KEY TEST

-- Error recorded:
-- Error Code: 1062
-- Duplicate entry 'A0001'
-- for key 'appointments.PRIMARY'


-- TASK 2.2: NO-SHOW RATE BY CLINIC

SELECT
    c.clinic_name,
    c.city,
    COUNT(*) AS appointments,
    SUM(a.no_show) AS no_shows,
    ROUND(
        100.0 * SUM(a.no_show) / COUNT(*), 1
    ) AS no_show_pct
FROM appointments a
JOIN clinics c
ON a.clinic_id = c.clinic_id
GROUP BY c.clinic_name, c.city
HAVING COUNT(*) >= 95
ORDER BY no_show_pct DESC;


-- TASK 2.2: ALL 8 CLINICS

SELECT
    c.clinic_name,
    c.city,
    COUNT(*) AS appointments,
    SUM(a.no_show) AS no_shows,
    ROUND(
        100.0 * SUM(a.no_show) / COUNT(*), 1
    ) AS no_show_pct
FROM appointments a
JOIN clinics c
ON a.clinic_id = c.clinic_id
GROUP BY c.clinic_name, c.city
ORDER BY no_show_pct DESC;


-- -- -- --------------------------------------


SELECT

    CASE
        WHEN lead_days <= 7 THEN '1-7'
        WHEN lead_days <= 14 THEN '8-14'
        WHEN lead_days <= 30 THEN '15-30'
        ELSE '31+'
    END AS lead_band,

    COUNT(*) AS appointments,

    SUM(no_show) AS no_shows,

    ROUND(
        100.0 * SUM(no_show) / COUNT(*),
        1
    ) AS no_show_pct

FROM appointments

GROUP BY lead_band

ORDER BY MIN(lead_days);

--  --------------------------------------


WITH monthly AS (

    SELECT
        SUBSTR(appt_date, 1, 7) AS month,

        COUNT(*) AS appointments,

        ROUND(
            100.0 * SUM(no_show) / COUNT(*),
            1
        ) AS no_show_pct

    FROM appointments

    GROUP BY SUBSTR(appt_date, 1, 7)

)

SELECT

    month,

    appointments,

    no_show_pct,

    ROUND(
        no_show_pct - LAG(no_show_pct) OVER (
            ORDER BY month
        ),
        1
    ) AS change_pct_points

FROM monthly

ORDER BY month;


-- ----------------------------------


WITH clinic_rates AS (

    SELECT
        c.clinic_name AS clinic,
        c.city,

        ROUND(
            100.0 * SUM(a.no_show) / COUNT(*),
            1
        ) AS no_show_pct

    FROM appointments a

    JOIN clinics c
    ON a.clinic_id = c.clinic_id

    GROUP BY
        c.clinic_name,
        c.city

)

SELECT

    clinic,
    city,
    no_show_pct,

    RANK() OVER (
        PARTITION BY city
        ORDER BY no_show_pct DESC
    ) AS rank_in_city,

    CASE
        WHEN no_show_pct > (
            SELECT
                100.0 * SUM(no_show) / COUNT(*)
            FROM appointments
        )
        THEN 'above'

        WHEN no_show_pct < (
            SELECT
                100.0 * SUM(no_show) / COUNT(*)
            FROM appointments
        )
        THEN 'below'

        ELSE 'equal'
    END AS vs_overall

FROM clinic_rates

ORDER BY city, rank_in_city;
