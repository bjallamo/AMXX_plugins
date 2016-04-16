/*
		Extended Weapon Menu
			v1.21 by mforce
	
	Changes:
	
	v1.1 - Multilang added, strip_user_weapons fixed, "hardcoded" things fixed,
	unnecessary cvar removed, using Safety1st method for money block, ColorChat included.
	
	v1.2 - AMXX 1.8.3 support fixed, minimal improvements (less cvar hook)
	v1.21 - Multilang fix.
*/


#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <hamsandwich> 

new const PLUGIN[] = "Extended Weapon Menu";
new const VERSION[] = "1.21";
new const AUTHOR[] = "mforce";


new const PREFIX[] = "^4[EWM]";

#if AMXX_VERSION_NUM < 183
#include <colorchat>
const MAX_PLAYERS = 32;
const m_fHasPrimary = 116;
#else
const m_fHasPrimary = 464;
#endif
const m_iHideHUD = 361;
const m_iClientHideHUD = 362;
const HUD_HIDE_MONEY = 1<<5;
const m_iMapZone = 235;

enum _:weapinfo {name[32], weap_name[32], bpammo};
enum _:PCVARS {AwpMinPlayers, MaxAwps, PistolMenu, MaxHeg, MaxFlash, MaxSmoke}
enum _:TEAMS {TE, CT};
enum _:MAXGRENADES {HE, FLASH, SMOKE};
enum _:AWPCVARS {MinPlayers, MaxAwp};
new g_Cvars[PCVARS], bool:g_AllowAWP, g_Awps[TEAMS], bool:g_Used[MAX_PLAYERS+1], g_Grenades[MAXGRENADES], g_AWPCvarHook[AWPCVARS];


new const weapons[][weapinfo] = {
	{"M4A1", "weapon_m4a1", 90},
	{"AK47", "weapon_ak47", 90},
	{"AWP", "weapon_awp", 30},
	{"M249", "weapon_m249", 200},
	{"AUG", "weapon_aug", 90},
	{"FAMAS", "weapon_famas", 90},
	{"GALIL", "weapon_galil", 90},
	{"MP5NAVY", "weapon_mp5navy", 120},
	{"XM1014", "weapon_xm1014", 32},
	{"M3", "weapon_m3", 32},
	{"SCOUT", "weapon_scout", 90},
	{"P90", "weapon_p90", 100},
	{"TMP", "weapon_tmp", 120},
	{"UMP45", "weapon_ump45", 100},
	{"MAC10", "weapon_mac10", 100}
};

new const pistols[][weapinfo] = {
	{"GLOCK18", "weapon_glock18", 120},
	{"USP", "weapon_usp", 100},
	{"DEAGLE", "weapon_deagle", 35},
	{"FIVESEVEN", "weapon_fiveseven", 100},
	{"P228", "weapon_p228", 52},
	{"ELITE", "weapon_elite", 120}
};

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_dictionary("extended_weapon_menu.txt");
	g_Cvars[AwpMinPlayers] = register_cvar("ewm_awpminplayers", "4")
	g_Cvars[MaxAwps] = register_cvar("ewm_maxawp", "3")
	g_Cvars[PistolMenu] = register_cvar("ewm_pistolmenu", "0")
	g_Cvars[MaxHeg] = register_cvar("ewm_maxheg", "1")
	g_Cvars[MaxFlash] = register_cvar("ewm_maxflash", "2")
	g_Cvars[MaxSmoke] = register_cvar("ewm_maxsmoke", "1")
	RegisterHam(Ham_Spawn, "player", "spawn_event", 1);
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0");
	
	new const commands[][] = {"say /gun", "say /guns", "say /weap", "say_team /gun", "say_team /guns", "say_team /weap"};
	for(new i; i < sizeof(commands); i++) {
		register_clcmd(commands[i], "weapmenu");
	}
	
	register_message(get_user_msgid("StatusIcon"), "Message_StatusIcon");
	register_event("ResetHUD", "Event_ResetHUD", "b")
	register_event("HideWeapon", "Event_HideWeapon", "b")
	set_msg_block(get_user_msgid("Money"), BLOCK_SET)
}

