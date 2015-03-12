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

#pragma semicolon 1
#define RES_MAIN_PLUGIN

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>

//#define DEBUG
#define PLUGIN_VERSION 					"0.7"
#define PLUGIN_PREFIX					"\x07F0E68CRes>\x01"

#define SOUND_REVIVE					"mvm/mvm_revive.wav"
#define SOUND_WARN 						"misc/doomsday_lift_warning.wav"
#define SOUND_MARKED 					"weapons/samurai/tf_marked_for_death_indicator.wav"
#define SOUND_LAST_RITES 				"misc/killstreak.wav"
#define SOUND_REVIVED_ALL 				"ui/itemcrate_smash_ultrarare_short.wav"

#define CAPHUD_PARITY_BITS				6
#define CAPHUD_PARITY_MASK				((1<<CAPHUD_PARITY_BITS)-1)

#define TIMER_STARTED_AUTO 				0
#define TIMER_STARTED_NOMINATED 		1

#define ArenaRoundState_RoundRunning 	7
#define TFTeam_Red						2
#define TFTeam_Blue						3

new const String:g_strReviveDemo[][] = {"vo/demoman_mvm_resurrect01.mp3", "vo/demoman_mvm_resurrect02.mp3", "vo/demoman_mvm_resurrect03.mp3", "vo/demoman_mvm_resurrect05.mp3", "vo/demoman_mvm_resurrect06.mp3", "vo/demoman_mvm_resurrect07.mp3", "vo/demoman_mvm_resurrect08.mp3", "vo/demoman_mvm_resurrect09.mp3", "vo/demoman_mvm_resurrect10.mp3", "vo/demoman_mvm_resurrect11.mp3"};
new const String:g_strReviveEngie[][] = {"vo/engineer_mvm_resurrect01.mp3", "vo/engineer_mvm_resurrect02.mp3", "vo/engineer_mvm_resurrect03.mp3"};
new const String:g_strReviveHeavy[][] = {"vo/heavy_mvm_resurrect01.mp3", "vo/heavy_mvm_resurrect02.mp3", "vo/heavy_mvm_resurrect04.mp3", "vo/heavy_mvm_resurrect05.mp3", "vo/heavy_mvm_resurrect06.mp3", "vo/heavy_mvm_resurrect07.mp3"};
new const String:g_strReviveMedic[][] = {"vo/medic_mvm_resurrect01.mp3", "vo/medic_mvm_resurrect02.mp3", "vo/medic_mvm_resurrect03.mp3"};
new const String:g_strReviveScout[][] = {"vo/scout_mvm_resurrect01.mp3", "vo/scout_mvm_resurrect02.mp3", "vo/scout_mvm_resurrect03.mp3", "vo/scout_mvm_resurrect04.mp3", "vo/scout_mvm_resurrect05.mp3", "vo/scout_mvm_resurrect06.mp3", "vo/scout_mvm_resurrect07.mp3", "vo/scout_mvm_resurrect08.mp3"};
new const String:g_strReviveSniper[][] = {"vo/sniper_mvm_resurrect01.mp3", "vo/sniper_mvm_resurrect02.mp3", "vo/sniper_mvm_resurrect03.mp3"};
new const String:g_strReviveSoldier[][] = {"vo/soldier_mvm_resurrect01.mp3", "vo/soldier_mvm_resurrect02.mp3", "vo/soldier_mvm_resurrect03.mp3", "vo/soldier_mvm_resurrect04.mp3", "vo/soldier_mvm_resurrect05.mp3", "vo/soldier_mvm_resurrect06.mp3"};
new const String:g_strReviveSpy[][] = {"vo/spy_mvm_resurrect01.mp3", "vo/spy_mvm_resurrect02.mp3", "vo/spy_mvm_resurrect03.mp3", "vo/spy_mvm_resurrect04.mp3", "vo/spy_mvm_resurrect05.mp3", "vo/spy_mvm_resurrect06.mp3", "vo/spy_mvm_resurrect07.mp3", "vo/spy_mvm_resurrect08.mp3", "vo/spy_mvm_resurrect09.mp3"};
new const String:g_strRevivePyro[][] = {"vo/pyro_sf13_spell_generic01.mp3", "vo/pyro_autocappedcontrolpoint01.mp3"};
new const String:g_strSoundMarked[][] = {"weapons/samurai/tf_marked_for_death_impact_01.wav", "weapons/samurai/tf_marked_for_death_impact_02.wav", "weapons/samurai/tf_marked_for_death_impact_03.wav"};

new const String:g_strSoundLastMan[][] = {"vo/announcer_am_lastmanalive01.mp3", "vo/announcer_am_lastmanalive02.mp3", "vo/announcer_am_lastmanalive03.mp3", "vo/announcer_am_lastmanalive04.mp3"};
new const String:g_strSoundForfeit[][] = {"vo/announcer_am_lastmanforfeit01.mp3", "vo/announcer_am_lastmanforfeit02.mp3", "vo/announcer_am_lastmanforfeit03.mp3", "vo/announcer_am_lastmanforfeit04.mp3"};

new const String:g_strTeamColors[][] = {"\x07B2B2B2", "\x07B2B2B2", "\x07FF4040", "\x0799CCFF"};

new bool:g_bIsArena;
new bool:g_bEnabledForRound = false;
new bool:g_bPlayOnce[MAXPLAYERS+1];
new Handle:g_hTimerVote;
new bool:g_bDemocracy[MAXPLAYERS+1];
new bool:g_bPlayAnnouncer;

new g_iRefCaptureArea;
new g_iRefObj;
new g_iRefTimer;
new g_iRefControlPoint;

new Handle:g_hCvarEnabled;
new Handle:g_hCvarTimeUnlock;
new Handle:g_hCvarTimeMFD;
new Handle:g_hCvarTimeImmunity;
new Handle:g_hCvarTimeTurtle;
new Handle:g_hCvarCapMid;
new Handle:g_hCvarCapMin;
new Handle:g_hCvarCapMax;
new Handle:g_hCvarHealthBonus;
new Handle:g_hCvarVotePercent;
new Handle:g_hCvarAutoStart;
new Handle:g_hCvarAutoAction;
new Handle:g_hCvarDemoAction;
new Handle:g_hCvarDemoCooldown;
new Handle:g_hCvarDemoTreshold;
new Handle:g_hCvarDemoMinPlayers;
new Handle:g_hCvarAnnouncer;
new Handle:g_hCvarLastRites;
new Handle:g_hCvarLastRitesDuration;
new Handle:g_hCvarFirstBlood;
new Handle:g_hCvarMapHack;

new Handle:g_hCvarArenaRoundTime;
new Handle:g_hCvarArenaFirstBlood;

enum eMapHack
{
	MapHack_None=0,
	MapHack_HardHat,
	MapHack_Arakawa,
	MapHack_BlackwoodValley,
	MapHack_Ferrous
};
new eMapHack:g_nMapHack;

enum eActionState
{
	Action_VoteNone=0,
	Action_VoteOn,
	Action_VoteOff,
	Action_VoteBoth
};

#include "resurrect_menus.sp"

public Plugin:myinfo = 
{
	name = "Resurrection",
	author = "linux_lover (abkowald@gmail.com)",
	description = "Teammates come back to life when the control point is captured.",
	version = PLUGIN_VERSION,
	url = "TF2Randomizer.com"
};

