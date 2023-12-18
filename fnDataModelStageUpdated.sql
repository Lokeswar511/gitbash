-- Drop table DMA.StgEmployees;

create table DMA.StgEmployees(
EmployeeId int identity(1,1) Primary key,
EmployeeName nvarchar(max),
EmployeeEmail nvarchar(max),
ViewEmail nvarchar(max)
);

-- Drop table DMA.StgReports;
create table DMA.StgReports(
Id int identity(1,1) Primary key,
Updates nvarchar(max),
SubmittedTime datetime,
EmployeeEmail nvarchar(max)
);


create table DMA.StgProject (
id int identity(1,1),
ProjectName nvarchar(max)
);

create table DMA.StgService (
id int identity(1,1),
RAGName nvarchar(max)

);

-- Drop table DMA.TControlSourceTargetMapping;

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
/*
create trigger tgrTControlUpdatedAt on DMA.TControlSourceTargetMapping
after update as 
Begin
update DMA.TControlSourceTargetMapping set updatedAt = getdate()
where Id in (select Id from inserted)
end;

*/

-- -- --------------------------------------------------------
insert into DMA.TControlSourceTargetMapping (SrcFileName, SrcSheetName, SrcColumns,DestinationSource,DestinationDataBase,DestinationSchema,DestinationTable,DestinationColumns)
values ('Updates.xlsx', 'Sheet1', 'Update', 'Sql Server', 'prospectmanagement', 'DMA', 'StgReports', 'Updates'),
('Updates.xlsx', 'Sheet1', 'Update', 'Sql Server', 'prospectmanagement', 'DMA', 'StgProject', 'ProjectName'),
('Updates.xlsx', 'Sheet1', 'Update', 'Sql Server', 'prospectmanagement', 'DMA', 'StgService', 'RAGName'),
('Updates.xlsx', 'Sheet1', 'Submitted Time', 'Sql Server', 'prospectmanagement', 'DMA', 'StgReports', 'SubmittedTime'),
('Updates.xlsx', 'Sheet1', 'Submitter''s Email', 'Sql Server', 'prospectmanagement', 'DMA', 'StgEmployees', 'EmployeeName'),
('Updates.xlsx', 'Sheet1', 'Submitter''s Email', 'Sql Server', 'prospectmanagement', 'DMA', 'StgEmployees', 'EmployeeEmail'),
('Updates.xlsx', 'Sheet1', 'Viewers'' Email Item', 'Sql Server', 'prospectmanagement', 'DMA', 'StgEmployees', 'ViewEmail');


-- -- ----------------------------------------------------------
-- truncate table DMA.StgReports;

select * from DMA.StgEmployees;

select * from DMA.StgReports;

select * from DMA.StgProject;

select * from DMA.StgService;

select * from DMA.TControlSourceTargetMapping where DestinationTable = 'StgService';

-- truncate table DMA.LogsSourceStage;

select * from DMA.LogsSourceStage;

-- lets work insert on temp tables first --------------------------------------------------------

select * into #tempE from DMA.DimEmployees;

select * from #tempE;

truncate table #tempE;
-- -- ----------------- Query for inserting data -- ------------------------------------------

WITH DataEmployees AS (
    SELECT
        EmployeeId,
        EmployeeName,
        EmployeeEmail ,
		ViewEmail,
        ROW_NUMBER() OVER (PARTITION BY EmployeeName, EmployeeEmail,ViewEmail ORDER BY EmployeeId) AS rn
    FROM DMA.StgEmployees
)select *  from DataEmployees;
-- --------------------------------------------------
WITH DataEmployees AS (
    SELECT
        EmployeeId,
        EmployeeName,
        EmployeeEmail AS Email,
        ROW_NUMBER() OVER (PARTITION BY EmployeeName, EmployeeEmail ORDER BY EmployeeId) AS rn
    FROM DMA.StgEmployees
    UNION
    SELECT
        EmployeeId,
        EmployeeName,
        ViewEmail AS Email,
        ROW_NUMBER() OVER (PARTITION BY EmployeeName, ViewEmail ORDER BY EmployeeId) AS rn
    FROM DMA.StgEmployees
)
INSERT INTO #tempE(EmployeeFirstName, EmployeeLastName, EmployeeEmail)
SELECT Distinct
    PARSENAME(s.EmployeeName, 3),
    REPLACE(PARSENAME(REPLACE(s.EmployeeName, '@', '.'), 3), '.', ''),
    s.Email
