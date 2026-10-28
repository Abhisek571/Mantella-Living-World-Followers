Scriptname MLWF_Main extends Quest
{Mantella Living World - Followers: Mantella actions for Nether's Follower Framework (NFF). NPCs join or leave the
party, wait, follow, stay out of fights or fight freely, and wear clothes the player hands them. They also attack,
keep their distance, change combat style or role, relax, sit, loot, carry torches and gather. Every order goes
through NFF's own commands, so NFF's menu always shows the same state. At conversation start each NPC is told
which of the clothes they wear came from the player.}

Actor Property PlayerRef Auto

string Property NFF_PLUGIN = "nwsFollowerFramework.esp" AutoReadOnly
string Property PREFIX = "MantellaConversation_Action_" AutoReadOnly
string Property ADVANCED = "MantellaConversation_Advanced_Action_" AutoReadOnly
; NFF recruits on its own update a moment after the call.
float Property JOIN_TIMEOUT = 10.0 AutoReadOnly

int Property ORDER_JOIN = 0 AutoReadOnly
int Property ORDER_LEAVE = 1 AutoReadOnly
int Property ORDER_WAIT = 2 AutoReadOnly
int Property ORDER_FOLLOW = 3 AutoReadOnly
int Property ORDER_PASSIVE = 4 AutoReadOnly
int Property ORDER_AGGRESSIVE = 5 AutoReadOnly
int Property ORDER_WEAR = 6 AutoReadOnly
int Property ORDER_ATTACK = 7 AutoReadOnly
int Property ORDER_BEHIND = 8 AutoReadOnly
int Property ORDER_DISTANCE = 9 AutoReadOnly
int Property ORDER_STYLE = 10 AutoReadOnly
int Property ORDER_ROLE = 11 AutoReadOnly
int Property ORDER_SIT = 12 AutoReadOnly
int Property ORDER_TORCH = 13 AutoReadOnly

; Enemies are looked for this far around the player; the party is fetched only when all are farther than WARP_DISTANCE.
float Property SCAN_RADIUS = 4096.0 AutoReadOnly
float Property WARP_DISTANCE = 2000.0 AutoReadOnly

bool busy = false
; Testing: the last line sent to Mantella.
string lastEvent = ""
; The NPC whose inventory is open for "wear this", and the armor she had before.
Actor wearActor = None
Form[] wearForms
int[] wearCounts

Event OnInit()
	Register()
EndEvent

Function Register()
	RegisterForModEvent(ADVANCED + "mantella_mlw_join", "OnJoinAdvanced")
	RegisterForModEvent(PREFIX + "mantella_mlw_join", "OnJoinLegacy")
	RegisterForModEvent(ADVANCED + "mantella_mlw_leave", "OnLeaveAdvanced")
	RegisterForModEvent(PREFIX + "mantella_mlw_leave", "OnLeaveLegacy")
	RegisterForModEvent(ADVANCED + "mantella_mlw_wait", "OnWaitAdvanced")
	RegisterForModEvent(PREFIX + "mantella_mlw_wait", "OnWaitLegacy")
	RegisterForModEvent(ADVANCED + "mantella_mlw_follow", "OnFollowAdvanced")
	RegisterForModEvent(PREFIX + "mantella_mlw_follow", "OnFollowLegacy")
	RegisterForModEvent(ADVANCED + "mantella_mlw_passive", "OnPassiveAdvanced")
	RegisterForModEvent(PREFIX + "mantella_mlw_passive", "OnPassiveLegacy")
	RegisterForModEvent(ADVANCED + "mantella_mlw_aggressive", "OnAggressiveAdvanced")
	RegisterForModEvent(PREFIX + "mantella_mlw_aggressive", "OnAggressiveLegacy")
	RegisterForModEvent(ADVANCED + "mantella_mlw_wear", "OnWearAdvanced")
	RegisterForModEvent(PREFIX + "mantella_mlw_wear", "OnWearLegacy")
	RegisterForModEvent(ADVANCED + "mantella_mlw_wait_all", "OnWaitAllAdvanced")
	RegisterForModEvent(PREFIX + "mantella_mlw_wait_all", "OnWaitAllLegacy")
	RegisterForModEvent(ADVANCED + "mantella_mlw_follow_all", "OnFollowAllAdvanced")
	RegisterForModEvent(PREFIX + "mantella_mlw_follow_all", "OnFollowAllLegacy")
	RegisterForModEvent(ADVANCED + "mantella_mlw_attack_target", "OnAttackAdvanced")
	RegisterForModEvent(PREFIX + "mantella_mlw_attack_target", "OnAttackLegacy")
	RegisterForModEvent(ADVANCED + "mantella_mlw_stay_behind", "OnBehindAdvanced")
	RegisterForModEvent(PREFIX + "mantella_mlw_stay_behind", "OnBehindLegacy")
	RegisterForModEvent(ADVANCED + "mantella_mlw_follow_distance", "OnDistanceAdvanced")
	RegisterForModEvent(ADVANCED + "mantella_mlw_combat_style", "OnStyleAdvanced")
	RegisterForModEvent(ADVANCED + "mantella_mlw_role", "OnRoleAdvanced")
	RegisterForModEvent(ADVANCED + "mantella_mlw_sit_there", "OnSitAdvanced")
	RegisterForModEvent(PREFIX + "mantella_mlw_sit_there", "OnSitLegacy")
	RegisterForModEvent(ADVANCED + "mantella_mlw_torch", "OnTorchAdvanced")
	RegisterForModEvent(ADVANCED + "mantella_mlw_relax_here", "OnRelaxAdvanced")
	RegisterForModEvent(PREFIX + "mantella_mlw_relax_here", "OnRelaxLegacy")
	RegisterForModEvent(ADVANCED + "mantella_mlw_loot", "OnLootAdvanced")
	RegisterForModEvent(ADVANCED + "mantella_mlw_gather_party", "OnGatherAdvanced")
	RegisterForModEvent(PREFIX + "mantella_mlw_gather_party", "OnGatherLegacy")
	RegisterForModEvent("MantellaConversation_NPC_Added", "OnNpcAdded")
	RegisterForModEvent("MantellaConversation_Started", "OnConversationStarted")
	RegisterForModEvent("MLW_ReportRequest", "OnReportRequest")
