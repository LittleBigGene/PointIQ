-- ============================================================================
-- PointIQ Database Schema
-- This script drops all existing tables and recreates the schema from scratch
-- ============================================================================

-- ============================================================================
-- DROP EXISTING TABLES (in reverse dependency order)
-- ============================================================================

-- Drop tables if they exist (CASCADE will handle dependencies)
DROP TABLE IF EXISTS points CASCADE;
DROP TABLE IF EXISTS games CASCADE;
DROP TABLE IF EXISTS matches CASCADE;
DROP TABLE IF EXISTS player_profiles CASCADE;

-- Drop views if they exist
DROP VIEW IF EXISTS match_summary CASCADE;
DROP VIEW IF EXISTS completed_matches CASCADE;
DROP VIEW IF EXISTS active_matches CASCADE;

-- Drop functions if they exist
DROP FUNCTION IF EXISTS get_match_stats(UUID) CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

-- ============================================================================
-- PointIQ Database Schema
-- Future-proof design to minimize data migrations
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- PLAYER PROFILES TABLE
-- Stores both player and opponent profile information
-- ============================================================================
CREATE TABLE player_profiles (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Foreign Key
    user_id UUID, -- For future multi-user support (nullable for now)
    
    -- Profile Type
    profile_type TEXT NOT NULL DEFAULT 'player', -- 'player' or 'opponent'
    
    -- Core Profile Data
    name TEXT NOT NULL DEFAULT 'YOU',
    grip TEXT NOT NULL DEFAULT 'Shakehand', -- Penhold, Shakehand, Other
    handedness TEXT NOT NULL DEFAULT 'Right-handed', -- Left-handed, Right-handed
    blade TEXT DEFAULT '',
    forehand_rubber TEXT DEFAULT '',
    backhand_rubber TEXT DEFAULT '',
    elo_rating TEXT DEFAULT '',
    club_name TEXT DEFAULT '',
    
    -- Future-proofing fields
    metadata JSONB DEFAULT '{}'::jsonb, -- Flexible storage for future features
    
    -- Audit fields
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ, -- Soft delete support
    
    -- Constraints
    CONSTRAINT valid_profile_type CHECK (profile_type IN ('player', 'opponent')),
    CONSTRAINT valid_grip CHECK (grip IN ('Penhold', 'Shakehand', 'Other')),
    CONSTRAINT valid_handedness CHECK (handedness IN ('Left-handed', 'Right-handed')),
    CONSTRAINT unique_user_player_profile UNIQUE (user_id, profile_type) DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT unique_user_profile_name UNIQUE (user_id, profile_type, name) DEFERRABLE INITIALLY DEFERRED
);

