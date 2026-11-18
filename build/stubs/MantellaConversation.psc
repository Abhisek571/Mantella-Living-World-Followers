Scriptname MantellaConversation extends Quest
{Compile stub: the Integration Hub's stub (kept in step with it) plus what this mod calls. The real script binds at runtime.}
int Function CountActorsInConversation()
EndFunction
Actor Function GetActorInConversationByIndex(int indexOfActor)
EndFunction
Function RemoveActorsFromConversation(Actor[] actorsToRemove)
EndFunction
bool Function IsPlayerInConversation()
EndFunction
; the Absolute Command hotkey (MLW_Command): an in-game event and an event-only NPC turn
bool Function GetIsTalking()
EndFunction
Function AddIngameEvent(string eventText)
EndFunction
Function AddExtraRequestAction(string extraAction)
EndFunction
Function RequestContinueConversation(bool updateInGameEvents = false)
EndFunction
; this mod
Actor function GetActorByName(string actorName)
EndFunction
