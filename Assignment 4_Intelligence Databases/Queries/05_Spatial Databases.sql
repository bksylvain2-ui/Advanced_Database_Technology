-- Create clinic table with spatial geometry
CREATE TABLE CLINIC (
    ID NUMBER PRIMARY KEY, 
    NAME VARCHAR2(100), 
    GEOM SDO_GEOMETRY
);

-- Insert sample clinics around Kigali area (using WGS84 SRID 4326)
INSERT INTO CLINIC VALUES (1, 'Kigali Central Clinic', 
    SDO_GEOMETRY(2001, 4326, SDO_POINT_TYPE(30.0589, -1.9550, NULL), NULL, NULL));
INSERT INTO CLINIC VALUES (2, 'Kimironko Health Center', 
    SDO_GEOMETRY(2001, 4326, SDO_POINT_TYPE(30.1123, -1.9432, NULL), NULL, NULL));
INSERT INTO CLINIC VALUES (3, 'Remera Clinic', 
    SDO_GEOMETRY(2001, 4326, SDO_POINT_TYPE(30.0921, -1.9523, NULL), NULL, NULL));
INSERT INTO CLINIC VALUES (4, 'Gisozi Medical Center', 
    SDO_GEOMETRY(2001, 4326, SDO_POINT_TYPE(30.0987, -1.9389, NULL), NULL, NULL));
INSERT INTO CLINIC VALUES (5, 'Nyamirambo Health Post', 
    SDO_GEOMETRY(2001, 4326, SDO_POINT_TYPE(30.0456, -1.9689, NULL), NULL, NULL));

-- Create spatial index
CREATE INDEX CLINIC_SPX ON CLINIC(GEOM) INDEXTYPE IS MDSYS.SPATIAL_INDEX;

-- Register the spatial metadata (CRITICAL STEP)
INSERT INTO USER_SDO_GEOM_METADATA VALUES (
    'CLINIC', 'GEOM',
    SDO_DIM_ARRAY(
        SDO_DIM_ELEMENT('Longitude', -180, 180, 0.5),
        SDO_DIM_ELEMENT('Latitude', -90, 90, 0.5)
    ),
    4326  -- SRID for WGS84
);
COMMIT;

-- ***********************************************************************************************
-- FIXED SOLUTION FOR SPATIAL QUERIES
-- ***********************************************************************************************
-- Query 1: Clinics within 1 km radius (FIXED)
SELECT C.ID, C.NAME
FROM CLINIC C
WHERE SDO_WITHIN_DISTANCE(
    C.GEOM,
    SDO_GEOMETRY(
        2001, 
        4326,  -- FIXED: WGS84 SRID (geographic coordinates)
        SDO_POINT_TYPE(30.0600, -1.9570, NULL),  -- FIXED: Longitude first, then Latitude
        NULL, NULL
    ),
    'distance=1 unit=KM'  -- FIXED: Explicitly specify kilometers
) = 'TRUE'
ORDER BY C.ID;

-- Query 2: Nearest 3 clinics with distances in kilometers (FIXED)
SELECT C.ID, C.NAME,
       ROUND(SDO_GEOM.SDO_DISTANCE(
           C.GEOM, 
           SDO_GEOMETRY(2001, 4326, SDO_POINT_TYPE(30.0600, -1.9570, NULL), NULL, NULL),
           0.005,        -- Tolerance for WGS84 coordinate system
           'unit=KM'     -- FIXED: Return distance in kilometers
       ), 3) AS DISTANCE_KM
FROM CLINIC C
ORDER BY DISTANCE_KM
FETCH FIRST 3 ROWS ONLY;

-- Verify clinic locations and spatial setup
SELECT ID, NAME, 
       SDO_UTIL.TO_WKTGEOMETRY(GEOM) AS LOCATION
FROM CLINIC;

-- Verify spatial index is valid
SELECT INDEX_NAME, STATUS 
FROM USER_INDEXES 
WHERE INDEX_NAME = 'CLINIC_SPX';
