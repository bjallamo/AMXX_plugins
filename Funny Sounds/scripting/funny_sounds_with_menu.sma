#include <amxmodx>
#include <colorchat>

new const PLUGIN[] = "Funny Sounds";
new const VERSION[] = "1.0";
new const AUTHOR[] = "mforce";


new const PREFIX[] = "Funny Sounds";

#define ACCESS_FLAG				ADMIN_KICK			// - Type // before # if you want it for all players.
#define TIME_BETWEEN_SOUNDS		30					// - in seconds

new Array:musicname, Array:musicpath;
new g_aSize;
new g_iTimeExpired[33], bool:g_iSwitchOff[33];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_dictionary("funny_sounds.txt");
	
	register_clcmd("say", "sayhandler");
	register_clcmd("say_team", "sayhandler");
	register_clcmd("say /sounds", "sound_switchoff");
	register_clcmd("say /soundlist", "musicmenu");
	set_task(300.0, "toswitchoff", 0, .flags="b")
}

public toswitchoff() {
	ColorChat(0, NORMAL, "^4[%s]^1 %L ^3/sounds", PREFIX, LANG_SERVER, "TO_SWTICH_OFF");
}

public plugin_precache() {
	musicname = ArrayCreate(32);
	musicpath = ArrayCreate(64);
	
	new sBuffer[256], sFile[64], sSoundName[32], sSoundPath[64], pFile;
 
	get_localinfo("amxx_configsdir", sFile, charsmax(sFile));
	format(sFile, charsmax(sFile), "%s/funny_sounds.ini", sFile);
 
	pFile = fopen(sFile, "rt");
 
	if(pFile) {		
		while(!feof(pFile)) {
			fgets(pFile, sBuffer, charsmax(sBuffer));
			trim(sBuffer);
			if(sBuffer[0] == ';' || sBuffer[0] == ' ') continue;
 
			parse(sBuffer, sSoundName, charsmax(sSoundName), sSoundPath, charsmax(sSoundPath));

			if(containi(sSoundPath, ".mp3") != -1 || containi(sSoundPath, ".wav") != -1) {
				precache_sound(sSoundPath);
				ArrayPushString(musicname, sSoundName);
				ArrayPushString(musicpath, sSoundPath);
			}
		}
		fclose(pFile);
		g_aSize = ArraySize(musicname);
	}
	else write_file(sFile, ";^"anything^" ^"any_dir/anything.mp3^"^n");
}

public sayhandler(id) {
	#if defined ACCESS_FLAG
	if(~get_user_flags(id) & ACCESS_FLAG) return;
	#endif

	new message[190]; read_args(message, charsmax(message));
	remove_quotes(message);
	new sSoundName[32];
	
	for(new i; i<g_aSize; i++) {
		ArrayGetString(musicname, i, sSoundName, charsmax(sSoundName));
		if(equali(message, sSoundName)) {
			expirecheck(id, i);
		}
	}
}

expirecheck(id, item) {
	new usrtime = get_user_time(id);
		
	if(usrtime >= g_iTimeExpired[id]) {
		playsound(item);
		g_iTimeExpired[id] = (usrtime + TIME_BETWEEN_SOUNDS);
	}
	else
		ColorChat(id, NORMAL, "^4[%s]^1 %L", PREFIX, LANG_SERVER, "YOU_HAVE_TO_WAIT" , (g_iTimeExpired[id] - usrtime));
}

playsound(item) {
	new szSound[64]; ArrayGetString(musicpath, item, szSound, charsmax(szSound));
	new makesound[128];
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
	ArrayDestroy(musicname);
	ArrayDestroy(musicpath);
}

stock bool:is_user_sounds_off(id) {
	new switcher[8];
	get_user_info(id, "_funnysoundsoff", switcher, charsmax(switcher));
	if(equal(switcher, "1")) return true;
	return false;
}

public musicmenu(id) {
	#if defined ACCESS_FLAG
	if(~get_user_flags(id) & ACCESS_FLAG) return;
	#endif
	
	new s_MenuName[128]; formatex(s_MenuName, charsmax(s_MenuName), "%s^nby \r%s \y", PLUGIN, AUTHOR);
	new menu = menu_create(s_MenuName, "musicmenu_h");
	new sSoundName[32];
	for(new i; i<g_aSize;i++) {
		ArrayGetString(musicname, i, sSoundName, charsmax(sSoundName));
		menu_additem(menu, sSoundName, "", 0)
	}
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_setprop(menu, MPROP_BACKNAME, "Vissza");
	menu_setprop(menu, MPROP_NEXTNAME, "Következő");
	menu_setprop(menu, MPROP_EXITNAME, "Kilépés");
	menu_display(id, menu, 0);
}

public musicmenu_h(id, menu, item) {
	if(item == MENU_EXIT) {
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	expirecheck(id, item);
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}