public plugin_cfg() {
	new sBuffer[256], sFile[64], sData[32], pFile;
	new mapname[32]; get_mapname(mapname, charsmax(mapname));
 
	get_localinfo("amxx_configsdir", sFile, charsmax(sFile));
	format(sFile, charsmax(sFile), "%s/ewm_blockmaps.ini", sFile);
 
	pFile = fopen(sFile, "rt");
 
	if(pFile) {		
		while(!feof(pFile)) {
			fgets(pFile, sBuffer, charsmax(sBuffer));
			trim(sBuffer);
			if(sBuffer[0] == ';') continue;
 
			parse(sBuffer, sData, charsmax(sData));

			if(containi(mapname, sData) != -1) {
				fclose(pFile);
				pause("od");
			}
		}
		fclose(pFile);
	}
	else fprintf(pFile, ";awp_^n;fy_");
}

public Event_NewRound() {
	arrayset(g_Used, false, sizeof(g_Used));
	arrayset(g_Awps, 0, sizeof(g_Awps));
	g_AWPCvarHook[MinPlayers] = get_pcvar_num(g_Cvars[AwpMinPlayers]);
	g_AllowAWP = (GetPlayers(1) >= g_AWPCvarHook[MinPlayers] && GetPlayers(2) >= g_AWPCvarHook[MinPlayers]) ? true : false;
	g_Grenades[HE] = get_pcvar_num(g_Cvars[MaxHeg]);
	g_Grenades[FLASH] = get_pcvar_num(g_Cvars[MaxFlash]);
	g_Grenades[SMOKE] = get_pcvar_num(g_Cvars[MaxSmoke]);
	g_AWPCvarHook[MaxAwp] = get_pcvar_num(g_Cvars[MaxAwps]);
}
 
public spawn_event(id) weapmenu(id);

