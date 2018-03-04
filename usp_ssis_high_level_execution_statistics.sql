USE RandomActsOfSQL
GO

/****** Object:  StoredProcedure [dbo].[usp_ssis_high_level_execution_statistics]    Script Date: 3/3/2018 10:23:33 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[usp_ssis_high_level_execution_statistics]
GO

/****** Object:  StoredProcedure [dbo].[usp_ssis_high_level_execution_statistics]    Script Date: 3/3/2018 10:23:33 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- ================================================
-- Author:		Elaena Bakman		 
-- Create date: 03/16/2017
-- Description:	This stored procedure will give
-- high-level informaiton on package executions.
-- Update:		
-- ================================================

CREATE PROCEDURE [dbo].[usp_ssis_high_level_execution_statistics] (
        @WindowBegins DATETIME = NULL
       ,@WindowEnds DATETIME = NULL
       ,@FolderName NVARCHAR(MAX) = NULL
       ,@ProjectName NVARCHAR(MAX) = NULL
       ,@PackageName NVARCHAR(MAX) = NULL
       ,@Status INT = -1
	   ,@UserId dtUserId = NULL)
AS
BEGIN
        SET NOCOUNT ON;

		DECLARE @Result INT;
		
        --=======================================================
        -- uncomment for testing
        --=======================================================
        --DROP TABLE IF EXISTS #source_rowcount;
        --DROP TABLE IF EXISTS #destination_rowcount;
        --=======================================================

        -- get source row count by execution id
        SELECT      EDS.execution_id
                   ,MIN(    EDS.created_time) AS StartDateTime
                   ,MAX(    EDS.created_time) AS EndedDateTime
                   ,SUM(    EDS.rows_sent) AS SourceRowCount
        INTO        #source_rowcount
        FROM        SSISDB.catalog.execution_data_statistics EDS WITH (NOLOCK)
        WHERE       EDS.dataflow_path_name = 'OLE DB Source Output'
                    AND EDS.source_component_name NOT LIKE '%valuation%'
        GROUP BY    EDS.execution_id;

        CREATE INDEX IDX_SR_1
        ON #source_rowcount (execution_id)
        INCLUDE (SourceRowCount);

        --get destination row count by execution id
        SELECT      EDS.execution_id
                   ,MIN(    EDS.created_time) AS StartDateTime
                   ,MAX(    EDS.created_time) AS EndedDateTime
                   ,SUM(    EDS.rows_sent) AS DestinationRowCount
        INTO        #destination_rowcount
        FROM        SSISDB.catalog.execution_data_statistics EDS WITH (NOLOCK)
        WHERE       EDS.destination_component_name LIKE 'OLE DB Destinatio%'
        GROUP BY    EDS.execution_id;

        CREATE INDEX IDX_DR_1
        ON #destination_rowcount (execution_id)
        INCLUDE (DestinationRowCount);

        WITH ProvidedParameters AS (SELECT  IQ.PackageName
                                           ,IQ.FolderName
                                           ,IQ.ProjectName
                                           ,ISNULL(IQ.WindowBegins, '19000101') AS WindowBegins
                                           ,ISNULL(IQ.WindowEnds, '25000101') AS WindowEnds
                                           ,NULLIF(IQ.StatusValue, -1) AS StatusValue
                                    FROM    (VALUES
                                                     (@PackageName, @FolderName, @ProjectName, @WindowBegins, @WindowEnds, @Status)) IQ (PackageName, FolderName, ProjectName, WindowBegins, WindowEnds, StatusValue) )
        SELECT              E.package_name AS PackageName
                           ,E.folder_name AS FolderName
                           ,E.project_name AS ProjectName
                           ,COUNT(  *) AS TotalCount
                           ,SUM(    CASE E.status
                                            WHEN 2 THEN 1
                                            ELSE    0
                                    END) AS Running
                           ,SUM(    CASE E.status
                                            WHEN 4 THEN 1
                                            ELSE    0
                                    END) AS Failed
                           ,SUM(    CASE E.status
                                            WHEN 7 THEN 1
                                            ELSE    0
                                    END) AS Success
                           ,SUM(    CASE
                                            WHEN E.status NOT IN (2, 4, 7) THEN 1
                                            ELSE    0
                                    END) AS Other
                           ,AVG(    CALC2.Duration) AS AverageDuration
                           ,MIN(    CALC2.Duration) AS ShortestRunTime
                           ,MAX(    CALC2.Duration) AS LongestRunTime
                           ,ISNULL(AVG(    SRC.SourceRowCount), 0) AS AverageSourceRowCount
                           ,ISNULL(AVG(    DRC.DestinationRowCount), 0) AS AverageDestinationRowCount
        FROM                SSISDB.catalog.executions E
        CROSS   APPLY       (SELECT CASE
                                            WHEN DATEDIFF(HOUR, E.start_time, ISNULL(E.end_time, SYSDATETIMEOFFSET())) > 24 THEN -1
                                            ELSE    DATEDIFF(MILLISECOND, E.start_time, ISNULL(E.end_time, SYSDATETIMEOFFSET()))
                                    END AS Duration) CALC1(Duration)
        CROSS   APPLY       (SELECT CONVERT(DATETIME, E.start_time) AS StartDateTime
                                   ,CONVERT(DATETIME, E.end_time) AS EndDateTime
                                   ,CONVERT(FLOAT, CALC1.Duration) / 1000 AS Duration) CALC2(StartDateTime, EndDateTime, Duration)
        LEFT    OUTER JOIN  ProvidedParameters PP
        ON ISNULL(PP.PackageName, E.package_name) = E.package_name
           AND  ISNULL(PP.FolderName, E.folder_name) = E.folder_name
           AND  ISNULL(PP.ProjectName, E.project_name) = E.project_name
           AND  ISNULL(PP.StatusValue, E.status) = E.status
        LEFT    OUTER JOIN  #source_rowcount SRC
        ON SRC.execution_id = E.execution_id
		AND SRC.SourceRowCount ! = 0 -- we'll exclude the 0's to keep from throwing off the avarages if the morning load brought in data and the faternoon load was 0 because there was nothing new
        LEFT    OUTER JOIN  #destination_rowcount DRC
        ON DRC.execution_id = E.execution_id
		AND DRC.DestinationRowCount != 0 -- we'll exclude the 0's to keep from throwing off the avarages if the morning load brought in data and the faternoon load was 0 because there was nothing new
        WHERE               CALC2.StartDateTime BETWEEN PP.WindowBegins AND PP.WindowEnds
        GROUP BY            E.package_name
                           ,E.folder_name
                           ,E.project_name
        ORDER BY            FolderName
                           ,ProjectName
                           ,PackageName;
END;
GO