public OnPluginStart()
{
	CreateConVar("resurrect_version", PLUGIN_VERSION, "Resurrection Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_hCvarEnabled = CreateConVar("resurrect_enabled", "1", "0/1 - Enable or disable the plugin.");
	g_hCvarTimeUnlock = CreateConVar("resurrect_time_unlock", "15", "Seconds until the control point unlocks and players can cap.");
	g_hCvarTimeMFD = CreateConVar("resurrect_time_mfd", "5.0", "Seconds after leaving a control point that mark for death effects remain on the player.");
	g_hCvarTimeImmunity = CreateConVar("resurrect_time_immunity", "3.0", "Seconds of immunity after being resurrected.");
	g_hCvarTimeTurtle = CreateConVar("resurrect_time_turtle", "81", "If a control point is held for this many seconds, the game ends. This prevents camping and turtling by C/D spies or engineers.");
	g_hCvarHealthBonus = CreateConVar("resurrect_health_bonus", "4.0", "Seconds of health bonus when capturing with no teammates. Set to 0.0 to disable.");
	g_hCvarVotePercent = CreateConVar("resurrect_vote_percentage", "0.5", "Percentage of votes needed in order for a vote to pass.", _, true, 0.0, true, 1.0);
	g_hCvarAnnouncer = CreateConVar("resurrect_announcer", "0", "Number of players required when the round starts to play 'last man standing' or 'disappointment' announcer sounds. Set to a high number (64) to disable.");
	g_hCvarLastRites = CreateConVar("resurrect_lastrites", "2", "Number of MORE players on the opposite team to activate last rites. Set to a high number (64) to disable last rites.");
	g_hCvarLastRitesDuration = CreateConVar("resurrect_lastrites_duration", "5.0", "Seconds of minicrits awarded for the last rite effect.");
	g_hCvarFirstBlood = CreateConVar("resurrect_firstblood", "-1", "Number of players required for first blood. -1 will do nothing.");
	g_hCvarMapHack = CreateConVar("resurrect_maphack", "1", "0/1 - Enable or disable changes to the map to support resurrection mode.");

	g_hCvarAutoStart = CreateConVar("resurrect_auto_start", "2.0", "Minutes after a map starts to launch a vote to toggle resurrection mode.");
	g_hCvarAutoAction = CreateConVar("resurrect_auto_action", "0", "0 - do not start automatic votes | 1 - only start votes to turn ON | 2 - only start votes to turn OFF | 3 - both");
	
	g_hCvarDemoAction = CreateConVar("resurrect_democracy_action", "0", "0 - do not allow players to vote | 1 - allow players to vote ON | 2 - allow players to vote OFF | 3 - allow both");
	g_hCvarDemoTreshold = CreateConVar("resurrect_democracy_treshold", "0.3", "Percentage of players needed to type !res in order to start a vote.");
	g_hCvarDemoCooldown = CreateConVar("resurrect_democracy_cooldown", "300", "Cooldown in seconds between voting to change resurrection mode.");
	g_hCvarDemoMinPlayers = CreateConVar("resurrect_democracy_minplayers", "3", "Minimum players on the server in order for players to start a vote.");

	g_hCvarCapMin = CreateConVar("resurrect_cap_min", "0.25", "Minimum capture time when one team has fewer alive players.");
	g_hCvarCapMid = CreateConVar("resurrect_cap_mid", "0.7", "Medium capture time when both teams have the same amount of alive players.");
	g_hCvarCapMax = CreateConVar("resurrect_cap_max", "2.0", "Maximum capture time when one team has more alive players.");

	g_hCvarArenaRoundTime = FindConVar("tf_arena_round_time");
	g_hCvarArenaFirstBlood = FindConVar("tf_arena_first_blood");

	Resurrect_StripNotifyFlag(g_hCvarArenaRoundTime, true);

	HookConVarChange(g_hCvarEnabled, CVarChanged_Enabled);
	HookConVarChange(g_hCvarMapHack, CVarChanged_MapHack);

	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("arena_round_start", Event_RoundActive);
	HookEvent("teamplay_point_captured", Event_PointCaptured);
	HookEvent("server_cvar", Event_Cvar, EventHookMode_Pre);
	HookEvent("teamplay_round_win", Event_RoundWin);
	HookEvent("player_death", Event_PlayerDeath);

	RegAdminCmd("resurrect_test", Command_Test, ADMFLAG_ROOT);
	RegAdminCmd("resurrect_toggle", Command_Toggle, ADMFLAG_GENERIC);
	RegAdminCmd("resurrect_vote", Command_Vote, ADMFLAG_VOTE);

	HookEntityOutput("tf_logic_arena", "OnCapEnabled", Logic_OnCapEnabled);

	LoadTranslations("resurrect.phrases");
}

public OnAllPluginsLoaded()
{
	AdminMenu_Init();
}

public OnLibraryAdded(const String:name[])
{
	if(strcmp(name, LIBRARY_ADMINMENU))
	{
		AdminMenu_Init();
	}
}

public OnLibraryRemoved(const String:name[])
{
	if(strcmp(name, LIBRARY_ADMINMENU) == 0)
	{
		g_hAdminMenu = INVALID_HANDLE;
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], error_max)
{
	CreateNative("Resurrect_Enable", Native_Enable);
	CreateNative("Resurrect_IsRunning", Native_IsRunning);
	
	RegPluginLibrary("resurrect");
	
	return APLRes_Success;
}

Resurrect_StripNotifyFlag(Handle:hCvar, bool:bStrip)
{
	new iFlags = GetConVarFlags(hCvar);
	if(bStrip)
	{
		iFlags &= ~FCVAR_NOTIFY;
	}else{
		iFlags &= FCVAR_NOTIFY;
	}
	SetConVarFlags(hCvar, iFlags);
}

public OnPluginEnd()
{
	Entity_Cleanup();

	// Fix the tf_arena_round_time cvar and notify the players
	Resurrect_StripNotifyFlag(g_hCvarArenaRoundTime, false);
	decl String:strValue[32];
	GetConVarString(g_hCvarArenaRoundTime, strValue, sizeof(strValue));
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i)) SendConVarValue(i, g_hCvarArenaRoundTime, strValue);
	}
}

public OnMapStart()
{
	g_bEnabledForRound = false;
	g_bVoteInProgress = false;
	for(new i=0; i<MAXPLAYERS+1; i++) 

	Entity_Cleanup();

	decl String:strMap[64];
	GetCurrentMap(strMap, sizeof(strMap));
	g_bIsArena = (strncmp(strMap, "arena_", 6) == 0);

	Resurrect_LoadResources();
}

MapHack_Init()
{
	g_nMapHack = MapHack_None;

	decl String:strMap[64];
	GetCurrentMap(strMap, sizeof(strMap));
	if(GetConVarBool(g_hCvarMapHack))
	{
		if(strncmp(strMap, "arena_hardhat", 13) == 0)
		{
			g_nMapHack = MapHack_HardHat;
		}else if(strncmp(strMap, "arena_arakawa", 13) == 0)
		{
			g_nMapHack = MapHack_Arakawa;
		}else if(strcmp(strMap, "arena_blackwood_valley") == 0)
		{
			g_nMapHack = MapHack_BlackwoodValley;
		}else if(strncmp(strMap, "arena_ferrous", 13) == 0)
		{
			g_nMapHack = MapHack_Ferrous;
		}
	}	
}

public OnMapEnd()
{
	Timer_KillVote();
}

