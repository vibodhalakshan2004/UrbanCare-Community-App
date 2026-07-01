-- 1. Create the required ENUM types 
CREATE TYPE issue_type AS ENUM ('road_damage', 'streetlight', 'garbage', 'water', 'other');
CREATE TYPE complaint_status AS ENUM ('created', 'verified', 'assigned', 'in_progress', 'fixed', 'closed', 'rejected');

-- 2. Create the Complaints Table (Fully merged with all ALTER statements)
CREATE TABLE complaints (
    complaint_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- THE FIX: Updated foreign key to point to users(user_id) per bottom ALTER
    citizen_id UUID REFERENCES users(user_id),
    
    assigned_authority_id UUID REFERENCES authorities(authority_id), -- Nullable until assigned
    location_id UUID REFERENCES locations(location_id),
    
    -- Core Complaint Data (Includes added columns: title, priority, is_hidden)
    title VARCHAR(150),
    issue_type issue_type NOT NULL,
    description TEXT NOT NULL,
    priority VARCHAR(20) DEFAULT 'medium',
    status complaint_status DEFAULT 'created',
    primary_image_url VARCHAR(500), 
    
    -- Lifecycle Tracking
    estimated_fix_at TIMESTAMPTZ,
    fixed_at TIMESTAMPTZ,
    
    -- Community Features (Includes verification_count and not_fixed_count)
    community_verified BOOLEAN DEFAULT FALSE,
    confirm_yes_count INT DEFAULT 0,
    confirm_no_count INT DEFAULT 0,
    verification_count INT DEFAULT 0,
    not_fixed_count INT DEFAULT 0,

    is_hidden BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Attach the Automated Timestamp Trigger
CREATE TRIGGER set_complaints_updated_at
BEFORE UPDATE ON complaints
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 4. Create the Performance Indexes
CREATE INDEX idx_complaints_citizen_status ON complaints USING BTREE (citizen_id, status);
CREATE INDEX idx_complaints_auth_status ON complaints USING BTREE (assigned_authority_id, status);
CREATE INDEX idx_complaints_created_at ON complaints USING BTREE (created_at DESC);
CREATE INDEX idx_complaints_type_status ON complaints USING BTREE (issue_type, status);
