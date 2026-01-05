-- ============================================================================
-- PointIQ Database Schema V2 - ML-Focused Design
-- Core Design Principles:
-- 1. Points are facts (what happened, when)
-- 2. Labels are interpretations (human / AI / task-separated)
-- 3. Video alignment is first-class
-- 4. Models are explicit entities
-- 5. UI convenience ≠ training truth
-- ============================================================================

-- ============================================================================
-- DROP EXISTING TABLES (in reverse dependency order)
-- ============================================================================

-- Drop all existing tables (clean slate)
DROP TABLE IF EXISTS labels CASCADE;
DROP TABLE IF EXISTS video_segments CASCADE;
DROP TABLE IF EXISTS model_training_runs CASCADE;
DROP TABLE IF EXISTS models CASCADE;
DROP TABLE IF EXISTS point_events CASCADE;
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
DROP FUNCTION IF EXISTS get_latest_labels(UUID) CASCADE;

-- ============================================================================
-- ENABLE EXTENSIONS
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For text similarity searches

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
    elo_rating INTEGER DEFAULT 1000, -- 4-digit Elo rating (1000-9999), default 1000 for unrated players
    home_club TEXT DEFAULT '',
    
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
    CONSTRAINT valid_elo_rating CHECK (elo_rating IS NULL OR (elo_rating >= 1000 AND elo_rating <= 9999)),
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
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,
    opponent_profile_id UUID REFERENCES player_profiles(id),
    best_of INTEGER NOT NULL CHECK (best_of IN (1,3,5,7)),
    start_date TIMESTAMPTZ DEFAULT NOW(),
    end_date TIMESTAMPTZ,
    notes TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- Indexes for matches
