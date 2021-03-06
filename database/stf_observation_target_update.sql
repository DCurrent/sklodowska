USE [EHSINFO]
GO
/****** Object:  StoredProcedure [dbo].[stf_observation_target_update]    Script Date: 2017-07-26 12:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Create date: 2015-07-27
-- Description:	Insert or update items.
-- =============================================
ALTER PROCEDURE [dbo].[stf_observation_target_update]
	
	-- Parameters
	@param_id_list				xml				= NULL, 
	@param_update_by			int				= NULL,
	@param_update_host			varchar(50)		= NULL,
	@param_label				varchar(50)		= NULL,
	@param_details				varchar(max)	= NULL,
	@param_building_code		varchar(max)	= NULL,
	@param_room_code			varchar(max)	= NULL,
	@param_observation_results	xml				= NULL,
	@param_update_account	varchar(50)		= NULL

AS
BEGIN
	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	

	-- Local cache of master result.
	CREATE TABLE #cache_master_update_result
	(
		id_row	int,
		id_key	int,
		id		int
	)

	-- Update master table. This creates a new
	-- version entry and primary key we need.
		INSERT INTO #cache_master_update_result
			EXEC stf_master_update
				@param_id_list,
				@param_update_by,
				@param_update_host,
				@param_update_account

	-- Update data table using the
	-- new primary key from master table.
		INSERT INTO tbl_stf_observation_target
				(id_key,
				label,
				details,
				building_code,
				room_code)	

		SELECT _master.id_key,
				@param_label,
				@param_details,
				@param_building_code,
				@param_room_code
		FROM 
			#cache_master_update_result AS _master

	-- Sub Data
		
		-- Declare and set a foreign key. Sub records
			-- are keyed by the the main record's key ID, NOT 
			-- the group ID.
		
			DECLARE @fk_id int = NULL

			SET @fk_id = (SELECT TOP 1 id_key FROM #cache_master_update_result)
		
		-- Observation results.
			SELECT 
				row.value('@item',				'INT')	AS item,
				row.value('result[1]',				'INT')	AS result
			INTO #cache_observation_target_result
			FROM @param_observation_results.nodes('root/row')Catalog(row)

			INSERT INTO tbl_stf_observation_target_result
				(fk_id,
				item,
				result)
			SELECT @fk_id,
				_source.item,
				_source.result
			FROM #cache_observation_target_result AS _source

	-- Output ID of the newly inserted record.
	SELECT TOP 1
		_master.id
		FROM #cache_master_update_result AS _main
		JOIN tbl_stf_master AS _master ON _main.id_key = _master.id_key
			
					
END