FROM
    DataEmployees s
WHERE
    s.rn = 1 AND NOT EXISTS (
        SELECT 1
        FROM #tempE t
        WHERE t.EmployeeId = s.EmployeeId
);


select * from #tempE;

truncate table #tempE;
-- ------------------------------------------------------------
WITH DataEmployees AS (
    SELECT
        EmployeeId,
        EmployeeName,
        EmployeeEmail ,
		ViewEmail,
        ROW_NUMBER() OVER (PARTITION BY EmployeeName, EmployeeEmail,ViewEmail ORDER BY EmployeeId) AS rn
    FROM DMA.StgEmployees
)INSERT INTO #tempE(EmployeeFirstName, EmployeeLastName, EmployeeEmail)
SELECT Distinct
    PARSENAME(s.EmployeeName, 3),
    REPLACE(PARSENAME(REPLACE(s.EmployeeName, '@', '.'), 3), '.', ''),
    s.EmployeeEmail
FROM
    DataEmployees s

WHERE
    s.rn = 1 AND NOT EXISTS (
        SELECT 1
        FROM #tempE t
        WHERE t.EmployeeEmail = s.EmployeeEmail
);


-- --------------------------------------------------------------
select * from DMA.StgEmployees;

select * from #tempE;

truncate table #tempE;

select EmployeeEmail from DMA.StgEmployees
union 
select ViewEmail from DMA.StgEmployees;

WITH CombinedEmails AS (
  SELECT EmployeeEmail AS Email FROM DMA.StgEmployees
  UNION ALL
  SELECT ViewEmail AS Email FROM DMA.StgEmployees
)
SELECT Distinct Email FROM CombinedEmails;


WITH CombinedEmails2 AS (
  SELECT EmployeeFirstName, EmployeeLastName, EmployeeEmail AS Email FROM #tempE
  UNION ALL
  SELECT EmployeeFirstName, EmployeeLastName,ViewEmail AS Email FROM #tempE
)
SELECT Distinct Email FROM CombinedEmails2;

WITH DistinctEmails AS (
  -- Combine emails from both sources
  SELECT Email FROM CombinedEmails
  UNION ALL
  SELECT EmployeeEmail FROM DMA.StgEmployees
)
UPDATE #tempE
SET EmployeeEmail = s.Email
FROM #tempE t
INNER JOIN DistinctEmails s ON t.EmployeeEmail = s.Email
WHERE NOT EXISTS (
  SELECT 1
  FROM #tempE x
  WHERE x.EmployeeEmail = s.Email AND x.EmployeeID != t.EmployeeID
);

-- -----------------------------------------

-- ----------------------------------- Final Insert into employees from stage -- 

with combinedEmails as (
	SELECT EmployeeEmail AS Email FROM DMA.StgEmployees
	UNION ALL
	SELECT ViewEmail AS Email FROM DMA.StgEmployees

),
 DataEmployees AS (
    SELECT
        EmployeeId,
        EmployeeName,
        EmployeeEmail ,
		ViewEmail,
        ROW_NUMBER() OVER (PARTITION BY EmployeeName, EmployeeEmail,ViewEmail ORDER BY EmployeeId) AS rn
    FROM DMA.StgEmployees
)INSERT INTO #tempE(EmployeeFirstName, EmployeeLastName, EmployeeEmail)
SELECT Distinct
    PARSENAME(s.EmployeeName, 3),
    REPLACE(PARSENAME(REPLACE(s.EmployeeName, '@', '.'), 3), '.', ''),
    s.EmployeeEmail
