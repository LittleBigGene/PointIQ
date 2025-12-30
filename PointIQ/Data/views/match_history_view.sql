-- ============================================================================
-- Match History View
-- Comprehensive view showing match details with games and point statistics
-- ============================================================================

CREATE OR REPLACE VIEW match_history AS
SELECT 
    -- Match Information
    m.id as match_id,
    m.start_date as match_start,
    m.end_date as match_end,
    m.opponent_name,
    m.notes as match_notes,
    m.created_at as match_created,
    
    -- Game Statistics
    COUNT(DISTINCT g.id) as total_games,
    COUNT(DISTINCT g.id) FILTER (WHERE g.end_date IS NOT NULL) as completed_games,
    
    -- Point Statistics
    COUNT(DISTINCT p.id) as total_points,
    COUNT(DISTINCT p.id) FILTER (WHERE p.outcome = 'my_winner') as points_won,
    COUNT(DISTINCT p.id) FILTER (WHERE p.outcome = 'i_missed') as points_lost,
    COUNT(DISTINCT p.id) FILTER (WHERE p.outcome = 'opponent_error') as opponent_errors,
    COUNT(DISTINCT p.id) FILTER (WHERE p.outcome = 'my_error') as my_errors,
    COUNT(DISTINCT p.id) FILTER (WHERE p.outcome = 'unlucky') as unlucky_points,
    
    -- Win/Loss Calculation
    CASE 
        WHEN COUNT(DISTINCT p.id) FILTER (WHERE p.outcome = 'my_winner') > 
             COUNT(DISTINCT p.id) FILTER (WHERE p.outcome = 'i_missed') 
        THEN 'Won'
        WHEN COUNT(DISTINCT p.id) FILTER (WHERE p.outcome = 'my_winner') < 
             COUNT(DISTINCT p.id) FILTER (WHERE p.outcome = 'i_missed') 
        THEN 'Lost'
        ELSE 'Tied'
    END as match_result,
    
    -- Games Won/Lost
    COUNT(DISTINCT g.id) FILTER (WHERE g.end_date IS NOT NULL AND 
        (SELECT COUNT(*) FROM points WHERE game_id = g.id AND outcome = 'my_winner') >
        (SELECT COUNT(*) FROM points WHERE game_id = g.id AND outcome = 'i_missed')) as games_won,
    COUNT(DISTINCT g.id) FILTER (WHERE g.end_date IS NOT NULL AND 
        (SELECT COUNT(*) FROM points WHERE game_id = g.id AND outcome = 'my_winner') <
        (SELECT COUNT(*) FROM points WHERE game_id = g.id AND outcome = 'i_missed')) as games_lost,
    
    -- Match Duration (if completed)
    CASE 
        WHEN m.end_date IS NOT NULL 
        THEN EXTRACT(EPOCH FROM (m.end_date - m.start_date)) / 60 
        ELSE NULL 
    END as duration_minutes

FROM matches m
LEFT JOIN games g ON g.match_id = m.id AND g.deleted_at IS NULL
LEFT JOIN points p ON p.match_id = m.id AND p.deleted_at IS NULL
WHERE m.deleted_at IS NULL
GROUP BY m.id, m.start_date, m.end_date, m.opponent_name, m.notes, m.created_at
ORDER BY m.start_date DESC;

-- ============================================================================
-- Usage Examples:
-- ============================================================================
-- 
-- View all match history:
-- SELECT * FROM match_history;
--
-- View recent matches:
-- SELECT * FROM match_history ORDER BY match_start DESC LIMIT 10;
--
-- View matches against a specific opponent:
-- SELECT * FROM match_history WHERE opponent_name = 'John Doe';
--
-- View win/loss record:
-- SELECT 
--     match_result,
--     COUNT(*) as count
-- FROM match_history
-- GROUP BY match_result;
--
-- View average points per match:
-- SELECT 
--     AVG(total_points) as avg_points,
--     AVG(points_won) as avg_points_won,
--     AVG(points_lost) as avg_points_lost
-- FROM match_history
-- WHERE total_points > 0;
-- ============================================================================

