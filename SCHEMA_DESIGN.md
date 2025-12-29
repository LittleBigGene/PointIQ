# Database Schema Design Philosophy

This document explains the design decisions made for the PointIQ database schema to ensure it remains flexible and minimizes the need for data migrations.

## Design Principles

### 1. **Normalized Structure with Denormalization Where Needed**

- **Three-tier hierarchy**: Matches → Games → Points
- **Foreign keys** maintain referential integrity
- **Denormalized fields** (e.g., `points.game_number`) for performance without breaking relationships

### 2. **Future-Proofing Strategies**

#### UUIDs for Primary Keys
- All IDs use UUIDs (except `points.id` which uses app-generated composite ID for compatibility)
- UUIDs prevent ID collisions and are globally unique
- Easy to merge data from multiple sources in the future

#### Soft Deletes
- `deleted_at` timestamp instead of hard deletes
- Allows data recovery and audit trails
- Queries filter out deleted records with `WHERE deleted_at IS NULL`

#### JSONB Metadata Fields
- `metadata` JSONB columns on all main tables
- Store flexible data without schema changes
- Examples of future use:
  - Location data (GPS coordinates, venue name)
  - Weather conditions
  - Equipment used (paddle, ball type)
  - Tournament information
  - Custom tags or categories
  - Video timestamps
  - Notes or annotations

#### User ID Support
- `user_id` field in `matches` table (nullable for now)
- Ready for multi-user support without migration
- Can add authentication later and populate existing records

### 3. **Performance Optimizations**

#### Strategic Indexing
- Indexes on foreign keys for join performance
- Composite indexes for common query patterns
- GIN indexes on JSONB fields for flexible queries
- Partial indexes (with `WHERE deleted_at IS NULL`) for efficiency

#### Views for Common Queries
- `active_matches` - Quick access to ongoing matches
- `completed_matches` - Historical matches
- `match_summary` - Pre-aggregated statistics

#### Helper Functions
- `get_match_stats()` - Calculated statistics without complex queries
- Can add more functions as needed

### 4. **Data Integrity**

#### Constraints
- Foreign key constraints with CASCADE deletes
- Check constraints for data validation (e.g., date ranges, valid outcomes)
- Unique constraints (e.g., match_id + game_number)

#### Audit Trail
- `created_at` - When record was created
- `updated_at` - Auto-updated on changes (via trigger)
- `deleted_at` - Soft delete timestamp

### 5. **Extensibility Without Migrations**

#### Adding New Features

**Option 1: Use Metadata JSONB**
```sql
-- Store location without schema change
UPDATE matches 
SET metadata = jsonb_set(metadata, '{location}', '"San Francisco"')
WHERE id = '...';
```

**Option 2: Add Nullable Columns**
```sql
-- Add new field without breaking existing data
ALTER TABLE matches ADD COLUMN tournament_id UUID;
-- All existing rows will have NULL, which is fine
```

**Option 3: Create Related Tables**
```sql
-- New feature as separate table
CREATE TABLE match_tags (
    match_id UUID REFERENCES matches(id),
    tag TEXT,
    PRIMARY KEY (match_id, tag)
);
```

## Schema Evolution Strategy

### Phase 1: Current (Single User)
- All `user_id` fields are NULL
- Public RLS policies
- Local-first with cloud sync

### Phase 2: Multi-User (Future)
- Add authentication
- Populate `user_id` for existing records
- Update RLS policies: `USING (auth.uid() = user_id)`
- No schema migration needed!

### Phase 3: Advanced Features (Future)
- Use `metadata` JSONB for new features
- Add related tables as needed
- Leverage views and functions for complex queries

## Migration Avoidance Techniques

1. **Nullable Fields**: New columns added as nullable won't break existing queries
2. **Default Values**: Sensible defaults for new required fields
3. **JSONB Flexibility**: Store varying structures without schema changes
4. **Views as Abstractions**: Change underlying tables without breaking queries
5. **Soft Deletes**: Never lose data, just mark as deleted

## Example: Adding a New Feature

Let's say you want to add "match location" in the future:

**Without Migration:**
```sql
-- Just use metadata
UPDATE matches 
SET metadata = jsonb_set(COALESCE(metadata, '{}'::jsonb), '{location}', '"SF Tennis Club"')
WHERE id = '...';
```

**With Migration (if you want it as a column):**
```sql
-- Add nullable column (safe, no data loss)
ALTER TABLE matches ADD COLUMN location TEXT;
-- Populate from metadata if needed
UPDATE matches SET location = metadata->>'location' WHERE metadata ? 'location';
```

## Query Patterns Optimized

1. **Get all points for a match**: `idx_points_match_id`
2. **Get all points for a game**: `idx_points_game_id`
3. **Recent matches**: `idx_matches_start_date DESC`
4. **Points by outcome**: `idx_points_outcome`
5. **Match statistics**: `match_summary` view
6. **Active matches**: `active_matches` view

## Security Considerations

### Current Setup
- Public RLS policies (all operations allowed)
- Suitable for single-user or development

### Production Setup (Future)
1. Enable Supabase Authentication
2. Update RLS policies:
   ```sql
   CREATE POLICY "Users can only access their own matches" ON matches
       FOR ALL
       USING (auth.uid() = user_id);
   ```
3. No schema changes needed!

## Performance Characteristics

- **Insert Performance**: Optimized with minimal indexes on write-heavy tables
- **Query Performance**: Comprehensive indexes for read patterns
- **Storage**: JSONB is efficient for sparse metadata
- **Scalability**: UUIDs and proper indexing support horizontal scaling

## Maintenance

### Regular Tasks
- Monitor index usage (PostgreSQL `pg_stat_user_indexes`)
- Analyze tables periodically (`ANALYZE`)
- Review and optimize slow queries

### Future Enhancements
- Partitioning for very large tables (by date range)
- Materialized views for complex aggregations
- Full-text search on notes/metadata if needed

## Conclusion

This schema design prioritizes:
1. **Flexibility** - Easy to extend without migrations
2. **Performance** - Optimized for common query patterns
3. **Integrity** - Proper constraints and relationships
4. **Maintainability** - Clear structure and documentation
5. **Future-proofing** - Ready for multi-user, new features, and scale

The design allows you to add features, support multiple users, and scale without major data migrations for years to come.

