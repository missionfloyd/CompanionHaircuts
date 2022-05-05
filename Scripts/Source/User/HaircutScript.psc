Scriptname HaircutScript extends Actor Conditional
{script for anyone who does haircuts}

ObjectReference Property BarberChair  Auto Const
{BarberChair to sit in for the haircut. Be sure to flag HasBarber on the FaceGenBarberHairScript on the Chair!}

GlobalVariable Property HaircutCost Auto Const
{Global value for how much the haircut costs}

ActorValue Property BoughtHaircutAV auto Const
{Used to Condition dialogue}

Keyword Property AnimFaceArchetypePlayer Auto Const
{Store Player Face Archetype. We need to switch player to Neutral while in the menu.}

InputEnableLayer Property BarberInputLayer Auto Hidden

Race Property HumanRace Auto Const
Race Property GhoulRace Auto Const
ActorBase Property EncCurieSynth Auto Const
Actor Property CurieRef Auto Const
Quest Property CompanionEditQuest Auto Const
ReferenceAlias Property CurieAlias Auto Const
Static Property XMarker Auto Const

Actor[] PlayerFollowers
Actor PlayerREF
Actor TargetREF
Bool FirstPerson

; purchase haircut
function BoughtHaircut()
	debug.trace(self + " BoughtHaircut called on HaircutScript - barber chair is available")
	PlayerREF = Game.GetPlayer()
	BarberChair.BlockActivation(True, False)
	BarberChair.SetNoFavorAllowed(False)
	PlayerREF.RemoveItem(Game.GetCaps(), HaircutCost.GetValueInt())
	; used to conditionalize barber dialogue
	SetValue(BoughtHaircutAV, 1.0)
	Self.EvaluatePackage()
	RegisterForRemoteEvent(PlayerREF, "OnSit")
	RegisterForRemoteEvent(PlayerREF, "OnGetUp")
	RegisterForRemoteEvent(BarberChair, "OnActivate")
	PlayerFollowers = Game.GetPlayerFollowers()
	int CurrentFollowerIndex = 0
	while (CurrentFollowerIndex < PlayerFollowers.Length)
		RegisterForRemoteEvent(PlayerFollowers[CurrentFollowerIndex], "OnSit")
		RegisterForRemoteEvent(PlayerFollowers[CurrentFollowerIndex], "OnGetUp")
		CurrentFollowerIndex += 1
	endWhile
endFunction

;reset everything
function ResetBarberChair()
	debug.trace(self + " ResetBarberChair called on HaircutScript - haircut used or expired")
	BarberChair.BlockActivation(True, True)
	BarberChair.SetNoFavorAllowed()
	; used to conditionalize dialogue
	SetValue(BoughtHaircutAV, 0.0)
	Self.EvaluatePackage()
	UnRegisterForRemoteEvent(PlayerREF, "OnSit")
	UnRegisterForRemoteEvent(PlayerREF, "OnGetUp")
	UnRegisterForRemoteEvent(BarberChair, "OnActivate")
	int CurrentFollowerIndex = 0
	while (CurrentFollowerIndex < PlayerFollowers.Length)
		UnRegisterForRemoteEvent(PlayerFollowers[CurrentFollowerIndex], "OnSit")
		UnRegisterForRemoteEvent(PlayerFollowers[CurrentFollowerIndex], "OnGetUp")
		CurrentFollowerIndex += 1
	endWhile
	If TargetREF.GetActorBase() == EncCurieSynth
		UnRegisterForRemoteEvent(TargetREF, "OnGetUp")
	Endif
endFunction

;if I load again, reset the chair
Event OnLoad()
	ResetBarberChair()
EndEvent

; if I die, reset the chair
Event OnDeath(Actor akKiller)
	ResetBarberChair()
endEvent

Event ObjectReference.OnActivate(ObjectReference akSender, ObjectReference akActionRef)
	TargetREF = akActionRef as Actor
	If TargetREF.IsInCombat()
		;do nothing
	ElseIf TargetREF.IsInPowerArmor()
		;do nothing
	ElseIf TargetREF.GetSitState()!=0
		;do nothing
	ElseIf akSender.IsFurnitureInUse()
		;do nothing
	Else
		If TargetREF == PlayerREF
			;disable controls and force player into the chair
			BarberInputLayer = InputEnableLayer.Create()
			BarberInputLayer.DisablePlayerControls()
		EndIf
		akSender.Activate(TargetREF, True)
	EndIf
