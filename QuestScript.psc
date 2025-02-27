Scriptname COB:QuestScript Extends Quest

Actor PlayerRef

MiscObject Credits

ReferenceAlias Property CurrentOutpost Auto Const Mandatory

Keyword Property LocTypeSettledPlanet Mandatory Const Auto
Keyword Property LocTypeSettledSystem Mandatory Const Auto
Keyword Property LocTypePlayerHouse Mandatory Const Auto
Keyword Property LocTypeMajorOrbital Mandatory Const Auto
Keyword Property LocTypeOutpost Mandatory Const Auto
Keyword Property LocTypeStarSystem Mandatory Const Auto
Keyword Property IgnoredByDynamicNavmeshKeyword Mandatory Const Auto
Keyword Property _COB_Refundable Mandatory Const Auto
Keyword Property _COB_FreeMove Mandatory Const Auto

ActorValue Property PowerGenerated Auto Const Mandatory
ActorValue Property PowerRequired Auto Const Mandatory
ActorValue Property OutpostEventsPackinDummyOnly Auto Const Mandatory
ActorValue Property WorkshopAutoFoundationMaxHeight Auto Const Mandatory

Spell Property _COB_PlacementCooldown Auto Const


Bool DEBUGON = true
Bool DEBUGVERBOSE = false
Int minVol = 10
Int totalCost = 0
Int cost2build = 10
Int cost2move = 2
Int cost2decomm = 1

;Generic debug function that can be disabled for prod
Function CDBG(String asTextToPrint = "Debug Error!")
    If DEBUGON
        Debug.Trace("COBDEBUG: " + asTextToPrint)
        IF DEBUGVERBOSE ; Can log in realtime to avoid alt-tabbing constantly
            Debug.Notification("COB: " + asTextToPrint)
        EndIF
    EndIF
EndFunction

;Requires Cassiopeia - notably, it spits out all the keywords on the ref. Awesome for testing!
Function KeywordArrayChecker(ObjectReference akReference)
    CDBG("running KAC on " + akReference)
    Keyword[] KWTestArray = CassiopeiaPapyrusExtender.GetKeywords(akReference)
    int i = 0
    While i < KWTestArray.Length
        CDBG("Keyword for " + akReference + i + " >> " + KWTestArray[i] )
        i += 1
    EndWhile
EndFunction

;Requires Cassiopeia
Int Function BoundsChecker(ObjectReference akReference)
    if akReference.HasKeyword(IgnoredByDynamicNavmeshKeyword)
        Return 0
    EndIf
    Form base = akReference.GetBaseObject()
    Int baseFormID = base.GetFormID()
    String hexFormID = Utility.IntToHex(baseFormID)
    Float[] BoundsArray = CassiopeiaPapyrusExtender.GetObjectBounds(base) 
    float minX = BoundsArray[0]
    float minY = BoundsArray[1]
    float minZ = BoundsArray[2]
    float maxX = BoundsArray[3]
    float maxY = BoundsArray[4]
    float maxZ = BoundsArray[5]
    float X = (maxX - minX)
    float Y = (maxY - minY)
    float Z = (maxZ - minZ)
    int volume = (X * Y * Z) as int
    String dimensions = "CPE X: " + X + " Y: " + Y + " Z: " + Z
    If volume == 0
        X = akReference.GetHeight() 
        Y = akReference.GetLength()
        Z = akReference.GetWidth()
        volume = (X * Y * Z) as int
        dimensions = "LEGACY X: " + X + " Y: " + Y + " Z: " + Z
    EndIf
    CDBG("Object Bounds for " + base + ": " + dimensions + " = " + volume + " m3")
    Debug.Notification("Size of " + hexFormID + " is " + volume + " cubic meters")
    Return volume
EndFunction

Function OperationalCosts(ObjectReference akReference)
    Form base = akReference.GetBaseObject()
    ObjectReference baseObj = base as ObjectReference
    Int baseFormID = base.GetFormID()
    String hexFormID = Utility.IntToHex(baseFormID)

    ; Is Powered
    If akReference.IsPowered()
        ;Debug.MessageBox(hexFormID + " is powered")
    EndIf

    ; Which Resources are produced and their Value
    Resource[] resources = akReference.GetValueResources()
    If resources.Length > 0
        int i = 0
        While (i < resources.Length)
            Resource res = resources[i]
            Int resFormID = res.GetFormID()
            Form resForm = Game.GetForm(resFormID)
            String strRes = res
            Debug.MessageBox(hexFormID + " produces " + strRes)
            Debug.Trace("KB1: " + hexFormID + " produces " + res + "; Value=" + resForm.GetGoldValue())
            i += 1
        EndWhile
    EndIf

    ; Find outpost objects
    ObjectReference myWorkshop = akReference.GetWorkshop()
    Debug.Notification("COB: " + myWorkshop)
    ObjectReference[] desObjects = myWorkshop.GetDestructibleOutpostObjects()
    Debug.Trace("COB: " + myWorkshop.GetBaseObject() +  myWorkshop.GetCurrentPlanet() + " " + desObjects.Length)
    If desObjects.Length > 0
        int j = 0
        While (j < desObjects.Length)
            ObjectReference obj = desObjects[j]
            CDBG(obj + " : " + obj.GetBaseObject() + " mass=" + obj.GetMass())
            ;obj.DamageObject(100.0)
            j += 1
        EndWhile
    EndIf
    ObjectReference[] workshopObjects = myWorkshop.GetWorkshopOwnedObjects(PlayerRef)
    Debug.Trace("COB: WorkshopOwnedObjects=" + workshopObjects.Length)
    If workshopObjects.Length > 0
        int k = 0
        While (k < workshopObjects.Length)
            ObjectReference workshopObject = workshopObjects[k]
            CDBG(workshopObject + " : " + workshopObject.GetBaseObject())
            k += 1
        EndWhile
    EndIf
