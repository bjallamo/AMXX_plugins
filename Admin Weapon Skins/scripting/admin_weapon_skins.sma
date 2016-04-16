#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

new const PLUGIN[] = "Admin Weapon Skins";
new const VERSION[] = "1.0";
new const AUTHOR[] = "mforce";


#define ACCESS_FLAG	ADMIN_KICK

new Trie:weaponlist

const m_pPlayer = 41
const XO_WEAPON = 4

#define get_weapon_owner(%1)		get_pdata_cbase(%1, m_pPlayer, XO_WEAPON)
#define AllocString(%1) 			engfunc(EngFunc_AllocString,%1)

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	weaponlist = TrieCreate()
}

public plugin_precache() {
	new sBuffer[256], sFile[64], sData[2][32], pFile;
 
	get_localinfo("amxx_configsdir", sFile, charsmax(sFile));
	format(sFile, charsmax(sFile), "%s/admin_weapon_skins.ini", sFile);
 
	pFile = fopen(sFile, "rt");
 
	if(pFile) {		
		while(!feof(pFile)) {
			fgets(pFile, sBuffer, charsmax(sBuffer));
			trim(sBuffer);
			if(sBuffer[0] == ';') continue;
 
			parse(sBuffer, sData[0], charsmax(sData[]), sData[1], charsmax(sData[]));

			if((containi(sData[0], "weapon_") != -1) && (containi(sData[1], ".mdl") != -1) && (!TrieKeyExists(weaponlist, sData[0]))) {
				precache_model(sData[1])
				RegisterHam(Ham_Item_Deploy, sData[0], "ItemDeploy_Post", true);
				TrieSetString(weaponlist, sData[0], sData[1])
			}
		}
		fclose(pFile);
	}
	else fprintf(pFile, ";^"weapon_ak47^" ^"models/adminskins/v_ak47.mdl^"^n");
}

public ItemDeploy_Post(Ent) {
	if(Ent <=0)
		return HAM_IGNORED;

	new id = get_weapon_owner(Ent)
	if((id > 0) && (get_user_flags(id) & ACCESS_FLAG)) {
		new szWeapon[32], WeaponPath[32];
		get_weaponname(Ent, szWeapon, charsmax(szWeapon));
		
		TrieGetString(weaponlist, szWeapon, WeaponPath, charsmax(WeaponPath));
		set_pev_string(id, pev_viewmodel2, AllocString(WeaponPath));
	}
	return HAM_IGNORED;
}

public plugin_end() {
    TrieDestroy(weaponlist);
}