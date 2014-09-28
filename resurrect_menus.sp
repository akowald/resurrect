/**
 * ==============================================================================
 * Resurrection - Arena Team Fortress 2 Mod
 * Copyright (C) 2014 Alex Kowald
 * ==============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

 // Do NOT compile this file alone. Compile resurrect.sp instead.

#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <adminmenu>
#define REQUIRE_PLUGIN

#define SOUND_VOTE_STARTED	"ui/vote_started.wav"
#define SOUND_VOTE_PASSED	"ui/vote_success.wav"
#define SOUND_VOTE_FAILED	"ui/vote_failure.wav"

#define MENU_VOTE_STAYTIME	15

#define LIBRARY_ADMINMENU 	"adminmenu"

new bool:g_bVoteInProgress;
new g_iTimeLastVote;

new Handle:g_hAdminMenu;

bool:Vote_Create(client=-1)
{
	if(IsVoteInProgress() || g_bVoteInProgress)
	{
		if(client != -1) PrintToChat(client, "%s %T", PLUGIN_PREFIX, "Res_Vote_InProgress", LANG_SERVER);
		return false;
	}

	new Handle:hMenu = CreateMenu(MenuHandler_Enabled);

	decl String:strYes[32];
	decl String:strNo[32];
	Format(strYes, sizeof(strYes), "%T", "Res_Vote_Yes", LANG_SERVER);
	Format(strNo, sizeof(strNo), "%T", "Res_Vote_No", LANG_SERVER);

	decl String:strState[32];
	if(GetConVarBool(g_hCvarEnabled))
	{
		Format(strState, sizeof(strState), "%T", "Res_Vote_Off", LANG_SERVER);
	}else{
		Format(strState, sizeof(strState), "%T", "Res_Vote_On", LANG_SERVER);
	}

	SetMenuTitle(hMenu, "%T", "Res_Vote_Title", LANG_SERVER, strState);
	SetVoteResultCallback(hMenu, VoteHandler_Enabled);

	AddMenuItem(hMenu, "", "", ITEMDRAW_NOTEXT);
	AddMenuItem(hMenu, "", "", ITEMDRAW_NOTEXT);
	AddMenuItem(hMenu, "", "", ITEMDRAW_NOTEXT);
	AddMenuItem(hMenu, "", "", ITEMDRAW_NOTEXT);

	AddMenuItem(hMenu, "yes", strYes);
	AddMenuItem(hMenu, "no", strNo);

	SetMenuExitButton(hMenu, true);

	if(VoteMenuToAll(hMenu, MENU_VOTE_STAYTIME))
	{
		g_bVoteInProgress = true;
		g_iTimeLastVote = GetTime();
		for(new i=0; i<MAXPLAYERS+1; i++) g_bDemocracy[i] = false;

		EmitSoundToAll(SOUND_VOTE_STARTED);

		if(client >= 1 && client <= MaxClients && IsClientInGame(client))
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "Res_Chat_VoteStarted", LANG_SERVER, g_strTeamColors[GetClientTeam(client)], client, 0x01, 0x04, strState, 0x01);
		}

		return true;
	}

	return false;
}

public MenuHandler_Enabled(Handle:hMenu, MenuAction:action, param1, param2)
{
	//PrintToServer("(MenuHandler_Enabled) action: %d!", _:action);

	if(action == MenuAction_VoteCancel)
	{
		// Vote was cancelled or received 0 votes
		EmitSoundToAll(SOUND_VOTE_FAILED);

		PrintToChatAll("%s %T", PLUGIN_PREFIX, "Res_Vote_Cancelled", LANG_SERVER, g_strTeamColors[TFTeam_Red], 0x01);
	}else if(action == MenuAction_End)
	{
		g_bVoteInProgress = false;

		CloseHandle(hMenu);
	}
}

public VoteHandler_Enabled(Handle:menu, num_votes, num_clients, const client_info[][2], num_items, const item_info[][2])
{
	// Received one or more votes so calculate the winner
	
	new iVotesYes;
	new iVotesNo;

	for(new i=0; i<num_items; i++)
	{
		decl String:strInfo[16];
		GetMenuItem(menu, item_info[i][VOTEINFO_ITEM_INDEX], strInfo, sizeof(strInfo));

		if(strcmp(strInfo, "yes") == 0)
		{
			iVotesYes += item_info[i][VOTEINFO_ITEM_VOTES];
		}else if(strcmp(strInfo, "no") == 0)
		{
			iVotesNo += item_info[i][VOTEINFO_ITEM_VOTES];
		}
	}

	new iVotesTotal = iVotesYes + iVotesNo; // probably the same as num_votes
	new Float:flPercentFor = float(iVotesYes) / float(iVotesTotal);

#if defined DEBUG
	PrintToServer("(VoteHandler_Enabled) Yes: %d No: %d (%d%%)", iVotesYes, iVotesNo, RoundToNearest(flPercentFor * 100.0));
#endif

	if(flPercentFor >= GetConVarFloat(g_hCvarVotePercent))
	{
		EmitSoundToAll(SOUND_VOTE_PASSED);

		PrintToChatAll("%s %T", PLUGIN_PREFIX, "Res_Chat_VotePassed", LANG_SERVER, 0x04, 0x01, 0x04, RoundToNearest(flPercentFor * 100.0), 0x01, RoundToNearest(GetConVarFloat(g_hCvarVotePercent) * 100.0));

		// Toggle the value of resurrect_enabled
		if(GetConVarBool(g_hCvarEnabled))
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "Res_Chat_Passed_No", LANG_SERVER, g_strTeamColors[TFTeam_Red], 0x01);

			SetConVarBool(g_hCvarEnabled, false);
		}else{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "Res_Chat_Passed_Yes", LANG_SERVER, 0x04, 0x01);

			SetConVarBool(g_hCvarEnabled, true);
		}
	}else{
		EmitSoundToAll(SOUND_VOTE_FAILED);

		PrintToChatAll("%s %T", PLUGIN_PREFIX, "Res_Chat_VoteFailed", LANG_SERVER, g_strTeamColors[TFTeam_Red], 0x01, g_strTeamColors[TFTeam_Red], RoundToNearest(flPercentFor * 100.0), 0x01, RoundToNearest(GetConVarFloat(g_hCvarVotePercent) * 100.0));
	}
}

public CVarChanged_Enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// If the enabled cvar has changed during a vote, abort the vote
	if(IsVoteInProgress() && g_bVoteInProgress)
	{
		PrintToChatAll("%s %T", PLUGIN_PREFIX, "Res_Vote_Cancelled_Changed", LANG_SERVER, newValue);

		CancelVote();
	}

	// If the state is changed manually before an automatic vote, stop the pending vote
	Timer_KillVote();

	// Reset any RTV progress
	for(new i=0; i<MAXPLAYERS+1; i++) g_bDemocracy[i] = false;
	g_iTimeLastVote = GetTime();
}

AdminMenu_Init()
{
	new Handle:hTopMenu;
	if(LibraryExists(LIBRARY_ADMINMENU) && ((hTopMenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		AdminMenu_OnAdminMenuReady(hTopMenu);
	}
}

AdminMenu_OnAdminMenuReady(Handle:hTopMenu)
{
	if(hTopMenu == g_hAdminMenu) return;

	g_hAdminMenu = hTopMenu;

	// Add an item under Server Commands to toggle resurrection mode
	new TopMenuObject:serverCommands = FindTopMenuCategory(g_hAdminMenu, ADMINMENU_SERVERCOMMANDS);
	if(serverCommands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(g_hAdminMenu, "resurrect_toggle", TopMenuObject_Item, AdminMenu_Toggle, serverCommands, "resurrect_toggle", ADMFLAG_GENERIC);
	}

	// Add an item under Voting Commands to start a resurrection vote
	new TopMenuObject:votingCommands = FindTopMenuCategory(g_hAdminMenu, ADMINMENU_VOTINGCOMMANDS);
	if(votingCommands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(g_hAdminMenu, "resurrect_vote", TopMenuObject_Item, AdminMenu_Vote, votingCommands, "resurrect_vote", ADMFLAG_VOTE);
	}
}

public AdminMenu_Toggle(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		decl String:strState[16];
		if(GetConVarBool(g_hCvarEnabled))
		{
			Format(strState, sizeof(strState), "%T", "Res_Vote_Off", LANG_SERVER);
		}else{
			Format(strState, sizeof(strState), "%T", "Res_Vote_On", LANG_SERVER);
		}

		Format(buffer, maxlength, "%T", "Res_Admin_Toggle", LANG_SERVER, strState);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		Command_Toggle(param, 0);
	}
}

public AdminMenu_Vote(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		decl String:strState[16];
		if(GetConVarBool(g_hCvarEnabled))
		{
			Format(strState, sizeof(strState), "%T", "Res_Vote_Off", LANG_SERVER);
		}else{
			Format(strState, sizeof(strState), "%T", "Res_Vote_On", LANG_SERVER);
		}

		Format(buffer, maxlength, "%T", "Res_Admin_Toggle", LANG_SERVER, strState);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		Command_Vote(param, 0);
	}
}