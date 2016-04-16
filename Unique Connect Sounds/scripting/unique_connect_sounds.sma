#include <amxmodx>

new const PLUGIN[] = "Unique Connect Sounds"
new const VERSION[] = "1.0"
new const AUTHOR[] = "mforce"

new Trie:g_SteamID;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
}

public plugin_precache() {
	g_SteamID = TrieCreate();

    new sBuffer[256], sFile[64], sData[2][32], pFile;
 
    get_localinfo("amxx_configsdir", sFile, charsmax(sFile));
    format(sFile, charsmax(sFile), "%s/unique_connect_sounds.ini", sFile);
 
    pFile = fopen(sFile, "rt");
 
    if(pFile) {    
        while(!feof(pFile)) {
            fgets(pFile, sBuffer, charsmax(sBuffer));
            trim(sBuffer);
            if(sBuffer[0] == ';') continue;
 
            parse(sBuffer, sData[0], charsmax(sData[]), sData[1], charsmax(sData[]));
 
            if(containi(sData[1], ".mp3") != -1 || containi(sData[1], ".wav") != -1) {
                precache_sound(sData[1])
                TrieSetString(g_SteamID, sData[0], sData[1])
            }
        }
        fclose(pFile);
    }
    else fprintf(pFile, ";^"STEAM_0:0:12345678^" ^"connectsounds/anybody.mp3^"^n");
}


public client_putinserver(id) {
	set_task(5.0, "makesound", id);
}

public makesound(id) {
	if(is_user_bot(id)) return;

	new steamid[32], connect_sound[64];
	get_user_authid(id, steamid, charsmax(steamid));
	
	if(TrieKeyExists(g_SteamID, steamid)) {
		TrieGetString(g_SteamID, steamid, connect_sound, charsmax(connect_sound));
		playsound(connect_sound);
	}
}

public client_disconnect(id) {
	remove_task(id);
}

public plugin_end() {
	TrieDestroy(g_SteamID);
}

stock playsound(const connect_sound[]) {	
	if(containi(connect_sound, ".mp3") != -1)
		client_cmd(0, "mp3 play ^"sound/%s^"", connect_sound);
	else
		client_cmd(0, "spk ^"%s^"", connect_sound);
}