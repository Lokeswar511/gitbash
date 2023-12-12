
select name from sys.schemas;
-- DimEmployees creation
create table DMA.DimEmployees(
EmployeeId int identity(1,1) Primary key,
EmployeeName nvarchar(max),
EmployeeEmail nvarchar(max),
CreatedAt datetime DEFAULT getDate(),
updatedAt datetime DEFAULT GETDATE(),

);

select * from DMA.DimEmployees;


-- DateDimension creation 
create table DMA.DimDate(
DateKey int  Primary key,
Date date,
DayofWeek nvarchar(max),
DayofMonth nvarchar(max),
MonthName nvarchar(max),
Quatr nvarchar(max),
Year int,
CreatedAt datetime DEFAULT getDate(),
updatedAt datetime DEFAULT GETDATE()
)

select * from DMA.DimDate;

-- FactReports creation 

create table DMA.FactReports(
Id int identity(1,1) Primary key,
Title nvarchar(max),
Updates nvarchar(max),
DEmployeesId int,
DDateKey int,
CreatedAt datetime DEFAULT getDate(),
updatedAt datetime DEFAULT GETDATE(),
FOREIGN KEY (DEmployeesId) REFERENCES DMA.DimEmployees(EmployeeId),
FOREIGN KEY (DDateKey) REFERENCES DMA.DimDate(DateKey)
);

select * from DMA.FactReports;

-- checks for PK and FK --
SELECT * FROM information_schema.key_column_usage

-- create a triggers for updatedAt values in Dim and Fact Tables
create trigger tgrUpdatedAtDateDim on DMA.DimDate
after update as
Begin
update DAM.DimDate set updatedAt = getdate()
where id in (select id from inserted)
end;

-- create a triggers for Fact to updateAt column
create trigger tgrUpdatedAtFact on DMA.FactReports
after update as
Begin
update DAM.FactReports set updatedAt = getdate()
where id in (select id from inserted)
end;

-- Populate DimDate Table upto 3months from now

SELECT CONVERT(date, GETDATE()); -- Date

select day(GetDate()); --DayofMonth

SELECT DATENAME(Week, getdate()); --WeekNumber of year

select DATENAME(Weekday, getdate()); -- Weekday Name

select year(getDate());

-- truncate table DMA.DimDate;

-- --------------------------------------------------------
with t as (
	select 1 as sr_no
	union all
	select sr_no+1 from t where sr_no < 90
),
t1 as (
	select DateAdd(Day, sr_no-1,getdate()) as a from t
)
Insert into DMA.DimDate(DateKey,Date, DayOfWeek, DayOfMonth, MonthName, Quatr, Year)
select replace(convert(date, a), '-', '') as DateKey, convert(date, a) as Date, DATENAME(Weekday, a) as DayOfWeek, 
day(a) as DayOfMonth, DATENAME(MONTH, a) AS MonthName,  'Q' + CAST(DATEPART(QUARTER, a) AS NVARCHAR(MAX)) AS Quatr,
YEAR(a) AS Year from t1;


select * from DMA.DimDate;