EndFunction

; The hub's troubleshooting report asks every module for its state: every party member.
Event OnReportRequest()
	MLW_Hub hub = Hub()
	nwsFollowerControllerScript nff = Controller()
	If !hub
		Return
	ElseIf !nff
		hub.ReportAdd("followers", "Nether's Follower Framework not found")
		Return
	EndIf
	; NFF keeps its followers in the vanilla follower quest's aliases.
	Quest followers = Game.GetFormFromFile(0x0750BA, "Skyrim.esm") as Quest
	int shown = 0
	int i = 0
	While followers && i < 12
		ReferenceAlias slot = followers.GetAlias(i) as ReferenceAlias
		Actor member = None
		If slot
			member = slot.GetActorReference()
		EndIf
		If member && InParty(nff, member)
			hub.ReportAdd("followers", member.GetDisplayName() + ": " + TestState(member))
			shown += 1
		EndIf
		i += 1
	EndWhile
	If shown == 0
		hub.ReportAdd("followers", "no party members")
	EndIf
EndEvent

Event OnConversationStarted()
	Register()
EndEvent

; ---------------------------------------------------------------------------
; Mantella actions. Advanced events name the NPCs in "source"; legacy events (the LLM left out the arguments)
; carry only the speaker.
; ---------------------------------------------------------------------------

Event OnJoinAdvanced(Form akSpeaker, Form akConversation, int aiArguments)
	Orders(ORDER_JOIN, ResolveSources(akSpeaker, akConversation, aiArguments))
EndEvent
Event OnJoinLegacy(Form akSpeaker)
	Order(ORDER_JOIN, akSpeaker as Actor)
EndEvent
Event OnLeaveAdvanced(Form akSpeaker, Form akConversation, int aiArguments)
	Orders(ORDER_LEAVE, ResolveSources(akSpeaker, akConversation, aiArguments))
EndEvent
Event OnLeaveLegacy(Form akSpeaker)
	Order(ORDER_LEAVE, akSpeaker as Actor)
EndEvent
Event OnWaitAdvanced(Form akSpeaker, Form akConversation, int aiArguments)
	Orders(ORDER_WAIT, ResolveSources(akSpeaker, akConversation, aiArguments))
EndEvent
Event OnWaitLegacy(Form akSpeaker)
	Order(ORDER_WAIT, akSpeaker as Actor)
EndEvent
Event OnFollowAdvanced(Form akSpeaker, Form akConversation, int aiArguments)
	Orders(ORDER_FOLLOW, ResolveSources(akSpeaker, akConversation, aiArguments))
EndEvent
Event OnFollowLegacy(Form akSpeaker)
	Order(ORDER_FOLLOW, akSpeaker as Actor)
EndEvent
Event OnPassiveAdvanced(Form akSpeaker, Form akConversation, int aiArguments)
	Orders(ORDER_PASSIVE, ResolveSources(akSpeaker, akConversation, aiArguments))
EndEvent
Event OnPassiveLegacy(Form akSpeaker)
	Order(ORDER_PASSIVE, akSpeaker as Actor)
EndEvent
Event OnAggressiveAdvanced(Form akSpeaker, Form akConversation, int aiArguments)
	Orders(ORDER_AGGRESSIVE, ResolveSources(akSpeaker, akConversation, aiArguments))
EndEvent
Event OnAggressiveLegacy(Form akSpeaker)
	Order(ORDER_AGGRESSIVE, akSpeaker as Actor)
EndEvent
; Clothes go to one NPC at a time: the first one named.
Event OnWearAdvanced(Form akSpeaker, Form akConversation, int aiArguments)
	Order(ORDER_WEAR, ResolveSources(akSpeaker, akConversation, aiArguments)[0])
EndEvent
Event OnWearLegacy(Form akSpeaker)
	Order(ORDER_WEAR, akSpeaker as Actor)
EndEvent

; Mod events only reach handlers whose parameters match what Mantella sends, hence a pair per action.
Event OnWaitAllAdvanced(Form akSpeaker, Form akConversation, int aiArguments)
	PartyOrder(true)
EndEvent
Event OnWaitAllLegacy(Form akSpeaker)
	PartyOrder(true)
EndEvent
Event OnFollowAllAdvanced(Form akSpeaker, Form akConversation, int aiArguments)
	PartyOrder(false)
EndEvent
Event OnFollowAllLegacy(Form akSpeaker)
	PartyOrder(false)
EndEvent

; Actions with a choice ("distance", "style", "role", "state") have no legacy handler: without the argument there
; is nothing to do.
Event OnAttackAdvanced(Form akSpeaker, Form akConversation, int aiArguments)
	Orders(ORDER_ATTACK, ResolveSources(akSpeaker, akConversation, aiArguments), SKSE_HTTP.getString(aiArguments, "target", ""))
