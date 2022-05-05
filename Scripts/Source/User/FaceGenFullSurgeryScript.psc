Scriptname FaceGenFullSurgeryScript extends ObjectReference

;does this chair have a surgeon? If so, everything related to the menu is handled in the SurgeonScript script on the Actor form for the Surgeon (except for CharGenSkeleton)
Bool Property HasSurgeon = False Auto 

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

;when the chair loads, put the skeleton on the player
Event OnLoad()
	PlayerREF = Game.GetPlayer()
	;84093 - do not set the chargen skeleton during OnLoad/OnUnload events, as the player might be in power armor and the skeletons are incompatible
	;Game.GetPlayer().SetHasCharGenSkeleton()
	If HasSurgeon == True
		;make sure we block activation if the surgeon isn't in the same loaded area
		Self.BlockActivation(True, True)
		Self.SetNoFavorAllowed()
	EndIf
EndEvent

;84093 - do not set the chargen skeleton during OnLoad/OnUnload events, as the player might be in power armor and the skeletons are incompatible
;when the chair unloads, pull the skeleton off the player
;Event OnUnload()
	;Game.GetPlayer().SetHasCharGenSkeleton(False)
;EndEvent

;when player activates furniture, wait until he sits, then open the face gen menu
Event OnActivate(ObjectReference akActionRef)
	TargetREF = akActionRef as Actor
	If HasSurgeon == True
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
	IF HasSurgeon == True
		;do nothing
	ElseIf akFurniture == Self
		Self.BlockActivation(True, True)
		If (TargetREF == PlayerREF || TargetREF.getRace() == HumanRace || TargetREF.getRace() == GhoulRace)
			;make sure player has CharGen Skeleton for editing
			TargetREF.SetHasCharGenSkeleton()
			
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
			Game.ShowRaceMenu(uimode = 3, akMenuTarget = TargetREF)
			UnRegisterForRemoteEvent(TargetREF, "OnSit")
		Endif
	EndIf
EndEvent

Event Actor.OnGetUp(Actor akSender, ObjectReference akFurniture)
	IF HasSurgeon == True
		;do nothing
	ElseIf (akFurniture == Self)
		Self.BlockActivation(False, False)
		If (TargetREF == PlayerREF || TargetREF.getRace() == HumanRace || TargetREF.getRace() == GhoulRace)
			;make sure the CharGen skeleton has been removed
			TargetREF.SetHasCharGenSkeleton(False)
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
			CompanionEditQuest.SetStage(10)
		Else
			TargetREF.Disable()
			TargetREF.Enable()
		Endif
		UnRegisterForMenuOpenCloseEvent("LooksMenu")
	EndIf
EndEvent

;84093 - do not set the chargen skeleton during OnLoad/OnUnload events, as the player might be in power armor and the skeletons are incompatible
;Event ObjectReference.OnUnload(ObjectReference akSender)
	;if the player unloads, clear the chargenskeleton
;	Game.GetPlayer().SetHasCharGenSkeleton(False)
;EndEvent