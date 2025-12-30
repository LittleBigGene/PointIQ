-- ============================================================================
-- Quick Views for Easy Querying
-- ============================================================================

-- Simple match list view (just the basics)
CREATE OR REPLACE VIEW match_list AS
SELECT 
    m.id,
    m.start_date,
    m.end_date,
    m.opponent_name,
    COUNT(DISTINCT p.id) FILTER (WHERE p.outcome = 'my_winner') as points_won,
    COUNT(DISTINCT p.id) FILTER (WHERE p.outcome = 'i_missed') as points_lost,
    CASE 
        WHEN COUNT(DISTINCT p.id) FILTER (WHERE p.outcome = 'my_winner') > 
             COUNT(DISTINCT p.id) FILTER (WHERE p.outcome = 'i_missed') 
        THEN 'W'
        WHEN COUNT(DISTINCT p.id) FILTER (WHERE p.outcome = 'my_winner') < 
             COUNT(DISTINCT p.id) FILTER (WHERE p.outcome = 'i_missed') 
        THEN 'L'
        ELSE 'T'
    END as result
FROM matches m
LEFT JOIN points p ON p.match_id = m.id AND p.deleted_at IS NULL
WHERE m.deleted_at IS NULL
GROUP BY m.id, m.start_date, m.end_date, m.opponent_name
ORDER BY m.start_date DESC;

-- Game detail view (shows each game with its points)
CREATE OR REPLACE VIEW game_details AS
SELECT 
    g.id as game_id,
    g.match_id,
    m.opponent_name,
    g.game_number,
    g.start_date as game_start,
    g.end_date as game_end,
    g.player_serves_first,
    COUNT(DISTINCT p.id) as total_points,
    COUNT(DISTINCT p.id) FILTER (WHERE p.outcome = 'my_winner') as points_won,
    COUNT(DISTINCT p.id) FILTER (WHERE p.outcome = 'i_missed') as points_lost,
    CASE 
        WHEN COUNT(DISTINCT p.id) FILTER (WHERE p.outcome = 'my_winner') > 
             COUNT(DISTINCT p.id) FILTER (WHERE p.outcome = 'i_missed') 
        THEN 'Won'
        WHEN COUNT(DISTINCT p.id) FILTER (WHERE p.outcome = 'my_winner') < 
             COUNT(DISTINCT p.id) FILTER (WHERE p.outcome = 'i_missed') 
        THEN 'Lost'
        ELSE 'Tied'
    END as game_result
FROM games g
JOIN matches m ON m.id = g.match_id
LEFT JOIN points p ON p.game_id = g.id AND p.deleted_at IS NULL
WHERE g.deleted_at IS NULL AND m.deleted_at IS NULL
GROUP BY g.id, g.match_id, m.opponent_name, g.game_number, g.start_date, g.end_date, g.player_serves_first
ORDER BY g.match_id, g.game_number;

-- Point breakdown by outcome type
CREATE OR REPLACE VIEW point_statistics AS
SELECT 
    m.id as match_id,
    m.opponent_name,
    p.outcome,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY m.id), 2) as percentage
FROM matches m
JOIN points p ON p.match_id = m.id
WHERE m.deleted_at IS NULL AND p.deleted_at IS NULL
GROUP BY m.id, m.opponent_name, p.outcome
ORDER BY m.start_date DESC, p.outcome;

-- ============================================================================
-- Usage Examples:
-- ============================================================================
--
-- Quick match list:
-- SELECT * FROM match_list;
--
-- Games for a specific match:
-- SELECT * FROM game_details WHERE match_id = 'your-match-uuid-here';
--
-- Point statistics for all matches:
-- SELECT * FROM point_statistics;
--
-- Point statistics for a specific match:
-- SELECT * FROM point_statistics WHERE match_id = 'your-match-uuid-here';
-- ============================================================================

