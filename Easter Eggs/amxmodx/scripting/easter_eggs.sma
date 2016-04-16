#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <cstrike>
#include <fun>

new const PLUGIN[] = "Easter Eggs";
new const VERSION[] = "1.0";
new const AUTHOR[] = "mforce";		// With lot of helps from tuty's plugin.



#define IS_PLAYER(%1)			(1 <= %1 <= gMaxPlayers)

enum _: iGifts {
	GIFT_ARMOR_KEVLAR,
	GIFT_AMMO,
	GIFT_BONUS_HEALTH,
	GIFT_RANDOM_GRENADE,
	GIFT_FRAG,
	GIFT_DEFUSER,
	GIFT_MONEY,
	GIFT_DRINK
};

new const szGiftNames[iGifts][] = {
	"Kevlár",
	"Töltény",
	"Bónusz Élet",
	"Random Gránát",
	"Bónusz Frag",
	"Hatástalanító készlet",
	"Pénz",
	"Pálinka"
};

new const gGiftModels[][] = {
	"models/easter_eggs/matyo1.mdl",
	"models/easter_eggs/matyo2.mdl",
	"models/easter_eggs/matyo3.mdl",
	"models/easter_eggs/matyo4.mdl",
	"models/easter_eggs/matyo5.mdl",
	"models/easter_eggs/matyo6.mdl",
	"models/easter_eggs/matyo7.mdl"
};

new const szPluginTag[] = "[Easter Eggs]";

new const szGiftClassname[] = "Present_Entity";

new const szPickupArmorSound[] = "items/ammopickup2.wav";
new const szHealthPickUpSound[] = "items/medshot4.wav";
new const szBonusFragsPickupSound[] = "bullchicken/bc_bite1.wav";
new const szDefuserPickupSound[] = "items/gunpickup3.wav";
new const szDrinkSound[] = "barney/whatisthat.wav";

new gMaxPlayers;
new gHudSync;
new gMessageScoreInfo;
new gInfoTarget;
new g_iMsgSetFOV;


public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_event("DeathMsg", "EVENT_DeathMsg", "a");

	register_event("HLTV", "EVENT_RoundStart", "a", "1=0", "2=0")  
	register_think(szGiftClassname, "forward_GiftThink");
	
	register_touch(szGiftClassname, "player", "forward_TouchGift");
	
	gHudSync = CreateHudSyncObj();
	gMaxPlayers = get_maxplayers();

	gMessageScoreInfo = get_user_msgid("ScoreInfo");
	g_iMsgSetFOV = get_user_msgid("SetFOV");

	gInfoTarget = engfunc(EngFunc_AllocString, "info_target");
}

public plugin_precache()
{
	for(new i = 0; i < sizeof gGiftModels; i++) {
		precache_model(gGiftModels[i]);
	}
	
	precache_sound(szPickupArmorSound);
	precache_sound(szHealthPickUpSound);
	precache_sound(szBonusFragsPickupSound);
	precache_sound(szDefuserPickupSound);
	precache_sound(szDrinkSound);
}

public EVENT_RoundStart()
{
	new players[32], num, tempid;
	get_players(players, num, "c");
	
	for(new i = 0; i < num; i++) {
		tempid = players[i]
		remove_task(tempid);
		removedrug(tempid);
	}
	
	RemoveEntities(szGiftClassname);
}

public EVENT_DeathMsg()
{
	new iKiller = read_data(1);	
	new iVictim = read_data(2);

	if(!IS_PLAYER(iVictim)) return;
	
	remove_task(iVictim);
	removedrug(iVictim);

	if(iVictim == iKiller) return;

	new Float:flOrigin[3];
	pev(iVictim, pev_origin, flOrigin);
	
	flOrigin[2] += -34.0;

	new Float:flAngles[3];
	pev(iVictim, pev_angles, flAngles);
		
	new iEntity = engfunc(EngFunc_CreateNamedEntity, gInfoTarget);

	if(!pev_valid(iEntity)) return;

	set_pev(iEntity, pev_classname, szGiftClassname);
	set_pev(iEntity, pev_angles, flAngles);

	engfunc(EngFunc_SetOrigin, iEntity, flOrigin);
	engfunc(EngFunc_SetModel, iEntity, gGiftModels[random_num(0, charsmax(gGiftModels))]);
	
	ExecuteHam(Ham_Spawn, iEntity);

	set_pev(iEntity, pev_solid, SOLID_BBOX);
	set_pev(iEntity, pev_movetype, MOVETYPE_NONE);
	set_pev(iEntity, pev_nextthink, get_gametime() + 2.0);

	engfunc(EngFunc_SetSize, iEntity, Float:{ -23.160000, -13.660000, -0.050000 }, Float:{ 11.470000, 12.780000, 6.720000 });
	engfunc(EngFunc_DropToFloor, iEntity);
	
	set_rendering(iEntity, kRenderFxGlowShell, random(256), random(256), random(256), kRenderFxNone, 23);

	return;
}

