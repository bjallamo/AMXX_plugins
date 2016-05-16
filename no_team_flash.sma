#include <amxmodx>

#define REHLDS		// If you are not using REHLDS type // characters before the #.

#if defined REHLDS
#include <reapi>
#else
#include <fakemeta>
#include <hamsandwich>
new g_FlId;
#endif

new const PLUGIN[] = "No Team Flash"
new const VERSION[] = "1.1"
new const AUTHOR[] = "mforce"


public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	#if defined REHLDS
	RegisterHookChain(RG_PlayerBlind, "fwdPlayerBlind");
	#else
	register_message(get_user_msgid("ScreenFade"), "mScreenFade");
	RegisterHam(Ham_Think, "grenade", "Grenade_Think", .Post = false)
	#endif
}

#if defined REHLDS
public fwdPlayerBlind(id, inflictor, attacker) {
	if(id == attacker || get_member(id, m_iTeam) != get_member(attacker, m_iTeam))
		return HC_CONTINUE;

	return HC_SUPERCEDE;
}
#else
public mScreenFade(iMsgId, iMsgType, iMsgEnt) {
	if(get_msg_arg_int(4) != 255 || get_msg_arg_int(5) != 255 || get_msg_arg_int(6) != 255 || get_msg_arg_int(7) < 200)
		return PLUGIN_CONTINUE;
	
	if(!g_FlId || iMsgEnt == g_FlId || get_user_team(iMsgEnt) != get_user_team(g_FlId))
		return PLUGIN_CONTINUE;

	return PLUGIN_HANDLED;
}

public Grenade_Think(ent) {
	static szModel[23]; pev(ent, pev_model, szModel, charsmax(szModel));

	if(equal(szModel, "models/w_flashbang.mdl")) {
		if(pev(ent, pev_dmgtime) <= get_gametime() && ~pev(ent, pev_effects) & EF_NODRAW)
			g_FlId = pev(ent, pev_owner);
	}
}
#endif