EndEvent

Event Actor.OnSit(Actor akSender, ObjectReference akFurniture)
	If (akFurniture == BarberChair)
		BarberChair.BlockActivation(True, True)
		If (TargetREF == PlayerREF || TargetREF.getRace() == HumanRace || TargetREF.getRace() == GhoulRace)
			BarberChair.BlockActivation(False, False)
			If TargetREF == PlayerREF
				;set player face to neutral
				PlayerREF.ChangeAnimFaceArchetype(None)
			Else
				If TargetREF == CurieRef
					CurieRef.Disable()
					TargetREF = CurieRef.PlaceActorAtMe(EncCurieSynth)
					TargetREF.WaitFor3DLoad()
					CurieAlias.ForceRefTo(TargetREF)
					TargetREF.SnapIntoInteraction(Barberchair)
					RegisterForRemoteEvent(TargetREF, "OnGetUp")
				Endif
				Utility.Wait(1)
				If PlayerREF.IsWeaponDrawn()
					InputEnableLayer HolsterWeaponLayer = InputEnableLayer.Create()
						HolsterWeaponLayer.DisablePlayerControls()
						HolsterWeaponLayer.EnablePlayerControls()
					HolsterWeaponLayer = None
				Endif
				FirstPerson = PlayerREF.GetAnimationVariableBool("IsFirstPerson") 
				Game.ForceFirstPerson()
				ObjectReference CameraMarker = BarberChair.PlaceAtMe(XMarker)
				Float ChairAngle = BarberChair.GetAngleZ()
				Float OffsetX = Math.sin(ChairAngle) * 50
				Float OffsetY = Math.cos(ChairAngle) * 50
				CameraMarker.MoveTo(BarberChair, afXOffset = OffsetX, afYOffset = OffsetY)
				CameraMarker.SetAngle(0, 0, CameraMarker.GetAngleZ() + CameraMarker.GetHeadingAngle(BarberChair))
				PlayerREF.MoveTo(CameraMarker)
				CameraMarker.Delete()
				If !PlayerREF.IsSneaking()
					PlayerRef.StartSneaking()
				Endif
				RegisterForMenuOpenCloseEvent("LooksMenu")
			Endif
			Game.ShowRaceMenu(uimode = 2, akMenuTarget = TargetREF)
			UnRegisterForRemoteEvent(TargetREF, "OnSit")
		Endif
	EndIf
EndEvent

Event Actor.OnGetUp(Actor akSender, ObjectReference akFurniture)
	If (akFurniture == BarberChair)
		BarberChair.BlockActivation(True, False)
		If (TargetREF == PlayerREF || TargetREF.getRace() == HumanRace || TargetREF.getRace() == GhoulRace)
			;reset barber chair
			ResetBarberChair()

			If TargetREF == PlayerREF
				;enable controls
				BarberInputLayer.EnablePlayerControls()
				BarberInputLayer = None

				;make sure player face is back to Player archetype
				PlayerREF.ChangeAnimFaceArchetype(AnimFaceArchetypePlayer)
			EndIf
			UnRegisterForRemoteEvent(TargetREF, "OnGetUp")
		Endif
	EndIf
EndEvent

Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
	if (asMenuName == "LooksMenu" && !abOpening)
		If PlayerREF.IsSneaking()
			PlayerREF.StartSneaking()
		Endif
		If !FirstPerson
			Game.ForceThirdPerson()
		Endif
		If TargetREF.GetActorBase() == EncCurieSynth
			CurieAlias.Clear()
			TargetREF.Delete()
			CurieRef.Enable()
			CompanionEditQuest.SetStage(10)
		Else
			TargetREF.Disable()
			TargetREF.Enable()
		Endif
		UnRegisterForMenuOpenCloseEvent("LooksMenu")
	EndIf
EndEvent