-- Indexes for player_profiles
CREATE INDEX idx_player_profiles_user_id ON player_profiles(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_player_profiles_type ON player_profiles(profile_type) WHERE deleted_at IS NULL;
CREATE INDEX idx_player_profiles_user_type ON player_profiles(user_id, profile_type) WHERE deleted_at IS NULL;
CREATE INDEX idx_player_profiles_active ON player_profiles(deleted_at) WHERE deleted_at IS NULL;

-- ============================================================================
-- MATCHES TABLE
-- Stores match-level information
-- ============================================================================
CREATE TABLE matches (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Core Match Data
    start_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_date TIMESTAMPTZ,
    opponent_name TEXT, -- Denormalized for quick access (can be derived from opponent_profile_id)
    notes TEXT,
    
    -- Opponent Profile Reference
    opponent_profile_id UUID REFERENCES player_profiles(id) ON DELETE SET NULL,
    
    -- Future-proofing fields
    user_id UUID, -- For future multi-user support (nullable for now)
    metadata JSONB DEFAULT '{}'::jsonb, -- Flexible storage for future features
    
    -- Audit fields
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ, -- Soft delete support
    
    -- Constraints
    CONSTRAINT valid_date_range CHECK (end_date IS NULL OR end_date >= start_date)
);

-- Indexes for matches
CREATE INDEX idx_matches_user_id ON matches(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_matches_start_date ON matches(start_date DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_matches_opponent_name ON matches(opponent_name) WHERE deleted_at IS NULL;
CREATE INDEX idx_matches_opponent_profile_id ON matches(opponent_profile_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_matches_active ON matches(deleted_at) WHERE deleted_at IS NULL;

-- ============================================================================
-- GAMES TABLE
-- Stores game-level information within a match
-- ============================================================================
CREATE TABLE games (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Foreign Keys
    match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    
    -- Core Game Data
    game_number INTEGER NOT NULL,
    start_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_date TIMESTAMPTZ,
    player_serves_first BOOLEAN NOT NULL DEFAULT true,
    
    -- Future-proofing fields
    metadata JSONB DEFAULT '{}'::jsonb, -- Flexible storage for future features
    
    -- Audit fields
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ, -- Soft delete support
    
    -- Constraints
    CONSTRAINT valid_game_date_range CHECK (end_date IS NULL OR end_date >= start_date),
    CONSTRAINT unique_match_game_number UNIQUE (match_id, game_number) DEFERRABLE INITIALLY DEFERRED
);

-- Indexes for games
CREATE INDEX idx_games_match_id ON games(match_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_games_match_game_number ON games(match_id, game_number) WHERE deleted_at IS NULL;
CREATE INDEX idx_games_start_date ON games(start_date DESC) WHERE deleted_at IS NULL;

-- ============================================================================
-- POINTS TABLE
-- Stores individual point records
-- ============================================================================
CREATE TABLE points (
    -- Primary Key (using composite ID from app for compatibility)
    id TEXT PRIMARY KEY,
    
    -- Foreign Keys
    match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
    game_id UUID REFERENCES games(id) ON DELETE CASCADE,
    
    -- Core Point Data
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    stroke_tokens TEXT[] NOT NULL DEFAULT '{}',
    outcome TEXT NOT NULL,
    serve_type TEXT,
    receive_type TEXT,
    rally_types TEXT[] NOT NULL DEFAULT '{}',
    game_number INTEGER, -- Denormalized for quick queries
    
    -- Future-proofing fields
    metadata JSONB DEFAULT '{}'::jsonb, -- Flexible storage for future features (e.g., location, weather, equipment)
    
    -- Audit fields
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ, -- Soft delete support
    
    -- Constraints
    CONSTRAINT valid_outcome CHECK (outcome IN ('myWinner', 'iMissed', 'opponentError', 'myError', 'unlucky'))
);

-- Indexes for points (optimized for common queries)
CREATE INDEX idx_points_match_id ON points(match_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_points_game_id ON points(game_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_points_timestamp ON points(timestamp DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_points_game_number ON points(game_number) WHERE deleted_at IS NULL;
CREATE INDEX idx_points_outcome ON points(outcome) WHERE deleted_at IS NULL;
CREATE INDEX idx_points_match_game ON points(match_id, game_number) WHERE deleted_at IS NULL;

-- GIN index for JSONB metadata (for flexible queries)
CREATE INDEX idx_points_metadata ON points USING GIN (metadata) WHERE deleted_at IS NULL;
CREATE INDEX idx_matches_metadata ON matches USING GIN (metadata) WHERE deleted_at IS NULL;
CREATE INDEX idx_games_metadata ON games USING GIN (metadata) WHERE deleted_at IS NULL;

-- ============================================================================
-- TRIGGERS
-- Auto-update updated_at timestamps
-- ============================================================================

-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to all tables
CREATE TRIGGER update_player_profiles_updated_at
    BEFORE UPDATE ON player_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_matches_updated_at
    BEFORE UPDATE ON matches
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_games_updated_at
    BEFORE UPDATE ON games
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_points_updated_at
    BEFORE UPDATE ON points
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE player_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE games ENABLE ROW LEVEL SECURITY;
ALTER TABLE points ENABLE ROW LEVEL SECURITY;

-- Policy: Allow all operations for now (adjust when adding authentication)
-- When you add auth, change to: USING (auth.uid() = user_id)
CREATE POLICY "Allow all operations on player_profiles" ON player_profiles
    FOR ALL
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Allow all operations on matches" ON matches
    FOR ALL
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Allow all operations on games" ON games
    FOR ALL
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Allow all operations on points" ON points
    FOR ALL
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to get match statistics
CREATE OR REPLACE FUNCTION get_match_stats(match_uuid UUID)
RETURNS TABLE (
    total_points BIGINT,
    points_won BIGINT,
    points_lost BIGINT,
    total_games BIGINT,
    games_won BIGINT,
    games_lost BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(p.id)::BIGINT as total_points,
        COUNT(p.id) FILTER (WHERE p.outcome = 'myWinner')::BIGINT as points_won,
        COUNT(p.id) FILTER (WHERE p.outcome = 'iMissed')::BIGINT as points_lost,
        COUNT(DISTINCT g.id)::BIGINT as total_games,
        COUNT(DISTINCT g.id) FILTER (WHERE g.end_date IS NOT NULL AND 
            (SELECT COUNT(*) FROM points WHERE game_id = g.id AND outcome = 'myWinner') >
            (SELECT COUNT(*) FROM points WHERE game_id = g.id AND outcome = 'iMissed'))::BIGINT as games_won,
        COUNT(DISTINCT g.id) FILTER (WHERE g.end_date IS NOT NULL AND 
            (SELECT COUNT(*) FROM points WHERE game_id = g.id AND outcome = 'myWinner') <
            (SELECT COUNT(*) FROM points WHERE game_id = g.id AND outcome = 'iMissed'))::BIGINT as games_lost
    FROM matches m
    LEFT JOIN games g ON g.match_id = m.id AND g.deleted_at IS NULL
    LEFT JOIN points p ON p.match_id = m.id AND p.deleted_at IS NULL
    WHERE m.id = match_uuid AND m.deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- VIEWS (for easier querying)
-- ============================================================================

-- View for active matches
CREATE OR REPLACE VIEW active_matches AS
SELECT *
FROM matches
WHERE deleted_at IS NULL AND end_date IS NULL;

-- View for completed matches
CREATE OR REPLACE VIEW completed_matches AS
SELECT *
FROM matches
WHERE deleted_at IS NULL AND end_date IS NOT NULL;

-- View for match summary with stats
CREATE OR REPLACE VIEW match_summary AS
SELECT
    m.*,
    COUNT(DISTINCT g.id) as game_count,
    COUNT(DISTINCT p.id) as point_count,
    COUNT(DISTINCT p.id) FILTER (WHERE p.outcome = 'myWinner') as points_won,
    COUNT(DISTINCT p.id) FILTER (WHERE p.outcome = 'iMissed') as points_lost
FROM matches m
LEFT JOIN games g ON g.match_id = m.id AND g.deleted_at IS NULL
LEFT JOIN points p ON p.match_id = m.id AND p.deleted_at IS NULL
WHERE m.deleted_at IS NULL
GROUP BY m.id;

-- ============================================================================
-- COMMENTS (Documentation)
-- ============================================================================

COMMENT ON TABLE player_profiles IS 'Stores both player and opponent profile information';
COMMENT ON TABLE matches IS 'Stores match-level information with future-proofing for multi-user support';
COMMENT ON TABLE games IS 'Stores game-level information within matches';
COMMENT ON TABLE points IS 'Stores individual point records with full stroke and outcome data';

COMMENT ON COLUMN player_profiles.profile_type IS 'Type of profile: player (user own profile) or opponent';
COMMENT ON COLUMN player_profiles.user_id IS 'For future multi-user support - nullable for now. For player profiles, one per user. For opponent profiles, can have multiple.';
COMMENT ON COLUMN player_profiles.name IS 'Profile name. Unique per (user_id, profile_type, name) to prevent duplicate opponent profiles';
COMMENT ON COLUMN player_profiles.metadata IS 'JSONB field for flexible future features';
COMMENT ON COLUMN matches.user_id IS 'For future multi-user support - nullable for now';
COMMENT ON COLUMN matches.opponent_profile_id IS 'Reference to opponent profile in player_profiles table';
COMMENT ON COLUMN matches.opponent_name IS 'Denormalized opponent name for quick access (can be derived from opponent_profile_id)';
COMMENT ON COLUMN matches.metadata IS 'JSONB field for flexible future features (e.g., location, tournament info)';
COMMENT ON COLUMN games.metadata IS 'JSONB field for flexible future features';
COMMENT ON COLUMN points.metadata IS 'JSONB field for flexible future features (e.g., location, weather, equipment)';
COMMENT ON COLUMN points.game_number IS 'Denormalized for quick queries without joins';

-- ============================================================================
-- MIGRATION NOTES
-- ============================================================================

-- This schema is designed to be future-proof:
-- 1. UUIDs for all IDs (except points.id which uses app-generated composite ID)
-- 2. Soft deletes (deleted_at) instead of hard deletes
-- 3. JSONB metadata fields for flexible feature additions
-- 4. Proper foreign keys with CASCADE deletes
-- 5. Comprehensive indexes for performance
-- 6. Audit timestamps (created_at, updated_at)
-- 7. User_id field ready for multi-user support
-- 8. Views for common queries
-- 9. Helper functions for statistics
-- 10. RLS policies ready for authentication
-- 11. Player and opponent profiles stored in unified player_profiles table
-- 12. Unique constraint on (user_id, profile_type, name) prevents duplicate opponent profiles

-- Future enhancements can be added via:
-- - Adding columns (nullable to avoid breaking existing data)
-- - Using metadata JSONB fields
-- - Creating new tables with foreign keys
-- - Adding new views and functions
