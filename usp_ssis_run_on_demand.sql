USE RandomActsOfSQL
GO

/****** Object:  StoredProcedure [dbo].[usp_ssis_run_on_demand]    Script Date: 2/23/2018 8:29:38 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[usp_ssis_run_on_demand]
GO

/****** Object:  StoredProcedure [dbo].[usp_ssis_run_on_demand]    Script Date: 2/23/2018 8:29:38 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- ================================================
-- Author:		Elaena Bakman		 
-- Create date: 05/31/2017
-- Description:	This stored procedure will allow 
-- us to run SSIS packages on demand
-- Update:		
-- ================================================

CREATE PROCEDURE [dbo].[usp_ssis_run_on_demand] (
        @FolderName NVARCHAR(MAX)
       ,@ProjectName NVARCHAR(MAX)
       ,@PackageName NVARCHAR(MAX))
AS
BEGIN
        SET NOCOUNT ON;

        DECLARE @ExecutionId BIGINT
               ,@ReferenceId AS INT;

        SET @ReferenceId =
        (SELECT     ER.reference_id
         FROM       SSISDB.catalog.environment_references ER
         INNER   JOIN SSISDB.catalog.projects P
         ON P.project_id = ER.project_id
         WHERE      P.name = @ProjectName);

        EXECUTE SSISDB.catalog.create_execution @folder_name = @FolderName
                                               ,@project_name = @ProjectName
                                               ,@package_name = @PackageName
                                               ,@reference_id = @ReferenceId
                                               ,@execution_id = @ExecutionId OUTPUT;

        EXECUTE SSISDB.catalog.start_execution @execution_id = @ExecutionId;
END;
GO