public weapmenu(id) {
	if (!is_user_alive(id) || g_Used[id]) return;
	
	switch(cs_get_user_team(id)) {
		case CS_TEAM_T: {
			if(user_has_weapon(id, CSW_C4)) {
				strip_user_weapons(id)
				give_item(id, "weapon_c4")
				cs_set_user_plant(id,1,1)
			}
			else {
				strip_user_weapons(id)
			}
		}
		case CS_TEAM_CT: {
			strip_user_weapons(id);
			cs_set_user_defuse(id, 1);
		}
	}
	set_pdata_int(id, m_fHasPrimary, 0)
	give_item(id, "weapon_knife");

	new s_MenuName[128]; formatex(s_MenuName, charsmax(s_MenuName), "%s^nby \r%s \y", PLUGIN, AUTHOR);
	new menu = menu_create(s_MenuName, "weapmenu_h");
	for(new i; i<sizeof(weapons);i++) {
		menu_additem(menu, weapons[i][name], "", 0)
	}
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	formatex(s_MenuName, charsmax(s_MenuName), "%L", LANG_SERVER, "EWM_MENU_BACK");
	menu_setprop(menu, MPROP_BACKNAME, s_MenuName);
	formatex(s_MenuName, charsmax(s_MenuName), "%L", LANG_SERVER, "EWM_MENU_NEXT");
	menu_setprop(menu, MPROP_NEXTNAME, s_MenuName);
	formatex(s_MenuName, charsmax(s_MenuName), "%L", LANG_SERVER, "EWM_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, s_MenuName);
	menu_display(id, menu, 0);
}

public weapmenu_h(id, menu, item) {
	if(item == MENU_EXIT) {
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	if(equal(weapons[item][weap_name], "weapon_awp")) {
		if(!g_AllowAWP) {
			client_print_color(id, print_team_default, "%s^1 %L", PREFIX, LANG_SERVER, "EWM_AWP_ALLOWFROM", g_AWPCvarHook[MinPlayers], g_AWPCvarHook[MinPlayers]);
			weapmenu(id);
			return PLUGIN_HANDLED;
		}
		else if(g_AWPCvarHook[MaxAwp]) {
			switch(cs_get_user_team(id)) {
				case CS_TEAM_T: {
					if(g_Awps[TE] < g_AWPCvarHook[MaxAwp]) g_Awps[TE]++;
					else {
						client_print_color(id, print_team_default, "%s^1 %L", PREFIX, LANG_SERVER, "EWM_AWP_TOOMANY", g_AWPCvarHook[MaxAwp]);
						weapmenu(id);
						return PLUGIN_HANDLED;
					}
				}
				case CS_TEAM_CT: {
					if(g_Awps[CT] < g_AWPCvarHook[MaxAwp]) g_Awps[CT]++;
					else {
						client_print_color(id, print_team_default, "%s^1 %L", PREFIX, LANG_SERVER, "EWM_AWP_TOOMANY", g_AWPCvarHook[MaxAwp]);
						weapmenu(id);
						return PLUGIN_HANDLED;
					}
				}
			}
		}
	}
	
	if(get_pcvar_num(g_Cvars[PistolMenu]) == 1) {
		pistolmenu(id);
	}
	else {
		give_item(id, "weapon_deagle");
		cs_set_user_bpammo(id, CSW_DEAGLE, 35);
	}
	give_item(id, weapons[item][weap_name]);
	cs_set_user_bpammo(id, get_weaponid(weapons[item][weap_name]), weapons[item][bpammo]);
	cs_set_user_armor(id, 100, CS_ARMOR_VESTHELM);
	give_grenades(id);
	client_print_color(id, print_team_default, "%s^1 %L", PREFIX, LANG_SERVER, "EWM_CHOOSED", weapons[item][name]);
	g_Used[id] = true;
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public pistolmenu(id) {
	new s_MenuName[128]; formatex(s_MenuName, charsmax(s_MenuName), "%s^nby \r%s \y", PLUGIN, AUTHOR);
	new menu = menu_create(s_MenuName, "pistolmenu_h");
	for(new i; i<sizeof(pistols);i++) {
		menu_additem(menu, pistols[i][name], "", 0)
	}
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	formatex(s_MenuName, charsmax(s_MenuName), "%L", LANG_SERVER, "EWM_MENU_BACK");
	menu_setprop(menu, MPROP_BACKNAME, s_MenuName);
	formatex(s_MenuName, charsmax(s_MenuName), "%L", LANG_SERVER, "EWM_MENU_NEXT");
	menu_setprop(menu, MPROP_NEXTNAME, s_MenuName);
	formatex(s_MenuName, charsmax(s_MenuName), "%L", LANG_SERVER, "EWM_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, s_MenuName);
	menu_display(id, menu, 0);
}

public pistolmenu_h(id, menu, item) {
	if(item == MENU_EXIT) {
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	give_item(id, pistols[item][weap_name]);
	cs_set_user_bpammo(id, get_weaponid(pistols[item][weap_name]), pistols[item][bpammo]);
	client_print_color(id, print_team_default, "%s^1 %L", PREFIX, LANG_SERVER, "EWM_CHOOSED_PISTOL", pistols[item][name]);
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

give_grenades(id) {
	if(g_Grenades[HE]) {
		give_item(id, "weapon_hegrenade");
		cs_set_user_bpammo(id, CSW_HEGRENADE, g_Grenades[HE]);
	}

	if(g_Grenades[FLASH]) {
		give_item(id, "weapon_flashbang" );
		cs_set_user_bpammo(id, CSW_FLASHBANG, g_Grenades[FLASH]);
	}

	if(g_Grenades[SMOKE]) {
		give_item(id, "weapon_smokegrenade" );
		cs_set_user_bpammo(id, CSW_SMOKEGRENADE, g_Grenades[SMOKE]);
	}
}

GetPlayers(team) {
	new players[32], num; 
	get_players(players, num, "ce", team == 1 ? "TERRORIST":"CT")

	return num;
}

public Event_ResetHUD(id) {
	set_pdata_int(id, m_iClientHideHUD, 0)
	set_pdata_int(id, m_iHideHUD, HUD_HIDE_MONEY)
}

public Event_HideWeapon(id) {
	// for compatibility with other plugins using that message; ZP for example
	new iFlags = read_data(1)
	if(~iFlags & HUD_HIDE_MONEY) {
		set_pdata_int(id, m_iClientHideHUD, 0)
		set_pdata_int(id, m_iHideHUD, iFlags|HUD_HIDE_MONEY)
	}
}

public Message_StatusIcon(iMsgId, iMsgDest, id) {
	static szIcon[8];
	get_msg_arg_string(2, szIcon, charsmax(szIcon));
	if(equal(szIcon, "buyzone")) {
		if(get_msg_arg_int(1)) {
			set_pdata_int(id, m_iMapZone, get_pdata_int(id, m_iMapZone) & ~(1<<0));
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}