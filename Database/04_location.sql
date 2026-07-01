-- 1. Enable PostGIS (Just in case)
CREATE EXTENSION IF NOT EXISTS postgis;

DROP TABLE IF EXISTS locations CASCADE;

-- 3. Create the strictly defined v3 Locations Table
CREATE TABLE locations (
    location_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    address TEXT,
    city VARCHAR(100),
    district VARCHAR(100),
    
    -- The PostGIS spatial column for exact earth coordinates
    geom GEOMETRY(POINT, 4326)
);

-- 4. Rebuild the Spatial Index (CRITICAL)
CREATE INDEX idx_locations_geom ON locations USING GIST (geom);
