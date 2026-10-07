# Skyrim Auto-Enchanting Grinder

**Published mod:** [Auto Enchanting Grinder on Nexus Mods](https://www.nexusmods.com/skyrimspecialedition/mods/44968)

This utility is written in AutoHotkey to automate the repetitive process of enchanting large numbers of items in Skyrim.

Rather than modifying Skyrim's enchanting system, the program works externally by controlling the game's existing user interface. The user identifies the menu positions of the item, enchantment, and soul gem to use, and the script handles the repeated navigation, selection, confirmation, and menu transitions required to enchant the requested number of items.


## The programming challenge

Instead of using Bethesda's Creation Kit or Papyrus scripting environment, AutoHotkey can reproduce the keyboard input a player would normally provide and turn the manual enchanting workflow into a repeatable process.

The solution did not require extending the system that created the problem. It required recognizing that the problem could be attacked at a different level entirely.

## Why this mod

Enchanting an item in Skyrim requires moving through several menu screens and becomes tedious when enchanting a large number of identical items:

1. Select the item to enchant.
2. Select an enchantment.
3. Select the enchantment strength when enchanting a weapon.
4. Select a soul gem.
5. Initiate the enchantment.
6. Confirm the operation.
7. Navigate back to the item list.
8. Repeat the entire process for the next item.
 
The utility asks the user for the row numbers of the item, enchantment, and soul gem, whether the item is a weapon, and the number of items to enchant. Once configured, it reproduces the complete workflow automatically.

## How the automation works

The program treats Skyrim's menus as predictable sequences of keyboard operations rather than attempting to read or modify the game's internal state.

For example, selecting a menu entry is reduced to a row number:

```autohotkey
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
```

Given a row number, the function moves down through the menu and selects the appropriate entry.

The same function can therefore be reused for the item, enchantment, and soul-gem menus:

```autohotkey
selectRow(itemRow, keyDelay, 0)
selectRow(enchantRow, keyDelay, 0)
selectRow(gemRow, keyDelay, keyDelay * PSDF)
```

This reduces the larger workflow to a small set of reusable operations rather than duplicating the keyboard-navigation logic for every menu.

## Modeling the workflow

Once the initial selections have been collected, each additional enchantment follows the same state sequence:

```text
Item
  ↓
Enchantment
  ↓
Strength, if the item is a weapon
  ↓
Soul Gem
  ↓
Enchant
  ↓
Confirm
  ↓
Return to Item menu
```

The main loop repeats that state transition for the remaining quantity:

```autohotkey
Loop %quantity%
{
    selectRow(itemRow, keyDelay, 0)
    tab(keyDelay)

    selectRow(enchantRow, keyDelay, 0)

    if(isWeapon = "y")
    {
        Send, {Enter}
        Sleep, keyDelay
    }

    tab(keyDelay)

    selectRow(gemRow, keyDelay, keyDelay * PSDF)

    enchant(keyDelay)
}
```

Weapons require an additional selection for enchantment strength, so the script adjusts the workflow according to the type of item being processed.

## Timing and synchronization

One of the less obvious problems with UI automation is synchronization.

The script cannot simply send all of its keystrokes as quickly as the computer can generate them. Skyrim needs time to respond to a selection, transition between menus, open a dialog, or return to another screen. Sending the next command too early can cause that input to be ignored or interpreted by the wrong screen.

For that reason, the program uses different delays for different types of operations:

```autohotkey
keyDelay  := 50
tabDelay  := 300
lookDelay := 1000
boxDelay  := 350
PSDF      := 2
```

These delays are not interchangeable. Opening an input dialog, changing a menu tab, selecting an entry, and preparing to initiate an enchantment can require different amounts of time.

For example, the soul-gem selection needs additional time before the enchant command is issued:

```autohotkey
selectRow(gemRow, keyDelay, keyDelay * PSDF)
```

The `PSDF` multiplier provides an adjustable synchronization margin without requiring the navigation logic itself to change.

This was an important part of making the automation reliable: the program has to operate at the speed of the application it controls, not simply at the speed of the script.

## Reusable operations

The script separates the repeated UI actions into three small functions:

| Function | Responsibility |
| --- | --- |
| `selectRow()` | Navigate to a numbered menu entry and select it. |
| `tab()` | Move to the next Skyrim menu tab. |
| `enchant()` | Start the enchantment, confirm it, and return to the item screen. |

The `enchant()` function encapsulates the final sequence:

```autohotkey
enchant(delay)
{
    Send, r
    Sleep, delay

    Send, y
    Sleep, delay

    Send, {Right}
    Sleep, delay

    Send, {Right}
    Sleep, delay
}
```

Breaking the workflow into these operations makes the main loop correspond closely to the actual sequence the player performs.

## Input and error handling

Before automation begins, the program collects the information it cannot determine from Skyrim directly:

- item row
- whether the item is a weapon
- enchantment row
- soul-gem row
- number of items to enchant

The weapon prompt rejects values other than `y` or `n`:

```autohotkey
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
```

Canceling one of the required input dialogs reloads the script rather than allowing an incomplete configuration to continue into the automation sequence.

An `Alt+X` hotkey also provides a quick way to reset the program:

```autohotkey
!x::
    Reload
return
```

## Design tradeoffs

This is intentionally a lightweight automation tool rather than a system that attempts to inspect Skyrim's memory, recognize screen contents, or modify the game's enchanting mechanics.

That simplicity has consequences. The script assumes that the relevant menu entries remain in the row positions supplied by the user and that Skyrim responds within the configured delays. If the menus change unexpectedly or the game becomes slow enough that a transition takes longer than expected, the automation can lose synchronization.

For the problem we're trying to solve, however, those tradeoffs are reasonable. A much more complicated system for identifying menu contents dynamically is unnecessary when a small amount of user input combined with predictable menu navigation could accomplish the same task.
