USE RandomActsOfSQL
GO

/****** Object:  StoredProcedure [dbo].[usp_ssis_all_messages_report]    Script Date: 2/23/2018 9:58:06 PM ******/
DROP PROCEDURE IF EXISTS [dbo].[usp_ssis_all_messages_report]
GO

/****** Object:  StoredProcedure [dbo].[usp_ssis_all_messages_report]    Script Date: 2/23/2018 9:58:06 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




-- ================================================
-- Author:		Elaena Bakman		 
-- Create date: 03/16/2017
-- Description:	This stored procedure will allow you 
-- to view the execution messages based on the specific 
-- Execution Id.  It is intended to be viewed through 
-- the "All Executions" report because the ID needs 
-- to be provided.  The logic behind requiring this 
-- is to make sure that the viewer first has the 
-- opportunity to select the correct event based on
-- the name of the package and the time of execution.
-- Update:		
-- ================================================
CREATE PROCEDURE [dbo].[usp_ssis_all_messages_report]
    (
     @ExecutionID NVARCHAR(MAX)
    )
AS
    BEGIN
        SET NOCOUNT ON;

        WITH    EventMessages
                  AS (SELECT    EM.event_message_id
                               ,EM.operation_id
                               ,CONVERT(DATETIME, EM.message_time) AS message_time
                               ,EM.message_type
                               ,EM.message_source_type
                               ,CASE WHEN LEN(EM.message) <= 4096 THEN EM.message
                                     ELSE LEFT(EM.message, 1024) + '...'
                                END AS message
                               ,EM.extended_info_id
                               ,EM.event_name
                               ,CASE WHEN LEN(EM.message_source_name) <= 1024 THEN EM.message_source_name
                                     ELSE LEFT(EM.message_source_name, 1024) + '...'
                                END AS message_source_name
                               ,EM.message_source_id
                               ,CASE WHEN LEN(EM.subcomponent_name) <= 1024 THEN EM.subcomponent_name
                                     ELSE LEFT(EM.subcomponent_name, 1024) + '...'
                                END AS subcomponent_name
                               ,CASE WHEN LEN(EM.package_path) <= 1024 THEN EM.package_path
                                     ELSE LEFT(EM.package_path, 1024) + '...'
                                END AS package_path
                               ,CASE WHEN LEN(EM.execution_path) <= 1024 THEN EM.execution_path
                                     ELSE LEFT(EM.execution_path, 1024) + '...'
                                END AS execution_path
                               ,EM.message_code
                               ,EOI.reference_id
                      FROM      SSISDB.catalog.event_messages EM
                      LEFT JOIN SSISDB.catalog.extended_operation_info EOI
                      ON        EM.extended_info_id = EOI.info_id
                      WHERE     EM.operation_id = @ExecutionID
                     ),
                FolderReference
                  AS (SELECT    EM.event_message_id
                               ,EM.operation_id
                               ,EM.message_time
                               ,EM.message_type
                               ,EM.message_source_type
                               ,EM.message
                               ,EM.extended_info_id
                               ,EM.event_name
                               ,EM.message_source_name
                               ,EM.message_source_id
                               ,EM.subcomponent_name
                               ,EM.package_path
                               ,EM.execution_path
                               ,EM.message_code
                               ,EM.reference_id
                               ,ref.reference_type
                               ,ref.environment_folder_name
                               ,ref.environment_name
                      FROM      EventMessages EM
                      LEFT JOIN SSISDB.catalog.environment_references ref
                      ON        EM.reference_id = ref.reference_id
                     )
            SELECT  FR.reference_id AS ReferenceId
                   ,FR.message_code AS MessageCode
                   ,FR.execution_path AS ExecutionPath
                   ,FR.package_path AS PackagePath
                   ,FR.subcomponent_name AS SubComponentName
                   ,FR.message_source_id AS MessageSourceId
                   ,FR.message_source_name AS MessageSourceName
                   ,FR.event_name AS EventName
                   ,FR.extended_info_id AS ExtendedInformationId
                   ,FR.message AS Message
                   ,FR.message_source_type AS MessageSourceType
                   ,FR.message_type AS MessageType
                   ,FR.message_time AS MessageTime
                   ,FR.operation_id AS OperationId
                   ,FR.event_message_id AS EventMessageId
                   ,FR.reference_type AS ReferenceType
                   ,FR.environment_folder_name AS EnvironmentFolderName
                   ,FR.environment_name AS EnvironmentName
                   ,CALC.Environment
            FROM    FolderReference FR
            CROSS APPLY (SELECT CASE WHEN FR.reference_id IS NULL THEN '-'
                                     ELSE (CASE WHEN FR.reference_type = 'R'
                                                     OR FR.reference_type = 'r' THEN '.'
                                                ELSE FR.environment_folder_name
                                           END) + '\' + FR.environment_name
                                END AS Environment
                        ) CALC (Environment)
            ORDER BY FR.message_time DESC;

    END;	

GO


