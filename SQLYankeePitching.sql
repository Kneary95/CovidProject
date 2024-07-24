--Checking if Data is in properly

SELECT *
FROM YankeesPitching..yankeesstaffstats

Select *
FROM YankeesPitching..YankeesLastPitchData

-- Questions to answer:
-- Question 1: Average pitches
-- 1a AVG Pitches per at bat

Select AVG(pitch_number) AS AvgnumofpitchesperAB
FROM YankeesPitching..YankeesLastPitchData

-- 1b Avg pitches per at bat Home & Away

Select 'Home' TyoeofGame,
	AVG(pitch_number) AS AvgnumofpitchesperAB
	FROM YankeesPitching..YankeesLastPitchData
WHERE home_team = 'NYY'
UNION
Select 'Away' TypeofGame,
	AVG(pitch_number) AS AvgnumofpitchesperAB
	FROM YankeesPitching..YankeesLastPitchData
WHERE away_team = 'NYY'

-- Yankee pitchers are more efficient at Home Games

-- 1c Avg pitches per at bat lefty vs righty

Select 
	AVG(CASE WHEN batter_position = 'L' Then pitch_number end) AS LeftyatBats,
	AVG(CASE WHEN batter_position = 'R' Then pitch_number end) AS RightyatBats
FROM YankeesPitching..YankeesLastPitchData

-- More Pitches per at bat against lefties

-- 1d avg pitches per at bat lefty vs righty away games

Select DISTINCT
	home_team, pitcher_position,
	AVG(pitch_number) OVER (Partition BY home_team, pitcher_position) AS Average_Pitches
FROM YankeesPitching..YankeesLastPitchData
WHERE away_team = 'NYY'
ORDER BY home_team ASC

-- Can see which teams take more pitches based on if pitcher is Righty or Lefty. 
-- Some teams arent played as often because they are in different league.


-- 1e Top 3 most common pitches for at bat 1 through 10 and totals.

with totalpitch AS (
	SELECT DISTINCT
		pitch_name, pitch_number, 
	count (pitch_name) OVER (Partition BY pitch_name, pitch_number) Pitchfrequency
FROM YankeesPitching..YankeesLastPitchData
WHERE pitch_number < 11 
), 
pitchfrequencyrank AS (
	SELECT pitch_name, pitch_number, pitchfrequency,
	rank() OVER (Partition by pitch_number ORDER BY pitchfrequency DESC) AS PitchFrequencyRank
FROM totalpitch
)

SELECT *
FROM pitchfrequencyrank
WHERE pitchfrequencyrank < 4

-- For the most part sinker, 4 seam fastball, and changeup are the most common last pitches of an at bat.

-- 1f Avg pitches per at bat per pitcher with 15+ innings

SELECT YSS.name, 
	avg(pitch_number) AS AVGPitches 
FROM YankeesPitching..YankeesLastPitchData YLP
JOIN YankeesPitching..yankeesstaffstats YSS ON YLP.pitcher = YSS.pitcher_id
WHERE IP >= 15
GROUP BY YSS.name
ORDER BY avg(pitch_number) DESC

-- Ron Marinaccio is the most inefficient per at bat
-- Despite being the best yankee pitcher Gerrit Cole has 7th highest pitches per at bat on team

-- Question 2 Last Pitch Analysis
-- 2a Count of the last pitches thrown

SELECT pitch_name, count(*) AS PitchThrown
FROM YankeesPitching..YankeesLastPitchData
GROUP BY pitch_name
ORDER BY count(*) DESC

-- Split-Finger was only thrown twice as the last pitch

-- 2b Count of the different last pitches Fastball or offspeed

SELECT
	sum(CASE WHEN pitch_name IN ('4-Seam Fastball', 'Cutter') then 1 else 0 end) Fastball,
	sum(CASE WHEN pitch_name NOT IN ('4-Seam Fastball', 'Cutter') then 1 else 0 end) Offspeed
FROM YankeesPitching..YankeesLastPitchData

-- Offspeed is twice as likely as a last pitch of an at bat

-- 2c Percentage of different last pitches