CREATE INDEX idx_matches_user_id ON matches(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_matches_start_date ON matches(start_date DESC) WHERE deleted_at IS NULL;
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
-- POINTS TABLE (FACTS ONLY)
-- Stores immutable facts: what happened, when
-- NO interpretations, NO labels, NO UI convenience fields
-- ============================================================================
CREATE TABLE points (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- External ID (app-generated composite ID, e.g., "match-uuid_game-num_point-num")
    external_point_id TEXT UNIQUE,
    
    -- Foreign Keys
    match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    game_id UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
    
    -- FACT: When did this point occur?
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- FACT: Who won the point? (objective fact)
    point_winner TEXT NOT NULL, -- 'me' or 'opponent'
    
    -- FACT: Did player make contact with ball?
    contact_made BOOLEAN NOT NULL DEFAULT false,
    
    -- FACT: Game number (denormalized for performance)
    game_number INTEGER NOT NULL,
    
    -- FACT: Raw metadata (sensor data, etc.)
    raw_metadata JSONB DEFAULT '{}'::jsonb, -- Raw sensor data, accelerometer, etc.
    
    -- Audit fields
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ, -- Soft delete support
    
    -- Constraints
    CONSTRAINT valid_point_winner CHECK (point_winner IN ('me', 'opponent'))
);

-- Indexes for points (optimized for fact queries)
CREATE INDEX idx_points_external_id ON points(external_point_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_points_match_id ON points(match_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_points_game_id ON points(game_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_points_timestamp ON points(timestamp DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_points_game_number ON points(game_number) WHERE deleted_at IS NULL;
CREATE INDEX idx_points_match_game ON points(match_id, game_number) WHERE deleted_at IS NULL;
CREATE INDEX idx_points_created_at ON points(created_at DESC) WHERE deleted_at IS NULL;

-- GIN index for JSONB raw_metadata
CREATE INDEX idx_points_raw_metadata ON points USING GIN (raw_metadata) WHERE deleted_at IS NULL;

-- ============================================================================
-- POINT EVENTS TABLE (DETAILED EVENT LOG)
-- Granular event log for each point (optional, for detailed analysis)
-- Each event in the sequence can be expanded here
-- ============================================================================
CREATE TABLE point_events (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Foreign Key
    point_id UUID NOT NULL REFERENCES points(id) ON DELETE CASCADE,
    
    -- Event Data
    event_type TEXT NOT NULL, -- 'serve', 'receive', 'rally_stroke', 'ball_bounce', 'ball_out', etc.
    event_order INTEGER NOT NULL, -- Order within the point (0-indexed)
    timestamp_offset_ms INTEGER NOT NULL DEFAULT 0, -- Milliseconds offset from point timestamp
    
    -- Event-specific data
    event_data JSONB DEFAULT '{}'::jsonb, -- Flexible event-specific data
    
    -- Audit fields
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_event_order CHECK (event_order >= 0),
    CONSTRAINT unique_point_event_order UNIQUE (point_id, event_order)
);

-- Indexes for point_events
CREATE INDEX idx_point_events_point_id ON point_events(point_id);
CREATE INDEX idx_point_events_event_type ON point_events(event_type);
CREATE INDEX idx_point_events_order ON point_events(point_id, event_order);

-- ============================================================================
-- VIDEO SEGMENTS TABLE (FIRST-CLASS VIDEO ALIGNMENT)
-- Links video files and timestamps to points
-- ============================================================================
CREATE TABLE video_segments (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Foreign Keys
    point_id UUID NOT NULL REFERENCES points(id) ON DELETE CASCADE,
    match_id UUID REFERENCES matches(id) ON DELETE CASCADE, -- Denormalized for quick queries
    
    -- Video File Reference
    video_file_path TEXT, -- Path to video file (local or cloud storage)
    video_file_url TEXT, -- URL if stored in cloud (S3, etc.)
    video_file_id TEXT, -- Reference ID if using video storage service
    
    -- Video Alignment (FIRST-CLASS)
    start_timestamp_ms BIGINT NOT NULL, -- Start time in video (milliseconds)
    end_timestamp_ms BIGINT NOT NULL, -- End time in video (milliseconds)
    point_timestamp TIMESTAMPTZ NOT NULL, -- Reference to point timestamp for alignment
    
    -- Video Metadata
    video_metadata JSONB DEFAULT '{}'::jsonb, -- Video resolution, fps, codec, etc.
    
    -- Alignment Quality
    alignment_confidence DECIMAL(3,2) DEFAULT 1.0, -- 0.0 to 1.0, how confident is the alignment?
    alignment_method TEXT, -- 'manual', 'automatic', 'ml_model_v1', etc.
    
    -- Audit fields
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT valid_timestamp_range CHECK (end_timestamp_ms > start_timestamp_ms),
    CONSTRAINT valid_confidence CHECK (alignment_confidence >= 0.0 AND alignment_confidence <= 1.0)
);

-- Indexes for video_segments
CREATE INDEX idx_video_segments_point_id ON video_segments(point_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_video_segments_match_id ON video_segments(match_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_video_segments_video_file ON video_segments(video_file_path) WHERE deleted_at IS NULL;
CREATE INDEX idx_video_segments_alignment ON video_segments(point_timestamp, start_timestamp_ms) WHERE deleted_at IS NULL;

-- ============================================================================
-- MODELS TABLE (EXPLICIT MODEL ENTITIES)
-- Tracks ML models, their versions, and metadata
-- ============================================================================
CREATE TABLE models (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Model Identity
    model_name TEXT NOT NULL, -- e.g., 'stroke_classifier', 'outcome_predictor'
    model_version TEXT NOT NULL, -- e.g., 'v1.0', 'v2.3', semantic versioning
    model_type TEXT NOT NULL, -- 'classification', 'regression', 'detection', etc.
    
    -- Model Storage
    model_file_path TEXT, -- Path to model file (local or cloud)
    model_file_url TEXT, -- URL if stored in cloud
    model_hash TEXT, -- SHA256 hash of model file for integrity
    
    -- Model Metadata
    framework TEXT, -- 'pytorch', 'tensorflow', 'coreml', etc.
    architecture TEXT, -- Model architecture name
    model_metadata JSONB DEFAULT '{}'::jsonb, -- Hyperparameters, training config, etc.
    
    -- Status
    status TEXT NOT NULL DEFAULT 'draft', -- 'draft', 'training', 'evaluating', 'production', 'deprecated'
    
    -- Audit fields
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT valid_status CHECK (status IN ('draft', 'training', 'evaluating', 'production', 'deprecated')),
    CONSTRAINT unique_model_version UNIQUE (model_name, model_version)
);

-- Indexes for models
CREATE INDEX idx_models_name ON models(model_name) WHERE deleted_at IS NULL;
CREATE INDEX idx_models_status ON models(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_models_name_version ON models(model_name, model_version) WHERE deleted_at IS NULL;

-- ============================================================================
-- MODEL TRAINING RUNS TABLE
-- Tracks training runs for models
-- ============================================================================
CREATE TABLE model_training_runs (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Foreign Key
    model_id UUID NOT NULL REFERENCES models(id) ON DELETE CASCADE,
    
    -- Training Data
    training_dataset_query TEXT, -- SQL query or filter that defines training data
    training_dataset_size INTEGER, -- Number of points/labels used
    validation_dataset_size INTEGER, -- Number of points/labels used for validation
    
    -- Training Results
    training_metrics JSONB DEFAULT '{}'::jsonb, -- Loss, accuracy, etc. over epochs
    validation_metrics JSONB DEFAULT '{}'::jsonb, -- Validation metrics
    final_metrics JSONB DEFAULT '{}'::jsonb, -- Final test metrics
    
    -- Training Metadata
    training_config JSONB DEFAULT '{}'::jsonb, -- Hyperparameters, optimizer, etc.
    training_duration_seconds INTEGER, -- How long training took
    
    -- Audit fields
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_completion CHECK (completed_at IS NULL OR completed_at >= started_at)
);

-- Indexes for model_training_runs
CREATE INDEX idx_training_runs_model_id ON model_training_runs(model_id);
CREATE INDEX idx_training_runs_started_at ON model_training_runs(started_at DESC);

-- ============================================================================
-- LABELS TABLE (INTERPRETATIONS)
-- Stores interpretations of points (human or AI labels)
-- Multiple labels per point allowed (different sources, tasks, models)
-- ============================================================================
CREATE TABLE labels (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Foreign Keys
    point_id UUID NOT NULL REFERENCES points(id) ON DELETE CASCADE,
    
    -- Label Source
    label_source TEXT NOT NULL, -- 'human' or 'ai'
    human_labeler_id UUID, -- User ID for human labels
    ai_model_id UUID REFERENCES models(id) ON DELETE SET NULL, -- Model ID for AI labels
    
    -- Label Task
    -- Separates different labeling tasks to avoid partial labels and noisy supervision
    label_task TEXT NOT NULL, -- 'outcome', 'stroke', 'serve', 'receive', 'rally'
    
    -- Label State
    is_active BOOLEAN NOT NULL DEFAULT true, -- Is this the active label?
    
    -- Label Data (INTERPRETATIONS)
    -- Fields are task-specific: outcome for 'outcome', serve_type for 'serve', etc.
    outcome TEXT, -- 'my_winner', 'i_missed', 'opponent_error', 'my_error', 'unlucky'
    serve_type TEXT, -- Serve type interpretation
    receive_type TEXT, -- Receive type interpretation
    rally_types TEXT[], -- Rally type interpretations
    stroke_tokens TEXT[], -- Stroke token interpretations (UI convenience)
    luck_factor TEXT, -- 'none', 'net or edge'
    
    -- Label Metadata
    confidence DECIMAL(3,2), -- 0.0 to 1.0, confidence in label (for AI labels)
    data_split TEXT DEFAULT 'train', -- ML data split: 'train', 'val', 'test' - prevents data leakage and ensures consistent splits
    label_metadata JSONB DEFAULT '{}'::jsonb, -- Additional label data
    
    -- Audit fields
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT valid_label_source CHECK (label_source IN ('human', 'ai')),
    CONSTRAINT valid_label_task CHECK (label_task IN ('outcome', 'stroke', 'serve', 'receive', 'rally')),
    CONSTRAINT valid_data_split CHECK (data_split IN ('train', 'val', 'test')),
    CONSTRAINT valid_labeler CHECK (
        (label_source = 'human' AND human_labeler_id IS NOT NULL AND ai_model_id IS NULL)
        OR
        (label_source = 'ai' AND ai_model_id IS NOT NULL AND human_labeler_id IS NULL)
    ),
    CONSTRAINT valid_outcome CHECK (outcome IS NULL OR outcome IN ('my_winner', 'i_missed', 'opponent_error', 'my_error', 'unlucky')),
    CONSTRAINT valid_luck_factor CHECK (luck_factor IS NULL OR luck_factor IN ('none', 'net or edge')),
    CONSTRAINT valid_confidence CHECK (confidence IS NULL OR (confidence >= 0.0 AND confidence <= 1.0))
);

-- Indexes for labels
CREATE INDEX idx_labels_point_id ON labels(point_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_labels_ai_model_id ON labels(ai_model_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_labels_human_labeler_id ON labels(human_labeler_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_labels_source ON labels(label_source) WHERE deleted_at IS NULL;
CREATE INDEX idx_labels_task ON labels(label_task) WHERE deleted_at IS NULL;
CREATE INDEX idx_labels_data_split ON labels(data_split) WHERE deleted_at IS NULL;
CREATE INDEX idx_labels_active ON labels(point_id, is_active) WHERE deleted_at IS NULL AND is_active = true;
-- Unique constraint: Only one active label per task per point
CREATE UNIQUE INDEX uniq_active_label_per_task ON labels(point_id, label_task) WHERE is_active = true AND deleted_at IS NULL;
CREATE INDEX idx_labels_outcome ON labels(outcome) WHERE deleted_at IS NULL;
CREATE INDEX idx_labels_created_at ON labels(created_at DESC) WHERE deleted_at IS NULL;

-- GIN index for JSONB label_metadata
CREATE INDEX idx_labels_metadata ON labels USING GIN (label_metadata) WHERE deleted_at IS NULL;

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

-- Apply triggers to all tables with updated_at
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

CREATE TRIGGER update_video_segments_updated_at
    BEFORE UPDATE ON video_segments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_models_updated_at
    BEFORE UPDATE ON models
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_labels_updated_at
    BEFORE UPDATE ON labels
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

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
        COUNT(p.id) FILTER (WHERE p.point_winner = 'me')::BIGINT as points_won,
        COUNT(p.id) FILTER (WHERE p.point_winner = 'opponent')::BIGINT as points_lost,
        COUNT(DISTINCT g.id)::BIGINT as total_games,
        COUNT(DISTINCT g.id) FILTER (WHERE g.end_date IS NOT NULL AND 
            (SELECT COUNT(*) FROM points WHERE game_id = g.id AND point_winner = 'me') >
            (SELECT COUNT(*) FROM points WHERE game_id = g.id AND point_winner = 'opponent'))::BIGINT as games_won,
        COUNT(DISTINCT g.id) FILTER (WHERE g.end_date IS NOT NULL AND 
            (SELECT COUNT(*) FROM points WHERE game_id = g.id AND point_winner = 'me') <
            (SELECT COUNT(*) FROM points WHERE game_id = g.id AND point_winner = 'opponent'))::BIGINT as games_lost
    FROM matches m
    LEFT JOIN games g ON g.match_id = m.id AND g.deleted_at IS NULL
    LEFT JOIN points p ON p.match_id = m.id AND p.deleted_at IS NULL
    WHERE m.id = match_uuid AND m.deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql;

-- Function to get latest active labels for a point
CREATE OR REPLACE FUNCTION get_latest_labels(point_id_param UUID)
RETURNS TABLE (
    label_id UUID,
    label_source TEXT,
    label_task TEXT,
    outcome TEXT,
    serve_type TEXT,
    receive_type TEXT,
    rally_types TEXT[],
    confidence DECIMAL,
    data_split TEXT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        l.id,
        l.label_source,
        l.label_task,
        l.outcome,
        l.serve_type,
        l.receive_type,
        l.rally_types,
        l.confidence,
        l.data_split,
        l.created_at
    FROM labels l
    WHERE l.point_id = point_id_param
        AND l.is_active = true
        AND l.deleted_at IS NULL
    ORDER BY l.created_at DESC;
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
    COUNT(DISTINCT p.id) FILTER (WHERE p.point_winner = 'me') as points_won,
    COUNT(DISTINCT p.id) FILTER (WHERE p.point_winner = 'opponent') as points_lost
FROM matches m
LEFT JOIN games g ON g.match_id = m.id AND g.deleted_at IS NULL
LEFT JOIN points p ON p.match_id = m.id AND p.deleted_at IS NULL
WHERE m.deleted_at IS NULL
GROUP BY m.id;

-- Note: For ML training, query labels table directly with task-specific filters:
-- Example: SELECT p.*, l.* FROM points p
--          INNER JOIN labels l ON l.point_id = p.id
--          WHERE l.label_source = 'human'
--            AND l.label_task = 'outcome'  -- Task-specific!
--            AND l.is_active = true
--            AND l.data_split = 'train'     -- Split-specific!
--            AND p.deleted_at IS NULL
--            AND l.deleted_at IS NULL
--          LEFT JOIN video_segments v ON v.point_id = p.id AND v.deleted_at IS NULL;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE player_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE games ENABLE ROW LEVEL SECURITY;
ALTER TABLE points ENABLE ROW LEVEL SECURITY;
ALTER TABLE point_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE video_segments ENABLE ROW LEVEL SECURITY;
ALTER TABLE models ENABLE ROW LEVEL SECURITY;
ALTER TABLE model_training_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE labels ENABLE ROW LEVEL SECURITY;

-- Policy: Allow operations for authenticated users or anonymous users (user_id IS NULL)
-- Authenticated users can access their own data, anonymous users can access data with NULL user_id
CREATE POLICY "Allow operations on player_profiles" ON player_profiles
    FOR ALL
    USING (auth.uid() IS NOT NULL OR user_id IS NULL)
    WITH CHECK (auth.uid() IS NOT NULL OR user_id IS NULL);

CREATE POLICY "Allow operations on matches" ON matches
    FOR ALL
    USING (auth.uid() IS NOT NULL OR user_id IS NULL)
    WITH CHECK (auth.uid() IS NOT NULL OR user_id IS NULL);

-- Games: Accessible if the match belongs to the user
CREATE POLICY "Allow operations on games" ON games
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM matches m
            WHERE m.id = games.match_id
            AND (m.user_id = auth.uid() OR m.user_id IS NULL)
            AND m.deleted_at IS NULL
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM matches m
            WHERE m.id = games.match_id
            AND (m.user_id = auth.uid() OR m.user_id IS NULL)
            AND m.deleted_at IS NULL
        )
    );

-- Points: Accessible if the match belongs to the user
CREATE POLICY "Allow operations on points" ON points
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM matches m
            WHERE m.id = points.match_id
            AND (m.user_id = auth.uid() OR m.user_id IS NULL)
            AND m.deleted_at IS NULL
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM matches m
            WHERE m.id = points.match_id
            AND (m.user_id = auth.uid() OR m.user_id IS NULL)
            AND m.deleted_at IS NULL
        )
    );

-- Point events: Accessible if the point's match belongs to the user
CREATE POLICY "Allow operations on point_events" ON point_events
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM points p
            JOIN matches m ON m.id = p.match_id
            WHERE p.id = point_events.point_id
            AND (m.user_id = auth.uid() OR m.user_id IS NULL)
            AND m.deleted_at IS NULL
            AND p.deleted_at IS NULL
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM points p
            JOIN matches m ON m.id = p.match_id
            WHERE p.id = point_events.point_id
            AND (m.user_id = auth.uid() OR m.user_id IS NULL)
            AND m.deleted_at IS NULL
            AND p.deleted_at IS NULL
        )
    );

-- Video segments: Accessible if the point's match belongs to the user
CREATE POLICY "Allow operations on video_segments" ON video_segments
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM points p
            JOIN matches m ON m.id = p.match_id
            WHERE p.id = video_segments.point_id
            AND (m.user_id = auth.uid() OR m.user_id IS NULL)
            AND m.deleted_at IS NULL
            AND p.deleted_at IS NULL
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM points p
            JOIN matches m ON m.id = p.match_id
            WHERE p.id = video_segments.point_id
            AND (m.user_id = auth.uid() OR m.user_id IS NULL)
            AND m.deleted_at IS NULL
            AND p.deleted_at IS NULL
        )
    );

-- Models: Readable by all authenticated users, writable by creators (if user_id added later)
-- For now, allow all authenticated users to read/write models
CREATE POLICY "Allow operations on models" ON models
    FOR ALL
    USING (auth.uid() IS NOT NULL)
    WITH CHECK (auth.uid() IS NOT NULL);

-- Model training runs: Accessible if the model is accessible
CREATE POLICY "Allow operations on model_training_runs" ON model_training_runs
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM models m
            WHERE m.id = model_training_runs.model_id
            AND m.deleted_at IS NULL
        )
        AND auth.uid() IS NOT NULL
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM models m
            WHERE m.id = model_training_runs.model_id
            AND m.deleted_at IS NULL
        )
        AND auth.uid() IS NOT NULL
    );

-- Labels: Accessible if the point's match belongs to the user
CREATE POLICY "Allow operations on labels" ON labels
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM points p
            JOIN matches m ON m.id = p.match_id
            WHERE p.id = labels.point_id
            AND (m.user_id = auth.uid() OR m.user_id IS NULL)
            AND m.deleted_at IS NULL
            AND p.deleted_at IS NULL
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM points p
            JOIN matches m ON m.id = p.match_id
            WHERE p.id = labels.point_id
            AND (m.user_id = auth.uid() OR m.user_id IS NULL)
            AND m.deleted_at IS NULL
            AND p.deleted_at IS NULL
        )
    );

