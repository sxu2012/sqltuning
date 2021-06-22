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

-- 1. List the name of the student with id equal to v1 (id).

EXPLAIN ANALYZE SELECT name FROM Student WHERE id = @v1;

-- bottleneck: EXPLAIN shows the above query did a scan of the student table, 
-- '-> Filter: (student.id = <cache>((@v1)))  (cost=41.00 rows=40) (actual time=0.115..2.847 rows=1 loops=1)\n    -> Table scan on Student  (cost=41.00 rows=400) (actual time=0.058..2.808 rows=400 loops=1)\n'

-- Add an index to the id column of the student table, the result became:
-- '-> Index lookup on Student using idx_student_id (id=(@v1))  (cost=0.35 rows=1) (actual time=0.740..0.745 rows=1 loops=1)\n'


SELECT name FROM student WHERE id = @v1;
