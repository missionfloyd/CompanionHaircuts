;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
Scriptname Fragments:Quests:QF_CompanionEditQuest_01005402 Extends Quest Hidden Const

;BEGIN FRAGMENT Fragment_Stage_0010_Item_00
Function Fragment_Stage_0010_Item_00()
;BEGIN AUTOCAST TYPE CompanionEditCurieFixScript
Quest __temp = self as Quest
CompanionEditCurieFixScript kmyQuest = __temp as CompanionEditCurieFixScript
;END AUTOCAST
;BEGIN CODE
kmyQuest.RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment
