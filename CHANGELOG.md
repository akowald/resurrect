# Changelog

## 0.4 (2014-09-28)

Features:

+ Added the admin commands `resurrect_toggle` and `resurrect_vote`.
+ Added admin menu integration to the above commands for ease of use.
+ Added automatic votes after a map begins to change the state of the mod.
+ Added nominated votes players may start by typing `res` into chat to change the state of the mod.
+ Added map fixes for **arena_brakawa** and **arena_blackwoodvalley**
+ Added the translation file `resurrect.phrases.txt`

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
