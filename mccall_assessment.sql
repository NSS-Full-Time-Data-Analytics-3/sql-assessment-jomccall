-- Data:
SELECT *
FROM poem_emotion;
-- "author" cols: id(int), name(charvar), grade_id(int), gender_id(int)
-- "emotion" cols: id(int), name(charvar) --> 1:Anger, 2:Fear, 3:Sadness, 4:Joy
-- "gender" cols: id(int), name(charvar) --> 1:Female, 2:Male, 3:Ambiguous, 4:NA
-- "grade" cols: id(int), name(charvar) --> 1 - 5 corresponds with grade in text
-- "poem" cols: id(int), title(charvar), text(text), author_id(int), char_count(int), poki_num(int)
-- "poem_emotion" cols: id(int), intensity_percent(int) (MAX 99, MIN 0), poem_id, emotion_id(int)

/*The poetry in this database is the work of children in grades 1 through 5.
a. How many poets from each grade are represented in the data?: 623 poets from 1st grade, 1,437 from 2nd grade, 2,344 from 3rd grade, 
3,288 from 4th grade, and 3,464 from 5th grade
b. How many of the poets in each grade are Male and how many are Female? Only return the poets identified as Male or Female.
1st: 243 F, 163 M; 2nd: 605 F, 412 M; 3rd 948 F, 577 M; 4th 1,241 F, 723 M; 5th 1,294 F, 757 M
c. Do you notice any trends across all grades? In all represented grades there are more female poets than male poets.*/

-- a)
SELECT grade_id AS grade, COUNT(id) AS count_students_per_grade
FROM author
GROUP BY grade_id
ORDER BY grade;
-- b)
WITH females_per_grade AS 
	(SELECT grade_id, COUNT(gender_id) AS females_per_grade
	 FROM author
	 WHERE gender_id = 1
	GROUP BY grade_id),
	 males_per_grade AS
	 (SELECT grade_id, COUNT(gender_id) AS males_per_grade
	 FROM author
	 WHERE gender_id = 2
	GROUP BY grade_id)
SELECT fpg.grade_id AS grade, 
	--COUNT(a.id) AS count_students_per_grade, 
	fpg.females_per_grade, 
	mpg.males_per_grade
FROM females_per_grade AS fpg
	INNER JOIN males_per_grade AS mpg
	ON fpg.grade_id = mpg.grade_id
ORDER BY grade;
	 
/* #2. Love and death have been popular themes in poetry throughout time. 
Which of these things do children write about more often? 
Which do they have the most to say about when they do? 
Return the total number of poems, their average character count for poems that 
mention death and poems that mention love. Do this in a single query.*/

/* Children write about love (4,546x) more often than hate (637x), but their poems about hate
have slightly more characters on average (297.93) than their poems about love (225.75).*/

-- I don't know if it's poor practice to create a mutual field like I've done here to join CTE's, but it worked.
WITH love_poems AS 
	(SELECT 'join' AS id, COUNT(id) AS love_poems, 
	 ROUND(AVG(char_count), 2) AS love_poem_avg_characters
	FROM poem
	WHERE text ILIKE '%love%' OR title ILIKE '%love%'),
	hate_poems AS 
	(SELECT 'join' AS id, COUNT(id) AS hate_poems,  
	 ROUND(AVG(char_count), 2) AS hate_poem_avg_characters
	FROM poem
	WHERE text ILIKE '%hate%' OR title ILIKE '%hate%')
SELECT lp.love_poems, hp.hate_poems, lp.love_poem_avg_characters, hp.hate_poem_avg_characters
FROM love_poems AS lp
	INNER JOIN hate_poems AS hp
	ON lp.id = hp.id;

/* #3a. Do longer poems have more emotional intensity compared to shorter poems?
Start by writing a query to return each emotion in the database with it's average intensity and character count.
Which emotion is associated the longest poems on average?: Poems associated with sadness have the longest
average character count - 491.
Which emotion has the shortest?: Poems associated with joy have the shortest average character count - 74.*/

