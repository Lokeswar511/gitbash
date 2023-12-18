
select name from sys.schemas;
-- DimEmployees creation
-- Drop table DMA.DimEmployees;

create table DMA.DimEmployees(
EmployeeId int identity(1,1) Primary key,
EmployeeFirstName nvarchar(max),
EmployeeLastName nvarchar(max),
EmployeeEmail nvarchar(max),
CreatedAt datetime DEFAULT getDate(),
updatedAt datetime DEFAULT GETDATE(),
);

select * from DMA.DimEmployees;


-- DateDimension creation 
-- Drop table DMA.DimDate;

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
-- Drop table DMA.FactReports;

create table DMA.FactReports(
Id int identity(1,1) Primary key,
Updates nvarchar(max),
SubmittedTime datetime,
DProjectId int,
DEmployeesId int,
ViewersID int,
DDateKey int,
CreatedAt datetime DEFAULT getDate(),
updatedAt datetime DEFAULT GETDATE(),
FOREIGN KEY (DEmployeesId) REFERENCES DMA.DimEmployees(EmployeeId),
FOREIGN KEY (ViewersID) REFERENCES DMA.DimEmployees(EmployeeId),
FOREIGN KEY (DDateKey) REFERENCES DMA.DimDate(DateKey),
FOREIGN KEY (DProjectId) REFERENCES DMA.DimProject(Id)
);

select * from DMA.FactReports;

-- checks for PK and FK --
SELECT * FROM information_schema.key_column_usage

-- create a triggers for updatedAt values in Dim and Fact Tables
create trigger UpdatedAtDimEmp2 on DMA.DimEmployees
after update as
Begin
update DMA.DimEmployees set updatedAt = getdate()
where EmployeeId in (select EmployeeId from inserted)
end;

-- 
create trigger UpdatedAtDimDate2 on DMA.DimDate
after update as
Begin
update DMA.DimDate set updatedAt = getdate()
where DateKey in (select DateKey from inserted)
end;



-- create a triggers for Fact to updateAt column
create trigger UpdatedAtFactReport on DMA.FactReports
after update as
Begin
update DMA.FactReports set updatedAt = getdate()
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

-- 
select * from DMA.DimDate;

select * from dev.Logs_Stage_raw;


-- truncate table DMA.DimEmployees;

select * from DMA.DimEmployees;
-- when ever table ref as fk constraint in another table .. instead of truncate use below query to Truncate the rows
DELETE FROM DMA.DimEmployees;

Delete from DMA.FactReports;

-- DELETE FROM DMA.DimDate;

select * from DMA.DimDate;

-- truncate table DMA.FactReports;

select * from DMA.FactReports;

-- DROP TRIGGER [IF EXISTS] [schema_name.]trigger1, trigger2, ... ];

DROP TRIGGER UpdatedAtFact2;

SELECT  
    name,
    is_instead_of_trigger
FROM 
    sys.triggers  
WHERE 
    type = 'TR';

-- All checks -----------------
select * from DMA.TControlSourceTargetMapping;

select * from DMA.LogsSourceStage;

select * from DMA.DimEmployees; -- 15 0

select * from DMA.DimDate ; --90

select * from DMA.FactReports; -- 15 0 

-- create 3 more dimensions Project, Client, Services

create table DMA.DimClient(
ClientId int identity(1,1) primary key,
ClientName nvarchar(max),
CreatedAt datetime DEFAULT getDate(),
updatedAt datetime DEFAULT GETDATE(),
);

-- create trigger updateAt fro DimClient
create trigger UpdatedAtDimClient on DMA.DimClient
after update as
Begin
update DMA.DimClient set updatedAt = getdate()
where ClientId in (select ClientId from inserted)
end;

-- ----------------------------------------------------------

create table DMA.DimProject(
Id int identity(1,1) Primary key,
ProjectName nvarchar(max),
DClientId int,
CreatedAt datetime DEFAULT getDate(),
updatedAt datetime DEFAULT GETDATE(),
FOREIGN KEY (DClientId) REFERENCES DMA.DimClient(ClientId),
);

-- create trigger updateAt fro DimProject
create trigger UpdatedAtDimProject on DMA.DimProject
after update as
Begin
update DMA.DimProject set updatedAt = getdate()
where Id in (select Id from inserted)
end;
--  --------------------------------------------
-- Drop table DMA.DimService;

create table DMA.DimService(
ServiceId int identity(1,1),
RagName nvarchar(max),
CreatedAt datetime DEFAULT getDate(),
updatedAt datetime DEFAULT GETDATE(),
)
-- create trigger updateAt fro DimProject
create trigger UpdatedAtDimService on DMA.DimService
after update as
Begin
update DMA.DimService set updatedAt = getdate()
where ServiceId in (select ServiceId from inserted)
end;

-- ------------------------------------------------------------------
select * from DMA.DimClient;

select * from DMA.DimProject;

select * from DMA.DimService;

select * from DMA.DimEmployees; -- 16 0

select * from DMA.DimDate ; --90

select * from DMA.FactReports; -- 15 0 

-- 
select substring('lokeswar', 2, len('lokeswar') ); -- okeswar

select concat(upper(substring('lokeswar',1,1)), lower(substring('lokeswar',2, len('lokeswar'))));

update DMA.DimEmployees
set EmployeeFirstName = concat(upper(substring(EmployeeFirstName,1,1)), lower(substring(EmployeeFirstName,2, len(EmployeeFirstName)))),

	EmployeeLastName = concat(upper(substring(EmployeeLastName,1,1)), lower(substring(EmployeeLastName,2, len(EmployeeLastName)))),





