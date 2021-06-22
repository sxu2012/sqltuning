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

-- 2. List the names of students with id in the range of v2 (id) to v3 (inclusive).
EXPLAIN ANALYZE SELECT name FROM Student WHERE id BETWEEN @v2 AND @v3;

-- bottleneck: EXPLAIN shows the above query did a scan of the student table, 
-- '-> Filter: (student.id between <cache>((@v2)) and <cache>((@v3)))  (cost=5.44 rows=44) (actual time=5.772..6.859 rows=278 loops=1)\n    -> Table scan on Student  (cost=5.44 rows=400) (actual time=5.764..6.788 rows=400 loops=1)\n'

-- Add an index to the id column of the student table, the result became:
-- '-> Filter: (student.id between <cache>((@v2)) and <cache>((@v3)))  (cost=41.00 rows=278) (actual time=0.029..0.459 rows=278 loops=1)\n    -> Table scan on Student  (cost=41.00 rows=400) (actual time=0.026..0.394 rows=400 loops=1)\n'

