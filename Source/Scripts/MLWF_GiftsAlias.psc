Scriptname MLWF_GiftsAlias extends ReferenceAlias
{On the player: remembers every piece of armor or clothing the player hands over (to an NPC, a trade window or an
NFF outfit chest), so an NPC wearing it is known to wear something the player gave. Everything an NPC wears that
never passed through the player's hands counts as her own choice.}

string Property KEY_GIVEN = "MLWF_GivenClothes" AutoReadOnly

Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
	If akDestContainer && akBaseItem as Armor
		StorageUtil.FormListAdd(None, KEY_GIVEN, akBaseItem, false)
	EndIf
EndEvent
