<?php
require_once('config.class.php');
require_once('returnData.class.php');

abstract class Module
{
	//constants for player_log table enums
	const kLOG_LOGIN = 'LOGIN';
	const kLOG_MOVE = 'MOVE';
	const kLOG_PICKUP_ITEM = 'PICKUP_ITEM';
	const kLOG_DROP_ITEM = 'DROP_ITEM';
	const kLOG_DESTROY_ITEM = 'DESTROY_ITEM';
	const kLOG_VIEW_ITEM = 'VIEW_ITEM';
	const kLOG_VIEW_NODE = 'VIEW_NODE';
	const kLOG_VIEW_NPC = 'VIEW_NPC';
	const kLOG_VIEW_MAP = 'VIEW_MAP';
	const kLOG_VIEW_QUESTS = 'VIEW_QUESTS';
	const kLOG_VIEW_INVENTORY = 'VIEW_INVENTORY';
	const kLOG_ENTER_QRCODE = 'ENTER_QRCODE';
	const kLOG_UPLOAD_MEDIA = 'UPLOAD_MEDIA';
	
	//constants for gameID_requirements table enums
	const kREQ_PLAYER_HAS_ITEM = 'PLAYER_HAS_ITEM';
	const kREQ_PLAYER_DOES_NOT_HAVE_ITEM = 'PLAYER_DOES_NOT_HAVE_ITEM';
	const kREQ_PLAYER_VIEWED_ITEM = 'PLAYER_VIEWED_ITEM';
	const kREQ_PLAYER_HAS_NOT_VIEWED_ITEM = 'PLAYER_HAS_NOT_VIEWED_ITEM';
	const kREQ_PLAYER_VIEWED_NODE = 'PLAYER_VIEWED_NODE';
	const kREQ_PLAYER_HAS_NOT_VIEWED_NODE = 'PLAYER_HAS_NOT_VIEWED_NODE';
	const kREQ_PLAYER_VIEWED_NPC = 'PLAYER_VIEWED_NPC';
	const kREQ_PLAYER_HAS_NOT_VIEWED_NPC = 'PLAYER_HAS_NOT_VIEWED_NPC';
	
	//constants for player_state_changes table enums
	const kPSC_GIVE_ITEM = 'GIVE_ITEM';
	const kPSC_TAKE_ITEM = 'TAKE_ITEM';	
	
	public function Module()
	{
		$this->conn = mysql_pconnect(Config::dbHost, Config::dbUser, Config::dbPass);
      	mysql_select_db (Config::dbSchema);
	}	
	
	/**
     * Fetch the prefix of a game
     * @returns a prefix string without the trailing _
     */
	public function getPrefix($intGameID) {	
		//Lookup game information
		$query = "SELECT * FROM games WHERE game_id = '{$intGameID}'";
		$rsResult = @mysql_query($query);
		if (mysql_num_rows($rsResult) < 1) return FALSE;
		$gameRecord = mysql_fetch_array($rsResult);
		return substr($gameRecord['prefix'],0,strlen($row['prefix'])-1);
		
	}
	
	/**
     * Fetch the GameID from a prefix
     * @returns a gameID int
     */
	public function getGameIdFromPrefix($strPrefix) {	
		//Lookup game information
		$query = "SELECT * FROM games WHERE prefix= '{$strPrefix}_'";
		$rsResult = @mysql_query($query);
		if (mysql_num_rows($rsResult) < 1) return FALSE;
		$gameRecord = mysql_fetch_array($rsResult);
		return $gameRecord['game_id'];
		
	}	
	
	
	
    /**
     * Adds the specified item to the specified player.
     */
     protected function giveItemToPlayer($strGamePrefix, $intItemID, $intPlayerID) {
		    	
    	$query = "INSERT INTO {$strGamePrefix}_player_items 
										  (player_id, item_id) VALUES ($intPlayerID, $intItemID)
										  ON duplicate KEY UPDATE item_id = $intItemID";
		@mysql_query($query);
		
    }
	
	
	/**
     * Removes the specified item from the user.
     */ 
    protected function takeItemFromPlayer($strGamePrefix, $intItemID, $intPlayerID) {

    	$query = "DELETE FROM {$strGamePrefix}_player_items 
					WHERE player_id = $intPlayerID AND item_id = $intItemID";
    	
    	@mysql_query($query);    	
    }
	
