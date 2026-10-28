Scriptname nwsFollowerControllerScript extends Quest
; Compile stub of Nether's Follower Framework (only what this mod calls).
Function RecruitFollower(Actor myActor)
EndFunction
Function RemoveFollower(Actor myActor, Int iMessage, Int iSayLine)
EndFunction
Function FollowerWaitHere(Actor myActor, Int notify, Int doPerm)
EndFunction
Function FollowerFollowMe(Actor myActor, Int notify)
EndFunction
Function WaitAll()
EndFunction
Function FollowAll()
EndFunction
ReferenceAlias Function SearchAlias(Actor myActor, Int myVal)
EndFunction
Function SetBehavior(ReferenceAlias myAlias, Int myTrait, Int myOpt)
EndFunction
nwsFollowerVariableScript Property varScript Auto
Function BehindMe(Actor myActor)
EndFunction
Function PerformTask(Int myVal, Actor myActor, Int myOpt, ReferenceAlias myAlias)
EndFunction
Function SetCombatST(ReferenceAlias myAlias, Actor myActor, Int myOpt, Int myRank)
EndFunction
Function SetFollowerRole(Actor myActor, Int myVal)
EndFunction
Function ToggleSandbox()
EndFunction
Function CallLooting(Bool doStart, Bool doStop, Bool doSilent)
EndFunction
Bool Function QueryLooting()
EndFunction
Function TakeTorches(ReferenceAlias myAlias)
EndFunction
Function GiveTorches(ReferenceAlias myAlias)
EndFunction
Function WarpAll()
EndFunction
