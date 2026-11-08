Scriptname MLWF_GiftsAlias extends ReferenceAlias
{On the player: remembers every piece of armor or clothing the player hands to a living NPC (directly or in a
trade window), on that NPC, so an NPC wearing it is known to wear something the player gave. Armor sold, stored in
a chest or left on a corpse is not a gift. Everything an NPC wears that never passed from the player to her counts
as her own choice.}

string Property KEY_GIVEN = "MLWF_GivenClothes" AutoReadOnly

Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
	Actor npc = akDestContainer as Actor
	If npc && akBaseItem as Armor && npc != Game.GetPlayer() && !npc.IsDead()
		StorageUtil.FormListAdd(npc, KEY_GIVEN, akBaseItem, false)
	EndIf
EndEvent

; Taken back: once the NPC has none of that item left, it is no longer something the player gave her (a follower
; used to carry loot).
Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
	If akBaseItem as Armor
		Actor npc = akSourceContainer as Actor
		If npc && npc.GetItemCount(akBaseItem) <= 0
			StorageUtil.FormListRemove(npc, KEY_GIVEN, akBaseItem, true)
		EndIf
	EndIf
EndEvent
