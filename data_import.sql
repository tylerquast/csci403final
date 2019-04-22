DROP TABLE IF EXISTS flights CASCADE;
DROP TABLE IF EXISTS airline CASCADE;
DROP TABLE IF EXISTS airport CASCADE;

CREATE TABLE airline (
id TEXT PRIMARY KEY,
name TEXT
);

CREATE TABLE airport (
id TEXT PRIMARY KEY,
name TEXT,
city TEXT,
state TEXT,
country TEXT,
latitude NUMERIC,
longitude NUMERIC
);

CREATE TABLE flights (
id SERIAL PRIMARY KEY,
year INTEGER,
month INTEGER,
day INTEGER,
day_of_week INTEGER,
airline_id TEXT,
flight_no INTEGER,
tail_no TEXT,
origin_airport_id TEXT ,
dest_airport_id TEXT,
scheduled_dep_time INTEGER,
dep_time INTEGER,
dep_delay INTEGER,
taxi_out_time INTEGER,
wheels_off_time INTEGER,
scheduled_time INTEGER,
elapsed_time INTEGER,
air_time INTEGER,
distance INTEGER,
wheels_on_time INTEGER,
taxi_in_time INTEGER,
scheduled_arr_time INTEGER,
arr_time INTEGER,
arr_delay INTEGER,
diverted BOOLEAN,
cancelled BOOLEAN,
cancel_reason TEXT,
air_system_delay INTEGER,
security_delay INTEGER,
airline_delay INTEGER,
late_aircraft_delay INTEGER,
weather_delay INTEGER
);

\COPY airline FROM 'airlines.csv' WITH CSV HEADER;
\COPY airport FROM 'airports.csv' WITH CSV HEADER;
\COPY flights (year, month, day, day_of_week, airline_id, flight_no, tail_no, origin_airport_id, dest_airport_id, scheduled_dep_time, dep_time, dep_delay, taxi_out_time, wheels_off_time, scheduled_time, elapsed_time, air_time, distance, wheels_on_time, taxi_in_time, scheduled_arr_time, arr_time, arr_delay, diverted, cancelled, cancel_reason, air_system_delay, security_delay, airline_delay, late_aircraft_delay, weather_delay) FROM 'flights.csv' WITH CSV HEADER;

-- get rid of origin airports with numbers as IDs instead of letters... not sure what these are
DELETE from flights where length(origin_airport_id) != 3;

-- add foreign constraints
ALTER TABLE flights ADD CONSTRAINT constraint_fkey1 FOREIGN KEY (airline_id) REFERENCES airline (id);
ALTER TABLE flights ADD CONSTRAINT constraint_fkey2 FOREIGN KEY (origin_airport_id) REFERENCES airport (id);
ALTER TABLE flights ADD CONSTRAINT constraint_fkey3 FOREIGN KEY (dest_airport_id) REFERENCES airport (id);



-- create worst flights table
CREATE TABLE worst_delays(
id TEXT ,
dep_delay INTEGER,
PRIMARY KEY (id)
);

INSERT INTO worst_delays (id, dep_delay) SELECT origin_airport_id, MAX(dep_delay) FROM flights GROUP BY origin_airport_id;


