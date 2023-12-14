-- select * from DMA.DimEmployees;

-- creating stage for the DimEmployees
-- Drop table DMA.StgEmployees;

create table DMA.StgEmployees(
EmployeeId int identity(1,1) Primary key,
EmployeeName nvarchar(max),
EmployeeEmail nvarchar(max),
);

select * from DMA.StgEmployees;


-- DateDimension creation 
create table DMA.StgDate(
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

select * from DMA.StgDate;

-- FactReports creation 
-- Drop table DMA.StgReports;
create table DMA.StgReports(
Id int identity(1,1) Primary key,
Title nvarchar(max),
Updates nvarchar(max),
SubmittedTime datetime,
);

select * from DMA.StgReports;


select * from DMA.StgEmployees;
/*
-- create a trigger for for StgEmployees for UpdateAt column
create trigger StgEmployeeUpdatedAt on DMA.StgEmployees
after update as 
Begin
update DMA.StgEmployees set updatedAt = getdate()
where EmployeeId in (select EmployeeId from inserted)
end;
-- StgDateDim
create trigger StgDateUpdatedAt on DMA.StgDate
after update as 
Begin
update DMA.StgDate set updatedAt = getdate()
where DateKey in (select DateKey from inserted)
end;

-- create a trigger for for StgReports for UpdateAt column
create trigger StgReportsUpdatedAt on DMA.StgReports
after update as 
Begin
update DMA.StgReports set updatedAt = getdate()
where Id in (select Id from inserted)
end;

*/

-- create a control table for mapping of source and Target 
--

create table DMA.TControlSourceTargetMapping (
id int identity(1,1),
SrcFileName nvarchar(max),
SrcSheetName nvarchar(max),
SrcColumns nvarchar(max),
DestinationSource nvarchar(max),
DestinationDataBase nvarchar(max),
DestinationSchema nvarchar(maX),
DestinationTable nvarchar(max),
DestinationColumns nvarchar(max),
CreatedAt datetime DEFAULT getDate(),
updatedAt datetime DEFAULT GETDATE(),
);

-- create trigger for controlTable updated at
create trigger tgrTControlUpdatedAt on DMA.TControlSourceTargetMapping
after update as 
Begin
update DMA.TControlSourceTargetMapping set updatedAt = getdate()
where Id in (select Id from inserted)
end;
-- ------ Insertion into ControlUpdatesTable 
select * from DMA.TControlSourceTargetMapping where DestinationTable='StgEmployees';

insert into DMA.TControlSourceTargetMapping (SrcFileName, SrcSheetName, SrcColumns,DestinationSource,DestinationDataBase,DestinationSchema,DestinationTable,DestinationColumns)
values ('Updates', 'Sheet1', 'Update Title', 'Sql Server', 'prospectmanagement', 'DMA', 'StgReports', 'Title'),
('Updates', 'Sheet1', 'Update', 'Sql Server', 'prospectmanagement', 'DMA', 'StgReports', 'Updates'),
('Updates', 'Sheet1', 'Submitted Time', 'Sql Server', 'prospectmanagement', 'DMA', 'StgReports', 'SubmittedTime'),
('Updates', 'Sheet1', 'Submitter''s Email', 'Sql Server', 'prospectmanagement', 'DMA', 'StgEmployees', 'EmployeeName'),
('Updates', 'Sheet1', 'Submitter''s Email', 'Sql Server', 'prospectmanagement', 'DMA', 'StgEmployees', 'EmployeeEmail');



-- -----------------------------------------------------
update DMA.TControlSourceTargetMapping 
set SrcFileName = 'Updates.xlsx';

-- StageDateDim check 
/*
with t as (
	select 1 as sr_no
	union all
	select sr_no+1 from t where sr_no < 90
),
t1 as (
	select DateAdd(Day, sr_no-1,getdate()) as a from t
)
Insert into DMA.StgDate(DateKey,Date, DayOfWeek, DayOfMonth, MonthName, Quatr, Year)
select replace(convert(date, a), '-', '') as DateKey, convert(date, a) as Date, DATENAME(Weekday, a) as DayOfWeek, 
day(a) as DayOfMonth, DATENAME(MONTH, a) AS MonthName,  'Q' + CAST(DATEPART(QUARTER, a) AS NVARCHAR(MAX)) AS Quatr,
YEAR(a) AS Year from t1
where not exists(
select 1 from DMA.StgDate
where DateKey = replace(convert(date, a), '-', '')
);


*/

select * from DMA.StgDate;

-- Logs table
select LogId, DataFactory, PipelineName, SourceFolderName, SourceFileName, DestinationFolderName, DestinationFileName, TriggerTime, FilesRead,  ExecutionDetailsStatus,CopyDuration 
into DMA.LogsSourceStage from  dev.Logs_Stage_raw;

-- truncate table DMA.LogsSourceStage;

select * from DMA.LogsSourceStage;
/*
ALTER TABLE DMA.LogsSourceStage
DROP COLUMN SourceFolderName;

*/


-- Exec Sp_rename 'DMA.LogsSourceStage.DestinationFileName', 'DestinationTable';

create procedure DMA.Insert_LogsSourceStage
@DataFactory nvarchar(max),
@PipelineName nvarchar(max),
@SourceFileName nvarchar(max),
@DestinationType nvarchar(max),
@DestinationTable nvarchar(max),
@TriggerTime DateTime,
@FilesRead int,
@ExecutionDetailsStatus nvarchar(max),
@CopyDuration int,
@RowsRead int,
@RowsCopied int,
@DestinationSchema nvarchar(max)
as
Begin
 insert into DMA.LogsSourceStage (DataFactory, PipelineName, SourceFileName, DestinationType,DestinationTable,TriggerTime,FilesRead,ExecutionDetailsStatus,CopyDuration,RowsRead,RowsCopied,DestinationSchema)
 values(@DataFactory,@PipelineName,@SourceFileName,@DestinationType,@DestinationTable,@TriggerTime,@FilesRead,@ExecutionDetailsStatus,@CopyDuration,@RowsRead,@RowsCopied,@DestinationSchema)

End


-- Alter table DMA.LogsSourceStage add DestinationSchema nvarchar(max)

-- truncate table DMA.StgEmployees;

select * from DMA.StgEmployees;

-- truncate table DMA.StgReports;

select * from DMA.StgReports;

 -- truncate table DMA.LogsSourceStage;

select * from DMA.LogsSourceStage;

-- Now update the Updates column and submittedTime to required format
update DMA.StgReports
set Updates = REPLACE(Updates, '<[^>]+>', '');

--  ((\<)[\w\/\=\x22\x27\:-;]+(>))

select * into #temp from DMA.StgReports;

select * from #temp;

update #temp
set Updates = REPLACE(Updates, '<[a-zA-Z\/][^>]*>', '');

select Updates from DMA.StgReports where id = 32;

select Updates from #temp where id = 32;


select PARSENAME('dilvin.riyo@xyenta.com', 1); -- com

select PARSENAME('dilvin.riyo@xyenta.com', 2); -- dilvin fname

select replace(PARSENAME('dilvin.riyo@xyenta.com', 2), '@' , ''); --riyoxyenta

select replace('dilvin.riyo@xyenta.com', '@', '.'); -- dilvin.riyo.xyenta.com

select replace(PARSENAME(replace('dilvin.riyo@xyenta.com', '@', '.'),3),'.', '') --riyo

-- -update for EmpName 
select * into #tempE from DMA.StgEmployees;

select * from #tempE;

select  EmployeeName, EmployeeEmail from #tempE group by EmployeeName, EmployeeEmail;

WITH RankedData2 AS (
    SELECT
        EmployeeId,
        EmployeeName,
        EmployeeEmail,
        ROW_NUMBER() OVER (PARTITION BY EmployeeName, EmployeeEmail ORDER BY EmployeeId) AS rn
    FROM #tempE
)select * from RankedData2 where rn = 1;

select * into #tempDE2 from DMA.DimEmployees;

select * from #tempDE;

select * from #tempDE2;

/*

Merge into #tempDE as t
using #tempE as s
on t.EmployeeId = s.EmployeeId
when matched then
	update set 
	     t.EmployeeFirstName = PARSENAME(s.EmployeeName, 2),
		 t.EmployeeLastName = REPLACE(PARSENAME(REPLACE(s.EmployeeName, '@', '.'), 3), '.', '')
when not matched then 
Insert (EmployeeFirstName, EmployeeLastName,EmployeeEmail)
values 
(PARSENAME(s.EmployeeName, 2), REPLACE(PARSENAME(REPLACE(s.EmployeeName, '@', '.'), 3), '.', ''), s.EmployeeEmail);

*/

-- truncate table #tempDE2

select * from #tempDE2;
-- Insert Distinct values of EmplyeeName and EmployeeEmail
WITH RankedData AS (
    SELECT
        EmployeeId,
        EmployeeName,
        EmployeeEmail,
        ROW_NUMBER() OVER (PARTITION BY EmployeeName, EmployeeEmail ORDER BY EmployeeId) AS rn
    FROM #tempE
)
MERGE INTO #tempDE2 AS t
USING (
    SELECT EmployeeId, EmployeeName, EmployeeEmail
    FROM RankedData
    WHERE rn = 1
) AS s
ON t.EmployeeId = s.EmployeeId
WHEN MATCHED THEN
    UPDATE SET
        t.EmployeeFirstName = PARSENAME(s.EmployeeName, 2),
        t.EmployeeLastName = REPLACE(PARSENAME(REPLACE(s.EmployeeName, '@', '.'), 3), '.', '')
WHEN NOT MATCHED THEN
    INSERT (EmployeeFirstName, EmployeeLastName, EmployeeEmail)
    VALUES (
        PARSENAME(s.EmployeeName, 2),
        REPLACE(PARSENAME(REPLACE(s.EmployeeName, '@', '.'), 3), '.', ''),
        s.EmployeeEmail
);
