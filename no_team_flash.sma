#include <amxmodx>

#define REHLDS		// If you are not using REHLDS type // characters before the #.

#if defined REHLDS
#include <reapi>
#else
#include <engine>
new g_iFlasher;
new g_iFlasherTeam;
#endif

new const PLUGIN[] = "No Team Flash"
new const VERSION[] = "1.0"
new const AUTHOR[] = "mforce & neygomon"


public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	#if defined REHLDS
	RegisterHookChain(RG_PlayerBlind, "fwdPlayerBlind");
	#else
	register_event("ScreenFade", "eScreenFade", "be", "4=255", "5=255", "6=255", "7>199")  
	register_think("grenade", "fwdThinkGrenade");
	#endif
}

#if defined REHLDS
public fwdPlayerBlind(id, inflictor, attacker) {
	if(id == attacker)
		return HC_CONTINUE;
	if(get_member(id, m_iTeam) != get_member(attacker, m_iTeam))
		return HC_CONTINUE;

	return HC_SUPERCEDE;
}
#else
public eScreenFade(id) {
	if(!g_iFlasher || id == g_iFlasher)
		return PLUGIN_CONTINUE;
	if(get_user_team(id) != g_iFlasherTeam)
		return PLUGIN_CONTINUE;
	
	return PLUGIN_HANDLED;
}

public fwdThinkGrenade(iEnt) {
	static sModel[23]; entity_get_string(iEnt, EV_SZ_model, sModel, charsmax(sModel));
	if(strcmp(sModel, "models/w_flashbang.mdl") == 1)
		return PLUGIN_CONTINUE;
	if(get_gametime() == entity_get_float(iEnt, EV_FL_dmgtime))
		return PLUGIN_CONTINUE;
	static iOwner; iOwner = entity_get_edict(iEnt, EV_ENT_owner);
	if(!is_user_connected(iOwner))
		g_iFlasher = g_iFlasherTeam = 0;
	else {
		g_iFlasher = iOwner;
		g_iFlasherTeam = get_user_team(iOwner);
	}
	return PLUGIN_CONTINUE;
}
#endif