SELECT emo.name, emo.id, 
	AVG(pemo.intensity_percent)::integer AS avg_intensity, 
	AVG(p.char_count)::integer AS avg_char_count
FROM emotion as emo
	INNER JOIN poem as p
	ON emo.id = p.id
	INNER JOIN poem_emotion as pemo
	ON emo.id = pemo.id
GROUP BY emo.name, emo.id
ORDER BY avg_char_count DESC;

/* #3b. Convert the query you wrote in part a into a CTE.: The CTE is very altered, but done.
Then find the 5 most intense poems that express joy and whether they are to be longer or shorter than the average joy poem.:
The average characters for the top 5 most intense joyful poems are: 336, 54, 271, 123, and 195. The average length is 74, so only one
(interestingly, one in the tie for most intense) is shorter than the average.
What is the most joyful poem about?: Identity, and a cat eating breakfast. These are tied at 98% intensity.
Do you think these are all classified correctly?: It's hard to say, the identity one seems a bit existential which isn't necessarily joyful,
and the cat one seems silly which may be why it's classified as joyful. I added in the emotional id to the query to be sure.*/

WITH joy AS
	(SELECT p.id, pe.intensity_percent AS intensity_percent,
	 p.char_count AS char_count, pe.emotion_id AS emo_id
	 FROM poem AS p
	 INNER JOIN poem_emotion AS pe
	 ON p.id = pe.id
	 WHERE pe.emotion_id = 4)
SELECT p.text, j.intensity_percent::integer AS intensity, j.char_count::integer AS avg_chars, j.emo_id
FROM poem as p
	INNER JOIN joy AS j
	ON j.id = p.id
ORDER BY intensity DESC
LIMIT 5; 

/* #4. Compare the 5 most angry poems by 1st graders to the 5 most angry poems by 5th graders.
a. Which group writes the angreist poems according to the intensity score?: 5th graders, with 90% intensity compared to
1st graders with 87% intensity.

b. Who shows up more in the top five for grades 1 and 5, males or females? Females show up more in the top 5 in 5th grade (4 of 5),
but males show up more in 1st grade (3 of 5).

c. Which of these do you like the best?
My favorite is this 5th grader's poem (doesn't seem that angry...): 
what  do you  see in the sea?  animals moving  free!                           
flat  fish fat fish chasing cat fish   what do you see in the sea? animals moving free!*/

-- 5th grade top 5
SELECT p.text AS top_five_5thgrade_angry_poems, pe.intensity_percent, a.gender_id
FROM author AS a
	INNER JOIN poem_emotion AS pe
	ON a.id = pe.id
	INNER JOIN poem AS p
	ON p.id = a.id
WHERE a.grade_id = 5 AND pe.emotion_id = 1
ORDER BY pe.intensity_percent DESC
LIMIT 5;
-- 1st grade top 5
SELECT p.text AS top_five_1stgrade_angry_poems, pe.intensity_percent, a.gender_id
FROM author AS a
	INNER JOIN poem_emotion AS pe
	ON a.id = pe.id
	INNER JOIN poem AS p
	ON p.id = a.id
WHERE a.grade_id = 1 AND pe.emotion_id = 1
ORDER BY pe.intensity_percent DESC
LIMIT 5;
-- 5th grade avg intensity for top 5 angry poems: 90
WITH top_five_5th_angry AS
	(SELECT a.id, pe.intensity_percent
	FROM author AS a
		INNER JOIN poem_emotion AS pe
		ON a.id = pe.id
	WHERE a.grade_id = 5 AND pe.emotion_id = 1
	ORDER BY pe.intensity_percent DESC
	LIMIT 5)
SELECT AVG(intensity_percent)::integer AS avg_intensity_top5thgrade_angriest
FROM top_five_5th_angry;
-- 1st grade avg intensity for top 5 angry poems: 87
WITH top_five_1st_angry AS
	(SELECT a.id, pe.intensity_percent
	FROM author AS a
		INNER JOIN poem_emotion AS pe
		ON a.id = pe.id
	WHERE a.grade_id = 1 AND pe.emotion_id = 1
	ORDER BY pe.intensity_percent DESC
	LIMIT 5)
