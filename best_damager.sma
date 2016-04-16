#include <amxmodx>
#include <colorchat>
#include <cstrike>

#define PLUGIN "Best Damager"
#define VERSION "1.0"
#define AUTHOR "mforce"

#define BESTDMG_MONEY 1000

new const PREFIX[] = "BestDamager"
new g_iDMG[33], g_BestName[32];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_logevent("logevent_round_end", 6, "3=CTs_Win", "3=All_Hostages_Rescued") 
	register_logevent("logevent_round_end" , 6, "3=Terrorists_Win", "3=Target_Bombed") 
	register_event("Damage", "EventDamage", "b", "2>0", "3=0");
}

public logevent_round_end() set_task(5.0, "BestDmger");

public BestDmger() {
	new players[32], num, tempid, bestid;
	get_players(players, num, "ch");
	if(num > 3) {
		SortCustom1D(players, num, "SortByDMG");
		bestid = players[0];
		get_user_name(bestid, g_BestName, charsmax(g_BestName));
		cs_set_user_money(bestid, cs_get_user_money(bestid)+BESTDMG_MONEY, 16000);
		client_print_color(bestid, print_team_default, "^4[%s]^1 You've got ^3 %d$^1, because you are the best in this round.", PREFIX, BESTDMG_MONEY);

		for(new i = 0; i < num; i++) {
			tempid = players[i];
			set_hudmessage(0, 100, 255, -1.0, 0.01, 2, 0.5, 6.0, .channel = -1);
			show_hudmessage(tempid, "Most damage in this round:^n%s (%i)^nYour damage: (%i)", strlen(g_BestName) > 0 ? g_BestName:"Nobody", g_iDMG[bestid], g_iDMG[tempid]);
		}
		g_BestName[0] = EOS;
	}
	arrayset(g_iDMG, 0, sizeof(g_iDMG));
}

public client_disconnect(id) {
	g_iDMG[id] = 0;
}

public SortByDMG(elem1, elem2) {
	if (g_iDMG[elem1] > g_iDMG[elem2])
		return -1;
	else
		return 1;
	return 0;
}

public EventDamage(iVictim) {
	new iAttacker = get_user_attacker(iVictim);
	if(!is_user_connected(iAttacker) || iAttacker == iVictim) return;
	g_iDMG[iAttacker] += read_data(2);
}