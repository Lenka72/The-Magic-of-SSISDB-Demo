USE SSISDB;
GO

--create SSISDB folder

DECLARE @folder_name NVARCHAR(128)
       ,@folder_id BIGINT;

SET @folder_name = N'<Folder Name, VARCHAR(100), Demo Folder>';

IF NOT EXISTS (SELECT   1 FROM  catalog.folders WHERE   name = @folder_name)
BEGIN
        EXEC SSISDB.catalog.create_folder @folder_name = @folder_name
                                         ,@folder_id = @folder_id OUTPUT;

        SELECT  @folder_id;

        EXEC SSISDB.catalog.set_folder_description @folder_name = @folder_name
                                                  ,@folder_description = N'<Folder Description, VARCHAR(500), This folder will hold the paramters for things you may want to use.'>;
END;
GO