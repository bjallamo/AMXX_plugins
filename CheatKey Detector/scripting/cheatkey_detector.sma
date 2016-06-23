#include <amxmodx>

new const PLUGIN[] = "CheatKey Detector";
new const VERSION[] = "1.0";
new const AUTHOR[] = "mforce";


#if AMXX_VERSION_NUM < 183
const MAX_PLAYERS = 32;
#endif

enum _:PCVARS{iKickLimit, iIsQuit};
new g_pCvars[PCVARS], g_iCheatKeysSize, g_iKickLimit[MAX_PLAYERS+1];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_cvar("cheatkey_detector", VERSION, FCVAR_SERVER | FCVAR_SPONLY);
	g_pCvars[iKickLimit] = register_cvar("ckd_kicklimit", "3");
	g_pCvars[iIsQuit] = register_cvar("ckd_quit", "0");
	
	register_clcmd("CKD", "CheatKey_Detected");
	g_aCheatKeys = ArrayCreate(32);
}

public plugin_cfg() {
	new szLine[32], szData[32], szFileName[128], iFilePointer; 
	get_localinfo("amxx_configsdir", szFileName, charsmax(szFileName));
	add(szFileName, charsmax(szFileName), "/CheatKeys.ini");
	
	iFilePointer = fopen(szFileName, "rt");
	if(!iFilePointer) set_fail_state("Can't read config file for CheatKeys.");
	
	while(!feof(iFilePointer)) {
		fgets(iFilePointer, szLine, charsmax(szLine)); trim(szLine);
		
		if(!szLine[0] || szLine[0] == ';' || szLine[0] == '#') continue;
		
		if(parse(szLine, szData, charsmax(szData)))
			ArrayPushString(g_aCheatKeys, szLine);
	}
	fclose(iFilePointer);
	
	g_iCheatKeysSize = ArraySize(g_aCheatKeys);
	if(!g_iCheatKeysSize) set_fail_state("Error! The array doesn't contain any CheatKeys.");
}


public client_authorized(id) {
	if(!is_user_connected(id) || is_user_bot(id) || is_user_hltv(id)) return;
	
	new szCheatKey[32], szTemp[64];
	for(new i; i < g_iCheatKeysSize; i++) {
		ArrayGetString(g_aCheatKeys, i, szCheatKey, charsmax(szCheatKey));
		formatex(szTemp, charsmax(szTemp), "bind ^"%s^" ^"CKD %s^"", szCheatKey, szCheatKey);
		message_begin(MSG_ONE, SVC_DIRECTOR, _, id);
		write_byte(strlen(szTemp) + 2);
		write_byte(10);
		write_string(szTemp);
		message_end();
	}
}

public CheatKey_Detected(id) {
	if(!is_user_connected(id)) return PLUGIN_HANDLED;
	
	new szKey[32]; read_args(szKey, charsmax(szKey));
	new szName[32]; get_user_name(id, szName, charsmax(szName));
	new szIP[32]; get_user_ip(id, szIP, charsmax(szIP), 1);
	new szSteamId[32]; get_user_authid(id, szSteamId, charsmax(szSteamId));
	
	log_to_file("CheatKeyLog.log", "^n[DETECTED]: ^"%s^" used key '%s' (IP: '%s', STEAMID: '%s').", szName, szKey, szIP, szSteamId);
	
	new iCacheKickLimit = get_pcvar_num(g_pCvars[iKickLimit]);
	if(iCacheKickLimit > 0) {
		if(++g_iKickLimit[id] >= iCacheKickLimit) {
			if(get_pcvar_num(g_pCvars[iIsQuit]) == 1)
				client_cmd(id, "quit");
			else
				server_cmd("kick #%d ^"Too much CheatKeys pressed.^"");
		}
	}
	
	return PLUGIN_HANDLED;
}

public plugin_end() {
	ArrayDestroy(g_aCheatKeys);
}