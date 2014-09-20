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

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>

//#define DEBUG
#define PLUGIN_VERSION "0.2"

#define SOUND_REVIVE					"mvm/mvm_revive.wav"
#define SOUND_WARN 						"misc/doomsday_lift_warning.wav"
#define SOUND_MARKED 					"weapons/samurai/tf_marked_for_death_indicator.wav"

new const String:g_strReviveDemo[][] = {"vo/demoman_mvm_resurrect01.wav", "vo/demoman_mvm_resurrect02.wav", "vo/demoman_mvm_resurrect03.wav", "vo/demoman_mvm_resurrect05.wav", "vo/demoman_mvm_resurrect06.wav", "vo/demoman_mvm_resurrect07.wav", "vo/demoman_mvm_resurrect08.wav", "vo/demoman_mvm_resurrect09.wav", "vo/demoman_mvm_resurrect10.wav", "vo/demoman_mvm_resurrect11.wav"};
new const String:g_strReviveEngie[][] = {"vo/engineer_mvm_resurrect01.wav", "vo/engineer_mvm_resurrect02.wav", "vo/engineer_mvm_resurrect03.wav"};
new const String:g_strReviveHeavy[][] = {"vo/heavy_mvm_resurrect01.wav", "vo/heavy_mvm_resurrect02.wav", "vo/heavy_mvm_resurrect04.wav", "vo/heavy_mvm_resurrect05.wav", "vo/heavy_mvm_resurrect06.wav", "vo/heavy_mvm_resurrect07.wav"};
new const String:g_strReviveMedic[][] = {"vo/medic_mvm_resurrect01.wav", "vo/medic_mvm_resurrect02.wav", "vo/medic_mvm_resurrect03.wav"};
new const String:g_strReviveScout[][] = {"vo/scout_mvm_resurrect01.wav", "vo/scout_mvm_resurrect02.wav", "vo/scout_mvm_resurrect03.wav", "vo/scout_mvm_resurrect04.wav", "vo/scout_mvm_resurrect05.wav", "vo/scout_mvm_resurrect06.wav", "vo/scout_mvm_resurrect07.wav", "vo/scout_mvm_resurrect08.wav"};
new const String:g_strReviveSniper[][] = {"vo/sniper_mvm_resurrect01.wav", "vo/sniper_mvm_resurrect02.wav", "vo/sniper_mvm_resurrect03.wav"};
new const String:g_strReviveSoldier[][] = {"vo/soldier_mvm_resurrect01.wav", "vo/soldier_mvm_resurrect02.wav", "vo/soldier_mvm_resurrect03.wav", "vo/soldier_mvm_resurrect04.wav", "vo/soldier_mvm_resurrect05.wav", "vo/soldier_mvm_resurrect06.wav"};
new const String:g_strReviveSpy[][] = {"vo/spy_mvm_resurrect01.wav", "vo/spy_mvm_resurrect02.wav", "vo/spy_mvm_resurrect03.wav", "vo/spy_mvm_resurrect04.wav", "vo/spy_mvm_resurrect05.wav", "vo/spy_mvm_resurrect06.wav", "vo/spy_mvm_resurrect07.wav", "vo/spy_mvm_resurrect08.wav", "vo/spy_mvm_resurrect09.wav"};
new const String:g_strRevivePyro[][] = {"vo/pyro_sf13_spell_generic01.wav", "vo/pyro_autocappedcontrolpoint01.wav"};
new const String:g_strSoundMarked[][] = {"weapons/samurai/tf_marked_for_death_impact_01.wav", "weapons/samurai/tf_marked_for_death_impact_02.wav", "weapons/samurai/tf_marked_for_death_impact_03.wav"};

new const String:g_strTeamColors[][] = {"\x07B2B2B2", "\x07B2B2B2", "\x07FF4040", "\x0799CCFF"};

#define ArenaRoundState_RoundRunning 	7
#define TFTeam_Red						2
#define TFTeam_Blue						3

new bool:g_bIsArena;

new g_iRefCaptureArea;
new g_iRefObj;
new g_iRefTimer;
new bool:g_bPlayOnce[MAXPLAYERS+1];

