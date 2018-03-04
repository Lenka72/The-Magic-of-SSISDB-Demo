USE SSISDB;
GO

DECLARE @reference_id BIGINT
       ,@folder_name NVARCHAR(128)
       ,@environment_name sysname
       ,@project_name NVARCHAR(128);

SET @folder_name = N'<Folder Name, VARCHAR(255), Demo Folder>';
SET @environment_name = N'<Environment Name, VARCHAR(255), Demo Environment>';
SET @project_name = N'<Project Name, VARCHAR(255), Demo>';

IF NOT EXISTS
(SELECT        1
 FROM           catalog.environment_references ER
 INNER   JOIN   catalog.projects P
 ON P.project_id = ER.project_id
 INNER   JOIN   catalog.folders F
 ON F.folder_id = P.folder_id
 WHERE          ER.environment_name = @environment_name
                AND P.name = @project_name
                AND F.name = @folder_name)
BEGIN
        EXEC catalog.create_environment_reference @environment_name = @environment_name
                                                 ,@reference_id = @reference_id OUTPUT
                                                 ,@project_name = @project_name
                                                 ,@folder_name = @folder_name
                                                 ,@reference_type = R;

        SELECT  @reference_id;
END;