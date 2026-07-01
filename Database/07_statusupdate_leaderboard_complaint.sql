-- 1. CLEAN UP: Drop these specific tables/views if they already exist
DROP VIEW IF EXISTS active_complaint_points CASCADE;
DROP TABLE IF EXISTS complaint_images CASCADE;
DROP TABLE IF EXISTS complaint_confirmations CASCADE;
DROP TABLE IF EXISTS leaderboard CASCADE;
DROP TABLE IF EXISTS status_updates CASCADE;

-- 2. CREATE: status_updates (The Audit Trail)
CREATE TABLE status_updates (
    update_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    complaint_id UUID REFERENCES complaints(complaint_id) ON DELETE CASCADE,
    authority_id UUID REFERENCES authorities(authority_id),
    old_status VARCHAR(50),
    new_status VARCHAR(50) NOT NULL,
    remarks TEXT,
    proof_image_url VARCHAR(500), 
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_status_updates_complaint ON status_updates USING BTREE (complaint_id, created_at);

-- 3. CREATE: leaderboard (Authority Scoring)
CREATE TABLE leaderboard (
    leaderboard_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    authority_id UUID UNIQUE REFERENCES authorities(authority_id),
    total_points INT DEFAULT 0,
    monthly_points INT DEFAULT 0,
    on_time_count INT DEFAULT 0,
    late_count INT DEFAULT 0,
    current_rank INT,
    last_updated TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_leaderboard_monthly_points ON leaderboard USING BTREE (monthly_points DESC);

-- 4. CREATE: complaint_confirmations (Community Verification)
CREATE TABLE complaint_confirmations (
    confirmation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    complaint_id UUID REFERENCES complaints(complaint_id),
    citizen_id UUID REFERENCES citizens(user_id), 
    is_fixed BOOLEAN NOT NULL,
    confirmed_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(complaint_id, citizen_id)
);

-- 5. CREATE: complaint_images (The Cloud Integration)
CREATE TABLE complaint_images (
    image_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    complaint_id UUID REFERENCES complaints(complaint_id) ON DELETE CASCADE,
    uploaded_by UUID REFERENCES users(user_id),
    image_url TEXT NOT NULL,
    image_type VARCHAR(20) NOT NULL, 
    uploaded_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_complaint_images_lookup ON complaint_images USING BTREE (complaint_id, image_type);

-- 6. CREATE: active_complaint_points (The Geofencing View)
-- Note: Fixed the syntax error where the WHERE clause was split by a semicolon
CREATE OR REPLACE VIEW active_complaint_points AS 
SELECT 
    c.complaint_id, 
    c.issue_type, 
    c.status,
    l.latitude, 
    l.longitude, 
    l.address, 
    l.geom 
FROM complaints c 
JOIN locations l ON l.location_id = c.location_id 
WHERE c.status NOT IN ('fixed', 'closed', 'rejected') 
  AND c.is_hidden = FALSE;
