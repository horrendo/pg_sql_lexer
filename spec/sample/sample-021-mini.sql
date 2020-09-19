select depname, empno, salary, enroll_date from (select depname, empno, salary, enroll_date, rank() over(partition by depname order by salary desc, empno) as pos from empsalary) as ss where pos < 3;