	/**
     * Decrement the item_qty at the specified location by the specified amount, default of 1
     */ 
    protected function decrementItemQtyAtLocation($strGamePrefix, $intLocationID, $intQty = 1) {
   		//If this location has a null item_qty, decrementing it will still be a null
		$query = "UPDATE {$strGamePrefix}_locations 
					SET item_qty = item_qty-{$intQty}
					WHERE location_id = '{$intLocationID}'";
    	@mysql_query($query);    	
	}
	
	
	/**
     * Adds an item to Locations at the specified latitude, longitude
     */ 
    protected function giveItemToWorld($strGamePrefix, $intItemID, $floatLat, $floatLong, $intQty = 1) {
		$itemName = $this->getItemName($strGamePrefix, $intItemID);
		$error = 100; //Use 100 meters
		$icon_media_id = $this->getItemIconMediaId($strGamePrefix, $intItemID); //Set the map icon = the item's icon
		
		$query = "INSERT INTO {$strGamePrefix}_locations (name, type, type_id, icon_media_id, latitude, longitude, error, item_qty)
										  VALUES ('{$itemName}','Item','{$intItemID}', '{$icon_media_id}', '{$floatLat}','{$floatLong}', '{$error}','{$intQty}')";
    	@mysql_query($query);    	
    }
	
    
    /**
    * Checks if a record Exists
    **/
    protected function recordExists($strPrefix, $strTable, $intRecordID){
    	$key = substr($strTable, 0, strlen($strTable)-1);
    	$query = "SELECT * FROM {$strPrefix}_{$strTable} WHERE {$key} = $intRecordID";
    	$rsResult = @mysql_query($query);
		if (mysql_error()) return FALSE;
		if (mysql_num_rows($rsResult) < 1) return FALSE;
		return true;
    }
	
	/**
    * Looks up an item name
    **/
    protected function getItemName($strPrefix, $intItemID){
    	$query = "SELECT name FROM {$strPrefix}_items WHERE item_id = $intItemID";
    	$rsResult = @mysql_query($query);		
		$row = @mysql_fetch_array($rsResult);	
		return $row['name'];
    }
    
 	/**
    * Looks up an item icon media id
    **/
    protected function getItemIconMediaId($strPrefix, $intItemID){
    	$query = "SELECT name FROM {$strPrefix}_items WHERE item_id = $intItemID";
    	$rsResult = @mysql_query($query);		
		$row = @mysql_fetch_array($rsResult);	
		return $row['icon_media_id'];
    }   
		
	/** 
	 * playerHasLog
	 *
     * Checks if the specified user has the specified log event in the game
	 *
     * @return boolean
     */
    protected function playerHasLog($strPrefix, $intPlayerID, $strEventType, $strEventDetail) {
		
		$intGameID = Module::getGameIdFromPrefix($strPrefix);

		$query = "SELECT * FROM player_log 
					WHERE player_id = '{$intPlayerID}' AND
						game_id = '{$intGameID}' AND
						event_type = '{$strEventType}' AND
						event_detail_1 = '{$strEventDetail}'";
		NetDebug::trace($query);
		
		$rsResult = @mysql_query($query);
		
		if (mysql_num_rows($rsResult) > 0) return true;
		else return false;
    }
    

	/** 
	 * playerHasItem
	 *
     * Checks if the specified user has the specified item in the specified game.
     * @return boolean
     */
    protected function playerHasItem($intGameID, $intPlayerID, $intItemID) {
    	$prefix = $this->getPrefix($intGameID);
		if (!$prefix) return FALSE;
    
		$query = "SELECT * FROM {$prefix}_player_items 
									  WHERE player_id = '{$intPlayerID}' 
									  AND item_id = '{$intItemID}'";
		
		$rsResult = @mysql_query($query);
		
		if (mysql_num_rows($rsResult) > 0) return true;
		else return false;
    }		
	
	
	/** 
	 * objectMeetsRequirements
	 *
     * Checks all requirements for the specified object for the specified user
     * @return boolean
     */	
	protected function objectMeetsRequirements ($strPrefix, $intPlayerID, $strObjectType, $intObjectID) {		
		
		//Fetch the requirements
		$query = "SELECT * FROM {$strPrefix}_requirements 
					WHERE content_type = '{$strObjectType}' AND content_id = '{$intObjectID}'";
		$rsRequirments = @mysql_query($query);
		
		while ($requirement = mysql_fetch_array($rsRequirments)) {
			//NetDebug::trace("Requirement for {$strObjectType}:{$intObjectID} is {$requirement['requirement']}:{$requirement['requirement_detail']}");

			//Check the requirement
			switch ($requirement['requirement']) {
				//Log related
				case Module::kREQ_PLAYER_VIEWED_ITEM:
					if (!Module::playerHasLog($strPrefix, $intPlayerID, Module::kLOG_VIEW_ITEM, $requirement['requirement_detail'])) return FALSE;
					break;
				case Module::kREQ_PLAYER_HAS_NOT_VIEWED_ITEM:
					if (Module::playerHasLog($strPrefix, $intPlayerID, Module::kLOG_VIEW_ITEM, $requirement['requirement_detail'])) return FALSE;
					break;
				case Module::kREQ_PLAYER_VIEWED_NODE:
					if (!Module::playerHasLog($strPrefix, $intPlayerID, Module::kLOG_VIEW_NODE, $requirement['requirement_detail'])) return FALSE;
					break;
				case Module::kREQ_PLAYER_HAS_NOT_VIEWED_NODE:
					if (Module::playerHasLog($strPrefix, $intPlayerID, Module::kLOG_VIEW_NODE, $requirement['requirement_detail'])) return FALSE;
					break;
				case Module::kREQ_PLAYER_VIEWED_NPC:
					if (!Module::playerHasLog($strPrefix, $intPlayerID, Module::kLOG_VIEW_NPC, $requirement['requirement_detail'])) return FALSE;
					break;
				case Module::kREQ_PLAYER_HAS_NOT_VIEWED_NPC:
					if (Module::playerHasLog($strPrefix, $intPlayerID, Module::kLOG_VIEW_NPC, $requirement['requirement_detail'])) return FALSE;
					break;					
				//Inventory related	
				case Module::kREQ_PLAYER_HAS_ITEM:
					if (!Module::playerHasItem($strPrefix, $intPlayerID, $requirement['requirement_detail'])) return FALSE;
					break;
				case Module::kREQ_PLAYER_DOES_NOT_HAVE_ITEM:
					if (Module::playerHasItem($strPrefix, $intPlayerID, $requirement['requirement_detail'])) return FALSE;
					break;
			}
		}
		return TRUE;
	}	
	
	
	/** 
	 * applyPlayerStateChanges
	 *
     * Applies any state changes for the given object
     * @return boolean. True if a change was made, false otherwise
     */	
	protected function applyPlayerStateChanges($strPrefix, $intPlayerID, $strEventType, $strEventDetail) {	
		
		$changeMade = FALSE;
		
		//Fetch the state changes
		$query = "SELECT * FROM {$strPrefix}_player_state_changes 
									  WHERE event_type = '{$strEventType}'
									  AND event_detail = '{$strEventDetail}'";
		NetDebug::trace($query);

		$rsStateChanges = @mysql_query($query);
		
		while ($stateChange = mysql_fetch_array($rsStateChanges)) {
			NetDebug::trace("State Change Found");

			//Check the requirement
			switch ($stateChange['action']) {
				case Module::kPSC_GIVE_ITEM:
					//echo 'Running a GIVE_ITEM';
					Module::giveItemToPlayer($strPrefix, $stateChange['action_detail'], $intPlayerID);
					$changeMade = TRUE;
					break;
				case Module::kPSC_TAKE_ITEM:
					//echo 'Running a TAKE_ITEM';
					Module::takeItemFromPlayer($strPrefix, $stateChange['action_detail'], $intPlayerID);
					$changeMade = TRUE;
					break;
			}
		}//stateChanges loop
		
		return $changeMade;
	}
		
	/**
     * Add a row to the player log
     * @returns true on success
     */
	protected function appendLog($intPlayerID, $intGameID, $strEventType, $strEventDetail1=null, $strEventDetail2=null)
	{
	
		if (!$intGameID) $intGameID = "NULL";
		
		$query = "INSERT INTO player_log 
					(player_id, game_id, event_type, event_detail_1,event_detail_2) 
				  VALUES 
				  	({$intPlayerID},{$intGameID},'{$strEventType}','{$strEventDetail1}','{$strEventDetail2}')";
		
		@mysql_query($query);
		
		NetDebug::trace($query);

		
		if (mysql_error()) {
			NetDebug::trace(mysql_error());
			return false;
		}
		
		else return true;
	}		
	
	
	
	
	
}