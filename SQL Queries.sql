USE indiapost;
SHOW TABLES;

SELECT COUNT(*) AS total_post_offices
FROM real_pincode_data;

USE indiapost;

DROP TABLE IF EXISTS cleaned_india_post;

CREATE TABLE cleaned_india_post AS
WITH cleaned AS (
    SELECT
        TRIM(officename) AS officename,
        TRIM(pincode) AS pincode,
        TRIM(officeType) AS officeType,
        TRIM(Deliverystatus) AS Deliverystatus,
        TRIM(divisionname) AS divisionname,
        TRIM(regionname) AS regionname,
        TRIM(circlename) AS circlename,
        NULLIF(TRIM(Taluk), '') AS Taluk,
        NULLIF(TRIM(Districtname), '') AS Districtname,
        TRIM(statename) AS statename,
        NULLIF(TRIM(Telephone), '') AS Telephone,
        NULLIF(NULLIF(TRIM(RelatedSuboffice), ''), 'NA') AS RelatedSuboffice,
        NULLIF(TRIM(RelatedHeadoffice), '') AS RelatedHeadoffice
    FROM real_pincode_data
),
deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY
                circlename,
                divisionname,
                officename,
                pincode
            ORDER BY officename
        ) AS rn
    FROM cleaned
)
SELECT
    officename,
    pincode,
    officeType,
    Deliverystatus,
    divisionname,
    regionname,
    circlename,
    Taluk,
    Districtname,
    statename,
    Telephone,
    RelatedSuboffice,
    RelatedHeadoffice
FROM deduplicated
WHERE rn = 1;


SELECT COUNT(*) AS cleaned_rows
FROM cleaned_india_post;


USE indiapost;

SELECT COUNT(*) AS total_post_offices
FROM cleaned_india_post

SELECT
    Deliverystatus,
    COUNT(*) AS total_offices,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cleaned_india_post),
        2
    ) AS percentage
FROM cleaned_india_post
GROUP BY Deliverystatus
ORDER BY total_offices DESC;

--  State-wise Post Office Distribution
SELECT
    statename AS state,
    COUNT(*) AS total_offices
FROM cleaned_india_post
GROUP BY statename
ORDER BY total_offices DESC;

-- State-wise Delivery Coverage
SELECT
    statename AS state,
    COUNT(*) AS total_offices,
    SUM(CASE
        WHEN Deliverystatus = 'Delivery' THEN 1
        ELSE 0
    END) AS delivery_offices,
    ROUND(
        100.0 * SUM(CASE
            WHEN Deliverystatus = 'Delivery' THEN 1
            ELSE 0
        END) / COUNT(*),
        2
    ) AS delivery_coverage_pct
FROM cleaned_india_post
GROUP BY statename
ORDER BY delivery_coverage_pct ASC;


-- Office Type Distribution
SELECT
    officeType AS office_type,
    COUNT(*) AS total_offices
FROM cleaned_india_post
GROUP BY officeType
ORDER BY total_offices DESC;


-- contact completeness
SELECT
    SUM(
        CASE
            WHEN Telephone IS NOT NULL
            AND TRIM(Telephone) <> ''
            AND UPPER(TRIM(Telephone)) <> 'NA'
            THEN 1
            ELSE 0
        END
    ) AS offices_with_contact,

    SUM(
        CASE
            WHEN Telephone IS NULL
            OR TRIM(Telephone) = ''
            OR UPPER(TRIM(Telephone)) = 'NA'
            THEN 1
            ELSE 0
        END
    ) AS offices_without_contact,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN Telephone IS NOT NULL
                AND TRIM(Telephone) <> ''
                AND UPPER(TRIM(Telephone)) <> 'NA'
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS contact_completeness_pct

FROM cleaned_india_post;

-- Service Gap 
SELECT
    statename AS state,
    COUNT(*) AS total_offices,
    SUM(CASE WHEN Deliverystatus = 'Non-Delivery' THEN 1 ELSE 0 END) AS non_delivery_offices,
    ROUND(
        100.0 * SUM(CASE WHEN Deliverystatus = 'Non-Delivery' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS non_delivery_pct
FROM cleaned_india_post
GROUP BY statename
ORDER BY non_delivery_pct DESC;