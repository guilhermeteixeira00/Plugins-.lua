#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <rezp_inc/rezp_main>

const SECTION_MAX_PAGE_ITEMS = 7;

enum _:SelectWeaponsData
{
	SelectWeapon_Section,
	SelectWeapon_Reference[RZ_MAX_REFERENCE_LENGTH],
	SelectWeapon_Name[RZ_MAX_LANGKEY_LENGTH],
	SelectWeapon_ShortName[RZ_MAX_LANGKEY_LENGTH],
	bool:SelectWeapon_IsCustom,
	SelectWeapon_CustomId,

}; new Array:g_aSelectWeapons;

enum
{
    SECTION_PISTOL,
    SECTION_PRIMARY,
    SECTION_EQUIPMENT,
    SECTION_KNIFE,
    MAX_SECTIONS,
};
 new bool:g_bSectionAvailable[MAX_SECTIONS];

new const SECTION_NAMES[MAX_SECTIONS][] =
{
    "RZ_MENU_WPN_SEC_PISTOL",    // Pistolas
    "RZ_MENU_WPN_SEC_PRIMARY",  // Categoria única para PRIMARY
    "RZ_MENU_WPN_SEC_EQUIP",    // Equipamentos
    "RZ_MENU_WPN_SEC_KNIFE",    // Facas
};

new const MAIN_MENU_ID[] = "RZ_WeaponsMain";
new const SECTION_MENU_ID[] = "RZ_WeaponsSection";

enum
{
	SLOT_PRIMARY,
	SLOT_SECONDARY,
	SLOT_KNIFE,
	SLOT_GRENADE1,
	SLOT_GRENADE2,
	SLOT_GRENADE3,
	MAX_SLOT_WEAPONS,
};

new g_iDefaultWeapons[MAX_SLOT_WEAPONS] = { -1, ... };

new bool:g_bWeaponsGiven[MAX_PLAYERS + 1];
new g_iSlotWeapon[MAX_PLAYERS + 1][MAX_SLOT_WEAPONS];

new g_iMenuSection[MAX_PLAYERS + 1];
new g_iMenuPage[MAX_PLAYERS + 1];
new g_iMenuTimer[MAX_PLAYERS + 1];
new Array:g_aMenuItems[MAX_PLAYERS + 1];

new g_iMenu_Main;
new g_iMenu_Section;

new g_iClass_Human, clanName[64];

public plugin_precache()
{
	register_plugin("[ReZP] Menu: Weapons", REZP_VERSION_STR, "fl0wer");

	RZ_CHECK_CLASS_EXISTS(g_iClass_Human, "class_human");

	for (new i = 1; i <= MaxClients; i++)
		g_aMenuItems[i] = ArrayCreate(1, 0);
}

public plugin_init()
{
	new const cmds[][] = { "guns", "say /guns" };

	for (new i = 0; i < sizeof(cmds); i++)
		register_clcmd(cmds[i], "@Command_Guns");

	rz_main_get(RZ_MAIN_CLAN_NAME, clanName, charsmax(clanName));

	g_iMenu_Main = register_menuid(MAIN_MENU_ID);
	g_iMenu_Section = register_menuid(SECTION_MENU_ID);

	register_menucmd(g_iMenu_Main, 1023, "@HandleMenu_Main");
	register_menucmd(g_iMenu_Section, 1023, "@HandleMenu_Section");

	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Post", true);

	g_aSelectWeapons = ArrayCreate(SelectWeaponsData);
	
	AddWeapons();
}

public client_putinserver(id)
{
	g_iSlotWeapon[id] = g_iDefaultWeapons;
}

public rz_class_change_post(id, attacker, class, bool:preSpawn)
{
	if (class != g_iClass_Human)
		return;

	if (preSpawn)
		return;

	g_bWeaponsGiven[id] = false;
	g_iMenuTimer[id] = get_member_game(m_bFreezePeriod) ? 90 : 30;

	MainMenu_Show(id);
}

@Command_Guns(id)
{
	if (is_nullent(id))
		return PLUGIN_CONTINUE;
	
	if (!is_user_alive(id))
		return PLUGIN_HANDLED;

	if (rz_player_get(id, RZ_PLAYER_CLASS) != g_iClass_Human)
		return PLUGIN_HANDLED;

	MainMenu_Show(id);
	return PLUGIN_HANDLED;
}

