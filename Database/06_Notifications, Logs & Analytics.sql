-- 1. Create the Notifications Table
CREATE TABLE notifications (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Links back to the user receiving the notification
    recipient_id UUID REFERENCES users(user_id),
    
    type VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    
    -- JSONB replaces the MongoDB nested document structure
    data JSONB, 
    
    is_read BOOLEAN DEFAULT FALSE,
    fcm_message_id VARCHAR(200),
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    read_at TIMESTAMPTZ
);

-- Notification Indexes
CREATE INDEX idx_notif_user_read ON notifications USING BTREE (recipient_id, is_read, sent_at);
CREATE INDEX idx_notif_sent ON notifications USING BTREE (sent_at);

-- 2. Create the Activity Logs Table (Audit Trail)
CREATE TABLE activity_logs (
    log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Links back to the user performing the action
    actor_id UUID REFERENCES users(user_id),
    
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    
    -- Not a strict Foreign Key because the resource could be a complaint, a user, etc.
    resource_id UUID,
    
    -- JSONB stores the flexible "before" and "after" states
    changes JSONB, 
    
    ip_address VARCHAR(45),
    app_version VARCHAR(20),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Activity Log Indexes
CREATE INDEX idx_logs_actor ON activity_logs USING BTREE (actor_id, created_at);
CREATE INDEX idx_logs_resource ON activity_logs USING BTREE (resource_id, resource_type);
CREATE INDEX idx_logs_created ON activity_logs USING BTREE (created_at);

-- Create the Analytics Cache Table (Dashboard Stats)
CREATE TABLE analytics_cache (
    cache_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Time period tracking (e.g., '2025-03', 'monthly')
    period VARCHAR(10) NOT NULL,
    period_type VARCHAR(20) NOT NULL,
    
    -- Can be NULL if the snapshot is for the entire country/system
    district VARCHAR(100),
    
    -- Pre-calculated totals
    total_reports INT DEFAULT 0,
    resolved_count INT DEFAULT 0,
    avg_resolution_hours FLOAT,
    
    -- JSONB replaces MongoDB nested objects for flexible charting
    by_type JSONB, 
    top_authorities JSONB,
    
    generated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- CRITICAL: This prevents the monthly cron job from accidentally 
    -- creating two identical snapshots for the same month and district.
    UNIQUE(period, period_type, district)
);
