<?php
	// MySQL host name, user name, password, database, and table
	$opts['hn'] = 'localhost';
	$opts['un'] = 'arisuser';
	$opts['pw'] = 'arispwd';
	$opts['db'] = 'aris';
	
	$google_key = 'ABQIAAAAKdhUzwbl5RsEXD6h2Ua_HRRloMOfjiI7F4SM41AgXh_4cb6l9xTntP3tXw4zMbRaLS6TOMA3-jBOlw';
	//ABQIAAAAaBINj42Tz4K8ZaoZWWSnWRT2yXp_ZAY8_ufC3CFXhHIE1NvwkxQkcVoUCrdum-UscUMoKinDrDjThQ is for localhost
	//ABQIAAAAKdhUzwbl5RsEXD6h2Ua_HRQsvlSBtAWfm4N2P3iTGfWOp-UrmRRwG9t9N2_fCbAVKXjr59p56Fx_zA is for atsosxdev
	//ABQIAAAAKdhUzwbl5RsEXD6h2Ua_HRRloMOfjiI7F4SM41AgXh_4cb6l9xTntP3tXw4zMbRaLS6TOMA3-jBOlw is for arisgames.org
	
	$engine_www_path = 'http://arisgames.org/games';
	// http://localhost/~davidgagnon/aris/src for Dave's laptop
	// http://atsosxdev.doit.wisc.edu/aris/games for dev
	// http://arisgames.org/games for arisgames.org
	
	$engine_path = '/Groups/web/arisgames/games';
	// /Users/davidgagnon/Sites/aris/src for Dave's Laptop
	// /Groups/web/aris/games for atsosxdev
	// /Groups/web/arisgames/games for arisgames.org
	
	$engine_sites_path = $engine_path . '/Framework/Site';
	$engine_sites_www_path = $engine_www_path . '/Framework/Site';
	
	$mysql_bin_path = '/usr/local/mysql/bin';
	$svn_bin_path = '/opt/local/bin';
	$default_site = 'Default';

	//Image Paths
	$image_path = $engine_sites_path . '/' . substr($_SESSION['current_game_prefix'],0,strlen($_SESSION['current_game_prefix'])-1) . '/Templates/Default/templates/';
	//echo "IMAGE PATH: $image_path";
	$image_www_path = $engine_sites_www_path  . '/' .  substr($_SESSION['current_game_prefix'],0,strlen($_SESSION['current_game_prefix'])-1) . '/Templates/Default/templates/';
	//echo "IMAGE WWW PATH: $image_www_path";
	
	
?>