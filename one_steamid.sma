#include <amxmodx>

new const PLUGIN[] = "Low Category SteamID Changer Block"
new const VERSION[] = "1.0"
new const AUTHOR[] = "mforce"

new Trie:g_IP, Trie:g_SteamID;


public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	g_IP = TrieCreate();
	g_SteamID = TrieCreate();
}

public client_authorized(id) { 
	if(is_user_bot(id)) return;
	
	new ip[32];	get_user_ip(id, ip, charsmax(ip), 1)
	new steamid[32]; get_user_authid(id, steamid, charsmax(steamid));
	
	if(!TrieKeyExists(g_IP, ip)) {
		TrieSetCell(g_IP, ip, 1);
		TrieSetCell(g_SteamID, steamid, 1);
	}
	else if(!TrieKeyExists(g_SteamID, steamid)) {
		server_cmd("kick #%d ^"SteamID valtas.^"", get_user_userid(id));
	}
}

public plugin_end() {
	TrieDestroy(g_IP);
	TrieDestroy(g_SteamID);
}