@CBasePlayer_Spawn_Post(const id)
{
	if (!is_user_alive(id))
		return;

	if (rz_player_get(id, RZ_PLAYER_CLASS) != g_iClass_Human)
		return;

	g_bWeaponsGiven[id] = false;
	g_iMenuTimer[id] = get_member_game(m_bFreezePeriod) ? 90 : 30;

	MainMenu_Show(id);
}

MainMenu_Show(id)
{
	if (g_bWeaponsGiven[id])
		{
			rz_print_chat(id, print_team_grey, "Você poderá selecionar suas armas no próximo round.");
			return;
		}

	new bool:isWarmup = rz_game_is_warmup();

	if (!isWarmup && !task_exists(id))
		set_task(1.0, "@Task_ShowMenu", id, .flags = "b");

	new keys;
	new len;
	new text[MAX_MENU_LENGTH];

	SetGlobalTransTarget(id);

	ADD_FORMATEX("\r[\d%s\r]^n", clanName);
	ADD_FORMATEX("\y%l", "RZ_MENU_WPN_TITLE");

	if (!isWarmup)
		ADD_FORMATEX("^n\w%l: %d", "RZ_MENU_WPN_TIMER", g_iMenuTimer[id]);

	ADD_FORMATEX("^n^n");

	new bool:empty = true;
	new weaponPack[] = { SLOT_PRIMARY, SLOT_SECONDARY };
	new equipPack[] = { SLOT_KNIFE, SLOT_GRENADE1, SLOT_GRENADE2, SLOT_GRENADE3 };
	new weaponText[128];
	new equipText[128];

	if (FillField(id, "RZ_MENU_WPN_FIELD_WPN", weaponText, weaponPack, sizeof(weaponPack)))
	{
		empty = false;
		ADD_FORMATEX("%s^n", weaponText);
	}

	if (FillField(id, "RZ_MENU_WPN_FIELD_EQUIP", equipText, equipPack, sizeof(equipPack)))
	{
		empty = false;
		ADD_FORMATEX("%s^n", equipText);
	}

	if (!empty)
		ADD_FORMATEX("^n");

	for (new i = 0; i < sizeof(SECTION_NAMES); i++)
	{
		if (g_bSectionAvailable[i])
		{
			ADD_FORMATEX("\r%d. \w%l^n", i + 1, SECTION_NAMES[i]);
			keys |= (1<<i);
		}
		else
			ADD_FORMATEX("\d%d. %l^n", i + 1, SECTION_NAMES[i]);
	}

	ADD_FORMATEX("^n");

	if (!empty)
	{
		ADD_FORMATEX("\r9. \w%l^n^n", "RZ_MENU_WPN_BUY_SELECT");
		keys |= MENU_KEY_9;
	}
	else
		ADD_FORMATEX("\d9. %l^n^n", "RZ_MENU_WPN_BUY_SELECT");

	ADD_FORMATEX("\r0. \w%l", "RZ_CLOSE");
	keys |= MENU_KEY_0;

	show_menu(id, keys, text, -1, MAIN_MENU_ID);
}

FillField(id, field[], textDest[128], selects[], selectsNum)
{
	new select;
	new selectedNum;
	new len;
	new text[128];
	new data[SelectWeaponsData];

	for (new i = 0; i < selectsNum; i++)
	{
		select = selects[i];

		if (g_iSlotWeapon[id][select] == g_iDefaultWeapons[SLOT_KNIFE])
			continue;
		
		if (g_iSlotWeapon[id][select] == -1)
			continue;

		ArrayGetArray(g_aSelectWeapons, g_iSlotWeapon[id][select], data);

		if (selectedNum == 0)
		{
			if (data[SelectWeapon_ShortName][0])
				ADD_FORMATEX("\w%l: \y%l", field, data[SelectWeapon_ShortName]);
			else
				ADD_FORMATEX("\w%l: \y%l", field, data[SelectWeapon_Name]);
		}
		else
		{
			if (data[SelectWeapon_ShortName][0])
				ADD_FORMATEX(" \w+ \y%l", data[SelectWeapon_ShortName]);
			else
				ADD_FORMATEX(" \w+ \y%l", data[SelectWeapon_Name]);
		}

		selectedNum++;
	}

	if (selectedNum)
	{
		textDest = text;
		return true;
	}

	return false;
}

@HandleMenu_Main(const id, const key)
{
    if (key == 9) // Fechar menu
    {
        remove_task(id);
        return PLUGIN_HANDLED;
    }

    // Caso o jogador escolha uma seção
    SectionMenu_Show(id, key);

    return PLUGIN_HANDLED;
}