public OnConfigsExecuted()
{
	MapHack_Init();

	Timer_KillVote();

	if(g_bIsArena)
	{
		new bool:bStartTimer = false;
		switch(eActionState:GetConVarInt(g_hCvarAutoAction))
		{
			case Action_VoteOn:
			{
				if(!GetConVarBool(g_hCvarEnabled))
				{
					bStartTimer = true;
				}
			}
			case Action_VoteOff:
			{
				if(GetConVarBool(g_hCvarEnabled))
				{
					bStartTimer = true;
				}
			}
			case Action_VoteBoth: bStartTimer = true;
		}

		if(bStartTimer)
		{
			new Float:flDuration = GetConVarFloat(g_hCvarAutoStart);
			if(flDuration > 0.0) g_hTimerVote = CreateTimer(flDuration * 60.0, Timer_StartVote, TIMER_STARTED_AUTO, TIMER_REPEAT);
		}
	}
}

Resurrect_LoadResources()
{
	PrecacheSound(SOUND_REVIVE);
	PrecacheSound(SOUND_WARN);
	PrecacheSound(SOUND_MARKED);
	PrecacheSound(SOUND_LAST_RITES);
	PrecacheSound(SOUND_REVIVED_ALL);

	PrecacheSound(SOUND_VOTE_STARTED);
	PrecacheSound(SOUND_VOTE_PASSED);
	PrecacheSound(SOUND_VOTE_FAILED);

	for(new i=0; i<sizeof(g_strReviveDemo); i++) PrecacheSound(g_strReviveDemo[i]);
	for(new i=0; i<sizeof(g_strReviveEngie); i++) PrecacheSound(g_strReviveEngie[i]);
	for(new i=0; i<sizeof(g_strReviveHeavy); i++) PrecacheSound(g_strReviveHeavy[i]);
	for(new i=0; i<sizeof(g_strReviveMedic); i++) PrecacheSound(g_strReviveMedic[i]);
	for(new i=0; i<sizeof(g_strReviveScout); i++) PrecacheSound(g_strReviveScout[i]);
	for(new i=0; i<sizeof(g_strReviveSniper); i++) PrecacheSound(g_strReviveSniper[i]);
	for(new i=0; i<sizeof(g_strReviveSoldier); i++) PrecacheSound(g_strReviveSoldier[i]);
	for(new i=0; i<sizeof(g_strReviveSpy); i++) PrecacheSound(g_strReviveSpy[i]);
	for(new i=0; i<sizeof(g_strRevivePyro); i++) PrecacheSound(g_strRevivePyro[i]);
	for(new i=0; i<sizeof(g_strSoundMarked); i++) PrecacheSound(g_strSoundMarked[i]);

	for(new i=0; i<sizeof(g_strSoundLastMan); i++) PrecacheSound(g_strSoundLastMan[i]);
	for(new i=0; i<sizeof(g_strSoundForfeit); i++) PrecacheSound(g_strSoundForfeit[i]);
}

bool:Resurrect_IsEnabled()
{
	return g_bEnabledForRound;
}

bool:Resurrect_CanBeEnabled()
{
	return g_bIsArena && GetConVarBool(g_hCvarEnabled);
}

Resurrect_RefreshCvars()
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			SendConVarValue(i, g_hCvarArenaRoundTime, "9001");
		}
	}
}

public OnClientPostAdminCheck(client)
{
	if(!IsFakeClient(client)) SendConVarValue(client, g_hCvarArenaRoundTime, "9001");
}

public OnClientDisconnect(client)
{
	g_bDemocracy[client] = false;
}

public Event_RoundStart(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
#if defined DEBUG
	PrintToServer("(Event_RoundStart)");
#endif

	g_bEnabledForRound = false;
	if(!Resurrect_CanBeEnabled()) return;
	g_bEnabledForRound = true;

	Entity_Cleanup();
	for(new i=0; i<sizeof(g_bPlayOnce); i++) g_bPlayOnce[i] = false;
	Resurrect_RefreshCvars();

	// Determine whether or not to play 'last man standing' or 'disappoint' announcer lines for the next round
	g_bPlayAnnouncer = false;
	new iPlayerCount;
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) >= 2) iPlayerCount++;
	}
	if(iPlayerCount >= GetConVarInt(g_hCvarAnnouncer)) g_bPlayAnnouncer = true;

	// Determine whether or not to enable first blood crits
	new iNumFirstBlood = GetConVarInt(g_hCvarFirstBlood);
	if(iNumFirstBlood > 0)
	{
		if(iPlayerCount >= iNumFirstBlood)
		{
			SetConVarInt(g_hCvarArenaFirstBlood, 1);

			PrintToChatAll("%s %T", PLUGIN_PREFIX, "Res_Chat_FirstBlood", LANG_SERVER, 0x04, iNumFirstBlood, 0x01, 0x04, 0x01);
		}else{
			SetConVarInt(g_hCvarArenaFirstBlood, 0);
		}
	}

	// Disable the master control point so the game does not end when the player captures a control point
	new iMaster = FindEntityByClassname(MaxClients+1, "team_control_point_master");
	if(iMaster > MaxClients)
	{
#if defined DEBUG
		PrintToServer("(Event_RoundStart) Found team_control_point_master: %d!", iMaster);
#endif
		AcceptEntityInput(iMaster, "Disable");
	}

	// Find tf_objective_resource for later
	new iObjective = Entity_GetObj();
	if(iObjective <= MaxClients)
	{
		LogMessage("Failed to find \"tf_objective_resource\" entity!");

		new iNumControlPoints = GetEntProp(iObjective, Prop_Send, "m_iNumControlPoints");
		if(iNumControlPoints != 1)
		{
			LogMessage("Found %d control points, this could mean trouble!", iNumControlPoints);
		}
	}

	// Find the trigger_capture_area which controls capping time
	new iCaptureArea = MaxClients+1;
	while((iCaptureArea = FindEntityByClassname(iCaptureArea, "trigger_capture_area")) > MaxClients)
	{
		if(GetEntProp(iCaptureArea, Prop_Data, "m_bDisabled")) continue;

		decl String:strName[128];
		GetEntPropString(iCaptureArea, Prop_Data, "m_iszCapPointName", strName, sizeof(strName));

#if defined DEBUG
		PrintToServer("(Event_RoundStart) Found trigger_capture_area: %d area_cap_point: \"%s\"!", iCaptureArea, strName);
#endif
		g_iRefCaptureArea = EntIndexToEntRef(iCaptureArea);

		new iControlPoint = Entity_FindEntityByName(strName, "team_control_point");
		if(iControlPoint > MaxClients)
		{
#if defined DEBUG
			PrintToServer("(Event_RoundStart) Found team_control_point: %d!", iControlPoint);
#endif
			g_iRefControlPoint = EntIndexToEntRef(iControlPoint);
		}

		// Set the initial capturing time
		// Respawn time will be reset when the player begins capturing so this isn't that important
		Resurrect_SetCaptureTime(TFTeam_Red, GetConVarFloat(g_hCvarCapMax));
		Resurrect_SetCaptureTime(TFTeam_Blue, GetConVarFloat(g_hCvarCapMax));

		HookSingleEntityOutput(iCaptureArea, "OnStartTeam1", Area_StartCapture, false);
		HookSingleEntityOutput(iCaptureArea, "OnStartTeam2", Area_StartCapture, false);

		// Hook touch 
		SDKHook(iCaptureArea, SDKHook_Touch, Area_Touch);
		SDKHook(iCaptureArea, SDKHook_StartTouch, Area_StartTouch);
		//SDKHook(iCaptureArea, SDKHook_EndTouch, Area_EndTouch);
	}

	// Find tf_logic_arena and allow us to dynamically set when capture points are unlocked
	new iTimeUnlock = GetConVarInt(g_hCvarTimeUnlock);
	if(iTimeUnlock != -1)
	{
		new iLogic = FindEntityByClassname(MaxClients+1, "tf_logic_arena");
		if(iLogic > MaxClients)
		{
#if defined DEBUG
			PrintToServer("(Event_RoundStart) Found tf_logic_arena: %d!", iLogic);
#endif
			if(g_nMapHack == MapHack_Ferrous) iTimeUnlock = 40; // Map starts the train moving 40s after OnArenaRoundStart

			SetEntPropFloat(iLogic, Prop_Data, "m_flTimeToEnableCapPoint", float(iTimeUnlock));
		}
	}

	PrintToChatAll("%s \x0732CD32%T", PLUGIN_PREFIX, "Res_Chat_Description", LANG_SERVER, "\x07F0E68C");
}

