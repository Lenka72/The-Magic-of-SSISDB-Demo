USE SSISDB;
GO

DECLARE @folder_name NVARCHAR(128)
       ,@environment_name sysname;

SET @folder_name = N'<Folder Name, VARCHAR(100), Demo Folder>';
SET @environment_name = N'<Environment Name, VARCHAR(100), Demo Environment>';

IF NOT EXISTS
(SELECT         1
 FROM           catalog.folders F
 INNER   JOIN   catalog.environments E
 ON E.folder_id = F.folder_id
 WHERE          F.name = @folder_name
                AND E.name = @environment_name)
BEGIN
        IF EXISTS (SELECT   1 FROM  catalog.folders F WHERE F.name = @folder_name)
        BEGIN
                EXEC SSISDB.catalog.create_environment @environment_name = @environment_name
                                                      ,@environment_description = N'<Environment Description, VARCHAR(500), This will be the environment we will be using for our demo.>'
                                                      ,@folder_name = @folder_name;
        END;
END;
GO