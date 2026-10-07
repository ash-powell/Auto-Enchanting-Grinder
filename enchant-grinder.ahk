#Persistent
#UseHook
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
;SetKeyDelay, 500, 500 ;<-- this doesn't work if Sendmode Input line is present(and it is present, so comment out)

; In this version 1.4 I added PSDF to slow it down a bit. Version 1.3 this didn't exist but was effectively 1. PSDF=2 seems to be good compromise but might still be too fast when game gets bloated. 5 should be very stable.
; future version make PSDF a user option
 
keyDelay := 50
tabDelay := 300
lookDelay:= 1000
boxDelay := 350
PSDF := 2 ;pre start delay factor. Added this in version 1.4 cuz 1.3 was too fast at times. 

!x::
	Reload
return

!n::

;********Get row number of item, check for weapon, select it, then switch to enchantment tab*****

InputBox, itemRow, Item Row Input, Enter the row number of the item to enchant ;
Sleep, boxDelay ;<-- this is necessary after InputBox, or first "Send," statement will not register in Skyrim
If ErrorLevel 
	Reload

Loop
{
	InputBox, isWeapon, Weapon?, Is this a weapon? Enter y or n
	Sleep, boxDelay
	If ErrorLevel 
		Reload

	if(isWeapon = "y" or isWeapon = "n")
	{
		break
	}
	MsgBox, Invalid input. Please enter y or n only.
	Sleep, boxDelay
}

selectRow(itemRow, keyDelay, lookDelay) ;<--scrolls down to row and selects it
tab(tabDelay) ;<-- switches to next tab

;********** 



;**********get enchantment row, select it, select strength if weapon, then switch to soul gem tab**********

InputBox, enchantRow, Enchantment Row Input, Enter the row number of the enchantment you want to use
Sleep, boxDelay
If ErrorLevel 
	Reload

selectRow(enchantRow, keyDelay, lookDelay)

if(isWeapon = "y") ;<-- don't need %% around variable when it's inside an if statement
{
	Send, {Enter}
	Sleep, LookDelay
}
tab(tabDelay)

;*****************get soul gem row and select it, get total number of items to enchant **************
InputBox, gemRow, Soul Gem Row Input, Enter the row number of the soul gem you want to use
If ErrorLevel 
	Reload
InputBox, quantity, Number of Items to Enchant, Enter number of items to enchant
Sleep, boxDelay
If ErrorLevel 
	Reload 

selectRow(gemRow, keyDelay, lookDelay)
;****************************************************************************************************

enchant(boxDelay) ;		<--first item has been enchanted so adjust quantity
quantity := quantity-1 ;        <--



; *****************Start loop and crank out rest of items ***********************

Loop %quantity% ;<-- quantity of soul gems to use(or items to enchant)
{

	selectRow(itemRow, keyDelay, 0) ;<--select item
	tab(keyDelay)

	selectRow(enchantRow, keyDelay, 0) ;<-- select enchantment
	if(isWeapon = "y")
	{
		Send, {Enter}
		Sleep, keyDelay
	}
	tab(keyDelay)

	selectRow(gemRow, keyDelay, keyDelay*PSDF) ;<-- select soul gem. Apparently a longer delay is required here before enchanting(hitting the r key)

	enchant(keyDelay)
}
;******************************
; <-- and we are done!

;****************************** Functions ***********************************************

selectRow(rowNumber, downDelay, enterDelay)
{
	Loop %rowNumber%
	{
		Send, {Down}
		Sleep, downDelay
	}
	Send, {Enter}
	Sleep, enterDelay
}

tab(delay)
{
	Send, {Right}
	Sleep, delay
}

enchant(delay)
{
	Send, r		;<-- enchant?
	Sleep, delay	
	Send, y		;<-- yes!
	Sleep, delay 
	Send, {Right}   ;<-- tab to disenchant screen  
	Sleep, delay
	Send, {Right}   ;<-- tab to item screen and ready to start over again 
	Sleep, delay
}

return
