USE dw_valuation;
GO

/****** Object:  UserDefinedFunction [dbo].[fn_get_environment_parameter_value]    Script Date: 5/4/2018 7:08:35 PM ******/
DROP FUNCTION IF EXISTS dbo.fn_get_environment_parameter_value;
GO

/****** Object:  UserDefinedFunction [dbo].[fn_get_environment_parameter_value]    Script Date: 5/4/2018 7:08:35 PM ******/
SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

-- =============================================
-- Author:		E. Bakman
-- Create date: 07/20/2017
-- Description:	This function would return the 
-- value of a parameter from SSISDB based on the
-- Folder and Value name.  It is not intended for
-- use within a query and should only be used in
-- a SET statement.
-- =============================================

CREATE FUNCTION dbo.fn_get_environment_parameter_value (
        -- Add the parameters for the function here
        @FolderName NVARCHAR(128)
       ,@EnvironmentName NVARCHAR(128)
       ,@EnvironmentVariableName NVARCHAR(128))
RETURNS SQL_VARIANT
AS
BEGIN
        -- Declare the return variable here
        DECLARE @ParameterValue SQL_VARIANT;

        -- Add the T-SQL statements to compute the return value here
        SELECT  @ParameterValue =
        (SELECT         EV.value AS VariableValue
         FROM           SSISDB.catalog.folders F
         INNER   JOIN   SSISDB.catalog.environments E
         ON F.folder_id = E.folder_id
         INNER   JOIN   SSISDB.internal.environment_variables EV
         ON E.environment_id = EV.environment_id
         WHERE          (F.name = @FolderName)
                        AND (E.name = @EnvironmentName)
                        AND EV.name = @EnvironmentVariableName);

        -- Return the result of the function
        RETURN @ParameterValue;
END;
GO