Scriptname CompanionEditPlayerAliasScript extends ReferenceAlias

Quest Property CompanionEditChairsQuest Auto Const
LocationRefType Property WorkshopRefType Auto Const
Keyword Property LocTypeWorkshopSettlement Auto Const

Event OnInit()
	ForceRefIfEmpty(Game.GetPlayer())
	RegisterForMenuOpenCloseEvent("WorkshopMenu")
EndEvent

Event OnPlayerLoadGame()
	StartChairQuest(GetRef().GetCurrentLocation())
	RegisterForMenuOpenCloseEvent("WorkshopMenu")
EndEvent

Event OnLocationChange(Location akOldLoc, Location akNewLoc)
	StartChairQuest(akNewLoc)
EndEvent

Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
	If (asMenuName == "WorkshopMenu" && !abOpening)
		CompanionEditChairsQuest.Start()
	EndIf
EndEvent

Function StartChairQuest(Location CurrLoc)
	If (CurrLoc.HasRefType(WorkshopRefType) || CurrLoc.HasKeyword(LocTypeWorkshopSettlement))
		CompanionEditChairsQuest.Start()
	EndIf
EndFunction