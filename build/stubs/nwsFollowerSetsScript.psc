Scriptname nwsFollowerSetsScript extends Quest
; Compile stub of Nether's Follower Framework (only what this mod uses).
Form[] Property outfitActors Auto
Faction Property nwsFF_storedFac Auto
Faction Property nwsFF_OutTypeFac Auto
FormList Property nwsFFOutfitChestList Auto
FormList Property nwsFFTownChestList Auto
FormList Property nwsFFHomeChestList Auto
FormList Property nwsFFSatchelList Auto
nwsFollowerMCMScript Property mcmScr Auto
Actor Property outfitActor Auto
Int Property createType Auto
Bool Property newOutfit Auto
Int Property currentSlot Auto
ObjectReference Property outfitChest Auto
Int Property viewMode Auto
Bool Property isProcessing Auto
Function AddOutfitFaction(Actor myActor, Int myType)
EndFunction
Function StoreOriginalOutfit(Int mySlot)
EndFunction
String Function CreateListName(Int myCount, Actor myActor)
EndFunction
Function CompleteOutfit()
EndFunction
Int Function OutfitTypeTarget(Actor myActor)
EndFunction
Int Property lastLocType Auto
Bool Function CheckPlayerLoc()
EndFunction
