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
#include <nativevotes>
#define REQUIRE_PLUGIN

#define LIBRARY_NATIVEVOTES "nativevotes"

new bool:g_bNativeVotes = false;

public OnAllPluginsLoaded()
{
	g_bNativeVotes = LibraryExists(LIBRARY_NATIVEVOTES);
}

public OnLibraryAdded(const String:name[])
{
	if(strcmp(name, LIBRARY_NATIVEVOTES) == 0)
	{
		g_bNativeVotes = true;
	}
}

public OnLibraryRemoved(const String:name[])
{
	if(strcmp(name, LIBRARY_NATIVEVOTES) == 0)
	{
		g_bNativeVotes = false;
	}
}

Vote_Create(client)
{
	if(IsVoteInProgress())
	{
		PrintToChat(client, "%s Failed to start vote: Vote in progress!", PLUGIN_PREFIX);
		return;
	}

	// See if native votes is available, if not, fall back on sourcemod votes.
	new Handle:hMenu;
	if(g_bNativeVotes)
	{
		if(NativeVotes_IsVoteInProgress())
		{
			PrintToChat(client, "%s Failed to start vote: Vote in progress!", PLUGIN_PREFIX);
			return;
		}

		if(NativeVotes_CheckVoteDelay() != 0)
		{
			PrintToChat(client, "%s Failed to start vote: Wait %d seconds!", PLUGIN_PREFIX, NativeVotes_CheckVoteDelay());
			return;			
		}

		hMenu = NativeVotes_Create(MenuHandler_Vote, NativeVotesType_Custom_YesNo, NATIVEVOTES_ACTIONS_DEFAULT);
		NativeVotes_SetTitle(hMenu, "Turn on Resurrection Mode?");
		NativeVotes_SetResultCallback(hMenu, Handler_NV_VoteFinishedGeneric);
		NativeVotes_DisplayToAll(hMenu, 20);
	}
}

public MenuHandler_Vote(Handle:hMenu, MenuAction:action, client, menu_item)
{
	PrintToServer("(MenuHandler_Vote) action: %d!", _:action);

	if(action == MenuAction_Select)
	{

	}else if(action == MenuAction_VoteCancel)
	{
		PrintToServer("(MenuHandler_Vote) VoteCancel");

		NativeVotes_DisplayFail(hMenu, NativeVotesFail_Generic);
	}else if(action == MenuAction_End)
	{
		if(g_bNativeVotes)
		{
			NativeVotes_Close(hMenu);
		}else{
			CloseHandle(hMenu);
		}
	}
}

public Handler_NV_VoteFinishedGeneric(Handle:menu,
						   num_votes, 
						   num_clients,
						   const client_indexes[],
						   const client_votes[],
						   num_items,
						   const item_indexes[],
						   const item_votes[])
{
	new client_info[num_clients][2];
	new item_info[num_items][2];
	
	NativeVotes_FixResults(num_clients, client_indexes, client_votes, num_items, item_indexes, item_votes, client_info, item_info);
	Handler_VoteFinishedGeneric(menu, num_votes, num_clients, client_info, num_items, item_info);
}

public Handler_VoteFinishedGeneric(Handle:menu,
						   num_votes, 
						   num_clients,
						   const client_info[][2], 
						   num_items,
						   const item_info[][2])
{
}