FROM
    DataEmployees s

WHERE
    s.rn = 1 AND NOT EXISTS (
        SELECT 1
        FROM #tempE t
        WHERE t.EmployeeEmail = s.EmployeeEmail
);

-- checks 

select * from #tempE;
truncate table #tempE;
-- -------------------------------------
WITH DataEmployees AS (
  SELECT
    EmployeeId,
    EmployeeName,
    ce.Email AS EmployeeEmail, 
    ViewEmail,
    ROW_NUMBER() OVER (PARTITION BY EmployeeName, ce.Email ORDER BY EmployeeId) AS rn
  FROM DMA.StgEmployees s
  JOIN CombinedEmails ce ON s.EmployeeEmail = ce.Email OR s.ViewEmail = ce.Email
)select * from DataEmployees where rn = 1;

-- ----------------------------------------------------------------------
WITH CombinedEmails AS (
  SELECT Distinct EmployeeEmail AS Email FROM DMA.StgEmployees
  UNION ALL
  SELECT Distinct ViewEmail AS Email FROM DMA.StgEmployees
)

, DataEmployees AS (
  SELECT
    EmployeeId,
    EmployeeName,
    ce.Email AS EmployeeEmail, 
    ViewEmail,
    ROW_NUMBER() OVER (PARTITION BY EmployeeName, ce.Email ORDER BY EmployeeId) AS rn
  FROM DMA.StgEmployees s
  JOIN CombinedEmails ce ON s.EmployeeEmail = ce.Email OR s.ViewEmail = ce.Email
)INSERT INTO #tempE(EmployeeFirstName, EmployeeLastName, EmployeeEmail)
SELECT Distinct
    PARSENAME(s.EmployeeName, 3),
    REPLACE(PARSENAME(REPLACE(s.EmployeeName, '@', '.'), 3), '.', ''),
    s.EmployeeEmail
FROM
    DataEmployees s

WHERE
    s.rn = 1;

-- ----------------------------------------------------------------------------------------
-- Final Query 

WITH DataEmployees AS (
    SELECT
        EmployeeId,
        EmployeeName,
        EmployeeEmail ,
		ViewEmail,
        ROW_NUMBER() OVER (PARTITION BY EmployeeName, EmployeeEmail,ViewEmail ORDER BY EmployeeId) AS rn
    FROM DMA.StgEmployees
)INSERT INTO #tempE(EmployeeFirstName, EmployeeLastName, EmployeeEmail)
SELECT Distinct
    PARSENAME(s.EmployeeName, 3),
    REPLACE(PARSENAME(REPLACE(s.EmployeeName, '@', '.'), 3), '.', ''),
    s.EmployeeEmail
FROM
    DataEmployees s

WHERE
    s.rn = 1 AND NOT EXISTS (
        SELECT 1
        FROM #tempE t
        WHERE t.EmployeeEmail = s.EmployeeEmail
);

-- 
-- Create a CTE to get unique ViewEmail values
WITH UniqueViewEmails AS (
    SELECT DISTINCT ViewEmail
    FROM DMA.StgEmployees
)

-- Insert unique ViewEmail values into #tempE
INSERT INTO #tempE (EmployeeFirstName, EmployeeLastName, EmployeeEmail)
SELECT
    PARSENAME(s.ViewEmail, 3) AS EmployeeFirstName,
    REPLACE(PARSENAME(REPLACE(s.ViewEmail, '@', '.'), 3), '.', '') AS EmployeeLastName,
    s.ViewEmail AS EmployeeEmail
FROM
    UniqueViewEmails s
WHERE
    NOT EXISTS (
        SELECT 1
        FROM #tempE t
        WHERE t.EmployeeEmail = s.ViewEmail
);

-- checks 

select * from #tempE;

truncate table #tempE;

select * from DMA.StgProject;

Drop table DMA.StgDate;

select * from DMA.TControlSourceTargetMapping;


