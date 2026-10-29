Mantella Living World - Followers
Version 1.0.0 by itsPigeon2000

Mantella actions for Nether's Follower Framework: NPCs join or leave your party, wait, follow, stay out of fights or fight freely, attack a target, change combat style, role and follow distance, sit, carry torches, loot, and wear clothes you hand them. Everything except joining is only offered to followers.

Requirements
- Mantella Living World - Integration Hub
- Mantella - Direct AI Connect (needed by the Hub)
- Mantella 0.14
- Nether's Follower Framework
- PapyrusUtil and SKSE
If the Hub or NFF is missing, nothing warns you at load; the actions just do nothing.
Combat style, party role, follow distance, carry torch and party loot need Mantella's Advanced Actions on; the other orders work without it.

Before you start
1. Mantella 0.14: install it and check that a normal conversation works.
2. Mantella - Direct AI Connect: install it below Mantella in MO2 and run its Setup Backend.cmd once (needs Python 3.11). Without it the stock Mantella.exe runs and Living World does nothing.
3. Mantella Living World - Integration Hub, then the modules you want.
4. API key: your LLM service's key stays in GPT_SECRET_KEY.txt in the Mantella mod folder (in MO2, right-click Mantella, Open in Explorer). A key for another service goes in the file named on the Direct AI Connect page, next to it.
5. Open Mantella's settings page (http://localhost:4999/ui in your browser, only while Mantella is running), go to the Actions tab and turn on Advanced Actions. Many Living World actions (bribe, persuade, marriage steps, positions, map marks and others) only work with it, and it needs a model that supports tool calling.
6. Nothing happens? Living World Main Status in Mantella's settings page lists what is missing.

Installation
1. Install the hub, then this module.
2. In the Mantella UI's action settings, turn off Mantella's own Follow, Unfollow, Wait and Loot.

Credits
- Mantella by Art from the Machine and contributors (AGPL-3.0)
- Nether's Follower Framework by Nether
- SKSE team

License
GNU Affero General Public License v3.0 (see LICENSE.txt). Script sources are included in Scripts\Source.
Source code: https://github.com/Abhisek571/Mantella-Living-World-Followers
