Resurrection
=========

Resurrection - Arena mod for Team Fortress 2

###Description

A simple mod for Arena mode. Capturing the control point will respawn your dead teammates instead of ending the round. Generally, capture time is lowered when most teammates are dead. Players take a penalty for standing on the control point. A team wins by eliminating the enemy team or by holding the control point for a period of time.

###CVars
```
resurrect_enabled 1 // 0/1 - Enable or disable the plugin.
resurrect_time_cap_min 0.25 // Roughly the minimum time possible to capture the control point.
resurrect_time_cap_max 0.55 // Roughly the max time possible to capture the control point.
resurrect_time_unlock 15 // Seconds until the control point unlocks and players can cap.
resurrect_time_mfd 5.0 // Seconds after leaving a control point that mark for death effects remain on the player.
resurrect_time_immunity 3.0 // Seconds of immunity after being resurrected.
resurrect_time_turtle 81 // If a control point is held for this many seconds, the game ends. This prevents camping and turtling by C/D spies or engineers.
```

###Install
1. Install [SourceMod >= 1.6.2](http://www.sourcemod.net)
2. Compile resurrect.sp and drop resurrect.smx into the `sourcemod/plugins/` directory.

###License
Released under GPLv3