EndEvent
Event OnAttackLegacy(Form akSpeaker)
	Order(ORDER_ATTACK, akSpeaker as Actor)
EndEvent
Event OnBehindAdvanced(Form akSpeaker, Form akConversation, int aiArguments)
	Orders(ORDER_BEHIND, ResolveSources(akSpeaker, akConversation, aiArguments))
EndEvent
Event OnBehindLegacy(Form akSpeaker)
	Order(ORDER_BEHIND, akSpeaker as Actor)
EndEvent
Event OnDistanceAdvanced(Form akSpeaker, Form akConversation, int aiArguments)
	Orders(ORDER_DISTANCE, ResolveSources(akSpeaker, akConversation, aiArguments), SKSE_HTTP.getString(aiArguments, "distance", ""))
EndEvent
Event OnStyleAdvanced(Form akSpeaker, Form akConversation, int aiArguments)
	Orders(ORDER_STYLE, ResolveSources(akSpeaker, akConversation, aiArguments), SKSE_HTTP.getString(aiArguments, "style", ""))
EndEvent
Event OnRoleAdvanced(Form akSpeaker, Form akConversation, int aiArguments)
	Orders(ORDER_ROLE, ResolveSources(akSpeaker, akConversation, aiArguments), SKSE_HTTP.getString(aiArguments, "role", ""))
EndEvent
; One seat, one NPC: the first one named.
Event OnSitAdvanced(Form akSpeaker, Form akConversation, int aiArguments)
	Order(ORDER_SIT, ResolveSources(akSpeaker, akConversation, aiArguments)[0])
EndEvent
Event OnSitLegacy(Form akSpeaker)
	Order(ORDER_SIT, akSpeaker as Actor)
EndEvent
Event OnTorchAdvanced(Form akSpeaker, Form akConversation, int aiArguments)
	Orders(ORDER_TORCH, ResolveSources(akSpeaker, akConversation, aiArguments), SKSE_HTTP.getString(aiArguments, "state", ""))
EndEvent
; Relaxing, looting and gathering are party-wide in NFF.
Event OnRelaxAdvanced(Form akSpeaker, Form akConversation, int aiArguments)
	Relax()
EndEvent
Event OnRelaxLegacy(Form akSpeaker)
	Relax()
EndEvent
Event OnLootAdvanced(Form akSpeaker, Form akConversation, int aiArguments)
	string choice = SKSE_HTTP.getString(aiArguments, "state", "")
	If choice == "on" || choice == "off"
		Loot(choice == "on")
	EndIf
EndEvent
Event OnGatherAdvanced(Form akSpeaker, Form akConversation, int aiArguments)
	Gather()
EndEvent
Event OnGatherLegacy(Form akSpeaker)
	Gather()
EndEvent

Function PartyOrder(bool abWait)
	nwsFollowerControllerScript nff = Controller()
	If !nff
		Return
	EndIf
	MLW_Hub hub = Hub()
	If hub
		hub.Log("followers", "party order, wait=" + abWait)
	EndIf
	If abWait
		nff.WaitAll()
	Else
		nff.FollowAll()
	EndIf
EndFunction

; Turns the "source" names into actors. Falls back to the speaker when no name resolves, the same fallback
; Mantella uses for its own actions.
Actor[] Function ResolveSources(Form akSpeaker, Form akConversation, int aiArguments)
	Actor[] result = new Actor[10]
	int found = 0
	MantellaConversation conversation = akConversation as MantellaConversation
	string[] names = SKSE_HTTP.getStringArray(aiArguments, "source")
	int i = 0
	While conversation && i < names.Length && found < result.Length
		Actor npc = conversation.GetActorByName(names[i])
		If npc && result.Find(npc) < 0
			result[found] = npc
			found += 1
		EndIf
		i += 1
	EndWhile
	If found == 0
		result[0] = akSpeaker as Actor
	EndIf
	Return result
EndFunction

Function Orders(int aiOrder, Actor[] akActors, string asOption = "")
	int i = 0
	While i < akActors.Length
		If akActors[i]
			Order(aiOrder, akActors[i], asOption)
		EndIf
		i += 1
	EndWhile
EndFunction

; ---------------------------------------------------------------------------
; Orders
; ---------------------------------------------------------------------------

; asOption: the action's choice (distance, style, role, torch on/off) or, for an attack, the target's name.
Function Order(int aiOrder, Actor akActor, string asOption = "")
	If !akActor || akActor == PlayerRef || akActor.IsDead()
		Return
	EndIf
	nwsFollowerControllerScript nff = Controller()
	If !nff
		Debug.Notification("Living World Followers: Nether's Follower Framework is not installed.")
		Return
	EndIf
	string name = akActor.GetDisplayName()
	MLW_Hub hub = Hub()
	If hub
		hub.Log("followers", OrderName(aiOrder) + " " + asOption + " for " + name)
	EndIf
	If aiOrder == ORDER_JOIN
		Lock()
		Join(nff, akActor)
		Unlock()
	ElseIf !InParty(nff, akActor)
		Tell(name + " is not in your party.", name + " is not one of the player's followers.")
	ElseIf aiOrder == ORDER_LEAVE
		nff.RemoveFollower(akActor, 0, 0)
	ElseIf aiOrder == ORDER_WAIT
		nff.FollowerWaitHere(akActor, 0, 0)
		Debug.Notification(name + " waits here.")
	ElseIf aiOrder == ORDER_FOLLOW
		nff.FollowerFollowMe(akActor, 0)
		Debug.Notification(name + " follows you.")
	ElseIf aiOrder == ORDER_PASSIVE || aiOrder == ORDER_AGGRESSIVE
		Behave(nff, akActor, aiOrder == ORDER_PASSIVE)
	ElseIf aiOrder == ORDER_WEAR
		OpenForClothes(akActor)
	ElseIf aiOrder == ORDER_ATTACK
		Attack(nff, akActor, asOption)
	ElseIf aiOrder == ORDER_BEHIND
		If akActor.GetActorValue("WaitingForPlayer") > 0
			nff.FollowerFollowMe(akActor, 0)
		EndIf
		nff.BehindMe(akActor)
		Debug.Notification(name + " stays behind you.")
	ElseIf aiOrder == ORDER_DISTANCE
		FollowDistance(nff, akActor, asOption)
	ElseIf aiOrder == ORDER_STYLE
		CombatStyle(nff, akActor, asOption)
	ElseIf aiOrder == ORDER_ROLE
		Role(nff, akActor, asOption)
	ElseIf aiOrder == ORDER_SIT
		Sit(nff, akActor)
	ElseIf aiOrder == ORDER_TORCH
		Torch(nff, akActor, asOption)
	EndIf