new Handle:g_hCvarEnabled;
new Handle:g_hCvarTimeCapMin;
new Handle:g_hCvarTimeCapMax;
new Handle:g_hCvarTimeUnlock;
new Handle:g_hCvarTimeMFD;
new Handle:g_hCvarTimeImmunity;
new Handle:g_hCvarTimeTurtle;

new Handle:g_hCvarArenaRoundTime;

enum eMapHack
{
	MapHack_None=0,
	MapHack_HardHat
};
new eMapHack:g_nMapHack;

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
	g_hCvarEnabled = CreateConVar("resurrect_enabled", "1", "0/1 - Enable or disable the plugin.");
	g_hCvarTimeCapMin = CreateConVar("resurrect_time_cap_min", "0.25", "Roughly the minimum time possible to capture the control point.");
	g_hCvarTimeCapMax = CreateConVar("resurrect_time_cap_max", "0.55", "Roughly the max time possible to capture the control point.");
	g_hCvarTimeUnlock = CreateConVar("resurrect_time_unlock", "15", "Seconds until the control point unlocks and players can cap.");
	g_hCvarTimeMFD = CreateConVar("resurrect_time_mfd", "5.0", "Seconds after leaving a control point that mark for death effects remain on the player.");
	g_hCvarTimeImmunity = CreateConVar("resurrect_time_immunity", "3.0", "Seconds of immunity after being resurrected.");
	g_hCvarTimeTurtle = CreateConVar("resurrect_time_turtle", "81", "If a control point is held for this many seconds, the game ends. This prevents camping and turtling by C/D spies or engineers.");

	g_hCvarArenaRoundTime = FindConVar("tf_arena_round_time");

	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("arena_round_start", Event_RoundActive);
	HookEvent("teamplay_point_captured", Event_PointCaptured);
	HookEvent("server_cvar", Event_Cvar, EventHookMode_Pre);
	HookEvent("teamplay_round_win", Event_RoundWin);

	RegAdminCmd("resurrect_test", Command_Test, ADMFLAG_ROOT);

	HookEntityOutput("tf_logic_arena", "OnCapEnabled", Logic_OnCapEnabled);
}

public OnPluginEnd()
{
	Entity_Cleanup();

	SetConVarInt(g_hCvarArenaRoundTime, 0, true, false);
}

public OnConfigsExecuted()
{
	SetConVarInt(g_hCvarArenaRoundTime, 0, true, false);
}

public OnMapStart()
{
	Entity_Cleanup();

	decl String:strMap[64];
	GetCurrentMap(strMap, sizeof(strMap));
	g_bIsArena = (strncmp(strMap, "arena_", 6) == 0);

	g_nMapHack = MapHack_None;
	if(strncmp(strMap, "arena_hardhat", 13) == 0)
	{
		g_nMapHack = MapHack_HardHat;
	}

	Resurrect_LoadResources();
}

Resurrect_LoadResources()
{
	PrecacheSound(SOUND_REVIVE);
	PrecacheSound(SOUND_WARN);
	PrecacheSound(SOUND_MARKED);

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
}

Resurrect_IsEnabled()
{
	return g_bIsArena && GetConVarBool(g_hCvarEnabled);
}

public Event_RoundStart(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	if(!Resurrect_IsEnabled()) return;

	Entity_Cleanup();
	for(new i=0; i<sizeof(g_bPlayOnce); i++) g_bPlayOnce[i] = false;
	
	SetConVarInt(g_hCvarArenaRoundTime, 0, true, false); // Keep the arena timer out of order until we need it for our timer

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

		// Set the initial capturing time
		// Respawn time will be reset when the player begins capturing so this isn't that important
		Resurrect_SetCaptureTime(GetConVarFloat(g_hCvarTimeCapMax));

		HookSingleEntityOutput(iCaptureArea, "OnStartTeam1", EntityOutput_StartCapture, false);
		HookSingleEntityOutput(iCaptureArea, "OnStartTeam2", EntityOutput_StartCapture, false);

		// Hook touch 
		SDKHook(iCaptureArea, SDKHook_StartTouch, Area_StartTouch);
		SDKHook(iCaptureArea, SDKHook_EndTouch, Area_EndTouch);
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
			SetEntPropFloat(iLogic, Prop_Data, "m_flTimeToEnableCapPoint", float(iTimeUnlock));
		}
	}

	PrintToChatAll("\x07F0E68CCapturing the control point will respawn your teammates!");
}

