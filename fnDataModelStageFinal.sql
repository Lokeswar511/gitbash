-- Drop table DMA.StgReports;

create table DMA.StgReports(
Id int identity(1,1) Primary key,
Title nvarchar(max),
Updates nvarchar(max),
SubmittedTime datetime,
EmployeeEmail nvarchar(max),
ViewEmail nvarchar(max)
);

select * from DMA.StgReports;

-- truncate table DMA.TControlSourceTargetMapping;

insert into DMA.TControlSourceTargetMapping (SrcFileName, SrcSheetName, SrcColumns,DestinationSource,DestinationDataBase,DestinationSchema,DestinationTable,DestinationColumns)
values ('Updates.xlsx', 'Sheet1', 'Update Title', 'Sql Server', 'prospectmanagement', 'DMA', 'StgReports', 'Title'),
('Updates.xlsx', 'Sheet1', 'Update', 'Sql Server', 'prospectmanagement', 'DMA', 'StgReports', 'Updates'),
('Updates.xlsx', 'Sheet1', 'Submitted Time', 'Sql Server', 'prospectmanagement', 'DMA', 'StgReports', 'SubmittedTime'),
('Updates.xlsx', 'Sheet1', 'Submitter''s Email', 'Sql Server', 'prospectmanagement', 'DMA', 'StgReports', 'EmployeeEmail'),
('Updates.xlsx', 'Sheet1', 'Viewers'' Email Item', 'Sql Server', 'prospectmanagement', 'DMA', 'StgReports', 'ViewEmail');

select * from DMA.TControlSourceTargetMapping;

-- truncate table DMA.LogsSourceStage;
select * from DMA.LogsSourceStage;

select * from DMA.StgReports;

-- --    ---------------  Insert data into EmployeesDim from StgReports ------------------------------------------------
-- 220 records at stgReports

select * into #tempDE from DMA.DimEmployees;

-- truncate table #tempDE;

select * from #tempDE;

/*
WITH DataEmployees AS (
    SELECT
        Id,
        EmployeeEmail ,
		ViewEmail,
        ROW_NUMBER() OVER (PARTITION BY  EmployeeEmail,ViewEmail ORDER BY Id) AS rn
    FROM DMA.StgReports
)select count(*) from DataEmployees;


*/


WITH DataEmployees AS (
    SELECT
        Id,
        EmployeeEmail ,
		ViewEmail,
        ROW_NUMBER() OVER (PARTITION BY  EmployeeEmail,ViewEmail ORDER BY Id) AS rn
    FROM DMA.StgReports
)
INSERT INTO #tempDE(EmployeeFirstName, EmployeeLastName, EmployeeEmail)
SELECT Distinct
    PARSENAME(s.EmployeeEmail, 3),
    REPLACE(PARSENAME(REPLACE(s.EmployeeEmail, '@', '.'), 3), '.', ''),
    s.EmployeeEmail
FROM
    DataEmployees s

WHERE
    s.rn = 1 AND NOT EXISTS (
        SELECT 1
        FROM #tempDE t
        WHERE t.EmployeeEmail = s.EmployeeEmail
);


WITH UniqueViewEmails AS (
    SELECT DISTINCT ViewEmail
    FROM DMA.StgReports
)
-- Insert unique ViewEmail values into #tempE
INSERT INTO #tempDE (EmployeeFirstName, EmployeeLastName, EmployeeEmail)
SELECT
    PARSENAME(s.ViewEmail, 3) AS EmployeeFirstName,
    REPLACE(PARSENAME(REPLACE(s.ViewEmail, '@', '.'), 3), '.', '') AS EmployeeLastName,
    s.ViewEmail AS EmployeeEmail
FROM
    UniqueViewEmails s
WHERE
    NOT EXISTS (
        SELECT 1
        FROM #tempDE t
        WHERE t.EmployeeEmail = s.ViewEmail
);
-- ------------------------------Insertion completed for Dim EMployees --------------------------------

-- -------------------------------Insert into DimProject from StageReports ------------------------------
select * into #tempProject from DMA.DimProject;

truncate table #tempProject;

select * from #tempProject;


select  * into #tempRp from DMA.StgReports;

select * from #tempRp;

