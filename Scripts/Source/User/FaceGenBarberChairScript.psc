Scriptname FaceGenBarberChairScript extends ObjectReference 

;does this chair have a barber? If so, everything is handled in the HairCut script on the Actor form for the Barber
Bool Property HasBarber = False Auto 

Keyword Property AnimFaceArchetypePlayer Auto Const
{Store Player Face Archetype. We need to switch player to Neutral while in the menu.}

Race Property HumanRace Auto
Race Property GhoulRace Auto
ActorBase Property EncCurieSynth Auto
Actor Property CurieRef Auto
Quest Property CompanionEditQuest Auto
ReferenceAlias Property CurieAlias Auto
Static Property XMarker Auto

Actor PlayerREF
Actor TargetREF
Bool FirstPerson

Event OnLoad()
	PlayerREF = Game.GetPlayer()
	If HasBarber == True
		;make sure we block activation if the barber isn't in the same loaded area
		Self.BlockActivation(True, True)
		Self.SetNoFavorAllowed()
	EndIf
EndEvent

;when player activates furniture, wait until he sits, then open the face gen menu
Event OnActivate(ObjectReference akActionRef)
	TargetREF = akActionRef as Actor
	If HasBarber == True
		;do nothing
	ElseIf TargetREF.IsInCombat()
		;do nothing
	ElseIf TargetREF.IsInPowerArmor()
		;do nothing
	Else
		RegisterForRemoteEvent(TargetREF, "OnSit")
		RegisterForRemoteEvent(TargetREF, "OnGetUp")
	EndIf
EndEvent

Event Actor.OnSit(Actor akSender, ObjectReference akFurniture)
	If HasBarber == True
		;do nothing
	ElseIf akFurniture == Self
		Self.BlockActivation(True, True)
		If (TargetREF == PlayerREF || TargetREF.getRace() == HumanRace || TargetREF.getRace() == GhoulRace)
			;allow player to get up out of the chair when the menu closes
			Self.BlockActivation(False, False)
			If TargetREF == PlayerREF
				;set player face to neutral
				PlayerREF.ChangeAnimFaceArchetype(None)
			Else
				If TargetREF == CurieRef
					CurieRef.Disable()
					TargetREF = CurieRef.PlaceActorAtMe(EncCurieSynth)
					TargetREF.WaitFor3DLoad()
					CurieAlias.ForceRefTo(TargetREF)
					TargetREF.SnapIntoInteraction(Self)
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
				ObjectReference CameraMarker = Self.PlaceAtMe(XMarker)
				Float ChairAngle = Self.GetAngleZ()
				Float OffsetX = Math.sin(ChairAngle) * 50
				Float OffsetY = Math.cos(ChairAngle) * 50
				CameraMarker.MoveTo(Self, afXOffset = OffsetX, afYOffset = OffsetY)
				CameraMarker.SetAngle(0, 0, CameraMarker.GetAngleZ() + CameraMarker.GetHeadingAngle(Self))
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
	IF HasBarber == True
		;do nothing
	ElseIf (akFurniture == Self)
		Self.BlockActivation(False, False)
		If (TargetREF == PlayerREF || TargetREF.getRace() == HumanRace || TargetREF.getRace() == GhoulRace)
			If TargetREF == PlayerREF
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
			;CompanionEditQuest.SetStage(10)
		Else
			TargetREF.Disable()
			TargetREF.Enable()
		Endif
		UnRegisterForMenuOpenCloseEvent("LooksMenu")
	EndIf
EndEvent