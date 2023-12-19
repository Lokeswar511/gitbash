select convert(date, GETDATE());

select * into #tempD from DMA.DimDate;

truncate table #tempD;

WITH t AS (
    SELECT 1 AS sr_no
    UNION ALL
    SELECT sr_no + 1 FROM t WHERE sr_no < 122
),
t1 AS (
    SELECT DATEADD(DAY, sr_no - 49, GETDATE()) AS a FROM t
)
INSERT INTO #tempD (DateKey, Date, DayOfWeek, DayOfMonth, MonthName, Quatr, Year)
SELECT REPLACE(CONVERT(DATE, a), '-', '') AS DateKey, CONVERT(DATE, a) AS Date, DATENAME(WEEKDAY, a) AS DayOfWeek, 
       DAY(a) AS DayOfMonth, DATENAME(MONTH, a) AS MonthName, 'Q' + CAST(DATEPART(QUARTER, a) AS NVARCHAR(MAX)) AS Quatr,
       YEAR(a) AS Year
FROM t1
ORDER BY Date desc
OPTION (MAXRECURSION 0);


select * from #tempD; -- min 2023-11-01 max 2024-03-01
-- ----------------------------------
select * into #tempService from DMA.DimService;

truncate table #tempService;

select count(*) from #tempService where RagName = '';

select * from #tempService;

-- -------------------------------------Final Insert Service passed all Test Cases --------


-- ---------------------------------
select * into #tempF from DMA.FactReports;

truncate table #tempF;

select distinct Title,SubmittedTime,ViewEmail,EmployeeEmail,Updates into #temp from DMA.StgReports;

select * from #temp;


SELECT Distinct 
  SUBSTRING(Updates,
    CHARINDEX('Update', Updates) + LEN('Update') + 1,
    CHARINDEX('Service Health RAG', Updates)  - CHARINDEX('Update', Updates) - LEN('Update') -1
  ) AS ServiceValue , SubmittedTime, SUBSTRING(Updates, CHARINDEX('Service Health RAG', Updates) + LEN('Service Health RAG') + 1, LEN(Updates)) as rag,Replace(SUBSTRING(Updates, 1, CHARINDEX('Update', Updates) - 1),'Service', '') as projectname
FROM #temp
WHERE Updates LIKE 'Service%' ;


select * 

-- Total 33 distinct records from 


insert into #tempF(Updates,SubmittedTime ,DDateKey,DProjectId,DEmployeesId,ViewersID,DServiceKey)
SELECT Distinct REPLACE(REPLACE(REPLACE(REPLACE(
  SUBSTRING(Updates,
    CHARINDEX('Update', Updates) + LEN('Update') + 1,
    CHARINDEX('Service Health RAG', Updates)  - CHARINDEX('Update', Updates) - LEN('Update') -1
  ) , '<div>', ''), '</div>', ''), '<br>', ''), '&nbsp;', '')AS ServiceValue,
  stg.SubmittedTime,
dd.DateKey,
dp.Id,
de.EmployeeId,
dv.EmployeeId,
ds.ServiceId
from #temp stg
join DMA.DimDate dd on  stg.SubmittedTime = dd.Date
join DMA.DimProject dp on Replace(SUBSTRING(stg.Updates, 1, CHARINDEX('Update', stg.Updates) - 1),'Service', '') = dp.ProjectName
join DMA.DimEmployees de on stg.EmployeeEmail = de.EmployeeEmail 
join DMA.DimEmployees dv on stg.ViewEmail = dv.EmployeeEmail 
join DMA.DimService ds on SUBSTRING(Updates, CHARINDEX('Service Health RAG', Updates) + LEN('Service Health RAG') + 1, LEN(Updates)) = ds.RagName 
WHERE stg.Updates LIKE 'Service%';


-- -----------------------------------------------
Insert into DMA.DimService(RagName)
select Distinct
SUBSTRING(Updates, CHARINDEX('Service Health RAG', Updates) + LEN('Service Health RAG') + 1, LEN(Updates)) AS ServiceValue
from #temp
where Updates like 'Service%'And CHARINDEX('Service Health RAG', Updates) > 0 AND NOT EXISTS (
  SELECT * FROM DMA.DimService
  WHERE RagName = SUBSTRING(Updates, CHARINDEX('Service Health RAG', Updates) + LEN('Service Health RAG') + 1, LEN(Updates))
)

select * from #tempService;

select * into DMA.Dummy from #tempService;

