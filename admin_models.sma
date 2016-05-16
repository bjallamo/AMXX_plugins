#include <amxmodx>
#include <cstrike>
#include <hamsandwich>


new const PLUGIN[] = "Admin Models";
new const VERSION[] = "1.1";
new const AUTHOR[] = "mforce";


#define ACCESS_FLAG	ADMIN_KICK		// Type // before the # if you want it for all players.

new const T_MODEL[] = "te_admin";
new const CT_MODEL[] = "ct_admin";

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	RegisterHam(Ham_Spawn, "player", "fwPlayerSpawn", 1);
}

public plugin_precache() {
	new model[128];
	formatex(model, charsmax(model), "models/player/%s/%s.mdl", T_MODEL, T_MODEL);
	precache_model(model);
	formatex(model, charsmax(model), "models/player/%s/%s.mdl", CT_MODEL, CT_MODEL);
	precache_model(model);
}

public fwPlayerSpawn(id) {
	#if defined ACCESS_FLAG
	if(~get_user_flags(id) & ACCESS_FLAG) return;
	#endif
	
	if(!is_user_alive(id)) {
		cs_reset_user_model(id);
		return;
	}
	
	switch(cs_get_user_team(id)) {
			case CS_TEAM_T: cs_set_user_model(id, T_MODEL);
			case CS_TEAM_CT: cs_set_user_model(id, CT_MODEL);
	}
}