SELECT
	100 * sum(CASE WHEN pitch_name IN ('4-Seam Fastball', 'Cutter') then 1 else 0 end) / count(*) FastballPercent,
	100 * sum(CASE WHEN pitch_name NOT IN ('4-Seam Fastball', 'Cutter') then 1 else 0 end) / count(*) OffspeedPercent
FROM YankeesPitching..YankeesLastPitchData

-- 2d Top 5 most common last pitch for relief vs starting pitcher vs closer

SELECT *
FROM (
	SELECT PitchThrown.pos, 
		PitchThrown.pitch_name,
		Pitchthrown.Timesthrown,
		rank() OVER (Partition By PitchThrown.pos ORDER BY PitchThrown.pitch_name DESC) PitchRank

	FROM (
		SELECT YSS.pos, YLP.pitch_name, count(*) AS Timesthrown
		FROM YankeesPitching..YankeesLastPitchData YLP
		JOIN YankeesPitching..yankeesstaffstats YSS ON YLP.pitcher = YSS.pitcher_id
		GROUP BY YSS.POS, YLP.pitch_name) 
	PitchThrown
) SubQuery2
WHERE SubQuery2.Pitchrank < 6

-- Sinkers were the most common last pitch for all three roles

-- Question 3 Homerun Analysis

-- 3a What pitches give the most HRs

SELECT pitch_name, count(*) AS homerunCount
FROM YankeesPitching..YankeesLastPitchData
WHERE events = 'home_run'
GROUP BY pitch_name 
ORDER BY count(*) DESC

-- Changeup is thrown less as a last pitch compared to sinker, but ties with homeruns thrown.

-- 3b Hrs given up by zone and pitch. Top 5 most common

SELECT TOP 5 ZONE, pitch_name, count(*) AS HRs
FROM YankeesPitching..YankeesLastPitchData
WHERE events = 'home_run'
GROUP BY ZONE, pitch_name
ORDER BY count(*) DESC

-- Surprised to see that a fastball in zone 2 has more than zone 5 which is right down the middle.

-- 3c Hrs for each pitch count type (Balls/Strikes)

SELECT YSS.pos, YLP.balls, YLP.strikes, count(*) AS HRs
	FROM YankeesPitching..YankeesLastPitchData YLP
	JOIN YankeesPitching..yankeesstaffstats YSS ON YLP.pitcher = YSS.pitcher_id
	WHERE events = 'home_run'
GROUP BY YSS.pos, YLP.balls, YLP.strikes
ORDER BY count(*) DESC

-- Starting pitchers give up the most homeruns on a 0-0 count
-- 3-0 count unsurprisingly dont give up a lot of homeruns. Batters are more hesistant to swing is my hypothesis.

-- Show each pitchers most common count to give up a HR (Min 20 IP)

with hrcountpitchers as (
SELECT YSS.name, YLP.balls, YLP.strikes, count(*) AS HRs
	FROM YankeesPitching..YankeesLastPitchData YLP
	JOIN YankeesPitching..yankeesstaffstats YSS ON YLP.pitcher = YSS.pitcher_id
	WHERE events = 'home_run' and IP >= 20
GROUP BY YSS.name, YLP.balls, YLP.strikes
), 
hrcountranks as (
	SELECT hcp.name, hcp.balls, hcp.strikes, hcp.HRs,
	rank() OVER (Partition BY NAME ORDER BY HRs DESC) HRRank
	FROM hrcountpitchers hcp
)

SELECT * 
FROM hrcountranks
WHERE HRRANk = 1

-- Clark Schmidt has given up the most home runs on a 0 - 1 count

-- Question 4 Gerrit Cole Stats

-- SELECT *
	FROM YankeesPitching..YankeesLastPitchData YLP
	JOIN YankeesPitching..yankeesstaffstats YSS ON YLP.pitcher = YSS.pitcher_id

-- 4a Avg Release speed, spin rate, strikeouts, most popular zone

SELECT 
	AVG(release_speed) AvgReleaseSpeed,
	AVG(release_spin_rate) AvgSpinRate,
	SUM(case when events = 'Strikeout' THEN 1 else 0 end) Strikeouts,
	MAX(zones.zone) AS Zone
