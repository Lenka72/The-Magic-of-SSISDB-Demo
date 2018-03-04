USE RandomActsOfSQL
GO

--option 1 - setting a variabl value

DECLARE @MyServerName VARCHAR(25);

SET @MyServerName =
(SELECT dbo.fn_get_environment_variable_value('<@FolderName, nvarchar(128), Demo Folder>', '<@EnvironmentName, nvarchar(128), Demo Environment>', 'ServerName_Damo'));

PRINT @MyServerName;

GO

--option 2 - in a SELECT Statement

SELECT dbo.fn_get_environment_variable_value('<@FolderName, nvarchar(128), Demo Folder>', '<@EnvironmentName, nvarchar(128), Demo Environment>', '<@EnvironmentVariableName, nvarchar(128), ServerName_Damo>');
