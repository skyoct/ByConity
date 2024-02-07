set dialect_type='MYSQL';
select time_format('12:00:00', '%H %k %h %I %l');
select time_format(timestamp '2022-01-22 23:00:00','%H %k %h %I %l')as result;       
select time_format(datetime '2022-01-22 23:00:00','%H %k %h %I %l')as result;     
select time_format(time '23:00:00','%H %k %h %I %l');
select time_format(date '2022-01-22','%H %k %h %I %l');
SELECT TIME_FORMAT('10:30:00', '%H');
SELECT TIME_FORMAT('10:30:00', '%k');
SELECT TIME_FORMAT('10:30:00', '%h');
SELECT TIME_FORMAT('10:30:00', '%I');
SELECT TIME_FORMAT('10:30:00', '%l');
SELECT TIME_FORMAT('10:30:00', '%i');
SELECT TIME_FORMAT('10:30:00', '%s');
SELECT TIME_FORMAT('10:30:00', '%p');
SELECT TIME_FORMAT('10:30:00', '%r');
SELECT TIME_FORMAT('10:30:00', '%T');

SELECT TIME_FORMAT(time'10:30:00', '%H');
SELECT TIME_FORMAT(time'10:30:00', '%k');
SELECT TIME_FORMAT(time'10:30:00', '%h');
SELECT TIME_FORMAT(time'10:30:00', '%I');
SELECT TIME_FORMAT(time'10:30:00', '%l');
SELECT TIME_FORMAT(time'10:30:00', '%i');
SELECT TIME_FORMAT(time'10:30:00', '%s');
SELECT TIME_FORMAT(time'10:30:00', '%p');
SELECT TIME_FORMAT(time'10:30:00', '%r');
SELECT TIME_FORMAT(time'10:30:00', '%T');

SELECT TIME_FORMAT(datetime'2023-05-30 10:30:00', '%H');
SELECT TIME_FORMAT(datetime'2023-05-30 10:30:00', '%k');
SELECT TIME_FORMAT(datetime'2023-05-30 10:30:00', '%h');
SELECT TIME_FORMAT(datetime'2023-05-30 10:30:00', '%I');
SELECT TIME_FORMAT(datetime'2023-05-30 10:30:00', '%l');
SELECT TIME_FORMAT(datetime'2023-05-30 10:30:00', '%i');
SELECT TIME_FORMAT(datetime'2023-05-30 10:30:00', '%s');
SELECT TIME_FORMAT(datetime'2023-05-30 10:30:00', '%p');
SELECT TIME_FORMAT(datetime'2023-05-30 10:30:00', '%r');
SELECT TIME_FORMAT(datetime'2023-05-30 10:30:00', '%T');

SELECT TIME_FORMAT('2023-05-30 10:30:00', '%H');
SELECT TIME_FORMAT('2023-05-30 10:30:00', '%k');
SELECT TIME_FORMAT('2023-05-30 10:30:00', '%h');
SELECT TIME_FORMAT('2023-05-30 10:30:00', '%I');
SELECT TIME_FORMAT('2023-05-30 10:30:00', '%l');
SELECT TIME_FORMAT('2023-05-30 10:30:00', '%i');
SELECT TIME_FORMAT('2023-05-30 10:30:00', '%s');
SELECT TIME_FORMAT('2023-05-30 10:30:00', '%p');
SELECT TIME_FORMAT('2023-05-30 10:30:00', '%r');
SELECT TIME_FORMAT('2023-05-30 10:30:00', '%T');

SELECT TIME_FORMAT(date'2023-05-30', '%H');
SELECT TIME_FORMAT('2023-05-30', '%H');

select TIME_FORMAT('12:00:00.', '%H %k %h %I %l %f');
select TIME_FORMAT('12:00:00.123', '%H %k %h %I %l %f');
select TIME_FORMAT('12:00:00.123456', '%H %k %h %I %l %f');
select TIME_FORMAT('12:00:00.1234567890', '%H %k %h %I %l %f');
