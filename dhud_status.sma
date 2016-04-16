#include <amxmodx>
#include <dhudmessage>

#define DHUD_RELOAD_TIME 2.0

enum _:TEAMS {TT, CT};
new g_iScore[TEAMS], g_iRoundNum, g_iAlive[TEAMS];

public plugin_init() {
	register_plugin("HUD Status", "1.0", "mforce & DUKKHAZ0R");
	register_event("TeamScore", "eTeamScore", "a");
	register_event("TextMsg", "eRestart", "a", "2&#Game_C", "2&#Game_w");
	register_event("HLTV", "eRoundStart", "a", "1=0", "2=0");
	set_task(DHUD_RELOAD_TIME, "HUDReloader", .flags="b");
}

public eTeamScore() {
	static sTeam[20]; read_data(1, sTeam, charsmax(sTeam));
	switch(sTeam[0]) {
		case 'T': g_iScore[TT] = read_data(2);
		case 'C': g_iScore[CT] = read_data(2);
	}
}

public eRestart()
	g_iRoundNum = 0;

public eRoundStart()
	++g_iRoundNum;
	
public HUDReloader()
{
	static pl[32];
	get_players(pl, g_iAlive[TT], "ae", "TERRORIST");
	get_players(pl, g_iAlive[CT], "ae", "CT");

	set_dhudmessage( 255, 0, 0, -1.0, 0.01, 0, 0.0, DHUD_RELOAD_TIME, 0.0, 0.0);
	show_dhudmessage( 0, "%02d TE                  ", g_iAlive[TT] );
	set_dhudmessage( 255, 255, 255, -1.0, 0.01, 0, 0.0, DHUD_RELOAD_TIME, 0.0, 0.0);
	show_dhudmessage( 0, "[ %02d ]^n%02d KÖRÖK %02d", g_iRoundNum, g_iScore[TT], g_iScore[CT] );
	set_dhudmessage( 0, 0, 255, -1.0, 0.01, 0, 0.0, DHUD_RELOAD_TIME, 0.0, 0.0);
	show_dhudmessage( 0, "                  CT %02d", g_iAlive[CT] );
}