EndFunction

Function Join(nwsFollowerControllerScript akNff, Actor akActor)
	string name = akActor.GetDisplayName()
	If InParty(akNff, akActor)
		If akActor.GetActorValue("WaitingForPlayer") > 0
			akNff.FollowerFollowMe(akActor, 0)
			Debug.Notification(name + " follows you again.")
		Else
			Debug.Notification(name + " is already in your party.")
		EndIf
		Return
	EndIf
	ReleaseFromMantella(akActor)
	akNff.RecruitFollower(akActor)
	float waited = 0.0
	While waited < JOIN_TIMEOUT && !InParty(akNff, akActor)
		Utility.Wait(0.5)
		waited += 0.5
	EndWhile
	If !InParty(akNff, akActor)
		Tell(name + " could not join: your party may be full.", name + " could not join the party; it may be full.")
	EndIf
EndFunction

; Passive: never starts a fight and does not help in one (aggression 0, assistance 0). Fights freely: attacks
; enemies and helps allies (aggression 1, assistance 2). Set through NFF, which keeps the value in its own
; factions; the faction ranks are set too because NFF only writes them the first time.
Function Behave(nwsFollowerControllerScript akNff, Actor akActor, bool abPassive)
	ReferenceAlias slot = akNff.SearchAlias(akActor, 1)
	int aggression = 1
	int assistance = 2
	If abPassive
		aggression = 0
		assistance = 0
	EndIf
	akNff.SetBehavior(slot, 0, aggression)
	akNff.SetBehavior(slot, 1, assistance)
	Faction aggrFac = Game.GetFormFromFile(0x081748, NFF_PLUGIN) as Faction
	Faction assistFac = Game.GetFormFromFile(0x081749, NFF_PLUGIN) as Faction
	If aggrFac
		akActor.SetFactionRank(aggrFac, aggression)
	EndIf
	If assistFac
		akActor.SetFactionRank(assistFac, assistance)
	EndIf
	If abPassive
		akActor.StopCombat()
		akActor.StopCombatAlarm()
		Debug.Notification(akActor.GetDisplayName() + " stays out of fights.")
	Else
		Debug.Notification(akActor.GetDisplayName() + " fights freely.")
	EndIf
	akActor.EvaluatePackage()
EndFunction

; Attack: the enemy named in "target", else the actor the player points at, else the nearest enemy. Someone who is no
; enemy (not hostile to the player and not fighting the party) is refused, and the NPCs are told why.
Function Attack(nwsFollowerControllerScript akNff, Actor akActor, string asTarget)
	string name = akActor.GetDisplayName()
	Actor target = FindTarget(akNff, akActor, asTarget)
	If !target
		Tell(name + " sees no enemy to attack.", name + " sees no enemy to attack.")
		Return
	EndIf
	string targetName = target.GetDisplayName()
	If target.IsDead()  ; the scan takes a moment; someone else may have killed it meanwhile
		Tell(targetName + " is already dead.", targetName + " is already dead; " + name + " has nobody to attack.")
		Return
	EndIf
	If !IsEnemy(akNff, target)
		Tell(name + " will not attack " + targetName + ".", name + " refuses to attack " + targetName + ", who is not an enemy.")
		Return
	EndIf
	akActor.StartCombat(target)
	Debug.Notification(name + " attacks " + targetName + ".")
EndFunction

Actor Function FindTarget(nwsFollowerControllerScript akNff, Actor akActor, string asTarget)
	Actor[] nearby = MiscUtil.ScanCellNPCs(PlayerRef, SCAN_RADIUS, None, true)
	Actor named = None
	Actor nearest = None
	float nearestDistance = 0.0
	int i = 0
	While i < nearby.Length
		Actor other = nearby[i]
		If other && other != akActor && other != PlayerRef
			bool enemy = IsEnemy(akNff, other)
			; String comparison is case-insensitive in Papyrus. A hostile namesake wins over a friendly one.
			If asTarget != "" && other.GetDisplayName() == asTarget && (!named || enemy)
				named = other
			EndIf
			If enemy
				float distance = other.GetDistance(PlayerRef)
				If !nearest || distance < nearestDistance
					nearest = other
					nearestDistance = distance
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile
	If named
		Return named
	EndIf
	Actor aimed = Game.GetCurrentCrosshairRef() as Actor
	If aimed && aimed != akActor && aimed != PlayerRef && !aimed.IsDead()
		Return aimed
	EndIf
	Return nearest
