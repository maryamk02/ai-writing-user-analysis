-- ============================================
-- BASIC STATISTICS
-- ============================================

-- Query 1: How many total users do we have?
SELECT COUNT(*) as total_users FROM users;

-- Query 2: How many free vs premium users?
SELECT 
    subscription_type,
    COUNT(*) as user_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM users), 1) as percentage
FROM users
GROUP BY subscription_type;

-- Query 3: How many total writing requests have been made?
SELECT COUNT(*) as total_requests FROM writing_requests;

-- ============================================
-- USER BEHAVIOUR ANALYSIS
-- ============================================

-- Query 4: Who are the top 10 most active users?
SELECT 
    u.username,
    u.subscription_type,
    COUNT(wr.request_id) as total_requests
FROM users u
LEFT JOIN writing_requests wr ON u.user_id = wr.user_id
GROUP BY u.user_id
ORDER BY total_requests DESC
LIMIT 10;

-- Query 5: Do premium users make more requests than free users?
SELECT 
    u.subscription_type,
    COUNT(wr.request_id) as total_requests,
    COUNT(DISTINCT u.user_id) as user_count,
    ROUND(1.0 * COUNT(wr.request_id) / COUNT(DISTINCT u.user_id), 2) as avg_requests_per_user
FROM users u
LEFT JOIN writing_requests wr ON u.user_id = wr.user_id
GROUP BY u.subscription_type;

-- Query 6: How many users signed up each month?
SELECT 
    strftime('%Y-%m', signup_date) as signup_month,
    COUNT(*) as new_users
FROM users
GROUP BY signup_month
ORDER BY signup_month;

-- Query 7: Which request categories do users prefer by subscription type?
SELECT 
    u.subscription_type,
    wr.request_category,
    COUNT(*) as request_count
FROM users u
JOIN writing_requests wr ON u.user_id = wr.user_id
GROUP BY u.subscription_type, wr.request_category
ORDER BY u.subscription_type, request_count DESC;

-- Query 8: When do users most commonly use the AI (by hour)?
SELECT 
    strftime('%H', timestamp) as hour_of_day,
    COUNT(*) as requests
FROM writing_requests
GROUP BY hour_of_day
ORDER BY hour_of_day;

-- ============================================
-- REQUEST PATTERN ANALYSIS
-- ============================================

-- Query 9: Which types of writing do users request most?
SELECT 
    request_category,
    COUNT(*) as request_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM writing_requests), 1) as percentage
FROM writing_requests
GROUP BY request_category
ORDER BY request_count DESC;

-- Query 10: Which request types have longest prompts?
SELECT 
    request_category,
    ROUND(AVG(prompt_length), 1) as avg_prompt_length,
    MIN(prompt_length) as min_length,
    MAX(prompt_length) as max_length
FROM writing_requests
GROUP BY request_category
ORDER BY avg_prompt_length DESC;

-- Query 11: How many users were active each month?
SELECT 
    strftime('%Y-%m', wr.timestamp) as month,
    COUNT(DISTINCT wr.user_id) as active_users,
    COUNT(wr.request_id) as total_requests
FROM writing_requests wr
GROUP BY month
ORDER BY month;

-- ============================================
-- AI PERFORMANCE METRICS
-- ============================================

-- Query 12: What percentage of AI responses get accepted vs regenerated vs discarded?
SELECT 
    action_type,
    COUNT(*) as action_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM user_actions), 1) as percentage
FROM user_actions
GROUP BY action_type
ORDER BY action_count DESC;

-- Query 13: Which types of requests have the highest acceptance rates?
SELECT 
wr.request_category, 
COUNT(DISTINCT ar.response_id) as total_responses, 
SUM(CASE WHEN ua.action_type = 'accepted' THEN 1 ELSE 0 END) as accepted, 
ROUND(100.0 * SUM(CASE WHEN ua.action_type = 'accepted' THEN 1 ELSE 0 END) / COUNT(DISTINCT ar.response_id), 1) as acceptance_rate
FROM writing_requests wr 
JOIN ai_responses ar ON wr.request_id = ar.request_id
LEFT JOIN user_actions ua ON ar.response_id = ua.response_id
GROUP BY wr.request_category 
ORDER BY acceptance_rate DESC; 

