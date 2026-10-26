Scriptname MLWF_Main extends Quest
{Mantella Living World - Followers: Mantella actions for Nether's Follower Framework (NFF). NPCs join or leave the
party, wait, follow, stay out of fights or fight freely, and wear clothes the player hands them. Every order goes
through NFF's own commands, so NFF's menu always shows the same state.}

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

bool busy = false
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

Function Orders(int aiOrder, Actor[] akActors)
	int i = 0
	While i < akActors.Length
		If akActors[i]
			Order(aiOrder, akActors[i])
		EndIf
		i += 1
	EndWhile
EndFunction

; ---------------------------------------------------------------------------
; Orders
; ---------------------------------------------------------------------------

Function Order(int aiOrder, Actor akActor)
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
		hub.Log("followers", OrderName(aiOrder) + " for " + name)
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
	string[] orders = new string[7]
	orders[0] = "join"
	orders[1] = "leave"
	orders[2] = "wait"
	orders[3] = "follow"
	orders[4] = "passive"
	orders[5] = "aggressive"
	orders[6] = "wear this"
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
	Return "party=" + InParty(nff, akActor) + " waiting=" + akActor.GetActorValue("WaitingForPlayer") + " aggression=" + akActor.GetActorValue("Aggression") + " assistance=" + akActor.GetActorValue("Assistance") + " outfitSlot=" + akActor.GetFactionRank(sets.nwsFF_storedFac) + " situation=" + sets.OutfitTypeTarget(akActor)
EndFunction