EndFunction

bool Function IsEnemy(nwsFollowerControllerScript akNff, Actor akActor)
	If akActor == PlayerRef || akActor.IsDead() || akActor.IsPlayerTeammate() || InParty(akNff, akActor)
		Return false
	ElseIf akActor.IsHostileToActor(PlayerRef)
		Return true
	EndIf
	Actor fighting = akActor.GetCombatTarget()
	Return fighting && (fighting == PlayerRef || InParty(akNff, fighting))
EndFunction

; NFF's follow range: faction rank 1 close, 0 medium, 2 far (NFF menu "Set Follow Range").
Function FollowDistance(nwsFollowerControllerScript akNff, Actor akActor, string asDistance)
	string name = akActor.GetDisplayName()
	int range = -1
	If asDistance == "near"
		range = 1
	ElseIf asDistance == "normal"
		range = 0
	ElseIf asDistance == "far"
		range = 2
	EndIf
	If range < 0 || !akNff.varScript
		Return
	ElseIf akActor.IsInFaction(akNff.varScript.nwsFF_DefaultFollow)
		Tell(name + " keeps the default follow package (NFF setting).", name + " keeps the usual follow distance; Nether's Follower Framework is set to the default follow behavior.")
		Return
	EndIf
	akNff.PerformTask(10, akActor, range, akNff.SearchAlias(akActor, 1))
	Debug.Notification(name + " follows at " + asDistance + " distance.")
EndFunction

; NFF combat styles (index in its list): 0 Mercenary (melee), 3 Archer (ranged), 6 Wizard (magic). NFF sets them on
; the actor base, so like NFF's own menu this only works for unique NPCs.
Function CombatStyle(nwsFollowerControllerScript akNff, Actor akActor, string asStyle)
	string name = akActor.GetDisplayName()
	int style = -1
	If asStyle == "melee"
		style = 0
	ElseIf asStyle == "ranged"
		style = 3
	ElseIf asStyle == "magic"
		style = 6
	EndIf
	If style < 0 || !akNff.varScript
		Return
	ElseIf !akActor.GetActorBase().IsUnique()
		Tell(name + " can't change combat style (not a unique NPC).", name + " can't change fighting style.")
		Return
	ElseIf akActor.IsInFaction(akNff.varScript.nwsFF_DefaultCombat)
		Tell(name + " keeps the default combat style (NFF setting).", name + " keeps the usual way of fighting; Nether's Follower Framework is set to the default combat style.")
		Return
	EndIf
	akNff.SetCombatST(akNff.SearchAlias(akActor, 1), akActor, 1, style)
	Debug.Notification(name + " now fights " + asStyle + ".")
	If style == 3 && !HasBow(akActor)
		Tell("", name + " has no bow or crossbow to shoot with.")
	EndIf
EndFunction

bool Function HasBow(Actor akActor)
	int i = akActor.GetNumItems()
	While i > 0
		i -= 1
		Weapon item = akActor.GetNthForm(i) as Weapon
		If item && (item.GetWeaponType() == 7 || item.GetWeaponType() == 9)
			Return true
		EndIf
	EndWhile
	Return false
EndFunction

; NFF roles: 0 standard, 1 healer, 2 tank, with the same stamina and magicka limits as NFF's menu.
Function Role(nwsFollowerControllerScript akNff, Actor akActor, string asRole)
	string name = akActor.GetDisplayName()
	int role = -1
	bool able = true
	If asRole == "none"
		role = 0
	ElseIf asRole == "healer"
		role = 1
		able = akActor.GetActorValue("Magicka") >= 80.0 || akActor.GetActorValue("Stamina") >= 50.0
	ElseIf asRole == "tank"
		role = 2
		able = akActor.GetActorValue("Stamina") >= 30.0
	EndIf
	If role < 0
		Return
	ElseIf !able
		Tell(name + " can't be a " + asRole + " yet.", name + " is not strong enough yet to be the party's " + asRole + ".")
		Return
	EndIf
	akNff.SetFollowerRole(akActor, role)
	If role == 0
		Debug.Notification(name + " has no special role now.")
	Else
		Debug.Notification(name + " is now the party's " + asRole + ".")
	EndIf
EndFunction

; Sit on the seat the player points at. She waits there afterwards, so she doesn't get up to follow at once.
Function Sit(nwsFollowerControllerScript akNff, Actor akActor)
	string name = akActor.GetDisplayName()
	ObjectReference seat = Game.GetCurrentCrosshairRef()
	If !seat || !(seat.GetBaseObject() as Furniture)
		Tell("Look at a seat for " + name + " to sit on.", "There is no seat where the player points for " + name + ".")
		Return
	ElseIf seat.IsFurnitureInUse()
		Tell("That seat is taken.", "The seat the player points at is taken.")
		Return
	EndIf
	akNff.FollowerWaitHere(akActor, 0, 0)
	seat.Activate(akActor)
	Tell(name + " sits down there.", name + " sits down and waits there until asked to follow again.")
EndFunction

; Torch on: NFF gives back the torches it stored; with none stored she takes one from the player. Torch off: NFF
; takes her torches and keeps the count.
Function Torch(nwsFollowerControllerScript akNff, Actor akActor, string asState)
	string name = akActor.GetDisplayName()
	If !akNff.varScript || (asState != "on" && asState != "off")
		Return
	EndIf
	Form torchItem = akNff.varScript.Torch01
	ReferenceAlias slot = akNff.SearchAlias(akActor, 1)
	If asState == "off"
		akNff.TakeTorches(slot)
		Debug.Notification(name + " puts the torches away.")
		Return
	EndIf
	akNff.GiveTorches(slot)
	If akActor.GetItemCount(torchItem) == 0
		If PlayerRef.GetItemCount(torchItem) == 0
			Tell(name + " has no torch.", name + " has no torch, and the player has none to give.")
			Return
		EndIf
		PlayerRef.RemoveItem(torchItem, 1, true, akActor)
	EndIf
	Debug.Notification(name + " carries a torch in the dark.")
