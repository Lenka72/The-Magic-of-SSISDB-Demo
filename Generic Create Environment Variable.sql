USE SSISDB;
GO

DECLARE @folder_name NVARCHAR(128)
       ,@environment_name sysname
       ,@variable_name NVARCHAR(128)
       ,@var SQL_VARIANT;

SET @folder_name = N'<Folder Name, VARCHAR(100), Demo Folder>';
SET @environment_name = N'<Environment Name, VARCHAR(100), Demo Environment>';
SET @variable_name = N'<Variable Name, VARCHAR(100), ServerName_Damo>';
SET @var = N'THOR';

IF NOT EXISTS
(SELECT         1 
 FROM           catalog.folders F
 INNER   JOIN   catalog.environments E
 ON E.folder_id = F.folder_id
 INNER   JOIN   catalog.environment_variables EV
 ON EV.environment_id = E.environment_id
 WHERE          F.name = @folder_name
                AND E.name = @environment_name
                AND EV.name = @variable_name)
BEGIN
        EXEC SSISDB.catalog.create_environment_variable @variable_name = @variable_name
                                                       ,@sensitive = False
                                                       ,@description = N'This is a variable we are going to use for our demo.'
                                                       ,@environment_name = @environment_name
                                                       ,@folder_name = @folder_name
                                                       ,@value = @var
                                                       ,@data_type = N'String';
END;
GO