Insert into #tempProject (ProjectName)
select Distinct 
SUBSTRING(Updates, 1, CHARINDEX('Update', Updates) - 1) AS ServiceValue
from #tempRp
where Updates like 'Service%' and not exists 
(select * from #tempProject where ProjectName =SUBSTRING(Updates, 1, CHARINDEX('Update', Updates) - 1) 
);

update #tempProject
set ProjectName = TRIM(REPLACE(ProjectName, 'Service', ''))

/*

select PARSENAME('Service IFRS17 / BR1  ', -1);

select replace(PARSENAME( REPLACE('Service IFRS17 / BR1', ' / ', '.'), 2),'Service', ''); --  IFRS17

select len('Service IFRS17 / BR1');

select replace(PARSENAME( REPLACE( ProjectName, ' / ', '.'), 2),'Service', '') from #tempProject;

select TRIM(REPLACE(ProjectName, 'Service', '')) from #tempProject; -- FDM/SMall Change (Service removed)

select Trim(replace(ProjectName, 'Service', '')) from #tempProject

select SUBSTRING(ProjectName,  1,CHARINDEX('', ProjectName))as res from #tempProject;

*/

/*
Rough 
select  * into #tempR from DMA.StgReports;

ALTER TABLE #temPR ADD NewColumn nvarchar(max);


select * from #tempR;


select EmployeeEmail, Updates from #tempR where Updates not like 'Team%';

select EmployeeEmail , Updates from #tempR where Updates like '[Service]% [Update]%' ;

-- Result

select EmployeeEmail, 
SUBSTRING(Updates, 1, CHARINDEX('Update', Updates) - 1) AS ServiceValue
from #tempR
where Updates like 'Service%';

select CHARINDEX('Service Health RAG', Updates) as res from #tempR;

select SUBSTRING(Updates, 1, CHARINDEX('Service Health RAG', Updates) - 1)as res from #tempR where Updates like 'Service%';

-- SUBSTRING(Updates, 1, CHARINDEX('/', Updates) - 1)


*/

-- ---------------------------Insert into DimService ----------------------------------------
select * into #tempService from DMA.DimService;

truncate table #tempService;

select count(*) from #tempService where RagName = '';

select * from #tempService;

Insert into #tempService(RagName)
select Distinct
SUBSTRING(Updates, CHARINDEX('Service Health RAG', Updates) + LEN('Service Health RAG') + 1, LEN(Updates)) AS ServiceValue
from #tempRp
where Updates like 'Service%'And CHARINDEX('Service Health RAG', Updates) > 0 AND NOT EXISTS (
    SELECT * FROM #tempService
    WHERE RagName = SUBSTRING(Updates, CHARINDEX('Service Health RAG', Updates) + LEN('Service Health RAG') + 1, LEN(Updates))
  );


UPDATE #tempService
SET RagName = CASE
  WHEN RagName IS NULL OR RagName = '' THEN 'None'
  ELSE RagName
END;
-- ---------------- Insert DimService --------------------
WITH new_ragnames AS (
  SELECT DISTINCT
    SUBSTRING(Updates, CHARINDEX('Service Health RAG', Updates) + LEN('Service Health RAG') + 1, LEN(Updates)) AS RagName
  FROM #tempRp
  WHERE Updates LIKE 'Service%'
)
MERGE INTO #tempService AS target
USING new_ragnames AS source
ON (target.RagName = source.RagName)
WHEN MATCHED THEN
  UPDATE SET target.RagName = CASE
    WHEN TRIM(target.RagName) = '' THEN 'None' 
    ELSE target.RagName 
  END
WHEN NOT MATCHED THEN
  INSERT (RagName) VALUES (source.RagName);



/*
where not exists (select 1 from olap.coupon_d  d where d.coupon_id = s.cupon_id);
*/


select 
SUBSTRING(Updates, CHARINDEX('Update', Updates) + LEN('Update') + 1, LEN(Updates)) AS ServiceValue
from #tempRp
where Updates like 'Service%';

select Updates from #tempRp where Updates like 'Service%';


-- ---------------------------------------------------------------------------------------------
-- stages check
select Updates from DMA.StgReports;

select SUBSTRING(Updates, CHARINDEX('Update', Updates)+ LEN('Update'), len(Updates)) from DMA.StgReports;



update DMA.StgReports
set Updates = replace(replace(replace(replace(Updates, '<div>', ''), '</div>', ''), '<br>', ''), '&nbsp', '');



-- Dimesnions Check

select * from DMA.DimEmployees;