EndFunction

Function tallyCost(Int cost, String reason)
    If cost > 0 
        Debug.Notification(reason + " cost: " + cost + " credits!")
    ElseIf cost < 0
        Debug.Notification(reason + ": " + cost + " credits!")
    EndIf
    totalCost = totalCost + cost
EndFunction

;These are called from DetectiveScript 
Function PlacementHandler(ObjectReference akReference)
    CDBG( "Placement detected of " + akReference )
    int volume = BoundsChecker(akReference) as Int
    If volume > minVol
        ; Add build cost to Total
        tallyCost(volume * cost2build, "Building")
        akReference.AddKeyword(_COB_Refundable)
        akReference.AddKeyword(_COB_FreeMove)
        _COB_PlacementCooldown.Cast(akReference)
    EndIf
EndFunction

Function MovementHandler(ObjectReference akReference)
    CDBG( "Movement detected of " + akReference )
    int volume = BoundsChecker(akReference) as Int
    If volume > minVol && !akReference.HasKeyword(_COB_FreeMove)
        ; Add move cost to Total
        tallyCost(volume * cost2move, "Moving")
        akReference.AddKeyword(_COB_FreeMove)
        _COB_PlacementCooldown.Cast(akReference)
    EndIf
EndFunction

Function RemovalHandler(ObjectReference akReference)
    CDBG("Removal detected of " + akReference)
    int volume = BoundsChecker(akReference) as Int
    If volume > minVol
        If akReference.HasKeyword(_COB_Refundable)
            ; Subtract build cost from Total
            tallyCost(volume * cost2build * -1, "Refunding")
        Else
            ; Add decomm cost to Total
            tallyCost(volume * cost2decomm, "Teardown")
        EndIf
    EndIf
EndFunction

Function WorkshopModeHandler(bool abStart)
    CDBG("COB: Startup - WorkshopMode=" + abStart + " - " + CurrentOutpost)
    ; End of Outpost Build Mode
    If !abStart
        If totalCost > 0
            Debug.MessageBox("Total credits due on Build Mode exit = " + totalCost)
            PlayerRef.RemoveItem(Credits, totalCost)
        ElseIf totalCost < 0
            Debug.MessageBox("Total credits refunded = " + totalCost)
            PlayerRef.AddItem(Credits, totalCost * -1)
        EndIf
        totalCost = 0
    EndIf
EndFunction

Function EndConstruction(ObjectReference akReference)
    Debug.Notification("Construction finished for " + akReference)
EndFunction

;This is my generic startup script, you can do this a hundred different ways. 
Event OnQuestInit()
	StartTimer(5)
    GoToState("Starting")
EndEvent

State Starting
    Event OnTimer(int aiTimerID)
        PlayerRef = Game.GetPlayer()
        Credits = Game.GetCredits()
        Self.RegisterForRemoteEvent(PlayerRef, "OnLocationChange")
        Self.RegisterForRemoteEvent(PlayerRef, "OnOutpostPlaced")
        Self.RegisterForRemoteEvent(PlayerRef, "OnWorkshopMode")
        Self.RegisterForRemoteEvent(PlayerRef, "OnPlayerLoadGame")
        CDBG("Initialized OK")
        totalCost = 0
        GotoState("Running")
    EndEvent
EndState

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Just for easy debugging
Event Actor.OnPlayerLoadGame(Actor akSender)
    CDBG("Running with currentoutpost: " + CurrentOutpost)
EndEvent

;This is my favorite game event.
Event Actor.OnLocationChange(Actor akSender, Location akOldLoc, Location akNewLoc)
    IF akNewLoc.HasKeyword(LocTypeOutpost)
        CurrentOutpost.RefillAlias()
        CDBG("found CurrentOutpost of " + CurrentOutpost)
    Else
        If CurrentOutpost
            CurrentOutpost.Clear()
            CDBG("cleared CurrentOutpost Alias")
        Else
            CDBG("did not find CurrentOutpost Alias to clear.")
        EndIf
    EndIf
EndEvent

;So we don't have to leave and come back
Event Actor.OnOutpostPlaced(Actor akSource, ObjectReference akOutpostBeacon)
    CurrentOutpost.RefillAlias()
    CDBG("Placed CurrentOutpost of " + CurrentOutpost)
EndEvent
