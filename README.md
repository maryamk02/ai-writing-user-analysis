# AI Writing Assistant Analytics

## Overview
I built a SQL database to analyse how people interact with AI writing tools like ChatGPT. The dataset simulates 100 writing requests across 20 users (free and premium). I created the data manually using SQL INSERT statements to reflect realistic usage patterns, more free users than premium, varied request types, and different post-response behaviours.

**The goal:** understand what makes these tools work (or not work) for real users.

## Why This Matters 
Companies building AI writing assistants need to know:
- What kinds of writing tasks do people actually trust AI with?
- When do users accept what the AI gives them vs. asking for rewrites?
- Are people paying for premium features just using them more, or using them differently?
- Which types of requests frustrate users the most?

I wanted to explore these questions using actual data patterns, not just assumptions.

## The Data 
- 20 users (14 free, 6 premium — matching typical freemium splits)
- 100 writing requests across 6 categories
- 100 AI responses
- 115 user actions (some requests had multiple actions like "regenerate then accept")
- Timespan: January 2024 - February 2025

## How It's Built 
I designed a normalised database with 4 connected tables
- _users:_ Basic account info (free vs premium, signup date, activity level)
- _writing_requests:_ What people asked the AI to write (emails, blog posts, code, etc.)
- _ai_responses:_ What the AI generated (including which model and how long it took)
- _user_actions:_ What users did next (accepted it, regenerated, edited, or threw it away) 

users → writing_requests → ai_responses → user_actions

## What I Found 

**1. Content Type Affects Acceptance** 

_Key insight:_
- Blog posts: 100.0% acceptance 
- Code: 84.6% acceptance 

_Interpretation:_
- Longer-form writing appears to be trusted more than technical outputs.

_Query:_
- This query calculates how often AI responses are accepted, grouped by the type of writing request

SELECT 
    wr.request_category,
    COUNT(DISTINCT ar.response_id) as total_responses,
    SUM(
	CASE 
		WHEN ua.action_type = 'accepted' THEN 1 
		ELSE 0 
	END
	) as accepted,
    ROUND(
	100.0 * SUM(
		CASE
			WHEN ua.action_type = 'accepted' THEN 1 
			ELSE 0 
		END
	) / COUNT(DISTINCT ar.response_id), 1
	) as acceptance_rate
FROM writing_requests wr
JOIN ai_responses ar 
	ON wr.request_id = ar.request_id
LEFT JOIN user_actions ua 
	ON ar.response_id = ua.response_id
GROUP BY wr.request_category
ORDER BY acceptance_rate DESC;
  
**2. Premium Users Are More Active** 

_Key insight:_
- Premium users: 5.88 requests per user
- Free users: 4.42 requests per user 

_Interpretation:_
- Premium users made more requests on average. The difference isn’t huge, but it suggests slightly higher engagement among subscribers.

_Query:_
- Calculates the average number of requests per user, grouped by subscription (free vs premium)

SELECT 
    u.subscription_type,
    COUNT(wr.request_id) as total_requests,
    COUNT(DISTINCT u.user_id) as user_count,
    ROUND(
	1.0 * COUNT(wr.request_id) / COUNT(DISTINCT u.user_id), 2
	) as avg_requests_per_user
FROM users u
LEFT JOIN writing_requests wr 
	ON u.user_id = wr.user_id
GROUP BY u.subscription_type;

**3. Most Responses Are Accepted**

_Key insight:_
- 79.8% of responses were accepted without changes

_Interpretation:_
- Most outputs were used as-is, indicating generally strong baseline AI performance in this simulated dataset.

_Query:_
- Counts how users acted on AI outputs
- Calculates the percentage of each action type

SELECT 
    action_type,
    COUNT(*) as action_count,
    ROUND(
	100.0 * COUNT(*) / (SELECT COUNT(*) FROM user_actions), 1
	) as percentage
FROM user_actions
GROUP BY action_type
ORDER BY action_count DESC;

**4. GPT-4 Is Slightly Slower**

_Key insights:_
- GPT-4: 4.25 seconds on average per response 
- GPT-3.5: 3.72 seconds on average per response 

_Interpretation:_
- GPT-4 responses were slightly slower on average, which aligns with the common tradeoff between model complexity and speed.

_Query:_
- Calculates the average response time in seconds for each AI model used

SELECT 
    model_version,
    COUNT(*) as response_count,
    ROUND(AVG(generation_time), 2) as avg_generation_seconds,
    ROUND(MIN(generation_time), 2) as fastest,
    ROUND(MAX(generation_time), 2) as slowest
FROM ai_responses
GROUP BY model_version;

**5. Users Act Within the Same Day** 

_Key insights:_
- Average time to action: 775 minutes on average (~13 hours) 
- Edited responses were resolved slightly faster than accepted ones

_Interpretation:_
- Users typically made decisions within the same day. Edited responses being slightly faster may indicate users quickly refine outputs they partially like.

_Query:_
-  Calculates average minutes it took users to act on AI outputs, grouped by action type (accepted, edited, etc.)

SELECT 
    ua.action_type,
    COUNT(*) as action_count,
    ROUND(AVG((julianday(ua.timestamp) - julianday(wr.timestamp)) * 1440), 1) as avg_minutes_to_action
FROM user_actions ua
JOIN ai_responses ar ON ua.response_id = ar.response_id
JOIN writing_requests wr ON ar.request_id = wr.request_id
GROUP BY ua.action_type
ORDER BY avg_minutes_to_action;

## Skills & Tools
- _Database:_ SQLite
- _Interface:_ DB Browser for SQLite
- _SQL Skills Used:_
	- Database normalisation and foreign keys
	- Multi-table JOINs (LEFT, INNER)	
	- Aggregate functions (COUNT, AVG, SUM, MIN, MAX)
	- Subqueries and CASE statements
	- Date/time functions for temporal analysis
	- GROUP BY for categorical breakdowns

## If I Had More Time
- _Some ideas I'd love to explore:_
	- Track multi-turn conversations (not just single requests)
	- Add user demographics to spot patterns by user type
	- Build visualisations showing trends over time
	- Compare prompt quality — what makes a good prompt?
	- Predict which users might churn based on their behaviour
	- Analyse cost per request vs revenue by user segment

## Files in This Repo 
- schema.sql: database schema 
- queries.sql: all 20 analysis queries 
- README.md: project documentation

## Want to Recreate This?
1. Download DB Browser for SQLite
2. Run schema.sql to create the tables
3. Add your own sample data using SQL INSERT statements (I wrote mine manually to ensure realistic patterns)
4. Run the queries in queries.sql to see the patterns

**Built:** February 2025

**Skills:** SQL · Database Design · Data Analysis · Business Intelligence
