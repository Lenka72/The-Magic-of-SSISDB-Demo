USE SSISDBDemo;
GO

/****** Object:  StoredProcedure [dbo].[usp_ssis_package_performance_report]    Script Date: 6/26/2018 10:16:34 AM ******/
DROP PROCEDURE dbo.usp_ssis_package_performance_report;
GO

/****** Object:  StoredProcedure [dbo].[usp_ssis_package_performance_report]    Script Date: 6/26/2018 10:16:34 AM ******/
SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

-- ================================================
-- Author:		Elaena Bakman		 
-- Create date: 05/04/2018
-- Description:	This stopred procedure would allow
-- us to pull the package performance statistics.
-- Update:		
-- ================================================

CREATE PROCEDURE dbo.usp_ssis_package_performance_report (
        @FolderName VARCHAR(500)
       ,@PackageName VARCHAR(500)
       ,@FromTimeframe DATE = NULL
       ,@ToTimeframe DATE = NULL)
AS
BEGIN
        SET NOCOUNT ON;

        IF @FromTimeframe IS NULL
                SET @FromTimeframe = DATEADD(MONTH, -1, GETDATE());

        IF @ToTimeframe IS NULL
                SET @ToTimeframe = GETDATE();

        SELECT          E.folder_name AS FolderName
                       ,E.project_name AS ProjectName
                       ,E.package_name AS PackageName
                       ,CALC2.StartDateTime AS StartDateTime
                       ,CALC2.EndDateTime AS EndDateTime
                       ,CALC1.Duration
        FROM            SSISDB.catalog.executions E
        CROSS   APPLY   (SELECT CASE
                                        WHEN DATEDIFF(HOUR, E.start_time, ISNULL(E.end_time, SYSDATETIMEOFFSET())) > 24 THEN -1
                                        ELSE    DATEDIFF(MILLISECOND, E.start_time, ISNULL(E.end_time, SYSDATETIMEOFFSET()))
                                END AS Duration) CALC1(Duration)
        CROSS   APPLY   (SELECT CONVERT(DATETIME, E.start_time) AS StartDateTime
                               ,CONVERT(DATETIME, E.end_time) AS EndDateTime
                               ,CONVERT(FLOAT, CALC1.Duration) / 1000 AS Duration) CALC2(StartDateTime, EndDateTime, Duration)
        WHERE           E.status = 7
                        AND E.package_name = @PackageName
                        AND E.folder_name = @FolderName
                        AND CALC2.StartDateTime >= @FromTimeframe
                        AND CALC2.EndDateTime <= @ToTimeframe;
END;
GO