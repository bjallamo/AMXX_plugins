/*
		CheatKey Detector
		v1.2 by mforce
	
	Changes:
	
	v1.1 - Removed hardcoded things, added stock for sendcmd, not connected bug fixed.
	v1.2 - Cvars moved to the file, for settings.
*/

#include <amxmodx>

new const PLUGIN[] = "CheatKey Detector";
new const VERSION[] = "1.2";
new const AUTHOR[] = "mforce";


#if AMXX_VERSION_NUM < 183
const MAX_PLAYERS = 32;
#endif
const SVC_DIRECTOR_STUFFTEXT = 10;

enum _:PCVARS{iKickLimit, iIsQuit};
new g_iCvars[PCVARS], g_iCheatKeysSize, g_iKickLimit[MAX_PLAYERS+1];
new Array:g_aCheatKeys;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_cvar("cheatkey_detector", VERSION, FCVAR_SERVER | FCVAR_SPONLY);
	register_clcmd("CKD", "CheatKey_Detected");
	g_aCheatKeys = ArrayCreate(32);
}

public plugin_cfg() {
	new szLine[64], szFileName[128], iFilePointer; 
	get_localinfo("amxx_configsdir", szFileName, charsmax(szFileName));
	add(szFileName, charsmax(szFileName), "/CheatKeys.ini");
	
	iFilePointer = fopen(szFileName, "rt");
	if(!iFilePointer) set_fail_state("Can't read config file for CheatKeys.");
	
	new iSection;
	new szKey[32], szSign[3], szValue[3];
	while(!feof(iFilePointer)) {
		fgets(iFilePointer, szLine, charsmax(szLine)); trim(szLine);
		if(!szLine[0] || szLine[0] == ';' || szLine[0] == '#') continue;
		
		if(szLine[0] == '[') {
			if(equali(szLine, "[settings]")) iSection = 1;
			else if(equali(szLine, "[keys]")) iSection = 2;
			else iSection = 0;
			
			continue;
		}
		
		if(iSection == 1 && parse(szLine, szKey, charsmax(szKey), szSign, charsmax(szSign), szValue, charsmax(szValue))) {
			if(equali(szKey, "ckd_kicklimit"))
				g_iCvars[iKickLimit] = str_to_num(szValue);
			else if(equali(szKey, "ckd_quit"))
				g_iCvars[iIsQuit] = str_to_num(szValue);
		}
		else if(iSection == 2 && parse(szLine, szKey, charsmax(szKey)))
			ArrayPushString(g_aCheatKeys, szKey);
	}
	fclose(iFilePointer);
	
	g_iCheatKeysSize = ArraySize(g_aCheatKeys);
	if(!g_iCheatKeysSize) set_fail_state("Error! The array doesn't contain any CheatKeys.");
}


public client_authorized(id) {
	if(is_user_bot(id) || is_user_hltv(id)) return;
	
	new szCheatKey[32];
	for(new i; i < g_iCheatKeysSize; i++) {
		ArrayGetString(g_aCheatKeys, i, szCheatKey, charsmax(szCheatKey));
		SendCmd(id, "bind ^"%s^" ^"CKD %s^"", szCheatKey, szCheatKey);
	}
}

public CheatKey_Detected(id) {
	if(!is_user_connected(id)) return PLUGIN_HANDLED;
	
	new szKey[32]; read_args(szKey, charsmax(szKey));
	new szName[32]; get_user_name(id, szName, charsmax(szName));
	new szIP[32]; get_user_ip(id, szIP, charsmax(szIP), 1);
	new szSteamId[32]; get_user_authid(id, szSteamId, charsmax(szSteamId));
	
	log_to_file("CheatKeyLog.log", "^n[DETECTED]: ^"%s^" used key '%s' (IP: '%s', STEAMID: '%s').", szName, szKey, szIP, szSteamId);
	
	if(g_iCvars[iKickLimit] > 0) {
		if(++g_iKickLimit[id] >= g_iCvars[iKickLimit]) {
			if(g_iCvars[iIsQuit] == 1)
				SendCmd(id, "quit");
			else
				server_cmd("kick #%d ^"Too much CheatKeys pressed.^"", get_user_userid(id));
		}
	}
	
	return PLUGIN_HANDLED;
}

public client_disconnect(id) {
	g_iKickLimit[id] = 0;
}

public plugin_end() {
	ArrayDestroy(g_aCheatKeys);
}

stock SendCmd(id, const szText[], any:...) {
	static szCmd[128]; vformat(szCmd, charsmax(szCmd), szText, 3);
	message_begin(MSG_ONE, SVC_DIRECTOR, _, id);
	write_byte(strlen(szCmd) + 2);
	write_byte(SVC_DIRECTOR_STUFFTEXT);
	write_string(szCmd);
	message_end();
}