public Area_StartTouch(iCaptureArea, client)
{
	//PrintToServer("(Area_StartTouch) client: %d!", client);

	// Touching the capture area should give you permanent mark for death until you leave the area
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
	{
		TF2_AddCondition(client, TFCond_MarkedForDeathSilent, TFCondDuration_Infinite);

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
}

public Area_EndTouch(iCaptureArea, client)
{
	//PrintToServer("(Area_EndTouch) client: %d!", client);

	// Player has left the capture area so remove their marked for death effects but give them a constant amount of time left
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
	{
		TF2_RemoveCondition(client, TFCond_MarkedForDeathSilent);
		TF2_AddCondition(client, TFCond_MarkedForDeathSilent, GetConVarFloat(g_hCvarTimeMFD));
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
		Format(strText, sizeof(strText), "Cap the point to bring back your teammates");

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

public EntityOutput_StartCapture(const String:output[], caller, activator, Float:delay)
{
#if defined DEBUG
	PrintToServer("(EntityOutput_StartCapture) caller: %d activator: %d!", output, caller, activator);
#endif

	if(activator != EntRefToEntIndex(g_iRefCaptureArea)) return;

	if(!Resurrect_IsEnabled()) return;
	if(!Resurrect_IsInRound()) return;

	// Determine which team started capping by the name of the output
	new iTeam = (strcmp(output, "OnStartTeam2") == 0) ? TFTeam_Blue : TFTeam_Red;

	Resurrect_SetCaptureTime(Resurrect_GetCaptureTime(iTeam));
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
	if(g_iRefTimer != 0)
	{
		new iTimer = EntRefToEntIndex(g_iRefTimer);
		if(iTimer > MaxClients) return iTimer;
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

		HookSingleEntityOutput(iTimer, "OnFinished", EntityOutput_TimerFinished, true);

		// Enable this cvar to place the timer correctly in client's HUDs
		SetConVarInt(g_hCvarArenaRoundTime, 9999, true, false);

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

public EntityOutput_TimerFinished(const String:output[], caller, activator, Float:delay)
{
#if defined DEBUG
	PrintToServer("(EntityOutput_TimerFinished) caller: %d activator: %d", caller, activator);
#endif

	if(activator != EntRefToEntIndex(g_iRefTimer)) return;

	if(!Resurrect_IsEnabled()) return;
	if(!Resurrect_IsInRound()) return;	

	// Determine which team control the control point and trigger a win
	AcceptEntityInput(FindEntityByClassname(MaxClients+1, "team_control_point_master"), "Enable");

	Timer_Cleanup();
}

Float:Resurrect_GetCaptureTime(iTeam)
{
	// The general idea: the more players dead on a team -> the quicker the control point can be captured

	// Find the percentage of dead players on a team
	new iSum, iNumDead;
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == iTeam)
		{
			iSum++;
			if(!IsPlayerAlive(i)) iNumDead++;
		}
	}

	return GetConVarFloat(g_hCvarTimeCapMin) + GetConVarFloat(g_hCvarTimeCapMax) * (1.0 - float(iNumDead) / float(iSum));
}

Resurrect_SetCaptureTime(Float:flCaptureTime)
{
	// Applies a new capture rate for the control point
	new iCaptureArea = EntRefToEntIndex(g_iRefCaptureArea);
	if(iCaptureArea > MaxClients)
	{
		new iObjective = Entity_GetObj();
		if(iObjective > MaxClients)
		{
#if defined DEBUG
			PrintToServer("(Resurrect_SetCaptureTime) Setting respawn to: %0.2f..", flCaptureTime);
#endif
			SetEntPropFloat(iCaptureArea, Prop_Data, "m_flCapTime", flCaptureTime);

			// You need to do this in order for client's HUDs to predict the capture rate
			SetEntPropFloat(iObjective, Prop_Data, "m_flTeamCapTime", flCaptureTime * 6.0, 0 + 8 * TFTeam_Red);
			SetEntPropFloat(iObjective, Prop_Data, "m_flTeamCapTime", flCaptureTime * 6.0, 0 + 8 * TFTeam_Blue);
		}
	}
}

public Event_RoundActive(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
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
				PrintToServer("(RoundStart) Removing entity \"door_any_trackdoor_1_prop\"!");
#endif
				AcceptEntityInput(iEntity, "Kill");
			}

			iEntity = Entity_FindEntityByName("door_any_trackdoor_2_prop", "prop_dynamic");
			if(iEntity > MaxClients)
			{
#if defined DEBUG
				PrintToServer("(RoundStart) Removing entity \"door_any_trackdoor_2_prop\"!");
#endif
				AcceptEntityInput(iEntity, "Kill");
			}

			iEntity = Entity_FindEntityByName("door_any_trackdoor_1", "func_door");
			if(iEntity > MaxClients)
			{
#if defined DEBUG
				PrintToServer("(RoundStart) Removing entity \"door_any_trackdoor_1\"!");
#endif
				AcceptEntityInput(iEntity, "Kill");
			}

			iEntity = Entity_FindEntityByName("door_any_trackdoor_2", "func_door");
			if(iEntity > MaxClients)
			{
#if defined DEBUG
				PrintToServer("(RoundStart) Removing entity \"door_any_trackdoor_2\"!");
#endif
				AcceptEntityInput(iEntity, "Kill");
			}
		}
	}
}

