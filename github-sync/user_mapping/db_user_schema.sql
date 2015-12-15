DROP TABLE IF EXISTS users;

-- is_employee=1 means an employee, is_employee=0 means ex-employee, is_employee=null means unknown
CREATE TABLE users (
    login VARCHAR,
    email VARCHAR,
    is_employee BOOLEAN
);