public forward_GiftThink(iEntity) {
	if(pev_valid(iEntity)) {
		set_rendering(iEntity, kRenderFxGlowShell, random(256), random(256), random(256), kRenderFxNone, random_num(5, 20));
		set_pev(iEntity, pev_nextthink, get_gametime() + 2.0);
	}
}
	
public forward_TouchGift(iEntity, id) {
	if(!pev_valid(iEntity) || !is_user_alive(id)) return PLUGIN_HANDLED;

	set_hudmessage(random(256), random(256), random(256), -1.0, 0.72, 1, 6.0, 6.0);

	switch(random(iGifts)) {
		case GIFT_ARMOR_KEVLAR: {
			new iArmor = 100;
			cs_set_user_armor(id, iArmor, CS_ARMOR_VESTHELM);

			ShowSyncHudMsg(id, gHudSync, "%s^nFelvetted:^n%s (%d)", szPluginTag, szGiftNames[GIFT_ARMOR_KEVLAR], iArmor);
			emit_sound(id, CHAN_ITEM, szPickupArmorSound, VOL_NORM, ATTN_NORM, 0 , PITCH_NORM);
      	}
		
		case GIFT_AMMO: {
			GiveWeaponAmmo(id);
			ShowSyncHudMsg(id, gHudSync, "%s^nFelvetted:^n%s", szPluginTag, szGiftNames[GIFT_AMMO]);
		}
		
		case GIFT_BONUS_HEALTH: {
			new iBonusHealth = 15;
			set_user_health(id, get_user_health(id) + iBonusHealth);
			
			ShowSyncHudMsg(id, gHudSync, "%s^nFelvetted:^n%s + (%d HP)", szPluginTag, szGiftNames[GIFT_BONUS_HEALTH], iBonusHealth);
			emit_sound(id, CHAN_ITEM, szHealthPickUpSound, VOL_NORM, ATTN_NORM, 0 , PITCH_NORM);
		}
		
		case GIFT_RANDOM_GRENADE: {
			switch(random_num(1, 3)) {
				case 1: {				
					give_item(id, "weapon_hegrenade");
					ShowSyncHudMsg(id, gHudSync, "%s^nFelvetted:^n%s (HE Gránát)", szPluginTag, szGiftNames[GIFT_RANDOM_GRENADE]);
				}

				case 2: {
					give_item(id, "weapon_flashbang");
					ShowSyncHudMsg(id, gHudSync, "%s^nFelvetted:^n%s (Flash Gránát)", szPluginTag, szGiftNames[GIFT_RANDOM_GRENADE]);
				}

				case 3: {	
					give_item(id, "weapon_smokegrenade");
					ShowSyncHudMsg(id, gHudSync, "%s^nFelvetted:^n%s (Smoke Gránát)", szPluginTag, szGiftNames[GIFT_RANDOM_GRENADE]);
				}
			}
			
			emit_sound(id, CHAN_ITEM, szPickupArmorSound, VOL_NORM, ATTN_NORM, 0 , PITCH_NORM);
		}
		
		case GIFT_FRAG: {
			new iBonusFrags = 2;

			set_user_frags(id, get_user_frags(id) + iBonusFrags);
			UpdateScoreboard(id);

			ShowSyncHudMsg(id, gHudSync, "%s^nFelvetted:^n%s (%d Frag)", szPluginTag, szGiftNames[GIFT_FRAG], iBonusFrags);
			emit_sound(id, CHAN_ITEM, szBonusFragsPickupSound, VOL_NORM, ATTN_NORM, 0 , PITCH_NORM);
		}
	
		case GIFT_DEFUSER: {
			if(get_user_team(id) == 2) {
				cs_set_user_defuse(id, 1);
				ShowSyncHudMsg(id, gHudSync, "%s^nFelvetted:^n%s", szPluginTag, szGiftNames[GIFT_DEFUSER]);
				
				emit_sound(id, CHAN_ITEM, szDefuserPickupSound, VOL_NORM, ATTN_NORM, 0 , PITCH_NORM);
			}
			
			else {
				ShowSyncHudMsg(id, gHudSync, "%s^nDefuser volt a tojásban, de te Terrorista vagy!", szPluginTag);
				
				emit_sound(id, CHAN_ITEM, szDefuserPickupSound, VOL_NORM, ATTN_NORM, 0 , PITCH_NORM);
			}
		}
		
		case GIFT_MONEY: {
			new iMoney = cs_get_user_money(id);
			new iMoneyGift = 1000;

			cs_set_user_money(id, (iMoney >= 16000) ? 16000 : iMoney + iMoneyGift, 1);
			ShowSyncHudMsg(id, gHudSync, "%s^nFelvetted:^n%s + (%d$)", szPluginTag, szGiftNames[GIFT_MONEY], iMoneyGift);

		}
		
		case GIFT_DRINK: {
			new iDrinkMinus = 5;
			set_user_health(id, get_user_health(id) - iDrinkMinus);
			makedrug(id);
			
			ShowSyncHudMsg(id, gHudSync, "%s^nFelvetted:^n%s (-%d HP)", szPluginTag, szGiftNames[GIFT_DRINK], iDrinkMinus);
			emit_sound(id, CHAN_ITEM, szDrinkSound, VOL_NORM, ATTN_NORM, 0 , PITCH_NORM);
		}
	}

        engfunc(EngFunc_RemoveEntity, iEntity);

        return PLUGIN_CONTINUE;
}	