SectionMenu_Show(id, section, page = 0)
{
	if (g_bWeaponsGiven[id])
		return;
	
	if (page < 0)
	{
		MainMenu_Show(id);
		return;
	}

	ArrayClear(g_aMenuItems[id]);

	new weaponsNum = ArraySize(g_aSelectWeapons);
	new data[SelectWeaponsData];

	for (new i = 0; i < weaponsNum; i++)
	{
		ArrayGetArray(g_aSelectWeapons, i, data);

		if (data[SelectWeapon_Section] != section)
			continue;

		ArrayPushCell(g_aMenuItems[id], i);
	}

	new itemNum = ArraySize(g_aMenuItems[id]);
	new bool:singlePage = bool:(itemNum < 9);
	new itemPerPage = singlePage ? 8 : SECTION_MAX_PAGE_ITEMS;
	new i = min(page * itemPerPage, itemNum);
	new start = i - (i % itemPerPage);
	new end = min(start + itemPerPage, itemNum);

	g_iMenuSection[id] = section;
	g_iMenuPage[id] = start / itemPerPage;

	new keys;
	new len;
	new index;
	new select;
	new item;
	new grenadeNum;
	new text[MAX_MENU_LENGTH];

	SetGlobalTransTarget(id);

	if (singlePage)
		ADD_FORMATEX("\y%l %l", "RZ_MENU_WPN_SEC_TITLE", SECTION_NAMES[section]);
	else
		ADD_FORMATEX("\y%l %l \r%d/%d", "RZ_MENU_WPN_SEC_TITLE", SECTION_NAMES[section], g_iMenuPage[id] + 1, ((itemNum - 1) / itemPerPage) + 1);

	if (!rz_game_is_warmup())
		ADD_FORMATEX("^n\w%l: %d", "RZ_MENU_WPN_TIMER", g_iMenuTimer[id]);

	ADD_FORMATEX("^n^n");

	for (i = start; i < end; i++)
	{
		index = ArrayGetCell(g_aMenuItems[id], i);
		ArrayGetArray(g_aSelectWeapons, index, data);

		select = MapSectionToSelect(section, index);

		switch (select)
		{
			case SLOT_KNIFE:
			{
				if (g_iSlotWeapon[id][select] != index)
				{
					ADD_FORMATEX("\r%d. \w%l^n", item + 1, data[SelectWeapon_Name]);
					keys |= (1<<item);
				}
				else
					ADD_FORMATEX("\r%d. \d%l \y*^n", item + 1, data[SelectWeapon_Name]);
			}
			case SLOT_GRENADE1, SLOT_GRENADE2, SLOT_GRENADE3:
			{
				if (g_iSlotWeapon[id][select] != index)
					ADD_FORMATEX("\r%d. \w%l^n", item + 1, data[SelectWeapon_Name]);
				else
				{
					if (select == SLOT_GRENADE1)
						grenadeNum = 1;
					else if (select == SLOT_GRENADE2)
						grenadeNum = 2;
					else if (select == SLOT_GRENADE3)
						grenadeNum = 3;

					ADD_FORMATEX("\r%d. \w%l \y(%d)^n", item + 1, data[SelectWeapon_Name], grenadeNum);
				}

				keys |= (1<<item);
			}
			default:
			{
				if (g_iSlotWeapon[id][select] != index)
					ADD_FORMATEX("\r%d. \w%l^n", item + 1, data[SelectWeapon_Name]);
				else
					ADD_FORMATEX("\r%d. \w%l \y*^n", item + 1, data[SelectWeapon_Name]);

				keys |= (1<<item);
			}
		}

		item++;
	}

	if (!singlePage)
	{
		for (i = item; i < SECTION_MAX_PAGE_ITEMS; i++)
			ADD_FORMATEX("^n");

		if (end < itemNum)
		{
			ADD_FORMATEX("^n\r8. \w%l", "RZ_NEXT");
			keys |= MENU_KEY_8;
		}
		else if (g_iMenuPage[id])
			ADD_FORMATEX("^n\d8. %l", "RZ_NEXT");
	}

	ADD_FORMATEX("^n\r9. \w%l^n", "RZ_BACK");
	keys |= MENU_KEY_9;

	ADD_FORMATEX("^n\r0. \w%l", "RZ_CLOSE");
	keys |= MENU_KEY_0;

	show_menu(id, keys, text, -1, SECTION_MENU_ID);
}

