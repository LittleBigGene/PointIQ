# Database Schema Design V2 - ML-Focused Architecture 🧠

## Core Design Principles

### 1. **Points are Facts (What Happened, When)**
Points store only immutable, objective facts:
- **When**: `timestamp` - when the point occurred
- **What**: `event_sequence` - raw sequence of events (ground truth)
- **Who**: `point_winner` - objective fact of who won
- **Contact**: `contact_made` - did player touch the ball?
- **Raw Data**: `raw_metadata` - sensor data, accelerometer readings, etc.

**What's NOT in points:**
- ❌ `outcome` (interpretation: "my_winner" vs "opponent_error")
- ❌ `serve_type` (interpretation: what type of serve was it?)
- ❌ `receive_type` (interpretation: what type of receive was it?)
- ❌ `rally_types` (interpretation: what rally types occurred?)
- ❌ `stroke_tokens` (interpretation: UI convenience tokens)
- ❌ `luck_factor` (interpretation: was it lucky?)

These are all **interpretations** and belong in the `labels` table.

### 2. **Labels are Interpretations (Human / AI / Versioned)**

Labels are separate from facts. Multiple labels can exist for the same point:
- **Human labels**: Ground truth annotations by users
- **AI labels**: Predictions from ML models
- **Hybrid labels**: Human-reviewed AI labels

**Key Features:**
- **Versioned**: Track changes over time via `label_versions` table
- **Source tracking**: Know if label came from human or AI
- **Model tracking**: Link AI labels to specific model versions
- **Confidence scores**: AI labels include confidence (0.0-1.0)
- **Active flag**: Mark which label is currently active
- **Supersession**: Track when labels are replaced

**Example:**
```sql
-- Point fact
INSERT INTO points (id, match_id, game_id, timestamp, event_sequence, point_winner)
VALUES ('point-123', 'match-1', 'game-1', NOW(), 
        ARRAY['serve', 'receive', 'rally_stroke', 'ball_out'], 
        'me');

-- Human label (ground truth)
INSERT INTO labels (point_id, label_source, outcome, serve_type, rally_types)
VALUES ('point-123', 'human', 'my_winner', 'SS', ARRAY['dragon']);

-- AI label (prediction)
INSERT INTO labels (point_id, label_source, model_id, outcome, confidence)
VALUES ('point-123', 'ai', 'model-v1', 'my_winner', 0.87);
```

### 3. **Video Alignment is First-Class**

Video alignment is not an afterthought - it's a core feature:

**Video Segments Table:**
- Links video files to points
- Stores precise timestamps (milliseconds)
- Tracks alignment confidence
- Records alignment method (manual, automatic, ML-based)
- Supports multiple video files per match

**Use Cases:**
- Training video-based ML models
- Reviewing points with video playback
- Automatic point detection from video
- Video-to-point synchronization

**Example:**
```sql
INSERT INTO video_segments (
    point_id, 
    video_file_path, 
    start_timestamp_ms, 
    end_timestamp_ms,
    alignment_confidence,
    alignment_method
) VALUES (
    'point-123',
    '/videos/match-2024-01-15.mp4',
    12345,  -- Start: 12.345 seconds
    15678,  -- End: 15.678 seconds
    0.95,   -- 95% confident in alignment
    'ml_model_v2'
);
```

### 4. **Models are Explicit Entities**

ML models are first-class citizens in the database:

**Models Table:**
- Track model name, version, type
- Store model file location/hash
- Record framework, architecture, metadata
- Track status: draft → training → evaluating → production → deprecated

**Training Runs Table:**
- Link training runs to models
- Record training dataset (query/filter)
- Store training/validation metrics
- Track training duration and config

**Benefits:**
- Reproducibility: Know exactly which model version made predictions
- Audit trail: Track model performance over time
- A/B testing: Compare different model versions
- Training data versioning: Know what data trained each model

**Example:**
```sql
-- Create model
INSERT INTO models (model_name, model_version, model_type, status)
VALUES ('stroke_classifier', 'v2.3', 'classification', 'production');

-- Record training run
INSERT INTO model_training_runs (
    model_id,
    training_dataset_query,
    training_dataset_size,
    final_metrics
) VALUES (
    'model-123',
    'SELECT * FROM training_dataset_view WHERE created_at > ''2024-01-01''',
    10000,
    '{"accuracy": 0.92, "f1_score": 0.89}'::jsonb
);

-- Use model for labeling
INSERT INTO labels (point_id, label_source, model_id, outcome, confidence)
VALUES ('point-123', 'ai', 'model-123', 'my_winner', 0.87);
```

### 5. **UI Convenience ≠ Training Truth**

Two separate views serve different purposes:

**`point_labels_view` (UI Convenience):**
- Shows points with latest active labels
- Prefers human labels over AI labels
- Optimized for display in UI
- **NOT for training!**

**`training_dataset_view` (Training Truth):**
- Only includes human labels (ground truth)
- Includes video alignment data
- Includes raw metadata
- Includes model information
- **Use this for ML training!**

**Why Separate?**
- UI needs convenience: show something, even if it's AI-predicted
- Training needs truth: only human-verified labels
- Prevents data leakage: don't train on AI predictions
- Enables A/B testing: compare UI predictions vs training performance

## Schema Structure

