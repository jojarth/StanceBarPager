# StanceBarPager

A lightweight, zero-dependency *World of Warcraft: Forever* add-on that dynamically swaps **Action Bars 2–5** to different internal action pages (Pages 1–15) whenever you change stances, stealth, or shapeshift forms—using Blizzard's native Edit Mode bars.

## Features
- **Combat-Safe Paging:** Uses Blizzard's secure state drivers (`SecureHandlerStateTemplate`) so bars swap instantaneously in combat without triggering blocked-action errors.
- **Multi-Class Automatic Detection:** Automatically labels stance and form slots for Warriors, Druids, Rogues, Priests, Paladins, and other classes.
- **Smart Page Scanner:** Scans all 15 internal action bar pages in real time, tagging pages as `[FREE - Empty]`, `[FREE - X Spells]`, `[RESERVED]`, or `[IN USE]` so you never overwrite existing bars.
- **Clutter-Free Filtering:** Hides reserved/unavailable pages by default, with a toggle checkbox (`Show unavailable / reserved pages`) for advanced overrides.
- **Profile Import / Export:** Generate compact shareable strings (`SBP1:...`) to share setups on Discord or sync across computers.

## Installation
1. Download the latest release (or clone this repository).
2. Ensure the folder is named **`StanceBarPager`** and contains `StanceBarPager.toc` and `StanceBarPager.lua`.
3. Move the folder into your WoW installation directory:
   `World of Warcraft\_forever_\Interface\AddOns\StanceBarPager`
4. Restart the game or type `/reload` in chat.

## Usage
1. Type **`/sbp`** (or `/stancebar`) in chat, or open **Options -> AddOns -> StanceBarPager**.
2. Select which bar (**Action Bar 2–5**) you want to configure.
3. Click any stance/form button to assign an unused action page (such as **Page 13, 14, or 15**).
4. **Adding spells to Pages 13–15:** Temporarily enable **Action Bar 6, 7, or 8** in Blizzard's Edit Mode, drag your stance-specific abilities onto them, and hide those bars again. Your configured bar will automatically pull those spells when you enter that stance.

## A note on AI Usage
Please note: I did use AI to assist in the writing of this add-on. 

Additionally, I did use AI to generate the icon for this add-on as well. 
