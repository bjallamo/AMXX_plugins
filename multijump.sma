#include <amxmodx>
#include <fakemeta>

#define REHLDS					// If you are not using REHLDS type // characters before the #.
#define MAXJUMPS	2			// maximum jumps


#if defined REHLDS
#include <reapi>
#else
#include <hamsandwich>
#endif

#if AMXX_VERSION_NUM < 183
	#define MAX_PLAYERS	32 + 1
#endif


new const PLUGIN[] = "Multijump"
new const VERSION[] = "1.0"
new const AUTHOR[] = "mforce & serfreeman1337"


enum _:jdata {
	bool:DOJUMP,
	JUMPCOUNT
}

new player_jumps[MAX_PLAYERS][jdata]

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	#if defined REHLDS
	RegisterHookChain(RG_CBasePlayer_Jump, "Hook_PlayerJump");
	#else
	RegisterHam(Ham_Player_Jump, "player", "Hook_PlayerJump")
	#endif
}

public Hook_PlayerJump(id) {
	static oldButtons
	oldButtons = pev(id, pev_oldbuttons)
	
	static onGround
	onGround = (pev(id, pev_flags) & FL_ONGROUND)
	
	if(!onGround && !(oldButtons & IN_JUMP)) {
		if(player_jumps[id][JUMPCOUNT] < MAXJUMPS - 1) {
			player_jumps[id][DOJUMP] = true
			player_jumps[id][JUMPCOUNT] ++
		}
	}
	else if(onGround) {
		player_jumps[id][JUMPCOUNT] = 0
	}
	
	if(player_jumps[id][DOJUMP]) {
		static Float:velocity[3]
		pev(id,pev_velocity,velocity)
		velocity[2] = random_float(265.0,285.0)
		set_pev(id, pev_velocity, velocity)
		
		player_jumps[id][DOJUMP] = false
	}
}

public client_disconnect(id) {
	arrayset(player_jumps[id], 0, jdata)
}

