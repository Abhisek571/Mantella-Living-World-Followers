# Changelog

Every change to Mantella Living World - Followers. The Nexus page lists only the main changes for each version.

## Unreleased

### Changed
- The 18 follower orders are now two actions with the order inside: FollowerOrder (wait, follow, stay behind, sit, leave, wear, fight, passive, attack, follow distance, combat style, role, torch) and PartyOrder (everyone wait or follow, gather, relax, loot on or off). Every order works as before, and the model is sent far less text on every reply. JoinParty stays its own action.
- With Mantella's Advanced Actions switched off, follower orders can no longer be triggered by keyword: both actions need the order as a parameter, so turn Advanced Actions on in Mantella. Before, most orders worked without it.
- The old separate order actions still work for one version, so a talk running across the update is not broken. When updating by hand, delete the old action files (mantella_mlw_wait.json and the others) or let your mod manager replace the folder.

### Fixed
- Joining the party and "wear this" can no longer hang for good after a save made at the wrong moment.
- Every order now tells the NPC (an event line) and you (a short line on screen) whether it worked, including follow distance and combat style, which said nothing; an order that cannot apply says why.
- Events are registered again only on older saves, not at every talk start; item events skip everything that is not clothing first.
- After "relax", telling the party to follow turns relax mode off again; before, the party kept relaxing every time you stood still.
- "Wear this" works for an NPC carrying more than 128 kinds of armor; before, it could equip old armor and store the wrong outfit.
- Party lookups and talk starts do less work: party members are no longer checked twice, and an NPC's file is only saved when the follower mark changes.

## 1.2.0 (2026-11-09)

### New
- Followers from Nether's Follower Framework are marked in each NPC's file, so the Integration Hub can limit follower actions to them.
- Action files updated for the Hub's follower check.

### Fixed
- Gather party warped a member out of another cell (for example out of Dragonsreach); only members in the same cell or worldspace are moved now.
- Attack target missed a named NPC who had moved from their usual place; the people in the conversation are now checked too.
- Group orders and follower lookups fixed.
- Gift handling fixes.

## 1.1.2 (2026-11-04)
- Finding an attack target no longer uses the scan that crashes Skyrim VR.
- Now requires powerofthree's Papyrus Extender, and Integration Hub 1.1.7.

## 1.1.1 (2026-10-30)
- No change in game.

## 1.1.0 (2026-10-30)
- New party orders: attack target, combat style, party role, follow distance, party loot, carry torch, sit there, relax here, stay behind and gather party.
- Clothes you hand an NPC are remembered as your gift.
- Join refuses children, guards, Jarls, stewards and other frameworks' followers; party orders only come from party members.
- Adds the version file the Integration Hub's update check reads.

## 1.0.0
- First release.
