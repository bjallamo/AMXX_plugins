#include <amxmodx>
#include <fakemeta>

#define REHLDS		// If you are not using REHLDS type // characters before the #.

#if defined REHLDS
#include <reapi>
#else
#include <hamsandwich>
#endif

new const PLUGIN[] = "No Team Flash"
new const VERSION[] = "1.0"
new const AUTHOR[] = "mforce & neygomon"


public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	#if defined REHLDS
	RegisterHookChain(RG_CBasePlayer_TraceAttack, "Multi_TraceAttack");
	#else
	RegisterHam(Ham_TraceAttack, "player", "Multi_TraceAttack");
	#endif
}

public Multi_TraceAttack(victim, attacker, Float:flDamage, Float:vecDir[3], tracehandle) {
	new bool:isknife = (get_user_weapon(attacker) == CSW_KNIFE) ? true : false;
	#if defined REHLDS
	return (get_tr2(tracehandle, TR_iHitgroup) == HIT_HEAD || isknife) ? HC_SUPERCEDE : HC_CONTINUE;
	#else
	return (get_tr2(tracehandle, TR_iHitgroup) == HIT_HEAD || isknife) ? HAM_SUPERCEDE : HAM_IGNORED;
	#endif
}