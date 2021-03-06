Resurrection
=========

Resurrection - Arena mod for Team Fortress 2

###Description

A simple mod for Arena mode. Capturing the control point will respawn your dead teammates instead of ending the round. The capture rate is increased when the opposite team has more alive players. Players take a penalty for standing on the control point. A team wins by eliminating the enemy team or by holding the control point for a period of time.

###Features
+ Automatic votes when a map begins to enable resurrection mod.
+ Player nominated votes activated by typing ```res``` in chat.

###CVars
```
resurrect_enabled 1 // 0/1 - Enable or disable the plugin.
resurrect_time_unlock 15 // Seconds until the control point unlocks and players can cap.
resurrect_time_mfd 5.0 // Seconds after leaving a control point that mark for death effects remain on the player.
resurrect_time_immunity 3.0 // Seconds of immunity after being resurrected.
resurrect_time_turtle 81 // If a control point is held for this many seconds, the game ends. This prevents camping and turtling by C/D spies or engineers.
resurrect_health_bonus 4.0 // Seconds of health bonus when capturing with no teammates.
resurrect_vote_percentage 0.5 // Percentage of votes needed in order for a vote to pass.
resurrect_announcer 0 // Number of players required when the round starts to play 'last man standing' or 'disappointment' announcer sounds. Set to a high number (64) to disable.
resurrect_lastrites 2 // Number of MORE players on the opposite team to activate last rites. Set to a high number (64) to disable last rites.
resurrect_lastrites_duration 5.0 // Seconds of minicrits awarded for the last rite effect.
resurrect_firstblood -1 // Number of players required for first blood. -1 will do nothing.
resurrect_maphack 1 // 0/1 - Enable or disable changes to the map to support resurrection mode.

resurrect_auto_start 1.5 // Minutes after a map starts to launch a vote to toggle resurrection mode.
resurrect_auto_action 0 // 0 - do not start automatic votes | 1 - only start votes to turn ON | 2 - only start votes to turn OFF | 3 - both
	
resurrect_democracy_action 0 // 0 - do not allow players to vote | 1 - allow players to vote ON | 2 - allow players to vote OFF | 3 - allow both
resurrect_democracy_treshold 0.3 // Percentage of players needed to type !res in order to start a vote.
resurrect_democracy_cooldown 300 // Cooldown in seconds between voting to change resurrection mode.
resurrect_democracy_minplayers 3 // Minimum players on the server in order for players to start a vote.

resurrect_cap_min 0.25 // Minimum capture time when one team has fewer alive players.
resurrect_cap_mid 0.7 // Medium capture time when both teams have the same amount of alive players.
resurrect_cap_max 2.0 // Maximum capture time when one team has more alive players.
```

###Commands
| Name          | Admin flag    | Description                                                                      |
| ------------- |---------------:|----------------------------------------------------------------------------------|
| resurrect_toggle | generic b |Toggles the state of the mod. Use arguements 1 or 0 to set the state of the mod.   |
| resurrect_vote   | vote k    | Starts a vote to toggle resurrection mod if possible.                             |

###Install
1. Install [SourceMod >= 1.6.2](http://www.sourcemod.net)
2. Compile `resurrect.sp` and copy `resurrect.smx` into the `sourcemod/plugins/` directory.
3. Copy `resurrect.phrases.txt` into the `sourcemod/translations/` directory. 

###[Changelog](https://github.com/akowald/resurrect/blob/master/CHANGELOG.md)

###License
Released under GPLv3