public Action:Area_Touch(iCaptureArea, client)
{
	//PrintToServer("(Area_Touch) client: %d!", client);

	// Only apply marked for death effects while they are defending the control point
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
	{
		// Check if they own the control point they are standing on
		new iControlPoint = EntRefToEntIndex(g_iRefControlPoint);
		if(iControlPoint > MaxClients && GetEntProp(iControlPoint, Prop_Send, "m_iTeamNum") == GetClientTeam(client))
		{
			if(!TF2_IsPlayerInCondition(client, TFCond_MarkedForDeathSilent))
			{
				// They are touching the point and not marked yet (they probably just captured)
				Resurrect_HandleMarkedEffects(client);
			}

			TF2_AddCondition(client, TFCond_MarkedForDeathSilent, GetConVarFloat(g_hCvarTimeMFD));
		}

	}

	return Plugin_Continue;
}

public Area_StartTouch(iCaptureArea, client)
{
	//PrintToServer("(Area_StartTouch) client: %d!", client);

	// Play a sound to let the player know they might be marked for death
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
	{
		// Check if they own the control point they are standing on
		new iControlPoint = EntRefToEntIndex(g_iRefControlPoint);
		if(iControlPoint > MaxClients && GetEntProp(iControlPoint, Prop_Send, "m_iTeamNum") == GetClientTeam(client))
		{
			Resurrect_HandleMarkedEffects(client);
		}
	}
}

Resurrect_HandleMarkedEffects(client)
{
	// Play the long 4.0s marked sound only the first time the player becomes marked for death to get the idea across
	if(!g_bPlayOnce[client])
	{
		EmitSoundToClient(client, SOUND_MARKED);
		g_bPlayOnce[client] = true;
	}else{
		// This is a shorter 'punch' impact sound
		EmitSoundToClient(client, g_strSoundMarked[GetRandomInt(0, sizeof(g_strSoundMarked)-1)], _, _, _, _, 1.0);
	}
}

public Logic_OnCapEnabled(const String:output[], caller, activator, Float:delay)
{
#if defined DEBUG
	PrintToServer("(Logic_OnCapEnabled) caller: %d activator: %d!", output, caller, activator);
#endif

	if(!Resurrect_IsEnabled()) return;
	if(!Resurrect_IsInRound()) return;

	new Handle:hAnno = CreateEvent("show_annotation");
	if(hAnno != INVALID_HANDLE)
	{
		decl String:strText[100];
		Format(strText, sizeof(strText), "%T", "Res_Anno_PointUnlocked", LANG_SERVER);

		// Display a message at the control point making players aware of the objective
		new Float:flPos[3];

		new iCP = FindEntityByClassname(MaxClients+1, "team_control_point");
		if(iCP > MaxClients)
		{
			GetEntPropVector(iCP, Prop_Send, "m_vecOrigin", flPos);
		}

		SetEventFloat(hAnno, "worldPosX", flPos[0]);
		SetEventFloat(hAnno, "worldPosY", flPos[1]);
		SetEventFloat(hAnno, "worldPosZ", flPos[2]);

		SetEventInt(hAnno, "id", 0);
		SetEventFloat(hAnno, "lifetime", 3.0);
		SetEventString(hAnno, "text", strText);
		SetEventString(hAnno, "play_sound", "misc/null.wav");
		FireEvent(hAnno); // Frees the handle			
	}
}

public Area_StartCapture(const String:output[], caller, activator, Float:delay)
{
#if defined DEBUG
	PrintToServer("(Area_StartCapture) caller: %d activator: %d!", output, caller, activator);
#endif

	if(activator != EntRefToEntIndex(g_iRefCaptureArea)) return;

	if(!Resurrect_IsEnabled()) return;
	if(!Resurrect_IsInRound()) return;

	// Determine which team started capping by the name of the output
	new iTeam = (strcmp(output, "OnStartTeam2") == 0) ? TFTeam_Blue : TFTeam_Red;

	Resurrect_SetCaptureTime(iTeam, Resurrect_GetCaptureTime(iTeam));
}

Entity_GetObj()
{
	if(g_iRefObj != 0)
	{
		new iEntity = EntRefToEntIndex(g_iRefObj);
		if(iEntity > MaxClients) return iEntity;
	}

	new iEntity = FindEntityByClassname(MaxClients+1, "tf_objective_resource");
	if(iEntity > MaxClients)
	{
		g_iRefObj = EntIndexToEntRef(iEntity);
		return iEntity;
	}

	return 0;
}

Entity_GetTimer()
{
	Resurrect_RefreshCvars();

	if(g_iRefTimer != 0)
	{
		new iTimer = EntRefToEntIndex(g_iRefTimer);
		if(iTimer > MaxClients) return iTimer;
	}

	// Catch the tf_arena_round_timer should it be alive and hide it from view
	// We aren't going to disable it, just hide it so it should stalemate the round when time is up
	new iRoundTimer = MaxClients+1;
	while((iRoundTimer = FindEntityByClassname(iRoundTimer, "team_round_timer")) > MaxClients)
	{
		if(GetEntProp(iRoundTimer, Prop_Send, "m_bIsDisabled")) continue;

		SetVariantInt(0);
		AcceptEntityInput(iRoundTimer, "ShowInHUD");

		SetVariantInt(0);
		AcceptEntityInput(iRoundTimer, "AutoCountdown", iRoundTimer);
	}

	new iTimer = CreateEntityByName("team_round_timer");
	if(iTimer > MaxClients)
	{
		DispatchSpawn(iTimer);

		new iDuration = GetConVarInt(g_hCvarTimeTurtle);
		SetVariantInt(iDuration);
		AcceptEntityInput(iTimer, "SetMaxTime");
		SetVariantInt(iDuration);
		AcceptEntityInput(iTimer, "SetTime");

		SetVariantInt(1);
		AcceptEntityInput(iTimer, "ShowInHUD");

		SetVariantInt(1);
		AcceptEntityInput(iTimer, "AutoCountdown", iTimer);

		AcceptEntityInput(iTimer, "Enable");
		AcceptEntityInput(iTimer, "Resume");

		g_iRefTimer = EntIndexToEntRef(iTimer);

		HookSingleEntityOutput(iTimer, "OnFinished", Timer_OnFinished, true);

		return iTimer;
	}

	return 0;
}

Entity_Cleanup()
{
	Timer_Cleanup();
	g_iRefObj = 0;
	g_iRefCaptureArea = 0;
}

