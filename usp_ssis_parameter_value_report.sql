USE SSISDBDemo
GO

/****** Object:  StoredProcedure [dbo].[usp_ssis_parameter_value_report]    Script Date: 2/25/2018 9:29:19 PM ******/
DROP PROCEDURE IF EXISTS dbo.usp_ssis_parameter_value_report;
GO

/****** Object:  StoredProcedure [dbo].[usp_ssis_parameter_value_report]    Script Date: 2/25/2018 9:29:19 PM ******/
SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

-- ================================================
-- Author:		Elaena Bakman		 
-- Create date: 05/02/107
-- Description:	This stored procedure will show the 
-- package and project level parameters associated 
-- WITH SSIS packages.
-- Update:		
-- ================================================

CREATE PROCEDURE dbo.usp_ssis_parameter_value_report (
        @FolderName NVARCHAR(MAX) = NULL
       ,@ProjectName NVARCHAR(MAX) = NULL
       ,@PackageName NVARCHAR(MAX) = NULL
       ,@UserId dtUserId)
AS
BEGIN
        SET NOCOUNT ON;

        DECLARE @Result INT;

        WITH Unassigned AS (SELECT          F.name AS FolderName
                                           ,'Not Assigned' AS ProjectNamme
                                           ,'Not Assigned' AS PackageName
                                           ,E.created_time AS ProjectLastDeployedDateTime
                                           ,'Unassigned' AS ParameterName
                                           ,'Not Assigned' AS ParameterDataType
                                           ,'Not Assigned' AS ParameterDesignDefaultValue
                                           ,'Not Assigned' AS ParameterReferencedVariableName
                                           ,EV.name AS EnvironmentVariableName
                                           ,EV.description AS EnvironmentVariableDescription
                                           ,EV.type AS EnvironmentVariableType
                                           ,EV.value AS EnvironmentVariableValue
                                           ,'Unassigned' AS VariableLevel
                            FROM            SSISDB.catalog.environment_variables EV
                            INNER   JOIN    SSISDB.catalog.environments E
                            ON E.environment_id = EV.environment_id
                            CROSS   APPLY   (SELECT     OP.parameter_id
                                             FROM       SSISDB.catalog.object_parameters OP
                                             WHERE      OP.value_type = 'R'
                                                        AND OP.object_name IN (20, 30)
                                                        AND OP.referenced_variable_name = EV.name) PP
                            INNER   JOIN    SSISDB.catalog.folders F
                            ON F.folder_id = E.folder_id
                            WHERE           PP.parameter_id IS NULL)
        SELECT          DISTINCT F.name AS FolderName
                                ,PRJ.name AS ProjectName
                                ,PKG.name AS PackageName
                                ,PRJ.last_deployed_time AS ProjectLastDeployedDateTime
                                ,PKGP.parameter_name AS ParameterName
                                ,PKGP.data_type AS ParameterDataType
                                ,PKGP.design_default_value AS ParameterDesignDefaultValue
                                ,PKGP.referenced_variable_name AS ParameterReferencedVariableName
                                ,EV.name AS EnvironmentVariableName
                                ,EV.description AS EnvironmentVariableDescription
                                ,EV.type AS EnvironmentVariableType
                                ,EV.value AS EnvironmentVariableValue
                                ,CASE PKGP.object_type
                                         WHEN 20 THEN 'Project'
                                         WHEN 30 THEN 'Package'
                                 END AS VariableLevel
        FROM            SSISDB.catalog.folders F
        INNER   JOIN    SSISDB.catalog.environments E
        ON E.folder_id = F.folder_id
        INNER   JOIN    SSISDB.catalog.projects PRJ
        ON PRJ.folder_id = F.folder_id
        INNER   JOIN    SSISDB.catalog.packages PKG
        ON PKG.project_id = PRJ.project_id
        INNER   JOIN    SSISDB.catalog.environment_variables EV
        ON EV.environment_id = E.environment_id
        CROSS   APPLY   (SELECT     OP.referenced_variable_name
                                   ,OP.object_type
                                   ,OP.parameter_name
                                   ,OP.data_type
                                   ,OP.design_default_value
                         FROM       SSISDB.catalog.object_parameters OP
                         WHERE      OP.value_type = 'R'
                                    AND OP.object_name = PKG.name
                                    AND OP.referenced_variable_name = EV.name) PKGP
        WHERE           F.name = ISNULL( @FolderName, F.name)
                        AND PRJ.name = ISNULL( @ProjectName, PRJ.name)
                        AND PKG.name = ISNULL( @PackageName, PKG.name)
        UNION
        SELECT          DISTINCT F.name AS FolderName
                                ,PRJ.name AS ProjectName
                                ,PKG.name AS PackageName
                                ,PRJ.last_deployed_time AS ProjectLastDeployedDateTime
                                ,PRJP.parameter_name AS ParameterName
                                ,PRJP.data_type AS ParameterDataType
                                ,PRJP.design_default_value AS ParameterDesignDefaultValue
                                ,PRJP.referenced_variable_name AS ParameterReferencedVariableName
                                ,EV.name AS EnvironmentVariableName
                                ,EV.description AS EnvironmentVariableDescription
                                ,EV.type AS EnvironmentVariableType
                                ,EV.value AS EnvironmentVariableValue
                                ,CASE PRJP.object_type
                                         WHEN 20 THEN 'Project'
                                         WHEN 30 THEN 'Package'
                                 END AS VariableLevel
        FROM            SSISDB.catalog.folders F
        INNER   JOIN    SSISDB.catalog.environments E
        ON E.folder_id = F.folder_id
        INNER   JOIN    SSISDB.catalog.projects PRJ
        ON PRJ.folder_id = F.folder_id
        INNER   JOIN    SSISDB.catalog.packages PKG
        ON PKG.project_id = PRJ.project_id
        INNER   JOIN    SSISDB.catalog.environment_variables EV
        ON EV.environment_id = E.environment_id
        CROSS   APPLY   (SELECT     OP.referenced_variable_name
                                   ,OP.object_type
                                   ,OP.parameter_name
                                   ,OP.data_type
                                   ,OP.design_default_value
                         FROM       SSISDB.catalog.object_parameters OP
                         WHERE      OP.value_type = 'R'
                                    AND OP.object_name = PRJ.name
                                    AND OP.referenced_variable_name = EV.name) PRJP
        WHERE           F.name = ISNULL( @FolderName, F.name)
                        AND PRJ.name = ISNULL( @ProjectName, PRJ.name)
                        AND PKG.name = ISNULL( @PackageName, PKG.name)
        UNION
        SELECT  U.FolderName
               ,U.ProjectNamme
               ,U.PackageName
               ,U.ProjectLastDeployedDateTime
               ,U.ParameterName
               ,U.ParameterDataType
               ,U.ParameterDesignDefaultValue
               ,U.ParameterReferencedVariableName
               ,U.EnvironmentVariableName
               ,U.EnvironmentVariableDescription
               ,U.EnvironmentVariableType
               ,U.EnvironmentVariableValue
               ,U.VariableLevel
        FROM    Unassigned U
        WHERE   U.FolderName = ISNULL(@FolderName, U.FolderName)
                AND U.ProjectNamme = ISNULL(@ProjectName, U.ProjectNamme)
                AND U.PackageName = ISNULL(@PackageName, U.PackageName)
        ORDER BY    FolderName
                   ,ProjectName
                   ,PackageName
                   ,EnvironmentVariableName
                   ,EnvironmentVariableValue;
END;
GO