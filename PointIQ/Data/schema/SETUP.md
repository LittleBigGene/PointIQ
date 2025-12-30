# Supabase Setup Guide for PointIQ

This guide will help you set up Supabase to store your point history data in the cloud.

## Prerequisites

1. A Supabase account (sign up at https://supabase.com)
2. A Supabase project created

## Step 1: Install Supabase Swift SDK

1. Open your Xcode project
2. Go to **File** → **Add Package Dependencies...**
3. Enter the package URL: `https://github.com/supabase/supabase-swift`
4. Select the latest version
5. Add the package to your **PointIQ** target

## Step 2: Configure Supabase Credentials

1. Open `PointIQ/Data/SupabaseConfig.swift`
2. Get your Supabase project URL and API key:
   - Go to your Supabase project dashboard: https://app.supabase.com
   - Navigate to **Settings** → **API**
   - Copy your **Project URL** and **anon/public key**
3. Update `SupabaseConfig.swift`:
   ```swift
   static let supabaseURL = "https://your-project.supabase.co"
   static let supabaseKey = "your-anon-key-here"
   ```

## Step 3: Create Database Schema

Run the SQL schema file in your Supabase SQL Editor (Dashboard → SQL Editor):

1. Open the file `SUPABASE.sql` in this repository
2. Copy the entire contents
3. Paste into Supabase SQL Editor
4. Click **Run** to execute

**Note:** This script will drop all existing tables and recreate the schema from scratch. If you have existing data, make sure to back it up first.

This creates a comprehensive, future-proof schema with:
- **player_profiles** table - for player profile data (one per user)
- **matches** table - for match-level data (includes opponent profile)
- **games** table - for game-level data  
- **points** table - for point-level data
- Proper relationships with foreign keys
- Indexes for optimal query performance
- Soft delete support (deleted_at)
- JSONB metadata fields for future features
- User ID support ready for multi-user features
- Audit timestamps (created_at, updated_at)
- Helper functions and views for common queries

The schema is designed to minimize future migrations by:
- Using nullable fields where appropriate
- Providing JSONB metadata fields for flexible data
- Including user_id for future authentication
- Using soft deletes instead of hard deletes
- Comprehensive indexing strategy

## Step 4: Verify Setup

1. Build and run your app
2. Check the Xcode console for:
   - `✅ Supabase client initialized successfully` - means connection is working
   - `⚠️ Supabase not configured` - means you need to update SupabaseConfig.swift

## Step 5: Test the Integration

1. Log a point in your app
2. Check your Supabase dashboard → **Table Editor** → **points** table
3. You should see the point data appear

## Database Schema

The schema consists of four main tables with proper relationships:

### `player_profiles` Table

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID (PRIMARY KEY) | Unique identifier for the profile |
| `user_id` | UUID (nullable) | For future multi-user support |
| `profile_type` | TEXT | Type of profile: 'player' or 'opponent' |
| `name` | TEXT | Profile name (default: "YOU" for player) |
| `grip` | TEXT | Grip type (Penhold, Shakehand, Other) |
| `handedness` | TEXT | Handedness (Left-handed, Right-handed) |
| `blade` | TEXT | Blade name/model |
| `forehand_rubber` | TEXT | Forehand rubber name/model |
| `backhand_rubber` | TEXT | Backhand rubber name/model |
| `elo_rating` | TEXT | Elo rating |
| `club_name` | TEXT | Club name |
| `metadata` | JSONB | Flexible storage for future features |
| `created_at` | TIMESTAMPTZ | When the record was created |
| `updated_at` | TIMESTAMPTZ | When the record was last updated |
| `deleted_at` | TIMESTAMPTZ (nullable) | Soft delete timestamp |

**Note:** This table stores both player profiles (user's own profile, one per user) and opponent profiles (can have multiple). The `profile_type` field distinguishes between them.

### `matches` Table

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID (PRIMARY KEY) | Unique identifier for the match |
| `start_date` | TIMESTAMPTZ | When the match started |
| `end_date` | TIMESTAMPTZ (nullable) | When the match ended (NULL = active) |
| `opponent_name` | TEXT (nullable) | Denormalized opponent name for quick access |
| `notes` | TEXT (nullable) | Match notes |
| `opponent_profile_id` | UUID (nullable) | Foreign key to opponent profile in player_profiles table |
| `user_id` | UUID (nullable) | For future multi-user support |
| `metadata` | JSONB | Flexible storage for future features |
| `created_at` | TIMESTAMPTZ | When the record was created |
| `updated_at` | TIMESTAMPTZ | When the record was last updated |
| `deleted_at` | TIMESTAMPTZ (nullable) | Soft delete timestamp |

**Note:** Opponent profile information is stored in the `player_profiles` table with `profile_type='opponent'`. The `opponent_profile_id` references this profile, allowing opponent profiles to be reused across multiple matches.

### `games` Table

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID (PRIMARY KEY) | Unique identifier for the game |
| `match_id` | UUID (FOREIGN KEY) | Reference to the match |
| `game_number` | INTEGER | Game number within the match |
| `start_date` | TIMESTAMPTZ | When the game started |
| `end_date` | TIMESTAMPTZ (nullable) | When the game ended (NULL = active) |
| `player_serves_first` | BOOLEAN | Whether player served first |
| `metadata` | JSONB | Flexible storage for future features |
| `created_at` | TIMESTAMPTZ | When the record was created |
| `updated_at` | TIMESTAMPTZ | When the record was last updated |
| `deleted_at` | TIMESTAMPTZ (nullable) | Soft delete timestamp |

### `points` Table

| Column | Type | Description |
|--------|------|-------------|
| `id` | TEXT (PRIMARY KEY) | Unique identifier (app-generated composite ID) |
| `match_id` | UUID (FOREIGN KEY, nullable) | Reference to the match |
| `game_id` | UUID (FOREIGN KEY, nullable) | Reference to the game |
| `timestamp` | TIMESTAMPTZ | When the point was recorded |
| `stroke_tokens` | TEXT[] | Array of stroke token values |
| `outcome` | TEXT | Outcome (my_winner, i_missed, opponent_error, my_error, unlucky) |
| `serve_type` | TEXT (nullable) | Type of serve |
| `receive_type` | TEXT (nullable) | Type of receive |
| `rally_types` | TEXT[] | Array of rally type values |
| `game_number` | INTEGER (nullable) | Denormalized game number for quick queries |
| `metadata` | JSONB | Flexible storage for future features |
| `created_at` | TIMESTAMPTZ | When the record was created |
| `updated_at` | TIMESTAMPTZ | When the record was last updated |
| `deleted_at` | TIMESTAMPTZ (nullable) | Soft delete timestamp |

### Schema Features

- **Foreign Keys**: Proper relationships with CASCADE deletes
- **Indexes**: Optimized for common query patterns
- **Soft Deletes**: Records are marked as deleted, not removed
- **Metadata Fields**: JSONB fields for flexible future features
- **Audit Trail**: created_at and updated_at timestamps
- **Views**: Pre-built views for common queries (active_matches, completed_matches, match_summary)
- **Helper Functions**: get_match_stats() for statistics
- **Profile Support**: Both player and opponent profiles stored in `player_profiles` table, with opponent profiles referenced by matches via foreign key

## Features

- **Automatic Sync**: Points are saved to Supabase automatically when logged
- **Offline Support**: Local storage is used as a backup and for offline access
- **Data Merging**: When loading, the app merges local and remote data
- **Error Handling**: Falls back to local storage if Supabase is unavailable

## Troubleshooting

### "Supabase not configured" warning
- Make sure you've updated `SupabaseConfig.swift` with your credentials
- Verify the URL and key are correct (no extra spaces)

### "Supabase SDK not available" warning
- Make sure you've added the Supabase Swift package to your project
- Clean build folder (Cmd+Shift+K) and rebuild

### Points not appearing in Supabase
- Check your internet connection
- Verify RLS policies allow insert operations
- Check the Xcode console for error messages

### Authentication (Future Enhancement)
Currently, the setup uses public access. For production, you should:
1. Set up Supabase Authentication
2. Update RLS policies to require authentication
3. Modify `SupabaseService` to include auth tokens in requests

## Next Steps

- Add user authentication for multi-user support
- Add match-level storage for better organization
- Set up real-time subscriptions for live updates
- Add analytics and reporting features

