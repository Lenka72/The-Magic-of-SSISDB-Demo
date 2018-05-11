USE dw_valuation;
GO

/****** Object:  StoredProcedure [dbo].[usp_ssis_all_exceptions_report]    Script Date: 3/8/2018 6:08:29 PM ******/
DROP PROCEDURE dbo.usp_ssis_all_exceptions_report;
GO

/****** Object:  StoredProcedure [dbo].[usp_ssis_all_exceptions_report]    Script Date: 3/8/2018 6:08:29 PM ******/
SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

-- ================================================
-- Author:		Elaena Bakman		 
-- Create date: 03/16/2017
-- Description:	This will allow us to display details 
-- of the SSIS Package execution that the developers 
-- will need in order to be able to address any 
-- production issues without having to have sysadmin 
-- access to the SSISDB database.  This is for viewing 
-- the data only. 
-- Update:		
-- ================================================
-- Action:		1 - Run Package - it this is fired from SSRS it will run under the service account that is being used for SSRS
-- ================================================

CREATE PROCEDURE dbo.usp_ssis_all_exceptions_report (
        @WindowBegins DATETIME = NULL
       ,@WindowEnds DATETIME = NULL
       ,@FolderName NVARCHAR(MAX) = NULL
       ,@ProjectName NVARCHAR(MAX) = NULL
       ,@PackageName NVARCHAR(MAX) = NULL
       ,@Status INT = -1
       ,@Action INT = NULL)
AS
BEGIN
        SET NOCOUNT ON;

        DECLARE @ErrorMessage VARCHAR(500)
               ,@Result INT;;

        SET @WindowEnds = DATEADD(DAY, 1, @WindowEnds);

        -- kick off a package
        IF @Action IS NOT NULL
        BEGIN
                IF @FolderName IS NULL
                   OR   @ProjectName IS NULL
                   OR   @PackageName IS NULL
                BEGIN
                        SET @ErrorMessage = 'Sorry, this request could not be processed.  Please provide the Folder Name, Project Name, and Package Name to run a package.';

                        RAISERROR(@ErrorMessage, 16, 1);

                        RETURN;
                END;

                IF @Action = 1
                BEGIN
                        EXECUTE @Result = dbo.usp_ssis_run_on_demand @FolderName
                                                                    ,@ProjectName
                                                                    ,@PackageName;

                        IF @Result != 0
                        BEGIN
                                SET @ErrorMessage = 'Sorry, it appears that we had a problem running your package.  Please use the back button to run the report without running the package and view the exception reason.';

                                RAISERROR(@ErrorMessage, 16, 1);

                                RETURN;
                        END;
                END;
        END;

        WITH StatusDescription AS (SELECT   IQ.StatusValue
                                           ,IQ.StatusDescription
                                   FROM     (VALUES
                                                     (1, 'Created')
                                                    ,(2, 'Running')
                                                    ,(3, 'Canceled')
                                                    ,(4, 'Failed')
                                                    ,(5, 'Pending')
                                                    ,(6, 'Ended Unexpectedly')
                                                    ,(7, 'Succeeded')
                                                    ,(8, 'Stopping')
                                                    ,(9, 'Completed')) IQ (StatusValue, StatusDescription) )
            ,ProvidedParameters AS (SELECT  IQ.PackageName
                                           ,IQ.FolderName
                                           ,IQ.ProjectName
                                           ,ISNULL(IQ.WindowBegins, '19000101') AS WindowBegins
                                           ,ISNULL(IQ.WindowEnds, '25000101') AS WindowEnds
                                           ,NULLIF(IQ.StatusValue, -1) AS StatusValue
                                    FROM    (VALUES
                                                     (@PackageName, @FolderName, @ProjectName, @WindowBegins, @WindowEnds, @Status)) IQ (PackageName, FolderName, ProjectName, WindowBegins, WindowEnds, StatusValue) )
        SELECT              E.execution_id AS ExecutionId
                           ,E.use32bitruntime AS Use32BitAtRuntime
                           ,CALC.StartDateTime
                           ,CALC.EndDateTime
                           ,CASE
                                    WHEN DATEDIFF(HOUR, E.start_time, ISNULL(E.end_time, SYSDATETIMEOFFSET())) > 24 THEN -1
                                    ELSE    DATEDIFF(MILLISECOND, E.start_time, ISNULL(E.end_time, SYSDATETIMEOFFSET()))
                            END AS Duration
                           ,E.caller_name AS CallerName
                           ,E.folder_name AS FolderName
                           ,E.project_name AS ProjectName
                           ,E.package_name AS PackageName
                           ,SD.StatusDescription AS Status
                           ,CAST(ISNULL( ED.HasDataStatistics, 0) AS BIT) AS HasDataStatistics
        FROM                SSISDB.catalog.executions E
        CROSS   APPLY       (SELECT CONVERT(DATETIME, E.start_time) AS StartDateTime
                                   ,CONVERT(DATETIME, E.end_time) AS EndDateTime) CALC(StartDateTime, EndDateTime)
        LEFT    OUTER JOIN  StatusDescription SD
        ON SD.StatusValue = E.status
        LEFT    OUTER JOIN  ProvidedParameters PP
        ON ISNULL(PP.PackageName, E.package_name) = E.package_name
           AND  ISNULL(PP.FolderName, E.folder_name) = E.folder_name
           AND  ISNULL(PP.ProjectName, E.project_name) = E.project_name
           AND  ISNULL(PP.StatusValue, E.status) = E.status
        OUTER   APPLY       (SELECT     DISTINCT 1 AS HasDataStatistics
                             FROM       SSISDB.catalog.execution_data_statistics EDS
                             WHERE      EDS.execution_id = E.execution_id) ED
        WHERE               CALC.StartDateTime BETWEEN PP.WindowBegins AND PP.WindowEnds
        ORDER BY            E.execution_id DESC;
END;
GO