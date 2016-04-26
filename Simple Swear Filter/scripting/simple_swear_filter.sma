#include <amxmodx>

/*	Remove the // before #define to hide the messages with swear words.
	Default: swears replaced to stars.
	Example: fuck - **** 												*/

//#define JUST_HIDE

new const PLUGIN[] = "Simple Swear Filter";
new const VERSION[] = "1.0";
new const AUTHOR[] = "mforce";


new Array:swearlist;
new g_ArraySize;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("say", "sayhandler");
	register_clcmd("say_team", "sayhandler");
	swearlist = ArrayCreate(32);
}

public plugin_cfg() {
	new sBuffer[256], sFile[64], sData[1][32], pFile;
	get_localinfo("amxx_configsdir", sFile, charsmax(sFile));
	format(sFile, charsmax(sFile), "%s/simple_swear_filter.ini", sFile);
 
	pFile = fopen(sFile, "rt");
	if(pFile) {		
		while(!feof(pFile)) {
			fgets(pFile, sBuffer, charsmax(sBuffer));
			trim(sBuffer);
			if(sBuffer[0] == ';' || sBuffer[0] == EOS) continue;
 
			parse(sBuffer, sData[0], charsmax(sData[]));
			ArrayPushString(swearlist, sData[0]);
		}
		fclose(pFile);
		g_ArraySize = ArraySize(swearlist);
	}
	else write_file(sFile, ";^"kurva^"");
}

public sayhandler(id) {
	new szMessage[190]; read_args(szMessage, charsmax(szMessage));
	remove_quotes(szMessage);
	
	new szCheck[32], bool:bFound;

	for(new i; i<g_ArraySize; i++) {
		ArrayGetString(swearlist, i, szCheck, charsmax(szCheck));
		if(containi(szMessage, szCheck) != -1) {
			bFound = true;
			
			#if !defined JUST_HIDE
			new szSaid[32], iChars = strlen(szCheck);
			
			for(new a; a<iChars; a++)
				szSaid[a] = '*';
			
			replace_all(szMessage, charsmax(szMessage), szCheck, szSaid);
			#endif
		}
	}
	
	if(bFound) {
		#if !defined JUST_HIDE
		new cmd[32]; read_argv(0, cmd, charsmax(cmd));
		engclient_cmd(id, cmd, szMessage);
		#endif

		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public plugin_end() {
	ArrayDestroy(swearlist);
}