FROM YankeesPitching..YankeesLastPitchData  YLP
JOIN (
	SELECT TOP 1 pitcher, zone, count(*) zonenum
	FROM YankeesPitching..YankeesLastPitchData 
	WHERE player_name = 'Cole, Gerrit'
	GROUP BY pitcher, zone
	ORDER BY count(*) DESC
	) 
Zones ON zones.pitcher = YLP.pitcher
WHERE player_name = 'Cole, Gerrit'

-- Gerritt Cole average strikeout speed is 92.73 and most likely gets people in Zone 14 which is slightly off the strike zone.

-- 4b top pitches for each position where total pitches are over 5

SELECT *
FROM (
	SELECT pitch_name, count(*) timeshit, 'Third' Position
	FROM YankeesPitching..YankeesLastPitchData 
	WHERE hit_location = 5 and player_name = 'Cole, Gerrit'
	GROUP BY pitch_name
	UNION
	SELECT pitch_name, count(*) timeshit, 'Short' Position
	FROM YankeesPitching..YankeesLastPitchData 
	WHERE hit_location = 6 and player_name = 'Cole, Gerrit'
	GROUP BY pitch_name
	UNION
	SELECT pitch_name, count(*) timeshit, 'Second' Position
	FROM YankeesPitching..YankeesLastPitchData 
	WHERE hit_location = 4 and player_name = 'Cole, Gerrit'
	GROUP BY pitch_name
	UNION
	SELECT pitch_name, count(*) timeshit, 'First' Position
	FROM YankeesPitching..YankeesLastPitchData 
	WHERE hit_location = 3 and player_name = 'Cole, Gerrit'
	GROUP BY pitch_name
) a
WHERE timeshit > 4
ORDER BY timeshit DESC

-- 4c Different balls/strikes as well as frequency when someone is on base

SELECT balls, strikes, count(*) Frequency
FROM YankeesPitching..YankeesLastPitchData
WHERE (on_3b is NOT NULL OR on_2b is NOT NULL OR on_1b is NOT NULL)
and player_name = 'Cole, Gerrit'
group by balls, strikes
ORDER By count(*) DESC

-- Gerrit Cole will usually get the last pitch when someone is on base with 2 strikes..


-- 4d pitch that causes lowest launch speed
SELECT pitch_name, avg(launch_speed * 1.00) AS Launch_Speed
FROM YankeesPitching..YankeesLastPitchData
Where player_name = 'Cole, Gerrit'
GROUP BY pitch_name
ORDER BY avg(Launch_Speed)
-- Changeup as lowest launch speed

-- 4e Most common strikeout last pitch against lefties vs righties

SELECT pitch_name, batter_position, count(*) AS strikeouts
FROM YankeesPitching..YankeesLastPitchData
Where player_name = 'Cole, Gerrit' and events = 'strikeout'
GROUP BY pitch_name, batter_position
ORDER BY strikeouts DESC

-- Cole is way more likely to strikeout right handed batters with a slider.
-- Cole is way more likely to strikeout left handed batters with a knuckle curve

-- Question 5 - When player on base

-- 5a - Which Pitch is thrown most often when player on base.
SELECT pitch_name, count(*) Frequency
FROM YankeesPitching..YankeesLastPitchData
WHERE (on_3b is NOT NULL OR on_2b is NOT NULL OR on_1b is NOT NULL)
group by pitch_name
ORDER By count(*) DESC

-- Sinker is thrown most often

-- 5B - Different Events when runner on base.
SELECT events, count(*) Frequency
FROM YankeesPitching..YankeesLastPitchData
WHERE (on_3b is NOT NULL OR on_2b is NOT NULL OR on_1b is NOT NULL)
group by events
ORDER By count(*) DESC

-- 5c - pitch per at bat with Runners on base
SELECT pitch_number, count(*) AS Frequency
FROM YankeesPitching..YankeesLastPitchData
WHERE (on_3b is NOT NULL OR on_2b is NOT NULL OR on_1b is NOT NULL)
group by pitch_number
ORDER By count(*) DESC



