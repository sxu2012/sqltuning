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

-- 3. List the names of students who have taken course v4 (crsCode).
EXPLAIN ANALYZE SELECT name FROM Student WHERE id IN (SELECT studId FROM Transcript WHERE crsCode = @v4);

-- bottle neck is the table scan on student and transcript tables, see below result with EXPLAIN:
-- '-> Inner hash join (student.id = `<subquery2>`.studId)  (cost=414.91 rows=400) (actual time=3.211..4.087 rows=2 loops=1)\n    -> Table scan on Student  (cost=5.04 rows=400) (actual time=0.837..1.674 rows=400 loops=1)\n    -> Hash\n        -> Table scan on <subquery2>  (cost=0.26..2.62 rows=10) (actual time=0.001..0.002 rows=2 loops=1)\n            -> Materialize with deduplication  (cost=11.51..13.88 rows=10) (actual time=2.307..2.308 rows=2 loops=1)\n                -> Filter: (transcript.studId is not null)  (cost=10.25 rows=10) (actual time=2.202..2.294 rows=2 loops=1)\n                    -> Filter: (transcript.crsCode = <cache>((@v4)))  (cost=10.25 rows=10) (actual time=2.200..2.292 rows=2 loops=1)\n                        -> Table scan on Transcript  (cost=10.25 rows=100) (actual time=2.127..2.247 rows=100 loops=1)\n'

-- After adding index on studion.id:
-- '-> Nested loop inner join  (cost=5.50 rows=10) (actual time=0.138..0.145 rows=2 loops=1)\n    -> Filter: (`<subquery2>`.studId is not null)  (cost=10.33..2.00 rows=10) (actual time=0.120..0.120 rows=2 loops=1)\n        -> Table scan on <subquery2>  (cost=0.26..2.62 rows=10) (actual time=0.001..0.001 rows=2 loops=1)\n            -> Materialize with deduplication  (cost=11.51..13.88 rows=10) (actual time=0.119..0.120 rows=2 loops=1)\n                -> Filter: (transcript.studId is not null)  (cost=10.25 rows=10) (actual time=0.065..0.114 rows=2 loops=1)\n                    -> Filter: (transcript.crsCode = <cache>((@v4)))  (cost=10.25 rows=10) (actual time=0.064..0.113 rows=2 loops=1)\n                        -> Table scan on Transcript  (cost=10.25 rows=100) (actual time=0.041..0.093 rows=100 loops=1)\n    -> Index lookup on Student using idx_student_id (id=`<subquery2>`.studId)  (cost=2.60 rows=1) (actual time=0.010..0.011 rows=1 loops=2)\n'

-- After adding index on studion.id and transcript. crsCode, results improved below:
-- '-> Nested loop inner join  (cost=1.10 rows=2) (actual time=6.061..6.080 rows=2 loops=1)\n    -> Filter: (`<subquery2>`.studId is not null)  (cost=0.65..0.40 rows=2) (actual time=0.070..0.073 rows=2 loops=1)\n        -> Table scan on <subquery2>  (cost=1.26..2.52 rows=2) (actual time=0.001..0.002 rows=2 loops=1)\n            -> Materialize with deduplication  (cost=2.16..3.42 rows=2) (actual time=0.070..0.071 rows=2 loops=1)\n                -> Filter: (transcript.studId is not null)  (cost=0.70 rows=2) (actual time=0.054..0.062 rows=2 loops=1)\n                    -> Index lookup on Transcript using idx_transcript_crsCode (crsCode=(@v4))  (cost=0.70 rows=2) (actual time=0.053..0.061 rows=2 loops=1)\n    -> Index lookup on Student using idx_student_id (id=`<subquery2>`.studId)  (cost=0.60 rows=1) (actual time=2.999..3.002 rows=1 loops=2)\n'