@HandleMenu_Section(id, key)
{
    if (key == 9) // Voltar ao menu principal
    {
        MainMenu_Show(id);
        return PLUGIN_HANDLED;
    }

    new section = g_iMenuSection[id];
    new itemNum = ArraySize(g_aMenuItems[id]);

    if (itemNum > SECTION_MAX_PAGE_ITEMS && key == 8) // Próxima página
    {
        SectionMenu_Show(id, section, ++g_iMenuPage[id]);
        return PLUGIN_HANDLED;
    }

    if (key == 7 && g_iMenuPage[id] > 0) // Página anterior
    {
        SectionMenu_Show(id, section, --g_iMenuPage[id]);
        return PLUGIN_HANDLED;
    }

    // Recupera o índice do item selecionado
    new index = ArrayGetCell(g_aMenuItems[id], g_iMenuPage[id] * SECTION_MAX_PAGE_ITEMS + key);
    new data[SelectWeaponsData];
    ArrayGetArray(g_aSelectWeapons, index, data);

    // Mapear o slot correspondente para a seção
    new select = MapSectionToSelect(section, index);

    // Entregar a arma imediatamente
    if (data[SelectWeapon_IsCustom])
    {
        rg_give_custom_item(id, data[SelectWeapon_Reference], GT_APPEND, data[SelectWeapon_CustomId]);
    }
    else
    {
        rg_give_item(id, data[SelectWeapon_Reference], GT_APPEND);
    }

    // Atualizar o slot para refletir a seleção
    g_iSlotWeapon[id][select] = index;

    // Retornar ao menu principal
    MainMenu_Show(id);

    return PLUGIN_HANDLED;
}

@Task_ShowMenu(id)
{
	new player = id;

	if (!is_user_connected(player))
	{
		remove_task(id);
		return;
	}

	if (!rz_game_is_warmup())
	{
		g_iMenuTimer[player]--;
	}

	new menu, keys;
	get_user_menu(player, menu, keys);

	if (!is_user_alive(player) || rz_player_get(player, RZ_PLAYER_CLASS) != g_iClass_Human ||
		g_bWeaponsGiven[player] || g_iMenuTimer[player] <= 0)
	{
		remove_task(id);

		if (menu == g_iMenu_Main || menu == g_iMenu_Section)
			MENU_CLOSER(player);

		return;
	}

	if (menu == g_iMenu_Main)
		MainMenu_Show(player);
	else if (menu == g_iMenu_Section)
		SectionMenu_Show(player, g_iMenuSection[player], g_iMenuPage[player]);
}

MapSectionToSelect(section, item)
{
    switch (section)
    {
        case SECTION_PISTOL: return SLOT_SECONDARY;
        case SECTION_PRIMARY: return SLOT_PRIMARY;
        case SECTION_EQUIPMENT:
        {
            new data[SelectWeaponsData];
            ArrayGetArray(g_aSelectWeapons, item, data);

            if (equal(data[SelectWeapon_Reference][7], "hegrenade"))
                return SLOT_GRENADE1;
            else if (equal(data[SelectWeapon_Reference][7], "flashbang"))
                return SLOT_GRENADE2;
            else if (equal(data[SelectWeapon_Reference][7], "smokegrenade"))
                return SLOT_GRENADE3;
        }
        case SECTION_KNIFE: return SLOT_KNIFE;
    }

    return -1;
}


