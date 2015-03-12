# Changelog

## 0.7 (2015-3-12)

Bug fixes:

+ Fixed broken sounds from latest update.

## 0.6 (2014-10-19)

Features:

+ Added acknowledgement when entire team was revived.
+ Added cvar `resurrect_maphack` to enable or disable map fixes.

Bug fixes:

+ Added map fixes for **arena_ferrous**.

## 0.5 (2014-10-05)

Features:

+ Added a way to toggle TF2's first blood crits by player count with the cvar `resurrect_firstblood`. Default value of `-1` leaves it alone.
+ Added last rites: If you are the last player alive and make a kill when the other team has `resurrect_lastrites` more players, you receive minicrits for `resurrect_lastrites_duration`.
+ Added announcer lines for the last player standing and the last player to die.

## 0.4 (2014-09-28)

Features:

+ Added the admin commands `resurrect_toggle` and `resurrect_vote`.
+ Added admin menu integration to the above commands for ease of use.
+ Added automatic votes after a map begins to change the state of the mod.
+ Added nominated votes players may start by typing `res` into chat to change the state of the mod.
+ Added the translation file `resurrect.phrases.txt`.

Bug fixes:

+ Added map fixes for **arena_brakawa** and **arena_blackwoodvalley**.

Changes:

+ Players are marked for death only while defending the control point instead of all the time.

## 0.3 (2014-09-24)

Features:

+ Fixed the capture HUD showing incorrect progress on certain maps.
+ Changed the capture time formula to be based on the difference of both team's alive players. Added cvars `resurrect_cap_[min/mid/max]` to allow for configuration. The command `resurrect_test` will print out a table of possible respawn times in server console to help with testing.
+ The value of `tf_arena_round_time` is no longer changed on the server.
+ The value of `resurrect_enabled` takes effect when the new round begins. Changing the value mid-round will not have any immediate effect.
+ Added natives: `Resurrect_Enable` and `Resurrect_IsRunning` to get started.
+ Capping when the game is 1v1 will provide you with a health boost set by `resurrect_health_bonus`.