Timer_Cleanup()
{
	if(g_iRefTimer != 0)
	{
		new iTimer = EntRefToEntIndex(g_iRefTimer);
		if(iTimer > MaxClients)
		{
			AcceptEntityInput(iTimer, "Disable");
			AcceptEntityInput(iTimer, "Kill");
		}
		g_iRefTimer = 0;
	}
}

public Timer_OnFinished(const String:output[], caller, activator, Float:delay)
{
#if defined DEBUG
	PrintToServer("(Timer_OnFinished) caller: %d activator: %d", caller, activator);
#endif

	if(activator != EntRefToEntIndex(g_iRefTimer)) return;

	if(!Resurrect_IsEnabled()) return;
	if(!Resurrect_IsInRound()) return;	

	// Determine which team control the control point and trigger a win
	AcceptEntityInput(FindEntityByClassname(MaxClients+1, "team_control_point_master"), "Enable");

	Timer_Cleanup();
}

Float:Resurrect_GetCaptureTime(iTeam, iAlive1=-1, iAlive2=-1)
{
	// The general idea: the more players alive on the other team -> the quicker the control point can be captured
	// and viceaversa: the more players alive on my team -> the slower the control point can be captured
	new iOppositeTeam = (iTeam == TFTeam_Red) ? TFTeam_Blue : TFTeam_Red;
	// The general idea: the more players dead on a team -> the quicker the control point can be captured

	// Find out how many more alive players the other team has
	new iNumAlive[4];
	if(iAlive1 != -1 && iAlive2 != -1)
	{
		iNumAlive[TFTeam_Red] = iAlive1;
		iNumAlive[TFTeam_Blue] = iAlive2;
	}else{
		for(new i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				new iClientTeam = GetClientTeam(i);
				if(iClientTeam == TFTeam_Red || iClientTeam == TFTeam_Blue)
				{
					if(IsPlayerAlive(i)) iNumAlive[iClientTeam]++;
				}
			}
		}
	}

	new Float:flMin = GetConVarFloat(g_hCvarCapMin);
	new Float:flMid = GetConVarFloat(g_hCvarCapMid);
	new Float:flMax = GetConVarFloat(g_hCvarCapMax);

	// Calculate the change for each player difference
	// For now, use the interval between the min and max to calculate the modifier
	new Float:flMult;
	if(iNumAlive[iTeam] >= iNumAlive[iOppositeTeam])
	{
		// More players are alive on my team
		flMult = flMax - flMid;
	}else{
		// More players are alive on the opposite team
		flMult = flMid - flMin;
	}

	// Get a percentage to be able to use a modifier
	new iPlayerCap = 10;
	new iDiff = iNumAlive[iTeam] - iNumAlive[iOppositeTeam];
	if(iDiff > iPlayerCap) iDiff = iPlayerCap; else if(iDiff < iPlayerCap * -1) iDiff = iPlayerCap * -1;

	new Float:flRate = flMid + (float(iDiff) / float(iPlayerCap)) * flMult;

	flRate = Pow(flRate, 1.1);
	if(flRate > flMax) flRate = flMax; else if(flRate < flMin) flRate = flMin;

	return flRate;
}

Resurrect_SetCaptureTime(iTeam, Float:flCaptureTime)
{
	if(iTeam != TFTeam_Red && iTeam != TFTeam_Blue) return;

	// Applies a new capture rate for the control point
	new iCaptureArea = EntRefToEntIndex(g_iRefCaptureArea);
	if(iCaptureArea > MaxClients)
	{
		new iObjective = Entity_GetObj();
		if(iObjective > MaxClients)
		{
#if defined DEBUG
			PrintToServer("(Resurrect_SetCaptureTime) Setting respawn on team %d to: %0.2f..", iTeam, flCaptureTime);
#endif
			SetEntPropFloat(iCaptureArea, Prop_Data, "m_flCapTime", flCaptureTime);

			// You need to do this in order for client's HUDs to predict the capture rate

			new iCPIndex = 0;
			// Mappers have a little control given by the property "Number of RED/BLUE players to cap" on trigger_capture_area
			new iReqCappers = GetEntProp(iObjective, Prop_Send, "m_iTeamReqCappers", _, iCPIndex + 8 * iTeam);
			SetEntPropFloat(iObjective, Prop_Send, "m_flTeamCapTime", flCaptureTime * float(iReqCappers * 2), iCPIndex + 8 * iTeam);

			// Tells the client to update the HUD
			new iHudParity = GetEntProp(iObjective, Prop_Send, "m_iUpdateCapHudParity");
			iHudParity = (iHudParity + 1) & CAPHUD_PARITY_MASK;
			SetEntProp(iObjective, Prop_Send, "m_iUpdateCapHudParity", iHudParity);
		}
	}
}

public Event_RoundActive(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
#if defined DEBUG
	PrintToServer("(Event_RoundActive)");
#endif

	if(!Resurrect_IsEnabled()) return;
	if(!Resurrect_IsInRound()) return;
	
	switch(g_nMapHack)
	{
		case MapHack_HardHat:
		{
			// Remove the spawn doors so respawning players are not trapped	
			new iEntity = Entity_FindEntityByName("door_any_trackdoor_1_prop", "prop_dynamic");
			if(iEntity > MaxClients)
			{
#if defined DEBUG
				PrintToServer("(Event_RoundActive) Removing entity \"door_any_trackdoor_1_prop\"!");
#endif
				AcceptEntityInput(iEntity, "Kill");
			}

			iEntity = Entity_FindEntityByName("door_any_trackdoor_2_prop", "prop_dynamic");
			if(iEntity > MaxClients)
			{
#if defined DEBUG
				PrintToServer("(Event_RoundActive) Removing entity \"door_any_trackdoor_2_prop\"!");
#endif
				AcceptEntityInput(iEntity, "Kill");
			}

			iEntity = Entity_FindEntityByName("door_any_trackdoor_1", "func_door");
			if(iEntity > MaxClients)
			{
#if defined DEBUG
				PrintToServer("(Event_RoundActive) Removing entity \"door_any_trackdoor_1\"!");
#endif
				AcceptEntityInput(iEntity, "Kill");
			}

			iEntity = Entity_FindEntityByName("door_any_trackdoor_2", "func_door");
			if(iEntity > MaxClients)
			{
#if defined DEBUG
				PrintToServer("(Event_RoundActive) Removing entity \"door_any_trackdoor_2\"!");
#endif
				AcceptEntityInput(iEntity, "Kill");
			}
		}
		case MapHack_Arakawa:
		{
			// Remove the spawn door props when the round starts
			new iEntity;
			while((iEntity = Entity_FindEntityByName("door_any_large_dyn_1", "func_door")) != -1)
			{
#if defined DEBUG
				PrintToServer("(Event_RoundActive) Removing entity \"door_any_large_dyn_1\"!");
#endif
				AcceptEntityInput(iEntity, "Kill");
			}

			while((iEntity = Entity_FindEntityByName("door_any_large_dyn_1_prop", "prop_dynamic")) != -1)
			{
#if defined DEBUG
				PrintToServer("(Event_RoundActive) Removing entity \"door_any_large_dyn_1_prop\"!");
#endif
				AcceptEntityInput(iEntity, "Kill");
			}

			while((iEntity = Entity_FindEntityByName("door_any_large_dyn_2", "func_door")) != -1)
			{
#if defined DEBUG
				PrintToServer("(Event_RoundActive) Removing entity \"door_any_large_dyn_2\"!");
#endif
				AcceptEntityInput(iEntity, "Kill");
			}

			while((iEntity = Entity_FindEntityByName("door_any_large_dyn_2_prop", "prop_dynamic")) != -1)
			{
#if defined DEBUG
				PrintToServer("(Event_RoundActive) Removing entity \"door_any_large_dyn_2_prop\"!");
#endif
				AcceptEntityInput(iEntity, "Kill");
			}
		}
		case MapHack_BlackwoodValley:
		{
			// Rename the logic_relay to disable the explosion when the point is captured
			new iEntity = Entity_FindEntityByName("end_pit_destroy_relay", "logic_relay");
			if(iEntity != -1)
			{
#if defined DEBUG
				PrintToServer("(Event_RoundActive) Found: \"end_pit_destroy_relay_res\"!");
#endif
				DispatchKeyValue(iEntity, "targetname", "end_pit_destroy_relay_res");
			}
		}
	}
}