AddWeapons()
{
    // Pistolas
    AddWeapon(SECTION_PISTOL, "weapon_glock18");
    AddWeapon(SECTION_PISTOL, "weapon_usp");
    AddWeapon(SECTION_PISTOL, "weapon_p228");
    g_iDefaultWeapons[SLOT_SECONDARY] = AddWeapon(SECTION_PISTOL, "weapon_deagle");
    AddWeapon(SECTION_PISTOL, "weapon_elite");
    AddWeapon(SECTION_PISTOL, "weapon_fiveseven");

    // Consolidado como PRIMARY
    AddWeapon(SECTION_PRIMARY, "weapon_m3");          // Shotgun
    AddWeapon(SECTION_PRIMARY, "weapon_xm1014");      // Shotgun
    AddWeapon(SECTION_PRIMARY, "weapon_mac10");       // SMG
    AddWeapon(SECTION_PRIMARY, "weapon_tmp");         // SMG
    AddWeapon(SECTION_PRIMARY, "weapon_mp5navy");     // SMG
    AddWeapon(SECTION_PRIMARY, "weapon_ump45");       // SMG
    AddWeapon(SECTION_PRIMARY, "weapon_p90");         // SMG
    AddWeapon(SECTION_PRIMARY, "weapon_galil");       // Rifle
    AddWeapon(SECTION_PRIMARY, "weapon_famas");       // Rifle
    AddWeapon(SECTION_PRIMARY, "weapon_ak47");        // Rifle
    g_iDefaultWeapons[SLOT_PRIMARY] = AddWeapon(SECTION_PRIMARY, "weapon_m4a1");
    AddWeapon(SECTION_PRIMARY, "weapon_sg552");       // Rifle
    AddWeapon(SECTION_PRIMARY, "weapon_aug");         // Rifle
    AddWeapon(SECTION_PRIMARY, "weapon_scout");       // Rifle
    // AddWeapon(SECTION_PRIMARY, "weapon_m249");     // Machinegun (opcional)

    // Equipamentos
    AddWeapon(SECTION_EQUIPMENT, "weapon_hegrenade");
    g_iDefaultWeapons[SLOT_GRENADE1] = AddWeapon(SECTION_EQUIPMENT, "grenade_fire");
    g_iDefaultWeapons[SLOT_GRENADE2] = AddWeapon(SECTION_EQUIPMENT, "grenade_frost");
    g_iDefaultWeapons[SLOT_GRENADE3] = AddWeapon(SECTION_EQUIPMENT, "grenade_flare");

    // Facas
    g_iDefaultWeapons[SLOT_KNIFE] = AddWeapon(SECTION_KNIFE, "weapon_knife");
}

AddWeapon(section, const handle[])
{
	new WeaponIdType:weaponId = any:rz_weapons_default_find(handle);
	new bool:found;
	new data[SelectWeaponsData];

	if (weaponId)
	{
		copy(data[SelectWeapon_Reference], charsmax(data[SelectWeapon_Reference]), handle);
		rz_weapon_default_get(weaponId, RZ_DEFAULT_WEAPON_NAME, data[SelectWeapon_Name], charsmax(data[SelectWeapon_Name]));
		rz_weapon_default_get(weaponId, RZ_DEFAULT_WEAPON_SHORT_NAME, data[SelectWeapon_ShortName], charsmax(data[SelectWeapon_ShortName]));

		found = true;
	}

	if (!found)
	{
		new weapon;

		switch (section)
		{
			case SECTION_EQUIPMENT:
			{
				weapon = rz_grenades_find(handle);

				if (weapon)
				{
					get_grenade_var(weapon, RZ_GRENADE_REFERENCE, data[SelectWeapon_Reference], charsmax(data[SelectWeapon_Reference]));
					get_grenade_var(weapon, RZ_GRENADE_NAME, data[SelectWeapon_Name], charsmax(data[SelectWeapon_Name]));
					get_grenade_var(weapon, RZ_GRENADE_SHORT_NAME, data[SelectWeapon_ShortName], charsmax(data[SelectWeapon_ShortName]));

					found = true;
				}
			}
			case SECTION_KNIFE:
			{
				weapon = rz_knifes_find(handle);

				if (weapon)
				{
					copy(data[SelectWeapon_Reference], charsmax(data[SelectWeapon_Reference]), "weapon_knife");
					get_knife_var(weapon, RZ_KNIFE_NAME, data[SelectWeapon_Name], charsmax(data[SelectWeapon_Name]));
					get_knife_var(weapon, RZ_KNIFE_SHORT_NAME, data[SelectWeapon_ShortName], charsmax(data[SelectWeapon_ShortName]));

					found = true;
				}
			}
			default:
			{
				weapon = rz_weapons_find(handle);

				if (weapon)
				{
					get_weapon_var(weapon, RZ_WEAPON_REFERENCE, data[SelectWeapon_Reference], charsmax(data[SelectWeapon_Reference]));
					get_weapon_var(weapon, RZ_WEAPON_NAME, data[SelectWeapon_Name], charsmax(data[SelectWeapon_Name]));
					get_weapon_var(weapon, RZ_WEAPON_SHORT_NAME, data[SelectWeapon_ShortName], charsmax(data[SelectWeapon_ShortName]));

					found = true;
				}
			}
		}

		data[SelectWeapon_IsCustom] = true;
		data[SelectWeapon_CustomId] = weapon;
	}

	if (!found)
	{
		log_amx("Weapon, knife or grenade '%s' not found", handle);
		return -1;
	}

	data[SelectWeapon_Section] = section;
	g_bSectionAvailable[section] = true;

	return ArrayPushArray(g_aSelectWeapons, data);
}
