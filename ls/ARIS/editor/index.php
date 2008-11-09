<?php	

	include_once('common.inc.php');

	//Clear Session variable for current game
	unset($_SESSION['current_game_prefix']);
	
	print_header('Your ARIS Games');
	
	echo '<!--Editor revision: ';
	include ('version');
	echo '-->';
	
	//Navigation
	echo "<div class = 'nav'>
		<a href = 'games_add.php'>Add a Game</a>
		<a href = 'games_restore.php'>Restore a Game</a>
		<a href = 'logout.php'>Logout</a>
	</div>";
	
	
	//Display a list of games this user can administrate
	$query = "SELECT * FROM editors WHERE editor_id = {$_SESSION['user_id']}";
	$result = mysql_query($query);
	$row = mysql_fetch_array($result);
	
	if (isset($row['super_admin']) and $row['super_admin']) $query = "SELECT * FROM games JOIN game_editors WHERE games.game_id = game_editors.game_id GROUP BY games.game_id";
	else $query = "SELECT * FROM games JOIN game_editors ON (games.game_id = game_editors.game_id) 
		WHERE game_editors.editor_id = {$_SESSION['user_id']}";
	
	$result = mysql_query($query);
	
	if (mysql_num_rows($result) == 0) echo 'No games are currently set up for your user. Please add or restore a game';
	else {
		echo '<table class = "games">
		<tr><th>Game Name</th><th>Prefix</th></tr>';

		while ($row=mysql_fetch_array($result)) 
			echo "<tr>
					<td><a href = 'games.php?game_id={$row['game_id']}'>{$row['name']}</a></td><td>{$row['prefix']}</td>
					<td><a href = 'games_delete.php?game_id={$row['game_id']}'>Delete</a></td>
					<td><a href = 'games_backup.php?prefix={$row['prefix']}'>Backup</a></td>
					<td><a href = 'games.php?game_id={$row['game_id']}'>Edit</a></td>
				</tr>";
		
		
		echo '</table>';
	}
	
	
?>