public Event_PointCaptured(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
#if defined DEBUG
	PrintToServer("(Event_PointCaptured)");
#endif

	if(!Resurrect_IsEnabled()) return;
	if(!Resurrect_IsInRound()) return;

	// A point has been captured
	// Respawn the dead teammates of the player that captured the control point
	new iCappingTeam = GetEventInt(hEvent, "team");
	if(iCappingTeam < 2 || iCappingTeam > 3) return;

	// Create a timer to force players from hiding
	new iTimeTurtle = GetConVarInt(g_hCvarTimeTurtle);
	if(iTimeTurtle > 0)
	{
		new iTimer = Entity_GetTimer();
		if(iTimer > MaxClients)
		{
			// ** VALVE BUG **: The AddTime input on team_round_timer does NOT work in arena
			// The timer thinks the game is over due to arena's specific round running state
			new RoundState:oldState = GameRules_GetRoundState();
			GameRules_SetProp("m_iRoundState", RoundState_RoundRunning);

			SetVariantInt(iTimeTurtle);
			AcceptEntityInput(iTimer, "AddTime");

			GameRules_SetProp("m_iRoundState", oldState);
		}
	}

	new iCount;
	new iNumTeammates;
	new Float:flTimeImmunity = GetConVarFloat(g_hCvarTimeImmunity);
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == iCappingTeam)
		{
			iNumTeammates++;

			if(!IsPlayerAlive(i))
			{
				TF2_RespawnPlayer(i);

				// Add immunity effects to the player being resurrected
				TF2_AddCondition(i, TFCond_UberchargedCanteen, flTimeImmunity);
				Particle_Attach(i, (iCappingTeam == TFTeam_Red) ? "hwn_cart_drips_red" : "hwn_cart_drips_blue", _, 50.0, flTimeImmunity);
				Resurrect_VocalizeRevive(i);

				iCount++;
			}
		}
	}

	// Play a sound to the team that didn't cap letting them know that new players are on the field
	new iOppositeTeam = (iCappingTeam == TFTeam_Red) ? TFTeam_Blue : TFTeam_Red;
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			new iTeam = GetClientTeam(i);
			if(iTeam == iCappingTeam)
			{
				if(iCount >= iNumTeammates-1 && iCount >= 3)
				{
					// Play a special sound when a player revives the entire team
					EmitSoundToClient(i, SOUND_REVIVED_ALL);
				}else{
					EmitSoundToClient(i, SOUND_REVIVE);
				}
			}else if(iTeam == iOppositeTeam)
			{
				EmitSoundToClient(i, SOUND_WARN);
			}
		}
	}

	new String:strCappers[64];
	GetEventString(hEvent, "cappers", strCappers, sizeof(strCappers));

	// Build a string of the list of cappers
	new Float:flTimeHealthBonus = GetConVarFloat(g_hCvarHealthBonus);
	new String:strChat[192];
	new iLength = strlen(strCappers);
	new bool:bOnce = false;
	for(new i=0; i<iLength; i++)
	{
		new client = strCappers[i];
		if(client >= 1 && client <= MaxClients && IsClientInGame(client))
		{
			if(!bOnce)
			{
				// All cappers should be on the same team
				Format(strChat, sizeof(strChat), "%s %s", PLUGIN_PREFIX, g_strTeamColors[GetClientTeam(client)]);
				bOnce = true;
			}

			Format(strChat, sizeof(strChat), "%s%N, ", strChat, client);

			// If there are no possible teammates to revive, give the player a small health bonus
			if(iNumTeammates <= 1 && flTimeHealthBonus > 0.0)
			{
				TF2_AddCondition(client, TFCond_HalloweenQuickHeal, flTimeHealthBonus);
			}
		}
	}

	// Get rid of that remaining comma
	iLength = strlen(strChat);
	if(iLength > 2 && strChat[iLength-2] == ',')
	{
		strChat[iLength-2] = '\0';
	}

	if(iCount >= iNumTeammates-1)
	{
		// Player revived the entire team
		Format(strChat, sizeof(strChat), "%s\x01 %T", strChat, "Res_Chat_Revived_EntireTeam", LANG_SERVER, "\x07FFD700", 0x01);
	}else{
		Format(strChat, sizeof(strChat), "%s\x01 %T", strChat, "Res_Chat_Revived", LANG_SERVER, "\x07CF7336", iCount, 0x01);
	}
	PrintToChatAll(strChat);
}