```
matches
  └── games
      └── points (FACTS ONLY)
          ├── point_events (optional granular events)
          ├── video_segments (video alignment)
          └── labels (INTERPRETATIONS)
              ├── label_versions (change history)
              └── models (if AI label)
                  └── model_training_runs
```

## Key Tables

### `points` (Facts Only)
- `id`: UUID
- `match_id`, `game_id`: Foreign keys
- `timestamp`: When point occurred
- `event_sequence`: Raw event sequence (ground truth)
- `point_winner`: 'me' or 'opponent' (objective fact)
- `contact_made`: Boolean
- `raw_metadata`: JSONB for sensor data

### `labels` (Interpretations)
- `id`: UUID
- `point_id`: Foreign key to point
- `label_source`: 'human', 'ai', 'hybrid'
- `model_id`: Foreign key (if AI label)
- `label_version`: Integer (for versioning)
- `is_active`: Boolean (active label flag)
- `outcome`: Interpretation of outcome
- `serve_type`, `receive_type`, `rally_types`: Interpretations
- `confidence`: Decimal (0.0-1.0, for AI labels)

### `video_segments` (First-Class Video)
- `id`: UUID
- `point_id`: Foreign key to point
- `video_file_path`: Path to video file
- `start_timestamp_ms`, `end_timestamp_ms`: Video timestamps
- `alignment_confidence`: How confident is alignment?
- `alignment_method`: How was alignment done?

### `models` (Explicit Entities)
- `id`: UUID
- `model_name`: e.g., 'stroke_classifier'
- `model_version`: e.g., 'v2.3'
- `model_type`: 'classification', 'regression', etc.
- `status`: 'draft', 'training', 'evaluating', 'production', 'deprecated'
- `model_file_path`: Where model is stored
- `model_hash`: SHA256 hash for integrity

## Migration from V1

### Step 1: Extract Facts from V1 Points
```sql
-- Migrate facts only
INSERT INTO points_v2 (id, match_id, game_id, timestamp, point_winner, contact_made)
SELECT id, match_id, game_id, timestamp, point_winner, contact_made
FROM points_v1;
```

### Step 2: Create Labels from V1 Interpretations
```sql
-- Create human labels from V1 interpretations
INSERT INTO labels (point_id, label_source, outcome, serve_type, receive_type, rally_types, luck_factor)
SELECT 
    id as point_id,
    'human' as label_source,
    outcome,
    serve_type,
    receive_type,
    rally_types,
    luck_factor
FROM points_v1
WHERE outcome IS NOT NULL;
```

### Step 3: Migrate Video Data (if exists)
```sql
-- If video data was in metadata, extract it
INSERT INTO video_segments (point_id, video_file_path, start_timestamp_ms, end_timestamp_ms)
SELECT 
    id as point_id,
    metadata->>'video_file' as video_file_path,
    (metadata->>'video_start_ms')::bigint as start_timestamp_ms,
    (metadata->>'video_end_ms')::bigint as end_timestamp_ms
FROM points_v1
WHERE metadata ? 'video_file';
```

## Query Examples

### Get Points with Latest Labels (UI)
```sql
SELECT * FROM point_labels_view
WHERE match_id = 'match-123'
ORDER BY timestamp DESC;
```

### Get Training Dataset (ML)
```sql
SELECT * FROM training_dataset_view
WHERE label_created_at > '2024-01-01'
ORDER BY timestamp;
```

### Get Points with Video
```sql
SELECT 
    p.*,
    v.video_file_path,
    v.start_timestamp_ms,
    v.end_timestamp_ms
FROM points p
INNER JOIN video_segments v ON v.point_id = p.id
WHERE p.match_id = 'match-123';
```

### Get Model Predictions vs Human Labels
```sql
SELECT 
    p.id,
    l_human.outcome as human_outcome,
    l_ai.outcome as ai_outcome,
    l_ai.confidence,
    l_ai.model_id
FROM points p
LEFT JOIN labels l_human ON l_human.point_id = p.id 
    AND l_human.label_source = 'human' 
    AND l_human.is_active = true
LEFT JOIN labels l_ai ON l_ai.point_id = p.id 
    AND l_ai.label_source = 'ai' 
    AND l_ai.is_active = true
WHERE p.match_id = 'match-123';
```

### Get Label History for a Point
```sql
SELECT 
    l.*,
    lv.version_number,
    lv.changed_fields,
    lv.old_values,
    lv.new_values,
    lv.change_reason
FROM labels l
LEFT JOIN label_versions lv ON lv.label_id = l.id
WHERE l.point_id = 'point-123'
ORDER BY l.created_at DESC, lv.version_number DESC;
```

## Benefits of V2 Design

1. **ML-Ready**: Clear separation of facts vs interpretations
2. **Reproducible**: Track model versions and training data
3. **Auditable**: Full history of label changes
4. **Flexible**: Multiple labels per point (human + AI)
5. **Video-First**: Video alignment is core, not afterthought
6. **Scalable**: Can handle large-scale ML training pipelines
7. **Versioned**: Track changes to labels and models over time
8. **Truth-Preserving**: Training data is clearly separated from UI convenience

## Future Enhancements

- **Active Learning**: Track which points need human labeling
- **Label Quality Metrics**: Track inter-annotator agreement
- **Model Comparison**: Compare model performance across versions
- **Automated Labeling**: Pipeline for AI-assisted labeling
- **Video Processing**: Automatic point detection from video
- **Federated Learning**: Support for distributed training

