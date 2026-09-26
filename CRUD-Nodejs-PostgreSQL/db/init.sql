CREATE TABLE IF NOT EXISTS employee (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  job VARCHAR(100),
  department VARCHAR(100),
  salary NUMERIC(12, 2),
  hire_date DATE
);