Resurrect_VocalizeRevive(client)
{
	// Random chance to play to help stop clipping and overuse
	if(GetURandomFloat() < 0.6) return;

	CreateTimer(1.0+GetRandomFloat(0.0, 1.0), Timer_VocalizeRevive, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_VocalizeRevive(Handle:hTimer, any:iUserId)
{
	if(!Resurrect_IsInRound()) return Plugin_Handled;

	new client = GetClientOfUserId(iUserId);
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
	{
		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_DemoMan: Resurrect_PlayVoiceline(client, g_strReviveDemo[GetRandomInt(0, sizeof(g_strReviveDemo)-1)]);
			case TFClass_Engineer: Resurrect_PlayVoiceline(client, g_strReviveEngie[GetRandomInt(0, sizeof(g_strReviveEngie)-1)]);
			case TFClass_Heavy: Resurrect_PlayVoiceline(client, g_strReviveHeavy[GetRandomInt(0, sizeof(g_strReviveHeavy)-1)]);
			case TFClass_Medic: Resurrect_PlayVoiceline(client, g_strReviveMedic[GetRandomInt(0, sizeof(g_strReviveMedic)-1)]);
			case TFClass_Scout: Resurrect_PlayVoiceline(client, g_strReviveScout[GetRandomInt(0, sizeof(g_strReviveScout)-1)]);
			case TFClass_Sniper: Resurrect_PlayVoiceline(client, g_strReviveSniper[GetRandomInt(0, sizeof(g_strReviveSniper)-1)]);
			case TFClass_Soldier: Resurrect_PlayVoiceline(client, g_strReviveSoldier[GetRandomInt(0, sizeof(g_strReviveSoldier)-1)]);
			case TFClass_Spy: Resurrect_PlayVoiceline(client, g_strReviveSpy[GetRandomInt(0, sizeof(g_strReviveSpy)-1)]);
			case TFClass_Pyro: Resurrect_PlayVoiceline(client, g_strRevivePyro[GetRandomInt(0, sizeof(g_strRevivePyro)-1)]);			
		}
	}

	return Plugin_Handled;
}

Resurrect_PlayVoiceline(client, const String:strSound[])
{
	EmitSoundToAll(strSound, client, SNDCHAN_VOICE, 95, 0, 0.81, 100);
}

bool:Resurrect_IsInRound()
{
	new RoundState:nRoundState = GameRules_GetRoundState();
	//PrintToServer("Game Mode: %d\nm_bInWaitingForPlayers: %d\nm_bInSetup: %d\nRound: %d", g_nGameMode, GameRules_GetProp("m_bInWaitingForPlayers", 1), GameRules_GetProp("m_bInSetup", 1), nRoundState);
	if(GameRules_GetProp("m_bInWaitingForPlayers", 1) || GameRules_GetProp("m_bInSetup", 1) || (g_bIsArena && nRoundState != RoundState:ArenaRoundState_RoundRunning) || (!g_bIsArena && nRoundState != RoundState_RoundRunning && nRoundState != RoundState_Stalemate))
	{
		return false;
	}
	
	return true;
}

Particle_Attach(iEntity, const String:strParticleEffect[], const String:strAttachPoint[]="", Float:flOffsetZ=0.0, Float:flTimeExpire=0.0)
{
	new iParticle = CreateEntityByName("info_particle_system");
	if(iParticle > MaxClients && IsValidEntity(iParticle))
	{
		new Float:flPos[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", flPos);
		flPos[2] += flOffsetZ;
		
		TeleportEntity(iParticle, flPos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(iParticle, "effect_name", strParticleEffect);
		DispatchSpawn(iParticle);
		
		SetVariantString("!activator");
		AcceptEntityInput(iParticle, "SetParent", iEntity);
		ActivateEntity(iParticle);
		
		if(strlen(strAttachPoint) > 0)
		{
			SetVariantString(strAttachPoint);
			AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset");
		}
		
		AcceptEntityInput(iParticle, "start");
		
		if(flTimeExpire > 0.0) CreateTimer(flTimeExpire, Timer_EntityExpire, EntIndexToEntRef(iParticle));
		
		return iParticle;
	}
	
	return 0;
}

public Action:Timer_EntityExpire(Handle:hTimer, any:iRef)
{
	new iEntity = EntRefToEntIndex(iRef);
	if(iEntity > MaxClients)
	{
		AcceptEntityInput(iEntity, "Kill");
	}
	
	return Plugin_Handled;
}

public Event_Cvar(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	if(!Resurrect_IsEnabled()) return;

	// Block the notification that this cvar has changed
	decl String:strCvar[30];
	GetEventString(hEvent, "cvarname", strCvar, sizeof(strCvar));
	if(strcmp(strCvar, "tf_arena_round_time") == 0 || strcmp(strCvar, "tf_arena_first_blood") == 0)
	{
		SetEventBroadcast(hEvent, true);
	}
}

public Event_RoundWin(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	if(!Resurrect_IsEnabled()) return;
	
	Entity_Cleanup();

	if(g_nMapHack == MapHack_BlackwoodValley)
	{
		// Trigger the map explosion manually when the round is over
		new iRelay = Entity_FindEntityByName("end_pit_destroy_relay_res", "logic_relay");
		if(iRelay != -1)
		{
#if defined DEBUG
			PrintToServer("(Event_RoundWin) Calling Trigger on \"end_pit_destroy_relay_res\"!");
#endif
			AcceptEntityInput(iRelay, "Trigger");
		}
	}
}

Entity_FindEntityByName(const String:strTargetName[], const String:strClassname[])
{
	decl String:strName[100];
	new iEntity = -1;
	while((iEntity = FindEntityByClassname(iEntity, strClassname)) != -1)
	{
		GetEntPropString(iEntity, Prop_Data, "m_iName", strName, sizeof(strName));
		if(strcmp(strTargetName, strName, false) == 0)
		{
			return iEntity;
		}
	}

	return -1;
}

stock Resurrect_DebugRespawnTimes()
{
	PrintToServer("Respawn times for RED based on alive players:\nMin: %0.2f ----> Mid: %0.2f ----> Max: %0.2f", GetConVarFloat(g_hCvarCapMin), GetConVarFloat(g_hCvarCapMid), GetConVarFloat(g_hCvarCapMax));

	for(new i=1; i<=12; i++)
	{
		new iNumRed = i;
		new iNumBlue = 13 - i;
		PrintToServer("RED %2d BLUE %2d ] %0.2f", iNumRed, iNumBlue, Resurrect_GetCaptureTime(TFTeam_Red, iNumRed, iNumBlue));
		if(i == 6)
		{
			iNumBlue = i;
			PrintToServer("RED %2d BLUE %2d ] %0.2f", iNumRed, iNumBlue, Resurrect_GetCaptureTime(TFTeam_Red, iNumRed, iNumBlue));
		}
	}
}

public Native_Enable(Handle:plugin, numParams)
{
	SetConVarBool(g_hCvarEnabled, GetNativeCell(1));
	return 1;
}

public Native_IsRunning(Handle:plugin, numParams)
{
	return g_bEnabledForRound;
}

public Action:Command_Test(client, args)
{
	Resurrect_DebugRespawnTimes();

	return Plugin_Handled;
}

public Action:Command_Toggle(client, args)
{
	// This command basically sets the cvar resurrect_enabled
	// No parameters will toggle the value
	// resurrect_toggle 0 or resurrect_toggle 1 sets the value of the cvar

	new bool:bNewValue;
	if(GetConVarBool(g_hCvarEnabled))
	{
		bNewValue = false;
	}else{
		bNewValue = true;
	}

	if(args == 1)
	{
		decl String:strArg[15];
		GetCmdArg(1, strArg, sizeof(strArg));
		if(strcmp(strArg, "0") == 0)
		{
			bNewValue = false;
		}else{
			bNewValue = true;
		}
	}

	decl String:strState[16];
	if(bNewValue)
	{
		Format(strState, sizeof(strState), "%T", "Res_Vote_On", LANG_SERVER);
		SetConVarBool(g_hCvarEnabled, bNewValue);
	}else{
		Format(strState, sizeof(strState), "%T", "Res_Vote_Off", LANG_SERVER);
		SetConVarBool(g_hCvarEnabled, bNewValue);
	}

	ShowActivity2(client, PLUGIN_PREFIX, " %N set Resurrection Mode: %s", client, strState);
	ReplyToCommand(client, "Changes will take effect next round.");

	return Plugin_Handled;
}

public Action:Command_Vote(client, args)
{
	// This command will try to start a vote to toggle the current resurrection mode
	Vote_Create(client);

	return Plugin_Handled;
}

Timer_KillVote()
{
	if(g_hTimerVote != INVALID_HANDLE)
	{
		KillTimer(g_hTimerVote);
		g_hTimerVote = INVALID_HANDLE;
	}
}

public Action:Timer_StartVote(Handle:hTimer, any:iSource)
{
	g_hTimerVote = INVALID_HANDLE;

	// Automatically start a vote to toggle resurrection mode
	if(!Vote_Create())
	{
		// Failed to start a vote so try again later
		g_hTimerVote = CreateTimer(5.0, Timer_StartVote, _, TIMER_REPEAT);
	}else{
		decl String:strState[32];
		if(GetConVarBool(g_hCvarEnabled))
		{
			Format(strState, sizeof(strState), "%T", "Res_Vote_Off", LANG_SERVER);
		}else{
			Format(strState, sizeof(strState), "%T", "Res_Vote_On", LANG_SERVER);
		}

		if(iSource == TIMER_STARTED_AUTO)
		{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "Res_Vote_Automatic", LANG_SERVER, 0x04, strState, 0x01);
		}else{
			PrintToChatAll("%s %T", PLUGIN_PREFIX, "Res_RTV_Started", LANG_SERVER, 0x04, strState, 0x01);	
		}
	}
	
	return Plugin_Stop;
}

public OnClientSayCommand_Post(client, const String:command[], const String:sArgs[])
{
	// Allow normal players to vote to start a resurrection toggle vote
	//PrintToServer("client: %N command: \"%s\" sArgs: \"%s\"", client, command, sArgs);

	if(!g_bIsArena) return;
	if(client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) < 2) return;

	if(strcmp(sArgs, "res", false) != 0 && strcmp(sArgs, "!res", false) != 0) return;

	new eActionState:state = eActionState:GetConVarInt(g_hCvarDemoAction);
	// Players are not allowed to start votes or a resurrection vote is already in progress
	if(state == Action_VoteNone || g_bVoteInProgress || g_hTimerVote != INVALID_HANDLE)
	{
		PrintToChat(client, "%s %T", PLUGIN_PREFIX, "Res_RTV_Disabled", LANG_SERVER);
		return;
	}

	// Players are not allowed to change the current resurrection state
	if((state == Action_VoteOn && GetConVarBool(g_hCvarEnabled) || (state == Action_VoteOff && !GetConVarBool(g_hCvarEnabled))))
	{
		PrintToChat(client, "%s %T", PLUGIN_PREFIX, "Res_RTV_Disabled", LANG_SERVER);
		return;		
	}

	// Too little time has passed since the last resurrection vote
	new iWaitTime = GetConVarInt(g_hCvarDemoCooldown) - (GetTime() - g_iTimeLastVote);
	if(g_iTimeLastVote != 0 && iWaitTime > 0)
	{
		PrintToChat(client, "%s %T", PLUGIN_PREFIX, "Res_RTV_Cooldown", LANG_SERVER, 0x04, iWaitTime, 0x01);
		return;
	}

	// Check if there's enough people on the server in order to start a vote
	new iPlayersNeeded = GetConVarInt(g_hCvarDemoMinPlayers) - GetPlayerCount();
	if(iPlayersNeeded > 0)
	{
		PrintToChat(client, "%s %T", PLUGIN_PREFIX, "Res_RTV_MinPlayers", LANG_SERVER, 0x04, iPlayersNeeded, 0x01);
		return;
	}

	new bool:bFirstTime = false;
	if(!g_bDemocracy[client])
	{
		bFirstTime = true;
	}

	g_bDemocracy[client] = true;

	// Check to see if we've reached the treshold
	new iNumVotes;
	for(new i=0; i<MAXPLAYERS+1; i++) if(g_bDemocracy[i]) iNumVotes++;
	new iNumVotesNeeded = RoundToCeil(float(GetPlayerCount()) * GetConVarFloat(g_hCvarDemoTreshold));
	if(iNumVotesNeeded < 1) iNumVotesNeeded = 1;

	if(bFirstTime)
	{
		decl String:strState[32];
		if(GetConVarBool(g_hCvarEnabled))
		{
			Format(strState, sizeof(strState), "%T", "Res_Vote_Off", LANG_SERVER);
		}else{
			Format(strState, sizeof(strState), "%T", "Res_Vote_On", LANG_SERVER);
		}

		PrintToChatAll("%s %T", PLUGIN_PREFIX, "Res_RTV_Nominated", LANG_SERVER, g_strTeamColors[GetClientTeam(client)], client, 0x01, strState, iNumVotes, iNumVotesNeeded);
	}

	if(iNumVotes >= iNumVotesNeeded)
	{
		Timer_KillVote();
		g_hTimerVote = CreateTimer(0.0, Timer_StartVote, TIMER_STARTED_NOMINATED, TIMER_REPEAT);
	}
}

GetPlayerCount()
{
	new iCount;
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) >= 2 && !IsFakeClient(i)) iCount++;
	}
	return iCount;
}

