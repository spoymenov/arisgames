<?php
require_once("module.php");

class Movables extends Module
{
    public static function createMovableTable(){
    
    //Create 'movables' table
                $query = "CREATE TABLE movables (
                        movable_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                     game_id INT NOT NULL,
                                     type ENUM('Node', 'Item', 'Npc', 'WebPage', 'AugBubble', 'PlayerNote') NOT NULL,
                                     type_id INT NOT NULL,
                                     location_name TINYTEXT NOT NULL DEFAULT '',
                                     algorithm_type ENUM('TOWARD_PLAYER', 'STRAIGHT_LINE', 'CIRCLE', 'CUSTOM') NOT NULL DEFAULT 'TOWARD_PLAYER',
                                     algorithm_detail INT NOT NULL DEFAULT 0,
                                     velocity INT NOT NULL DEFAULT 0,
                                     latitude DOUBLE NOT NULL default 0,
                                     longitude DOUBLE NOT NULL default 0,
                                     delete_when_viewed TINYINT(1) NOT NULL DEFAULT 0,
                                     move_stamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                     error_range INT NOT NULL DEFAULT 10,
                                     force_view TINYINT(1) NOT NULL DEFAULT 0,
                                     hidden TINYINT(1) NOT NULL DEFAULT 0,
                                     allow_quick_travel TINYINT(1) NOT NULL DEFAULT 0,
                                     wiggle TINYINT(1) NOT NULL DEFAULT 1,
                                     active TINYINT(1) NOT NULL DEFAULT 1,
                                     show_title TINYINT(1) NOT NULL DEFAULT 0,
                                     time_to_live INT NOT NULL DEFAULT 100);";
                mysql_query($query);
    }
 
    public static function createMovable($gameId, $type, $typeId, $locationName, $algorithm_type, $algorithm_detail, $velocity, $moveStamp, $lat, $lon, $deleteWhenViewed, $timeToLive, $errorRange, $forceView, $hidden, $allowQuickTravel, $wiggle, $showTitle = 0)
    {
        if($spawnableId = Spawnables::hasSpawnable($gameId, $type, $typeId))
            $query = "UPDATE spawnables SET active = 1 WHERE game_id = $gameId AND type = '$type' AND type_id = $typeId";
        else
            $query = "INSERT INTO spawnables (game_id, type, type_id, location_name, amount, min_area, max_area, amount_restriction, location_bound_type, latitude, longitude, spawn_probability, spawn_rate, delete_when_viewed, time_to_live, error_range, force_view, hidden, allow_quick_travel, wiggle, show_title, active) VALUES ($gameId, '{$type}', $typeId, '$locationName', $amount, $minArea, $maxArea, '{$amountRestriction}', '{$locationBoundType}', $lat, $lon, $spawnProbability, $spawnRate, $deleteWhenViewed, $timeToLive, $errorRange, $forceView, $hidden, $allowQuickTravel, $wiggle, $showTitle, 1);";

        mysql_query($query);
        $spawnableId = mysql_insert_id();
        return new returnData(0,$spawnableId);
    }

    public static function hasActiveSpawnable($gameId, $type, $typeId)
    {
        $query = "SELECT * FROM spawnables WHERE game_id = $gameId AND type = '$type' AND type_id = $typeId AND active = 1"; 
        $result = mysql_query($query);
        if($obj = mysql_fetch_object($result)) return $obj->spawnable_id;
        else return false;
    }

    public static function hasSpawnable($gameId, $type, $typeId)
    {
        $query = "SELECT * FROM spawnables WHERE game_id = $gameId AND type = '$type' AND type_id = $typeId"; 
        $result = mysql_query($query);
        if($obj = mysql_fetch_object($result)) return $obj->spawnable_id;
        else return false;
    }

    public static function deleteSpawnable($spawnableId)
    {
        $query = "UPDATE spawnables SET active = 0 WHERE spawnable_id = $spawnableId";
        mysql_query($query);
        /*
        //This does a hard delete
        $query = "SELECT * FROM spawnables WHERE spawnable_id = $spawnableId";
        $result = mysql_query($query);
        $obj = mysql_fetch_object($result);
        if($obj)
        {
        $query = "DELETE FROM spawnables WHERE spawnable_id = $spawnableId";
        mysql_query($query);
        $query = "DELETE FROM ".$obj->game_id."_requirements WHERE content_type = 'Spawnable' AND content_id = $spawnableId";
        mysql_query($query);
        }
         */
        return new returnData(0);
    }

    public static function deleteSpawnablesOfObject($gameId, $type, $typeId)
    {

        if($spawnableId = Spawnables::hasSpawnable($gameId, $type, $typeId))
            Spawnables::deleteSpawnable($spawnableId);
        return new returnData(0);
    }

    //Optionally by spawnableId or by gameId, type, and typeId
    public static function updateSpawnable($spawnableId = 0, $gameId, $type, $typeId, $locationName, $amount, $minArea, $maxArea, $amountRestriction, $locationBoundType, $lat, $lon, $spawnProbability, $spawnRate, $deleteWhenViewed, $timeToLive, $errorRange, $forceView, $hidden, $allowQuickTravel, $wiggle, $active, $showTitle)
    {
        if($spawnableId == 0)
            $query = "UPDATE spawnables SET location_name = '$locationName', amount = $amount, min_area = $minArea, max_area = $maxArea, amount_restriction = '{$amountRestriction}', location_bound_type = '{$locationBoundType}', latitude = $lat, longitude = $lon, spawn_probability = $spawnProbability, spawn_rate = $spawnRate, delete_when_viewed = $deleteWhenViewed, time_to_live = $timeToLive, error_range = $errorRange, force_view = $forceView, hidden = $hidden, allow_quick_travel = $allowQuickTravel, wiggle = $wiggle, show_title = $showTitle, active = $active WHERE game_id = $gameId AND type = '{$type}' AND type_id = $typeId";
        else
            $query = "UPDATE spawnables SET game_id = $gameId, type = '$type', type_id = $typeId, location_name = '$locationName', amount = $amount, min_area = $minArea, max_area = $maxArea, amount_restriction = '{$amountRestriction}', location_bound_type = '{$locationBoundType}', latitude = $lat, longitude = $lon, spawn_probability = $spawnProbability, spawn_rate = $spawnRate, delete_when_viewed = $deleteWhenViewed, time_to_live = $timeToLive, error_range = $errorRange, force_view = $forceView, hidden = $hidden, allow_quick_travel = $allowQuickTravel, wiggle = $wiggle, show_title = $showTitle, active = $active WHERE spawnable_id = $spawnableId";
        mysql_query($query);
        return new returnData(0);
    }

    public static function createSpawnableForObject($gameId, $type, $typeId)
    {
        switch ($type) {
            case 'Item':
                $query = "SELECT name as title FROM {$gameId}_items WHERE item_id = {$typeId} LIMIT 1";
                break;
            case 'Node':
                $query = "SELECT title FROM {$gameId}_nodes WHERE node_id = {$typeId} LIMIT 1";
                break;
            case 'Npc':
                $query = "SELECT name as title FROM {$gameId}_npcs WHERE npc_id = {$typeId} LIMIT 1";
                break;
            case 'WebPage':
                $query = "SELECT name as title FROM web_pages WHERE web_page_id = {$typeId} LIMIT 1";
                break;
            case 'AugBubble':
                $query = "SELECT name as title FROM aug_bubbles WHERE aug_bubble_id = {$typeId} LIMIT 1";
                break;
        }
        $result = mysql_query($query);
        $obj = mysql_fetch_object($result);
        $title = $obj->title;
        Spawnables::createSpawnable($gameId, $type, $typeId, $title, 5, 35, 50, 'PER_PLAYER', 'PLAYER', 0, 0, 50, 10, 0, 100, 15, 0, 0, 0, 1, 0);
        return Spawnables::getSpawnableForObject($gameId, $type, $typeId);
    }

    public static function getSpawnableForObject($gameId, $type, $typeId)
    {
        $query = "SELECT * FROM spawnables WHERE game_id = $gameId AND type = '".$type."' AND type_id = '".$typeId."' AND active = 1 LIMIT 1";
        $result = mysql_query($query);
        $obj = mysql_fetch_object($result);
        if($obj) return new returnData(0, $obj);
        else return new returnData(1, "No Spawnables For Object");
    }

    public static function getSpawnablesForGame($gameId)
    {
        $query = "SELECT * FROM spawnables WHERE game_id = $gameId AND active = 1";
        $result = mysql_query($query);
        $spawnables = array();
        while($obj = mysql_fetch_object($result))
        {
            $spawnables[] = $obj;
        }
        return new returnData(0, $spawnables);
    }
}