EndFunction

; Turns on NFF's relax mode: the party relaxes nearby while the player stays put.
Function Relax()
	nwsFollowerControllerScript nff = Controller()
	If !nff || !nff.varScript
		Return
	ElseIf nff.varScript.nwsAllowSandbox.GetValue() >= 1.0
		Tell("", "The party already relaxes nearby whenever the player stays put.")
		Return
	EndIf
	nff.ToggleSandbox()
	Tell("", "The party relaxes nearby while the player stays put.")
EndFunction

Function Loot(bool abOn)
	nwsFollowerControllerScript nff = Controller()
	If !nff || nff.QueryLooting() == abOn
		Return
	EndIf
	nff.CallLooting(abOn, !abOn, false)
	If abOn
		Tell("", "The party loots bodies and containers nearby.")
	Else
		Tell("", "The party stops looting.")
	EndIf
EndFunction

; Everyone follows. Only when every member is out of sight and farther than WARP_DISTANCE does NFF move them to the
; player, so nobody pops into view.
Function Gather()
	nwsFollowerControllerScript nff = Controller()
	If !nff
		Return
	EndIf
	Actor[] members = PartyMembers(nff)
	If !members[0]
		Tell("You have no party.", "The player has no party to gather.")
		Return
	EndIf
	nff.FollowAll()
	bool allAway = true
	int i = 0
	While i < members.Length && members[i] && allAway
		allAway = members[i].GetDistance(PlayerRef) > WARP_DISTANCE && !PlayerRef.HasLOS(members[i])
		i += 1
	EndWhile
	If allAway
		nff.WarpAll()
		Tell("", "The party catches up with the player.")
	Else
		Tell("", "The party gathers around the player.")
	EndIf
EndFunction