-- ============================================================================
-- COMMENTS (Documentation)
-- ============================================================================

COMMENT ON TABLE player_profiles IS 'Stores both player and opponent profile information';
COMMENT ON TABLE matches IS 'Stores match-level information with future-proofing for multi-user support';
COMMENT ON TABLE games IS 'Stores game-level information within matches';
COMMENT ON TABLE points IS 'FACTS ONLY: Immutable facts about what happened, when. No interpretations, no labels, no UI convenience fields.';
COMMENT ON TABLE point_events IS 'Granular event log for each point (optional, for detailed analysis)';
COMMENT ON TABLE video_segments IS 'FIRST-CLASS: Video alignment and timestamps for points';
COMMENT ON TABLE models IS 'EXPLICIT ENTITIES: ML models, versions, and metadata';
COMMENT ON TABLE model_training_runs IS 'Tracks training runs for models';
COMMENT ON TABLE labels IS 'INTERPRETATIONS: Human or AI labels for points. Multiple labels per point allowed. Each label represents a specific task (outcome, stroke, serve, receive, rally).';

COMMENT ON COLUMN points.point_winner IS 'FACT: Objective fact - who won the point';
COMMENT ON COLUMN points.raw_metadata IS 'FACT: Raw sensor data, accelerometer readings, etc.';
COMMENT ON COLUMN labels.label_source IS 'INTERPRETATION SOURCE: human or ai';
COMMENT ON COLUMN labels.label_task IS 'LABEL TASK: Separates different labeling tasks (outcome, stroke, serve, receive, rally) to avoid partial labels and noisy supervision for ML training';
COMMENT ON COLUMN labels.data_split IS 'ML DATA SPLIT: train/val/test assignment. Prevents data leakage, ensures consistent splits across training runs, and prevents accidental test contamination. Critical for frequent retraining.';
COMMENT ON COLUMN labels.is_active IS 'Is this the active label for this point?';
COMMENT ON COLUMN labels.confidence IS 'Confidence in label (0.0-1.0), typically for AI labels';
COMMENT ON COLUMN video_segments.alignment_confidence IS 'How confident is the video-to-point alignment?';
COMMENT ON COLUMN video_segments.alignment_method IS 'How was alignment done: manual, automatic, ml_model_v1, etc.';
COMMENT ON COLUMN models.status IS 'Model status: draft, training, evaluating, production, deprecated';

