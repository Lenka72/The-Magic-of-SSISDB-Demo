USE dw_valuation;
GO

/****** Object:  StoredProcedure [dbo].[usp_ssis_high_level_execution_statistics]    Script Date: 5/4/2018 7:13:49 PM ******/
DROP PROCEDURE dbo.usp_ssis_high_level_execution_statistics;
GO

/****** Object:  StoredProcedure [dbo].[usp_ssis_high_level_execution_statistics]    Script Date: 5/4/2018 7:13:49 PM ******/
SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

-- ================================================
-- Author:		Elaena Bakman		 
-- Create date: 03/16/2017
-- Description:	This stored procedure will give
-- high-level informaiton on package executions.
-- Update:		
-- ================================================

CREATE PROCEDURE dbo.usp_ssis_high_level_execution_statistics (
        @WindowBegins DATETIME = NULL
       ,@WindowEnds DATETIME = NULL
       ,@FolderName NVARCHAR(MAX) = NULL
       ,@ProjectName NVARCHAR(MAX) = NULL
       ,@PackageName NVARCHAR(MAX) = NULL
       ,@Status INT = -1)
AS
BEGIN
        SET NOCOUNT ON;

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
                           ,AVG(    CALC.Duration) AS AverageDuration
                           ,MIN(    CALC.Duration) AS ShortestRunTime
                           ,MAX(    CALC.Duration) AS LongestRunTime
        FROM                SSISDB.catalog.executions E
        CROSS   APPLY       (SELECT CONVERT(DATETIME, E.start_time) AS StartDateTime
                                   ,CONVERT(DATETIME, E.end_time) AS EndDateTime
                                   ,CONVERT(FLOAT, DATEDIFF(MILLISECOND, E.start_time, ISNULL(E.end_time, SYSDATETIMEOFFSET()))) / 1000 AS Duration) CALC(StartDateTime, EndDateTime, Duration)
        LEFT    OUTER JOIN  ProvidedParameters PP
        ON ISNULL(PP.PackageName, E.package_name) = E.package_name
           AND  ISNULL(PP.FolderName, E.folder_name) = E.folder_name
           AND  ISNULL(PP.ProjectName, E.project_name) = E.project_name
           AND  ISNULL(PP.StatusValue, E.status) = E.status
        WHERE               CALC.StartDateTime BETWEEN PP.WindowBegins AND PP.WindowEnds
        GROUP BY            E.package_name
                           ,E.folder_name
                           ,E.project_name
        ORDER BY            FolderName
                           ,ProjectName
                           ,PackageName;
END;
GO