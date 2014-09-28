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

#if defined _resurrect_included
  #endinput
#endif
#define _resurrect_included

/*********************************************************
 * Enables or disables the mod. This will take effect when the round starts.
 * So when the map changes, this will be false until the first round begins.
 *
 * @param	bEnabled	True to turn on, false otherwise
 * @return				None
 *********************************************************/
native Resurrect_Enable(bool:bEnabled);

/*********************************************************
 * Returns if the mod is running for the current round.
 *
 * @return				True if running, false otherwise
 *********************************************************/
native bool:Resurrect_IsRunning();

public SharedPlugin:__pl_resurrect = 
{
	name = "resurrect",
	file = "resurrect.smx",
#if defined REQUIRE_PLUGIN
	required=1,
#else
	required=0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_resurrect_SetNTVOptional()
{
	MarkNativeAsOptional("Resurrect_Enable");
	MarkNativeAsOptional("Resurrect_IsRunning");
}
#endif