-- Query 14: Which AI model is faster?
SELECT 
model_version, 
COUNT(*) as response_count, 
ROUND(AVG(generation_time), 2) as avg_generation_seconds, 
ROUND(MIN(generation_time), 2) as fastest, 
ROUND(MAX(generation_time), 2) as slowst 
FROM ai_responses 
GROUP BY model_version; 

-- Query 15: Do longer responses get accepted more or less? 
SELECT 
CASE 
WHEN ar.response_length < 200 THEN 'Short (<200)' 
WHEN ar.response_length < 500 THEN 'Medium (200-500)' 
WHEN ar.response_length < 1000 THEN 'Long (500-1000)' 
ELSE 'Very Long (1000+)' 
END as response_length_category, 
COUNT(ar.response_id) as total_responses, 
SUM(CASE WHEN ua.action_type = 'accepted' THEN 1 ELSE 0 END) as accepted, 
ROUND(100.0 * SUM(CASE WHEN ua.action_type = 'accepted' THEN 1 ELSE 0 END) / COUNT(ar.response_id), 1) as acceptance_rate 
FROM ai_responses ar 
LEFT JOIN user_actions ua ON ar.response_id = ua.response_id
GROUP BY response_length_category 
ORDER BY acceptance_rate DESC; 
  
-- ============================================
-- ADVANCED INSIGHTS
-- ============================================

-- Query 16: Which users edit AI outputs more frequently?
SELECT 
u.username, 
u.subscription_type,
COUNT(ua.action_id) as edit_count, 
ROUND(AVG(ua.edits_made), 1) as avg_edits_per_session 
FROM users u 
JOIN user_actions ua ON u.user_id = ua.user_id 
WHERE ua.action_type = 'edited' AND ua.edits_made > 0
GROUP BY u.user_id 
ORDER BY edit_count DESC 
LIMIT 10; 

-- Query 17: Which AI models do premium vs free users get?
SELECT 
u.subscription_type, 
ar.model_version, 
COUNT(*) as usage_count 
FROM users u 
JOIN writing_requests wr ON u.user_id = wr.user_id
JOIN ai_responses ar ON wr.request_id = ar.request_id
GROUP BY u.subscription_type, ar.model_version 
ORDER BY u.subscription_type, usage_count DESC; 

-- Query 18: Time between request and action (in minutes)
SELECT 
ua.action_type, 
COUNT(*) as action_count, 
ROUND(AVG((julianday(ua.timestamp) - julianday(wr.timestamp)) * 1440), 1) as avg_minutes_to_action
FROM user_actions ua 
JOIN ai_responses ar ON ua.response_id = ar.response_id 
JOIN writing_requests wr ON ar.request_id = wr. request_id 
GROUP BY ua.action_type 
ORDER BY avg_minutes_to_action; 

-- Query 19: Most engaged users (by total actions)
SELECT 
u.username, 
u.subscription_type, 
COUNT(ua.action_id) as total_actions, 
COUNT(DISTINCT wr.request_id) as total_requests, 
ROUND(1.0 * COUNT(ua.action_id) / COUNT(DISTINCT wr.request_id), 2) as actions_per_request 
FROM users u 
JOIN writing_requests wr ON u.user_id = wr.user_id
JOIN ai_responses ar ON wr.request_id = ar.request_id
JOIN user_actions ua ON ar.response_id = ua.response_id
GROUP BY u.user_id
ORDER BY total_actions DESC 
LIMIT 10; 

-- Query 20: Average prompt length trend over time 
SELECT 
strftime('%Y-%m', timestamp) as month, 
ROUND(AVG(prompt_length), 1) as avg_prompt_length, 
COUNT(*)  as total_requests
FROM writing_requests
GROUP BY month 
ORDER BY month; 