RemoveEntities(const szClassname[]) {
	new iEntity = FM_NULLENT;
	
	while((iEntity = engfunc(EngFunc_FindEntityByString, FM_NULLENT, "classname", szClassname))) {
		engfunc(EngFunc_RemoveEntity, iEntity);
	}
}

UpdateScoreboard(id) {
	message_begin(MSG_ALL, gMessageScoreInfo);
	write_byte(id);
	write_short(get_user_frags(id));
	write_short(get_user_deaths(id));
	write_short(0);
	write_short(get_user_team(id)); 
	message_end();
}

GiveWeaponAmmo(index) {
	new szCopyAmmoData[40];
	
	switch(get_user_weapon(index))
	{
		case CSW_P228: copy(szCopyAmmoData, charsmax(szCopyAmmoData), "ammo_357sig");
		case CSW_SCOUT, CSW_G3SG1, CSW_AK47: copy(szCopyAmmoData, charsmax(szCopyAmmoData), "ammo_762nato");
		case CSW_XM1014, CSW_M3: copy(szCopyAmmoData, charsmax(szCopyAmmoData), "ammo_buckshot");
		case CSW_MAC10, CSW_UMP45, CSW_USP: copy(szCopyAmmoData, charsmax(szCopyAmmoData), "ammo_45acp");
		case CSW_SG550, CSW_GALIL, CSW_FAMAS, CSW_M4A1, CSW_SG552, CSW_AUG: copy(szCopyAmmoData, charsmax(szCopyAmmoData), "ammo_556nato");
		case CSW_ELITE, CSW_GLOCK18, CSW_MP5NAVY, CSW_TMP: copy(szCopyAmmoData, charsmax(szCopyAmmoData), "ammo_9mm");
		case CSW_AWP: copy(szCopyAmmoData, charsmax(szCopyAmmoData), "ammo_338magnum");
		case CSW_M249: copy(szCopyAmmoData, charsmax(szCopyAmmoData), "ammo_556natobox");
		case CSW_FIVESEVEN, CSW_P90: copy(szCopyAmmoData, charsmax(szCopyAmmoData), "ammo_57mm");
		case CSW_DEAGLE: copy(szCopyAmmoData, charsmax(szCopyAmmoData), "ammo_50ae");
	}
	
	give_item(index, szCopyAmmoData);
	give_item(index, szCopyAmmoData);
	give_item(index, szCopyAmmoData);
}

public makedrug(id) {
	message_begin(MSG_ONE, g_iMsgSetFOV, {0, 0, 0}, id);
	write_byte(135);
	message_end();
	
	set_task(3.0, "removedrug", id);
}

public removedrug(id) {
	message_begin(MSG_ONE, g_iMsgSetFOV, { 0, 0, 0 }, id);
	write_byte(90);
	message_end();
}

public client_disconnect(id) {
	remove_task(id);
	removedrug(id);
}