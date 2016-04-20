#include <amxmodx>
#include <colorchat>

new const PLUGIN[] = "Funny Sounds";
new const VERSION[] = "1.0";
new const AUTHOR[] = "mforce";


new const PREFIX[] = "Funny Sounds";

#define ACCESS_FLAG				ADMIN_KICK			// - Type // before # if you want it for all players.
#define TIME_BETWEEN_SOUNDS		30					// - in seconds


new Trie:musiclist
new g_iTimeExpired[33], bool:g_iSwitchOff[33];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_dictionary("funny_sounds.txt");
	
	register_clcmd("say", "sayhandler");
	register_clcmd("say_team", "sayhandler");
	register_clcmd("say /sounds", "sound_switchoff");
	set_task(300.0, "toswitchoff", 0, .flags="b")
}

public toswitchoff() {
	ColorChat(0, NORMAL, "^4[%s]^1 %L ^3/sounds", PREFIX, LANG_SERVER, "TO_SWTICH_OFF");
}

public plugin_precache() {
	musiclist = TrieCreate()
	
	new sBuffer[256], sFile[64], sData[2][32], pFile;
 
	get_localinfo("amxx_configsdir", sFile, charsmax(sFile));
	format(sFile, charsmax(sFile), "%s/funny_sounds.ini", sFile);
 
	pFile = fopen(sFile, "rt");
 
	if(pFile) {		
		while(!feof(pFile)) {
			fgets(pFile, sBuffer, charsmax(sBuffer));
			trim(sBuffer);
			if(sBuffer[0] == ';') continue;
 
			parse(sBuffer, sData[0], charsmax(sData[]), sData[1], charsmax(sData[]));

			if((containi(sData[1], ".mp3") != -1 || containi(sData[1], ".wav") != -1) && !TrieKeyExists(musiclist, sData[0])) {
				precache_sound(sData[1])
				TrieSetString(musiclist, sData[0], sData[1]);
			}
		}
		fclose(pFile);
	}
	else write_file(sFile, ";^"anything^" ^"any_dir/anything.mp3^"^n");
}

public sayhandler(id) {
	#if defined ACCESS_FLAG
	if(~get_user_flags(id) & ACCESS_FLAG) return;
	#endif

	new message[190]; read_args(message, charsmax(message));
	remove_quotes(message);
	
	if(TrieKeyExists(musiclist, message)) {
		new usrtime = get_user_time(id);
		
		if(usrtime > g_iTimeExpired[id]) {
			new szSound[64];
			TrieGetString(musiclist, message, szSound, charsmax(szSound));
			playsound(szSound);
			g_iTimeExpired[id] = (usrtime + TIME_BETWEEN_SOUNDS);
		}
		else
			ColorChat(id, NORMAL, "^4[%s]^1 %L", PREFIX, LANG_SERVER, "YOU_HAVE_TO_WAIT" , (g_iTimeExpired[id] - usrtime));
	}
}

playsound(const szSound[]) {
	new makesound[256];
	if(containi(szSound, ".mp3") != -1)
		formatex(makesound, charsmax(makesound), "mp3 play ^"sound/%s^"", szSound);
	else
		formatex(makesound, charsmax(makesound), "spk ^"%s^"", szSound);


	new players[32], num, tempid;
	get_players(players, num, "c");
	for(new i; i<num; i++) {
		tempid = players[i];
		if(!g_iSwitchOff[tempid])
			client_cmd(tempid, "%s", makesound);
	}
}

public sound_switchoff(id) {
	switch(g_iSwitchOff[id]) {
		case false: {
			g_iSwitchOff[id] = true;
			client_cmd(id, "setinfo _funnysoundsoff 1");
			ColorChat(id, NORMAL, "^4[%s]^3 %L", PREFIX, LANG_SERVER, "SOUNDS_SWITCHED_OFF");
		}
		case true: {
			g_iSwitchOff[id] = false;
			client_cmd(id, "setinfo _funnysoundsoff 0");
			ColorChat(id, NORMAL, "^4[%s]^3 %L", PREFIX, LANG_SERVER, "SOUNDS_SWITCHED_ON");
		}
	}
}

public client_putinserver(id) {
	if(is_user_sounds_off(id))
		g_iSwitchOff[id] = true;
}

public client_disconnect(id) {
	g_iTimeExpired[id] = 0;
	g_iSwitchOff[id] = false;
}

public plugin_end() {
    TrieDestroy(musiclist);
}

stock bool:is_user_sounds_off(id) {
	new switcher[8];
	get_user_info(id, "_funnysoundsoff", switcher, charsmax(switcher));
	if(equal(switcher, "1")) return true;
	return false;
}