public Event_PlayerDeath(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
#if defined DEBUG
	PrintToServer("(Event_PlayerDeath)");
#endif
	if(!Resurrect_IsEnabled()) return;
	if(!Resurrect_IsInRound()) return;

	if(GetEventInt(hEvent, "death_flags") & TF_DEATHFLAG_DEADRINGER) return;

	// Play a 'last man standing' sound to the victim's team if his team has just a single player left
	new iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(iVictim >= 1 && iVictim <= MaxClients && IsClientInGame(iVictim))
	{
		new iTeam = GetClientTeam(iVictim);
		if(iTeam == TFTeam_Red || iTeam == TFTeam_Blue)
		{
			new iOppositeTeam = (iTeam == TFTeam_Red) ? TFTeam_Blue : TFTeam_Red;
			new iNumLeftVictim = -1;
			for(new i=1; i<=MaxClients; i++) if(IsClientInGame(i) && GetClientTeam(i) == iTeam && IsPlayerAlive(i)) iNumLeftVictim++;
			new iNumLeftAttacker;
			for(new i=1; i<=MaxClients; i++) if(IsClientInGame(i) && GetClientTeam(i) == iOppositeTeam && IsPlayerAlive(i)) iNumLeftAttacker++;

			if(g_bPlayAnnouncer)
			{
				if(iNumLeftVictim == 1)
				{
					// Only play the 'You are the last one alive' announcer type messages to the team with 1 player to avoid confusion
					for(new i=1; i<=MaxClients; i++)
					{
						if(IsClientInGame(i) && GetClientTeam(i) != iOppositeTeam)
						{
							EmitSoundToClient(i, g_strSoundLastMan[GetRandomInt(0, sizeof(g_strSoundLastMan)-1)]);
						}
					}
				}else if(iNumLeftVictim == 0)
				{
					// The victim was the last person alive, delay this a little bit to avoid clutter, the flawless defeat line seems to still clip
					CreateTimer(7.5, Timer_Forfeit, GetClientUserId(iVictim), TIMER_FLAG_NO_MAPCHANGE);
				}
			}

			//PrintToServer("iNumLeftVictim: %d\niNumLeftAttacker: %d", iNumLeftVictim, iNumLeftAttacker);

			// Activate last rites if the last player kills a player with a team that has resurrect_lastrites more players
			if(iNumLeftAttacker == 1 && iNumLeftVictim - iNumLeftAttacker >= GetConVarFloat(g_hCvarLastRites))
			{
				new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
				if(iAttacker >= 1 && iAttacker <= MaxClients && IsClientInGame(iAttacker) && GetClientTeam(iAttacker) != iTeam && IsPlayerAlive(iAttacker))
				{
					PrintToChatAll("%s %T", PLUGIN_PREFIX, "Res_Chat_LastRites", LANG_SERVER, g_strTeamColors[GetClientTeam(iAttacker)], iAttacker, 0x01, "\x07EF4293", 0x01);
					
					TF2_AddCondition(iAttacker, TFCond_Buffed, GetConVarFloat(g_hCvarLastRitesDuration));
					EmitSoundToAll(SOUND_LAST_RITES);
				}
			}
		}
	}
}

public Action:Timer_Forfeit(Handle:hTimer, any:iUserId)
{
	new client = GetClientOfUserId(iUserId);
	if(client >= 1 && client <= MaxClients && IsClientInGame(client))
	{
		EmitSoundToClient(client, g_strSoundForfeit[GetRandomInt(0, sizeof(g_strSoundForfeit)-1)]);
	}

	return Plugin_Handled;
}

public CVarChanged_MapHack(Handle:convar, const String:oldValue[], const String:newValue[])
{
	MapHack_Init();
}