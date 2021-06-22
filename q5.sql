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

-- 5. List the names of students who have taken a course from department v6 (deptId), but not v7.
EXPLAIN ANALYZE SELECT * FROM Student, 
	(SELECT studId FROM Transcript, Course WHERE deptId = @v6 AND Course.crsCode = Transcript.crsCode
	AND studId NOT IN
	(SELECT studId FROM Transcript, Course WHERE deptId = @v7 AND Course.crsCode = Transcript.crsCode)) as alias
WHERE Student.id = alias.studId;

 -- '-> Filter: <in_optimizer>(transcript.studId,<exists>(select #3) is false)  (cost=4112.69 rows=4000) (actual time=0.568..9.781 rows=30 loops=1)\n    -> Inner hash join (student.id = transcript.studId)  (cost=4112.69 rows=4000) (actual time=0.289..3.083 rows=30 loops=1)\n        -> Table scan on Student  (cost=0.06 rows=400) (actual time=0.011..2.710 rows=400 loops=1)\n        -> Hash\n            -> Filter: (transcript.crsCode = course.crsCode)  (cost=110.52 rows=100) (actual time=0.135..0.254 rows=30 loops=1)\n                -> Inner hash join (<hash>(transcript.crsCode)=<hash>(course.crsCode))  (cost=110.52 rows=100) (actual time=0.135..0.247 rows=30 loops=1)\n                    -> Table scan on Transcript  (cost=0.13 rows=100) (actual time=0.014..0.105 rows=100 loops=1)\n                    -> Hash\n                        -> Filter: (course.deptId = <cache>((@v6)))  (cost=10.25 rows=10) (actual time=0.041..0.101 rows=26 loops=1)\n                            -> Table scan on Course  (cost=10.25 rows=100) (actual time=0.037..0.085 rows=100 loops=1)\n    -> Select #3 (subquery in condition; dependent)\n        -> Limit: 1 row(s)  (actual time=0.216..0.216 rows=0 loops=30)\n            -> Filter: <if>(outer_field_is_not_null, <is_not_null_test>(transcript.studId), true)  (actual time=0.216..0.216 rows=0 loops=30)\n                -> Filter: (<if>(outer_field_is_not_null, ((<cache>(transcript.studId) = transcript.studId) or (transcript.studId is null)), true) and (transcript.crsCode = course.crsCode))  (cost=110.52 rows=100) (actual time=0.216..0.216 rows=0 loops=30)\n                    -> Inner hash join (<hash>(transcript.crsCode)=<hash>(course.crsCode))  (cost=110.52 rows=100) (actual time=0.119..0.210 rows=34 loops=30)\n                        -> Table scan on Transcript  (cost=0.13 rows=100) (actual time=0.006..0.074 rows=100 loops=30)\n                        -> Hash\n                            -> Filter: (course.deptId = <cache>((@v7)))  (cost=10.25 rows=10) (actual time=0.007..0.094 rows=32 loops=30)\n                                -> Table scan on Course  (cost=10.25 rows=100) (actual time=0.004..0.075 rows=100 loops=30)\n'

-- after adding index on course.deptId, student.id:
-- '-> Nested loop inner join  (cost=97.25 rows=26) (actual time=2.470..7.338 rows=30 loops=1)\n    -> Filter: (transcript.crsCode = course.crsCode)  (cost=29.65 rows=26) (actual time=0.901..1.034 rows=30 loops=1)\n        -> Inner hash join (<hash>(transcript.crsCode)=<hash>(course.crsCode))  (cost=29.65 rows=26) (actual time=0.900..1.025 rows=30 loops=1)\n            -> Filter: (transcript.studId is not null)  (cost=0.05 rows=10) (actual time=0.490..0.591 rows=100 loops=1)\n                -> Table scan on Transcript  (cost=0.05 rows=100) (actual time=0.489..0.561 rows=100 loops=1)\n            -> Hash\n                -> Index lookup on Course using idx_course_deptId (deptId=(@v6))  (cost=3.35 rows=26) (actual time=0.347..0.388 rows=26 loops=1)\n    -> Filter: <in_optimizer>(transcript.studId,<exists>(select #3) is false)  (cost=0.25 rows=1) (actual time=0.209..0.210 rows=1 loops=30)\n        -> Index lookup on Student using idx_student_id (id=transcript.studId)  (cost=0.25 rows=1) (actual time=0.045..0.046 rows=1 loops=30)\n        -> Select #3 (subquery in condition; dependent)\n            -> Limit: 1 row(s)  (actual time=0.158..0.158 rows=0 loops=30)\n                -> Filter: <if>(outer_field_is_not_null, <is_not_null_test>(transcript.studId), true)  (actual time=0.157..0.157 rows=0 loops=30)\n                    -> Filter: (<if>(outer_field_is_not_null, ((<cache>(transcript.studId) = transcript.studId) or (transcript.studId is null)), true) and (transcript.crsCode = course.crsCode))  (cost=324.26 rows=320) (actual time=0.157..0.157 rows=0 loops=30)\n                        -> Inner hash join (<hash>(transcript.crsCode)=<hash>(course.crsCode))  (cost=324.26 rows=320) (actual time=0.069..0.153 rows=34 loops=30)\n                            -> Table scan on Transcript  (cost=0.04 rows=100) (actual time=0.003..0.066 rows=100 loops=30)\n                            -> Hash\n                                -> Index lookup on Course using idx_course_deptId (deptId=(@v7))  (cost=3.95 rows=32) (actual time=0.003..0.045 rows=32 loops=30)\n'