SELECT AVG(intensity_percent)::integer AS avg_intensity_top1stgrade_angriest
FROM top_five_1st_angry;

/* #5. a. Examine the poets in the database with the name emily. 
Create a report showing the count of emilys by grade along with the distribution of emotions that characterize their work.
b. Export this report to Excel and create a visualization that shows what you have found.*/
	
WITH emily_count_per_grade AS 
	(SELECT grade_id, COUNT(name) AS emily_count
	FROM author AS a
	WHERE name ILIKE '%EMILY%' OR name ILIKE '%EMILEE%'
	GROUP BY grade_id),
	intensity_anger_per_grade AS
	(SELECT grade_id, AVG(intensity_percent)::integer AS anger_intensity
	FROM author AS a
	INNER JOIN poem_emotion AS pe
	ON a.id = pe.id
	WHERE name ILIKE '%EMILY%' OR name ILIKE '%EMILEE%'
	AND emotion_id = 1
	GROUP BY grade_id),
	intensity_fear_per_grade AS
	(SELECT grade_id, AVG(intensity_percent)::integer AS fear_intensity
	FROM author AS a
	INNER JOIN poem_emotion AS pe
	ON a.id = pe.id
	WHERE name ILIKE '%EMILY%' OR name ILIKE '%EMILEE%'
	AND emotion_id = 2
	GROUP BY grade_id),
	intensity_sadness_per_grade AS
	(SELECT grade_id, AVG(intensity_percent)::integer AS sadness_intensity
	FROM author AS a
	INNER JOIN poem_emotion AS pe
	ON a.id = pe.id
	WHERE name ILIKE '%EMILY%' OR name ILIKE '%EMILEE%'
	AND emotion_id = 3
	GROUP BY grade_id),
	intensity_joy_per_grade AS
	(SELECT grade_id, AVG(intensity_percent)::integer AS joy_intensity
	FROM author AS a
	INNER JOIN poem_emotion AS pe
	ON a.id = pe.id
	WHERE name ILIKE '%EMILY%' OR name ILIKE '%EMILEE%'
	AND emotion_id = 4
	GROUP BY grade_id),
	overall_intensity_per_grade AS
	(SELECT grade_id, AVG(intensity_percent)::integer AS overall_intensity
	FROM author AS a
	INNER JOIN poem_emotion AS pe
	ON a.id = pe.id
	WHERE name ILIKE '%EMILY%' OR name ILIKE '%EMILEE%'
	GROUP BY grade_id),
	overall_intensity_per_grade_non_emily AS
	(SELECT grade_id, AVG(intensity_percent)::integer AS overall_intensity_non_emily
	FROM author AS a
	INNER JOIN poem_emotion AS pe
	ON a.id = pe.id
	GROUP BY grade_id)
SELECT ec.grade_id AS grade, ec.emily_count, anger.anger_intensity, fear.fear_intensity, 
sadness.sadness_intensity, joy.joy_intensity, overall.overall_intensity, overallnonem.overall_intensity_non_emily
FROM emily_count_per_grade AS ec
	INNER JOIN intensity_anger_per_grade AS anger
	ON ec.grade_id = anger.grade_id
	INNER JOIN intensity_fear_per_grade AS fear
	ON ec.grade_id = fear.grade_id
	INNER JOIN intensity_sadness_per_grade AS sadness
	ON ec.grade_id = sadness.grade_id
	INNER JOIN intensity_joy_per_grade AS joy
	ON ec.grade_id = joy.grade_id
	INNER JOIN overall_intensity_per_grade AS overall
	ON ec.grade_id = overall.grade_id
	INNER JOIN overall_intensity_per_grade_non_emily AS overallnonem
	ON ec.grade_id = overallnonem.grade_id;
	