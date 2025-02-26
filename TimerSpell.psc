Scriptname COB:TimerSpell Extends ActiveMagicEffect
 
COB:Questscript Property CBQ Auto Mandatory Const

Event OnEffectStart(ObjectReference akTarget, Actor akCaster, MagicEffect akBaseEffect, float afMagnitude, float afDuration)
    CBQ.CDBG("Outpost Construction started on " + akTarget)
    ;akTarget.AddKeyword(CBQ._COB_Refundable)
    ;akTarget.AddKeyword(CBQ._COB_FreeMove)
EndEvent

Event OnEffectFinish(ObjectReference akTarget, Actor akCaster, MagicEffect akBaseEffect, float afMagnitude, float afDuration)
    CBQ.CDBG("Outpost Construction complete on " + akTarget)
    akTarget.RemoveKeyword(CBQ._COB_Refundable)
    akTarget.RemoveKeyword(CBQ._COB_FreeMove)
    CBQ.TriggerPayment(akTarget)
EndEvent
