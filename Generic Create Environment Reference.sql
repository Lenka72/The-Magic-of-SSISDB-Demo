USE SSISDB
GO

DECLARE @reference_id BIGINT;

EXEC catalog.create_environment_reference @environment_name = N'<Environment Name, VARCHAR(255), Demo Environment>'
                                         ,@reference_id = @reference_id OUTPUT
                                         ,@project_name = N'<Project Name, VARCHAR(255), Demo>'
                                         ,@folder_name = N'<Folder Name, VARCHAR(255), Demo Folder>'
                                         ,@reference_type = R;

SELECT  @reference_id;