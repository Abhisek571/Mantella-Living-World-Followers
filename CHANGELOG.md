# Changelog

Every change to Mantella Living World - Followers. The Nexus page lists only the main changes for each version.

## Unreleased

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