-- ============================================================================
-- SCHEMA NOTES
-- ============================================================================

-- V2 Schema Design Principles:
-- 1. Points are facts (what happened, when) - NO interpretations in points table
-- 2. Labels are interpretations (human / AI / task-separated) - Separate table, multiple per point
-- 3. Video alignment is first-class - Dedicated video_segments table with alignment metadata
-- 4. Models are explicit entities - models table tracks ML models and versions
-- 5. UI convenience ≠ training truth - Query labels directly with task-specific filters for both UI and ML

-- Key Features:
-- - Points table stores only immutable facts: timestamp, point_winner, contact_made
-- - Event details stored in point_events table (normalized, detailed event log)
-- - Labels table stores interpretations: outcome, serve_type, receive_type, rally_types, etc.
-- - Multiple labels per point allowed (human + AI labels), separated by task (outcome, stroke, serve, receive, rally)
-- - Only one active label per task per point (enforced by unique index)
-- - Data splits (train/val/test) stored at label level to prevent data leakage
-- - Video alignment with confidence scores and alignment methods
-- - Model tracking with versions, training runs, and performance metrics
-- - Separate views for UI convenience vs ML training truth

-- Usage:
-- - For UI: Query labels table directly with appropriate filters (label_task, is_active, label_source)
-- - For ML Training: Query labels table directly with task-specific filters:
--   * Filter by label_task (outcome, stroke, serve, receive, rally) for task-specific models
--   * Filter by data_split (train, val, test) to prevent data leakage
--   * Filter by label_source = 'human' for ground truth
--   * Join with points and video_segments as needed
-- - For Video: Query video_segments table for video-to-point alignment
-- - For Models: Track model versions and training runs in models and model_training_runs tables