public Event_PointCaptured(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
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
	new Float:flTimeImmunity = GetConVarFloat(g_hCvarTimeImmunity);
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == iCappingTeam && !IsPlayerAlive(i))
		{
			TF2_RespawnPlayer(i);

			// Add immunity effects to the player being resurrected
			TF2_AddCondition(i, TFCond_UberchargedCanteen, flTimeImmunity);
			Particle_Attach(i, (iCappingTeam == TFTeam_Red) ? "hwn_cart_drips_red" : "hwn_cart_drips_blue", _, 50.0, flTimeImmunity);
			Resurrect_VocalizeRevive(i);

			iCount++;
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
				EmitSoundToClient(i, SOUND_REVIVE);
			}else if(iTeam == iOppositeTeam)
			{
				EmitSoundToClient(i, SOUND_WARN);
			}
		}
	}

	new String:strCappers[64];
	GetEventString(hEvent, "cappers", strCappers, sizeof(strCappers));

	// Build a string of the list of cappers
	new String:strChat[192];
	new iLength = strlen(strCappers);
	for(new i=0; i<iLength; i++)
	{
		new client = strCappers[i];
		if(client >= 1 && client <= MaxClients && IsClientInGame(client))
		{
			Format(strChat, sizeof(strChat), "%s%s%N, ", strChat, g_strTeamColors[GetClientTeam(client)], client);
		}
	}

	// Get rid of that remaining comma
	iLength = strlen(strChat);
	if(iLength > 2 && strChat[iLength-2] == ',')
	{
		strChat[iLength-2] = '\0';
	}

	Format(strChat, sizeof(strChat), "%s\x01 saved \x07CF7336%d", strChat, iCount);
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
	if(strcmp(strCvar, "tf_arena_round_time") == 0)
	{
		SetEventBroadcast(hEvent, true);
	}
}

public Event_RoundWin(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	if(!Resurrect_IsEnabled()) return;
	
	Entity_Cleanup();
}

Entity_FindEntityByName(const String:strTargetName[], const String:strClassname[])
{
	// This only searches for entities above MaxClients (non-player/non-world entities)
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

public Action:Command_Test(client, args)
{
	/*
	new iObj = FindEntityByClassname(MaxClients+1, "tf_objective_resource");
	if(iObj > MaxClients)
	{
		for(new i=0; i<64; i++)
		{
			PrintToServer("%d = %0.2f", i, GetEntPropFloat(iObj, Prop_Data, "m_flTeamCapTime", i));
		}

		PrintToServer("Obj = %d", iObj);
		//SetEntPropFloat(activator, Prop_Data, "m_flCapTime", GetConVarFloat(g_hCvarTimeCapMin));
		//SetEntPropFloat(iObj, Prop_Data, "m_flTeamCapTime", GetConVarFloat(g_hCvarTimeCapMin), 0);
	}
	*/

	return Plugin_Handled;
}