select * from DMA.Dummy;
-- ---------------------------------------------
select * from #temp;

select * into #temp1 from DMA.FactReports;

truncate table #temp1;

select * from #temp1;

INSERT INTO #temp1 (Updates, SubmittedTime, DDateKey, DProjectId, DEmployeesId, ViewersID, DServiceKey)
SELECT DISTINCT
    REPLACE(REPLACE(REPLACE(REPLACE(
        SUBSTRING(Updates, CHARINDEX('Update', Updates) + LEN('Update') + 1,
            CHARINDEX('Service Health RAG', Updates) - CHARINDEX('Update', Updates) - LEN('Update') - 1
        ), '<div>', ''), '</div>', ''), '<br>', ''), '&nbsp;', '') AS ServiceValue,
    stg.SubmittedTime,
    dd.DateKey,
    dp.Id AS DProjectId,
    de.EmployeeId AS DEmployeesId,
    dv.EmployeeId AS ViewersID,
    ds.ServiceId AS DServiceKey
FROM
    #temp stg
JOIN DMA.DimDate dd ON convert(date, stg.SubmittedTime) = dd.Date
JOIN DMA.DimProject dp ON REPLACE(SUBSTRING(stg.Updates, 1, CHARINDEX('Update', stg.Updates) - 1), 'Service', '') = dp.ProjectName
JOIN DMA.DimEmployees de ON stg.EmployeeEmail = de.EmployeeEmail 
JOIN DMA.DimEmployees dv ON stg.ViewEmail = dv.EmployeeEmail 
JOIN DMA.DimService ds ON SUBSTRING(stg.Updates, CHARINDEX('Service Health RAG', stg.Updates) + LEN('Service Health RAG') + 1, LEN(stg.Updates)) = ds.RagName 
WHERE
    stg.Updates LIKE 'Service%' and NOT EXISTS (select 1 from #temp1 tf where tf.Updates = REPLACE(REPLACE(REPLACE(REPLACE(
        SUBSTRING(stg.Updates,
            CHARINDEX('Update', stg.Updates) + LEN('Update') + 1,
            CHARINDEX('Service Health RAG', stg.Updates) - CHARINDEX('Update', stg.Updates) - LEN('Update') - 1
        ), '<div>', ''), '</div>', ''), '<br>', ''), '&nbsp;', '')
    AND tf.SubmittedTime = stg.SubmittedTime);



-- ---------------------------------------------
select count(*) from #temp1; -- 33

select count(*) from #temp1 where DDateKey = '20231211' -- 6

select min(DDateKey) from #temp1; -- 20231117

select count(*) from #temp1 where DDateKey >= '20231117' -- 33

select a.Updates, a.SubmittedTime, a.DProjectId, b.ProjectName from #temp1 a
join DMA.DimProject b on b.Id = a.DProjectId
where DDateKey = '20231211' ; -- passed

select a.Updates, a.SubmittedTime, a.DProjectId, b.ProjectName from #temp1 a
join DMA.DimProject b on b.Id = a.DProjectId
where DDateKey = '20231208' ; -- passed

select * from #temp;

-- 

select  Replace(Replace(Replace(Replace(Replace(Replace(Replace('<ul><li style="list-style-type: disc">Main sprint-92 Dev completed, Release will happen tomorrow.
</li><ul style="list-style-type: circle"><li style="">Totaljobs and Dice job board 
new team settings changes related to search is completed.</li><li style="">Crm 
unlinking functionality done for Bullhorn, Salseforece, 
Vincere and Salesforce</li><li style="">Toolbox service domain changes done</li></ul><li style="list-style-type: disc">
Prod sprint-159 completed, Release will happen tomorrow.</li></ul> ', '<ul>', ''), '</ul>', ''), 
'<li style="list-style-type: disc">', ''),'<li style="">', '' ), '</li>', ''), '<li>', ''),'<ul style="list-style-type:circle">', '');


Declare @text nvarchar(max) = 'Service IFRS17 / BR2  Update <div>I worked on LIC/LRC reconcile query(Writing the queries for the remaining Balances in LRC RI) and looked into the bug 5951.<br></div>  Service Health RAG '

SELECT
  REPLACE(REPLACE(REPLACE(REPLACE(@text, '<', ''), '>', ''), '/>', ''), '</[^>]+>', ''),
  REPLACE(REPLACE(REPLACE(@text, '<', ''), '>', ''), '/>', ''),
  REPLACE(REPLACE(@text, '<br>', ''), '<br/>', '')
  AS clean_text;
