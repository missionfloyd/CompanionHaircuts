Scriptname CompanionEditCurieFixScript extends Quest

Actor Property CurieRef Auto Const

Event Actor.OnPlayerLoadGame(actor aSender)
	CurieRef.Disable()
	CurieRef.Enable()
	UnRegisterForRemoteEvent(aSender, "OnPlayerLoadGame")
EndEvent
