# Mantella Living World - Followers

Talk your followers into things through [Nether's Follower Framework](https://www.nexusmods.com/skyrimspecialedition/mods/55653). A module of [Mantella Living World - Integration Hub](https://github.com/Abhisek571/Mantella-Living-World-Hub).

| Action | What it does |
|---|---|
| JoinParty / LeaveParty | The NPC joins or leaves your party. Joining first releases them from Mantella's own follower system. If the party is full, they say so. Children, guards, Jarls, stewards and NPCs who already follow you through another framework cannot join, and are told why |
| WaitHere / FollowMe | That follower waits, or follows again |
| EveryoneWait / EveryoneFollow | The whole party waits or follows again |
| GatherParty | The whole party comes to you. They are only teleported if all of them are over 2000 units away and out of sight |
| StayPassive / FightFreely | Stays out of fights, or fights and helps again |
| AttackTarget | Attacks the enemy named, the one you point at, or the nearest. Refused if there is no enemy |
| CombatStyle / PartyRole | Melee, ranged or magic; tank, healer or no role. Refused if the NPC cannot do it |
| FollowDistance / StayBehind | How close they walk; step in behind you |
| SitThere / RelaxHere | Sit on the seat you point at (refused if it is taken); the whole party relaxes nearby |
| CarryTorch / PartyLoot | Torches in the dark (refused if they have none); looting on or off for the whole party |
| WearThis | Opens trade: everything they wear afterwards becomes their outfit for where you are. Their earlier stored outfit goes back into their inventory |

Followers also notice clothes you gave them.

All actions except JoinParty are only offered to followers (JoinParty is offered to everyone except guards). EveryoneWait, EveryoneFollow, GatherParty, RelaxHere and PartyLoot are refused unless a party member gives them. CombatStyle, PartyRole, FollowDistance, CarryTorch and PartyLoot need Mantella's Advanced Actions on; the other orders work without it. EveryoneWait, EveryoneFollow, GatherParty, RelaxHere and PartyLoot always act on the whole party; the rest act on every NPC named in the talk. Every order goes through NFF, so NFF's own menu shows the same state. When a refusal happens, the NPC is told why. Join and leave refresh the NPC's file in the Hub while you talk.

Requires: [Mantella Living World - Integration Hub](https://github.com/Abhisek571/Mantella-Living-World-Hub) (and with it [Mantella - Direct AI Connect](https://github.com/Abhisek571/Mantella-Anthropic-API), [PapyrusUtil](https://www.nexusmods.com/skyrimspecialedition/mods/13048) and SKSE), [Mantella](https://www.nexusmods.com/skyrimspecialedition/mods/98631) 0.14, [Nether's Follower Framework](https://www.nexusmods.com/skyrimspecialedition/mods/55653). The plugin only has Skyrim as a master, so if the Hub or NFF is missing nothing warns you at load; the actions just do nothing.

In Mantella's action settings, turn off its own Follow, Unfollow, Wait and Loot, or they clash with these.

Build: the Hub's `tools/build.py --only followers`. In-game tests: `bash test/run-tests.sh` (DevBench).

License: GNU AGPL-3.0.
