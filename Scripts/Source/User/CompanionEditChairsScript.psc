Scriptname CompanionEditChairsScript extends RefCollectionAlias

Race Property HumanRace Auto Const
Race Property GhoulRace Auto Const
ActorBase Property EncCurieSynth Auto Const
Actor Property CurieRef Auto Const
Quest Property CompanionEditQuest Auto Const
ReferenceAlias Property CurieAlias Auto Const
Static Property XMarker Auto Const

Event OnAliasInit()
	Int i = 0
	While i < GetCount()
		ObjectReference TheChair = GetAt(i)
		TheChair.SetNoFavorAllowed(False)

		FaceGenBarberChairScript BarberScript = TheChair as FaceGenBarberChairScript
		If BarberScript
			BarberScript.HumanRace = HumanRace
			BarberScript.GhoulRace = GhoulRace
			BarberScript.EncCurieSynth = EncCurieSynth
			BarberScript.CurieRef = CurieRef
			BarberScript.CompanionEditQuest = CompanionEditQuest
			BarberScript.CurieAlias = CurieAlias
			BarberScript.XMarker = XMarker
		EndIf

		FaceGenFullSurgeryScript SurgeryScript = TheChair as FaceGenFullSurgeryScript
		If SurgeryScript
			SurgeryScript.HumanRace = HumanRace
			SurgeryScript.GhoulRace = GhoulRace
			SurgeryScript.EncCurieSynth = EncCurieSynth
			SurgeryScript.CurieRef = CurieRef
			SurgeryScript.CompanionEditQuest = CompanionEditQuest
			SurgeryScript.CurieAlias = CurieAlias
			SurgeryScript.XMarker = XMarker
		EndIf
		i += 1
	EndWhile
	GetOwningQuest().Stop()
EndEvent