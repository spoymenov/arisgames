<?php
require("module.php");

class Nodes extends Module
{	

	/**
     * Fetch all nodes
     * @returns the nodes rs
     */
	public function getNodes($intGameID)
	{
		$prefix = $this->getPrefix($intGameID);
		if (!$prefix) return new returnData(1, NULL, "invalid game id");

		
		$query = "SELECT * FROM {$prefix}_nodes";
		$rsResult = @mysql_query($query);
		
		if (mysql_error()) return new returnData(3, NULL, "SQL Error");
		return new returnData(0, $rsResult);	
		
	}
	
	/**
     * Fetch a specific nodes
     * @returns a single node
     */
	public function getNode($intGameID, $intNodeID)
	{
		$prefix = $this->getPrefix($intGameID);
		if (!$prefix) return new returnData(1, NULL, "invalid game id");

		
		$query = "SELECT * FROM {$prefix}_nodes WHERE node_id = {$intNodeID} LIMIT 1";
		
		$rsResult = @mysql_query($query);
		if (mysql_error()) return new returnData(3, NULL, "SQL Error");
		
		$node = mysql_fetch_object($rsResult);
		
		if (!$node) return new returnData(2, NULL, "invalid node id");
		
		$node->media = Config::engineWWWPath . "/{$prefix}/" . Config::gameMediaSubdir . '/' . $node->media;

		
		return new returnData(0, $node);
		
	}


	/**
     * Create a node
     * @returns the new nodeID on success
     */
	public function createNode($intGameID, $strTitle, $strText, $strMedia,
								$strOpt1Text, $intOpt1NodeID, 
								$strOpt2Text, $intOpt2NodeID,
								$strOpt3Text, $intOpt3NodeID,
								$strQACorrectAnswer, $intQAIncorrectNodeID, $intQACorrectNodeID)
	{
		$prefix = $this->getPrefix($intGameID);
		$query = "INSERT INTO {$prefix}_nodes 
					(title, text, media, 
						opt1_text, opt1_node_id, 
						opt2_text, opt2_node_id, 
						opt3_text, opt3_node_id,
						require_answer_string, 
						require_answer_incorrect_node_id, 
						require_answer_correct_node_id)
					VALUES ('{$strTitle}', '{$strText}', '{$strMedia}',
						'{$strOpt1Text}', '{$intOpt1NodeID}',
						'{$strOpt2Text}','{$intOpt2NodeID}',
						'{$strOpt3Text}','{$intOpt3NodeID}',
						'{$strQACorrectAnswer}', 
						'{$intQAIncorrectNodeID}', 
						'{$intQACorrectNodeID}')";
		
		NetDebug::trace("createNode: Running a query = $query");	
		
		@mysql_query($query);
		
		if (mysql_error()) return new returnData(3, NULL, "SQL Error");
	
		return new returnData(0, mysql_insert_id());
	}



	
	
	/**
     * Update a specific node
     * @returns true if a record was updated, falso if no changes were made
     */
	public function updateNode($intGameID, $intNodeID, $strTitle, $strText, $strMedia,
								$strOpt1Text, $intOpt1NodeID, 
								$strOpt2Text, $intOpt2NodeID,
								$strOpt3Text, $intOpt3NodeID,
								$strQACorrectAnswer, $intQAIncorrectNodeID, $intQACorrectNodeID)
	{
		$prefix = $this->getPrefix($intGameID);
		if (!$prefix) return new returnData(1, NULL, "invalid game id");

		
		$query = "UPDATE {$prefix}_nodes 
					SET title = '{$strTitle}', text = '{$strText}',
					media = '{$strMedia}',
					opt1_text = '{$strOpt1Text}', opt1_node_id = '{$intOpt1NodeID}',
					opt2_text = '{$strOpt2Text}', opt2_node_id = '{$intOpt2NodeID}',
					opt3_text = '{$strOpt3Text}', opt3_node_id = '{$intOpt3NodeID}',
					require_answer_string = '{$strQACorrectAnswer}', 
					require_answer_incorrect_node_id = '{$intQAIncorrectNodeID}', 
					require_answer_correct_node_id = '{$intQACorrectNodeID}'
					WHERE node_id = '{$intNodeID}'";
		
		NetDebug::trace("updateNode: Running a query = $query");	
		
		mysql_query($query);
		if (mysql_error()) return new returnData(3, NULL, "SQL Error");

		
		if (mysql_affected_rows()) return new returnData(0, TRUE);
		else return new returnData(0, FALSE);
	}
	
	
	/**
     * Delete a specific nodes
     * @returns returnCode 0 if successfull
     */
	public function deleteNode($intGameID, $intNodeID)
	{
		$prefix = $this->getPrefix($intGameID);
		if (!$prefix) return new returnData(1, NULL, "invalid game id");

		$query = "DELETE FROM {$prefix}_nodes WHERE node_id = {$intNodeID}";
		
		$rsResult = @mysql_query($query);
		if (mysql_error()) return new returnData(3, NULL, "SQL Error");
		
		if (mysql_affected_rows()) return new returnData(0);
		else return new returnData(2, NULL, 'invalid node id');
	}	
	
	
	/**
     * Get a list of objects that refer to the specified node
     * @returns a list of object types and ids
     */
	public function getReferrers($intGameID, $intNodeID)
	{
		$prefix = $this->getPrefix($intGameID);
		if (!$prefix) return new returnData(1, NULL, "invalid game id");

		//Find locations
		$query = "SELECT location_id FROM {$prefix}_locations WHERE 
					type  = 'Node' and type_id = {$intNodeID}";
		$rsLocations = @mysql_query($query);
		if (mysql_error()) return new returnData(3, NULL, "SQL Error in Locations query");
		
		//Find qrcodes
		$query = "SELECT qrcode_id FROM {$prefix}_qrcodes WHERE 
						type  = 'Node' and type_id = {$intNodeID}";
		$rsQRCodes = @mysql_query($query);
		if (mysql_error()) return new returnData(3, NULL, "SQL Error in QR query");
		
		//Find Nodes
		$query = "SELECT node_id FROM {$prefix}_nodes WHERE
					opt1_node_id  = {$intNodeID} or
					opt2_node_id  = {$intNodeID} or
					opt3_node_id  = {$intNodeID}";
		$rsNodes = @mysql_query($query);
		if (mysql_error()) return new returnData(3, NULL, "SQL Error in Nodes Query");
		
		
		//Find NPCs
		$query = "SELECT {$prefix}_npcs.npc_id FROM {$prefix}_npcs 
					JOIN {$prefix}_npc_conversations
					ON ({$prefix}_npcs.npc_id = {$prefix}_npc_conversations.npc_id)
					WHERE {$prefix}_npc_conversations.node_id = {$intNodeID}";
		NetDebug::trace($query);			
		$rsNpcs = @mysql_query($query);
		if (mysql_error()) return new returnData(3, NULL, "SQL Error in NPC Query");
		
		
		
		//Combine them together
		$referrers = array();
		while ($row = mysql_fetch_array($rsLocations)){
			$referrers[] = array('type'=>'Location', 'id' => $row['location_id']);
		}
		while ($row = mysql_fetch_array($rsQRCodes)){
			$referrers[] = array('type'=>'QRCode', 'id' => $row['qrcode_id']);
		}
		while ($row = mysql_fetch_array($rsNodes)){
			$referrers[] = array('type'=>'Node', 'id' => $row['node_id']);
		}
		while ($row = mysql_fetch_array($rsNpcs)){
			$referrers[] = array('type'=>'Npc', 'id' => $row['npc_id']);
		}
		
		return new returnData(0,$referrers);
	}	
	
	
	
}