; Every NFF party member (NFF keeps them in the vanilla follower quest's aliases).
Actor[] Function PartyMembers(nwsFollowerControllerScript akNff)
	Actor[] result = new Actor[12]
	Quest followers = Game.GetFormFromFile(0x0750BA, "Skyrim.esm") as Quest
	int n = 0
	int i = 0
	While followers && i < 12
		ReferenceAlias slot = followers.GetAlias(i) as ReferenceAlias
		If slot
			Actor member = slot.GetActorReference()
			If member && InParty(akNff, member)
				result[n] = member
				n += 1
			EndIf
		EndIf
		i += 1
	EndWhile
	Return result
EndFunction

; ---------------------------------------------------------------------------
; Default vs given clothes: what an NPC wears is her own choice, except clothes that came from the player.
; ---------------------------------------------------------------------------

Event OnNpcAdded(Form akActor)
	CheckClothes(akActor as Actor)
EndEvent

; Sends "(Vega wears Steel Armor, which CHAD gave her.)" when she wears body, hand, foot or head armor the player
; handed over, and returns that line ("" = all her own).
string Function CheckClothes(Actor akActor)
	If !akActor || akActor == PlayerRef || akActor.IsDead()
		Return ""
	EndIf
	string line = GivenClothesLine(akActor)
	If line != ""
		Tell("", line)
	EndIf
	Return line
EndFunction

; Only NPCs the player could have handed clothes: party members, teammates, NPCs with an NFF outfit and close
; friends (spouse, housecarl). Strangers whose mods dress them from their inventory are left alone.
string Function GivenClothesLine(Actor akActor)
	nwsFollowerControllerScript nff = Controller()
	nwsFollowerSetsScript sets = Sets()
	bool hasNffOutfit = sets && akActor.IsInFaction(sets.nwsFF_storedFac)
	If !(hasNffOutfit || akActor.IsPlayerTeammate() || (nff && InParty(nff, akActor)) || akActor.GetRelationshipRank(PlayerRef) >= 3)
		Return ""
	EndIf
	; Given = it once left the player's inventory (MLWF_GiftsAlias). Many follower mods dress their NPC from the
	; inventory with no outfit record at all, so the outfit can't tell what is her own.
	; Head (30), hair or hood (31), body (32), hands (33), feet (37). Weapons and jewelry don't count.
	int[] masks = new int[5]
	masks[0] = 0x00000001
	masks[1] = 0x00000002
	masks[2] = 0x00000004
	masks[3] = 0x00000008
	masks[4] = 0x00000080
	Form[] seen = new Form[5]
	string names = ""
	int count = 0
	int i = 0
	While i < masks.Length
		Form item = akActor.GetWornForm(masks[i])
		If item && seen.Find(item) < 0
			seen[i] = item
			If StorageUtil.FormListHas(None, "MLWF_GivenClothes", item)
				If count > 0
					names += " and "
				EndIf
				names += item.GetName()
				count += 1
			EndIf
		EndIf
		i += 1
	EndWhile
	If count == 0
		Return ""
	EndIf
	string pronoun = "him"
	If akActor.GetActorBase().GetSex() == 1
		pronoun = "her"
	EndIf
	Return "(" + akActor.GetDisplayName() + " wears " + names + ", which " + PlayerRef.GetDisplayName() + " gave " + pronoun + ".)"
EndFunction


; ---------------------------------------------------------------------------
; Wear this: the player hands over clothes in the trade window; on close she puts on the new pieces and they
; become her NFF outfit for where she is now (adventuring, town or home).
; ---------------------------------------------------------------------------

Function OpenForClothes(Actor akActor)
	If wearActor
		Return
	EndIf
	wearActor = akActor
	SnapshotArmor(akActor)
	RegisterForMenu("ContainerMenu")
	akActor.OpenInventory(true)
EndFunction

Event OnMenuClose(string asMenuName)
	UnregisterForMenu("ContainerMenu")
	Actor npc = wearActor
	If !npc
		Return
	EndIf
	Lock()
	; Changing clothes floods Mantella with equip lines; the hub mutes them for a few seconds.
	MLW_Hub hub = Hub()
	If hub
		hub.Quiet("followers")
	EndIf
	Form[] added = NewArmor(npc)
	If added.Length == 0 || !added[0]
		Debug.Notification(npc.GetDisplayName() + " got nothing new to wear.")
	Else
		string names = ""
		int i = 0
		While i < added.Length && added[i]
			npc.EquipItem(added[i], false, true)
			If i > 0
				names += ", "
			EndIf
			names += added[i].GetName()
			i += 1
		EndWhile
		Utility.Wait(1.0)
		; Where the player is decides the outfit: 0 adventuring, 1 town, 2 home (NFF's own location check).
		nwsFollowerSetsScript sets = Sets()
		int situation = 0
		If sets
			sets.CheckPlayerLoc()
			situation = sets.lastLocType
			If situation < 0 || situation > 2
				situation = 0
			EndIf
		EndIf
		If SaveOutfit(npc, situation, WornArmor(npc), true)
			Debug.Notification(npc.GetDisplayName() + " now wears this as the " + SituationName(situation) + " outfit.")
		EndIf
		Tell("", npc.GetDisplayName() + " put on the clothes the player gave: " + names + ".")
	EndIf
	If hub
		hub.Unquiet("followers", 10.0)
	EndIf
	wearActor = None
	Unlock()
EndEvent

Function SnapshotArmor(Actor akActor)
	wearForms = new Form[128]
	wearCounts = new int[128]
	int n = 0
	int i = 0
	int total = akActor.GetNumItems()
	While i < total && n < 128
		Form item = akActor.GetNthForm(i)
		If item as Armor
			wearForms[n] = item
			wearCounts[n] = akActor.GetItemCount(item)
			n += 1
		EndIf
		i += 1
	EndWhile
EndFunction

; Armor the NPC has more of than before the trade window opened.
Form[] Function NewArmor(Actor akActor)
	Form[] result = new Form[32]
	int n = 0
	int i = 0
	int total = akActor.GetNumItems()
	While i < total && n < 32
		Form item = akActor.GetNthForm(i)
		If item as Armor
			int before = 0
			int at = wearForms.Find(item)
			If at >= 0
				before = wearCounts[at]
			EndIf
			If akActor.GetItemCount(item) > before
				result[n] = item
				n += 1
			EndIf
		EndIf
		i += 1
	EndWhile
	Return result
EndFunction

; Every armor piece the NPC wears now, once each.
Form[] Function WornArmor(Actor akActor)
	Form[] result = new Form[32]
	int n = 0
	int i = 0
	While i < 32
		Form item = akActor.GetWornForm(Math.LeftShift(1, i))
		If item && result.Find(item) < 0
			result[n] = item
			n += 1
		EndIf
		i += 1
	EndWhile
	Return result
EndFunction

string Function OrderName(int aiOrder)
	string[] orders = new string[14]
	orders[0] = "join"
	orders[1] = "leave"
	orders[2] = "wait"
	orders[3] = "follow"
	orders[4] = "passive"
	orders[5] = "aggressive"
	orders[6] = "wear this"
	orders[7] = "attack"
	orders[8] = "stay behind"
	orders[9] = "follow distance"
	orders[10] = "combat style"
	orders[11] = "role"
	orders[12] = "sit there"
	orders[13] = "torch"
	Return orders[aiOrder]
EndFunction

string Function SituationName(int aiType)
	If aiType == 1
		Return "town"
	ElseIf aiType == 2
		Return "home"
	EndIf
	Return "adventuring"
EndFunction

; Stores akItems as the NPC's NFF outfit for one situation (0 adventuring, 1 town, 2 home), the same way NFF's own
; "Set Outfit" does after the player fills the outfit chest. abTakeFromActor moves the pieces out of her
; inventory (clothes she was given); otherwise new copies are created.
bool Function SaveOutfit(Actor akActor, int aiType, Form[] akItems, bool abTakeFromActor)
	nwsFollowerSetsScript sets = Sets()
	nwsFollowerControllerScript nff = Controller()
	If !sets || !nff || sets.isProcessing
		Return false
	EndIf
	bool isNew = !akActor.IsInFaction(sets.nwsFF_storedFac)
	int slot
	If isNew
		slot = sets.outfitActors.Find(None)
		If slot < 0
			Debug.Notification("Nether's Follower Framework has no free outfit slot.")
			Return false
		EndIf
		ReferenceAlias follower = nff.SearchAlias(akActor, 1)
		If !follower
			Return false
		EndIf
		akActor.AddToFaction(sets.nwsFF_storedFac)
		akActor.SetFactionRank(sets.nwsFF_storedFac, slot)
		sets.outfitActors[slot] = akActor
		akActor.AddToFaction(sets.nwsFF_OutTypeFac)
		akActor.SetFactionRank(sets.nwsFF_OutTypeFac, aiType)
		sets.mcmScr.outfitsInUse[slot] = sets.CreateListName(slot, akActor)
		(follower as followeraliasscript).myContainer = sets.nwsFFSatchelList.GetAt(slot) as ObjectReference
		sets.outfitActor = akActor
		sets.StoreOriginalOutfit(slot)
	Else
		slot = akActor.GetFactionRank(sets.nwsFF_storedFac)
	EndIf
	sets.AddOutfitFaction(akActor, aiType)
	ObjectReference chest
	If aiType == 1
		chest = sets.nwsFFTownChestList.GetAt(slot) as ObjectReference
	ElseIf aiType == 2
		chest = sets.nwsFFHomeChestList.GetAt(slot) as ObjectReference
	Else
		chest = sets.nwsFFOutfitChestList.GetAt(slot) as ObjectReference
	EndIf
	; A previous outfit for this situation goes back into her inventory, nothing is lost.
	chest.RemoveAllItems(akActor, false, true)
	int i = 0
	While i < akItems.Length
		If akItems[i]
			If abTakeFromActor && akActor.GetItemCount(akItems[i]) > 0
				akActor.RemoveItem(akItems[i], 1, true, chest)
			Else
				chest.AddItem(akItems[i], 1, true)
			EndIf
		EndIf
		i += 1
	EndWhile
	; NFF's preview mode would move her whole inventory; the stored outfit works without it.
	int oldView = sets.viewMode
	sets.viewMode = 0
	sets.outfitActor = akActor
	sets.createType = aiType
	sets.newOutfit = isNew
	sets.currentSlot = slot
	sets.outfitChest = chest
	sets.CompleteOutfit()
	sets.viewMode = oldView
	Return true
EndFunction

; ---------------------------------------------------------------------------
; Helpers
; ---------------------------------------------------------------------------

MLW_Hub Function Hub()
	Return Game.GetFormFromFile(0x000820, "Mantella Living World - Integration Hub.esp") as MLW_Hub
EndFunction

nwsFollowerControllerScript Function Controller()
	Return Game.GetFormFromFile(0x00434F, NFF_PLUGIN) as nwsFollowerControllerScript
EndFunction

nwsFollowerSetsScript Function Sets()
	Return Game.GetFormFromFile(0x0487C1, NFF_PLUGIN) as nwsFollowerSetsScript
EndFunction

bool Function InParty(nwsFollowerControllerScript akNff, Actor akActor)
	Return akNff.SearchAlias(akActor, 1) != None
EndFunction

bool Function IsMantellaFollower(Actor akActor)
	Faction following = Game.GetFormFromFile(0x003806, "Mantella.esp") as Faction
	Return following && akActor.IsInFaction(following)
EndFunction

; Takes an NPC out of Mantella's own follower quest, if it put them there, so only NFF manages her.
Function ReleaseFromMantella(Actor akActor)
	If !IsMantellaFollower(akActor)
		Return
	EndIf
	Faction following = Game.GetFormFromFile(0x003806, "Mantella.esp") as Faction
	Quest followerQuest = Game.GetFormFromFile(0x021211, "Mantella.esp") as Quest
	akActor.RemoveFromFaction(following)
	akActor.SetPlayerTeammate(false)
	If followerQuest
		followerQuest.Reset()
		followerQuest.Stop()
		Utility.Wait(0.5)
		followerQuest.Start()
	EndIf
	akActor.EvaluatePackage()
EndFunction

; Shows a notification (if any) and tells the NPCs in the conversation what happened.
Function Tell(string asNotification, string asEvent)
	If asNotification != ""
		Debug.Notification(asNotification)
	EndIf
	If asEvent != ""
		lastEvent = asEvent
	EndIf
	int handle = ModEvent.Create("MantellaAddEvent")
	If handle
		ModEvent.PushString(handle, asEvent)
		ModEvent.Send(handle)
	EndIf
EndFunction

Function Lock()
	While busy
		Utility.WaitMenuMode(0.25)
	EndWhile
	busy = true
EndFunction

Function Unlock()
	busy = false
EndFunction

; Testing: the NPC's NFF state as text.
string Function TestState(Actor akActor)
	nwsFollowerControllerScript nff = Controller()
	nwsFollowerSetsScript sets = Sets()
	If !nff || !sets
		Return "no NFF"
	EndIf
	string text = "party=" + InParty(nff, akActor) + " waiting=" + akActor.GetActorValue("WaitingForPlayer") + " aggression=" + akActor.GetActorValue("Aggression") + " assistance=" + akActor.GetActorValue("Assistance") + " outfitSlot=" + akActor.GetFactionRank(sets.nwsFF_storedFac) + " situation=" + sets.OutfitTypeTarget(akActor)
	nwsFollowerVariableScript vars = nff.varScript
	If vars
		text += " range=" + akActor.GetFactionRank(vars.nwsFF_NCRangeFac) + " style=" + akActor.GetFactionRank(vars.nwsFF_CSFac) + " role=" + akActor.GetFactionRank(vars.nwsFF_RoleFac) + " torches=" + akActor.GetItemCount(vars.Torch01) + " relax=" + vars.nwsAllowSandbox.GetValue()
	EndIf
	Return text + " looting=" + nff.QueryLooting() + " combat=" + akActor.IsInCombat() + " sit=" + akActor.GetSitState()
EndFunction

; Testing: the last line sent to Mantella; forgets it.
string Function TestTakeEvent()
	string line = lastEvent
	lastEvent = ""
	Return line
EndFunction
