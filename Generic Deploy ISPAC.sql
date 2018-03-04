USE SSISDB
GO 


PRINT 'Deploying <Project Name, VARCHAR(255), Demo> - Time: ' + CONVERT(VARCHAR(25), GETDATE(), 131);
GO 

DECLARE @ProjectBinary AS VARBINARY(MAX)
       ,@OperationId AS BIGINT
       ,@ProjectName NVARCHAR(128)
       ,@FolderName NVARCHAR(128);

SET @ProjectName = '<Project Name, VARCHAR(255), Demo>';
--=====================================================================================================
-- if the project exists, you can pull the Folder Name based on the Project Name, but for a brand new
-- project you would have to set it.
--=====================================================================================================

-- you can use this section of the project already exists in the project folder

SET @FolderName = 
(SELECT     F.name
 FROM       catalog.projects P
 INNER   JOIN catalog.folders F
 ON F.folder_id = P.folder_id
 WHERE      P.name = @ProjectName);

 -- or this section if this is a new project

 SET @FolderName = '<Folder Name, VARCHAR(100), Demo Folder>';

SET @ProjectBinary =
(SELECT     *
 FROM
            OPENROWSET(BULK
                    '<ISPAC Path, VARCHAR(255), C:\Users\Elaena\Documents\Visual Studio 2015\Projects\SSIS 2016\Vitamins Demo\Vitamins Demo\bin\Development\Demo.ispac>'
                   ,SINGLE_BLOB)
            AS BinaryData );

EXEC catalog.deploy_project @folder_name = @FolderName
                           ,@project_name = @ProjectName
                           ,@project_stream = @ProjectBinary
                           ,@operation_id = @OperationId OUT;
GO

PRINT 'Finished deploying <Project Name, VARCHAR(255), Demo> - Time: ' + CONVERT(VARCHAR(25), GETDATE(), 131);
GO 
