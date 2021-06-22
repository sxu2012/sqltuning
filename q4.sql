USE springboardopt;

-- -------------------------------------
SET @v1 = 1612521;
SET @v2 = 1145072;
SET @v3 = 1828467;
SET @v4 = 'MGT382';
SET @v5 = 'Amber Hill';
SET @v6 = 'MGT';
SET @v7 = 'EE';			  
SET @v8 = 'MAT';

-- 4. List the names of students who have taken a course taught by professor v5 (name).
EXPLAIN ANALYZE SELECT name FROM Student,
	(SELECT studId FROM Transcript,
		(SELECT crsCode, semester FROM Professor
			JOIN Teaching
			WHERE Professor.name = @v5 AND Professor.id = Teaching.profId) as alias1
	WHERE Transcript.crsCode = alias1.crsCode AND Transcript.semester = alias1.semester) as alias2
WHERE Student.id = alias2.studId;

-- The bottle neck is from table scans of the student, professor and transcript tables, see below from EXPLAIN:
-- '-> Inner hash join (student.id = transcript.studId)  (cost=1313.72 rows=160) (actual time=0.317..0.317 rows=0 loops=1)\n    -> Table scan on Student  (cost=0.03 rows=400) (never executed)\n    -> Hash\n        -> Inner hash join (professor.id = teaching.profId)  (cost=1144.90 rows=4) (actual time=0.305..0.305 rows=0 loops=1)\n            -> Filter: (professor.`name` = <cache>((@v5)))  (cost=0.95 rows=4) (never executed)\n                -> Table scan on Professor  (cost=0.95 rows=400) (never executed)\n            -> Hash\n                -> Filter: ((teaching.semester = transcript.semester) and (teaching.crsCode = transcript.crsCode))  (cost=1010.70 rows=100) (actual time=0.290..0.290 rows=0 loops=1)\n                    -> Inner hash join (<hash>(teaching.semester)=<hash>(transcript.semester)), (<hash>(teaching.crsCode)=<hash>(transcript.crsCode))  (cost=1010.70 rows=100) (actual time=0.290..0.290 rows=0 loops=1)\n                        -> Table scan on Teaching  (cost=0.01 rows=100) (actual time=0.006..0.088 rows=100 loops=1)\n                        -> Hash\n                            -> Table scan on Transcript  (cost=10.25 rows=100) (actual time=0.027..0.109 rows=100 loops=1)\n'

-- Once indexes are added to student, professor and teaching and transcript tables:
-- '-> Nested loop inner join  (cost=49.22 rows=1) (actual time=0.996..0.996 rows=0 loops=1)\n    -> Nested loop inner join  (cost=48.86 rows=1) (actual time=0.994..0.994 rows=0 loops=1)\n        -> Nested loop inner join  (cost=45.25 rows=10) (actual time=0.334..0.972 rows=1 loops=1)\n            -> Filter: ((teaching.profId is not null) and (teaching.crsCode is not null))  (cost=10.25 rows=100) (actual time=0.070..0.224 rows=100 loops=1)\n                -> Table scan on Teaching  (cost=10.25 rows=100) (actual time=0.069..0.197 rows=100 loops=1)\n            -> Filter: (professor.`name` = <cache>((@v5)))  (cost=0.25 rows=0) (actual time=0.007..0.007 rows=0 loops=100)\n                -> Index lookup on Professor using idx_professor_id (id=teaching.profId)  (cost=0.25 rows=1) (actual time=0.005..0.007 rows=1 loops=100)\n        -> Filter: ((transcript.semester = teaching.semester) and (transcript.studId is not null))  (cost=0.26 rows=0) (actual time=0.022..0.022 rows=0 loops=1)\n            -> Index lookup on Transcript using idx_transcript_crsCode (crsCode=teaching.crsCode)  (cost=0.26 rows=1) (actual time=0.016..0.021 rows=2 loops=1)\n    -> Index lookup on Student using idx_student_id (id=transcript.studId)  (cost=0.35 rows=1) (never executed)\n'

