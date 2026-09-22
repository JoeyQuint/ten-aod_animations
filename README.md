# TRLE - AOD Animations for TombEngine

A **Tomb Raider: The Angel Of Darkness** based animation set for **[Tomb Engine](https://tombengine.com/)**.

Preview (**Jul 28, 2019**):

<a href="http://www.youtube.com/watch?feature=player_embedded&v=O-3Q1sZRti4" target="_blank">
	<img src="https://img.youtube.com/vi/O-3Q1sZRti4/0.jpg" alt="Video preview of the animations from Jul 28, 2019" width="240" height="180" border="10" />
</a>

Note that this video was made using the **[TRNG version](https://github.com/Joey79100/trle-aod_animations)**.


- [TRLE - AOD Animations for TombEngine](#trle---aod-animations-for-tombengine)
- [1. General information](#1-general-information)
  - [1.1. Updates and progression](#11-updates-and-progression)
  - [1.2. Target engine/editor](#12-target-engineeditor)
- [2. Installation](#2-installation)
  - [2.1. Importing the animations](#21-importing-the-animations)
  - [2.2. Fixes & additional features](#22-fixes--additional-features)
    - [Fix: Ladders snapping](#fix-ladder-snapping)
    - [Feature: Last chance grab](#feature-last-chance-grab)
    - [Feature: Safe drop](#feature-safe-drop)
  - [2.3. Interactible objects with custom animations](#23-interactible-objects-with-custom-animations)
  - [2.4. Sounds](#24-sounds)
    - [Basics](#basics)
    - [If you want to use the "**1 terrain type = 1 footstep sound**"](#if-you-want-to-use-the-1-terrain-type--1-footstep-sound)
- [3. Credits](#3-credits)
- [4. See also](#4-see-also)


# 1. General information

## 1.1. Updates and progression
You can:
- Follow the [commits](https://github.com/Joey79100/ten-aod_animations/commits/main) to see the **latest updates**.
- Read the [issues](https://github.com/Joey79100/ten-aod_animations/issues) named "_Progress tracker \*\*\*_" to see the **lists of animations** that have been remade or planned.  


## 1.2. Target engine/editor
The project is currently developped using **TombEngine**.  
The original **[TRNG version](https://github.com/Joey79100/ten-aod_animations)** will remain available, but I have no plan to continue working on them, as it would double the work for me.

You can build levels for [Tomb Engine (TEN)](https://tombengine.com/) using [Tomb Editor (TE)](https://github.com/TombEngine/TombEditorReleases/releases).


# 2. Installation

First, you can either:
- Download the **playable package** if you want to playtest the animations before using them.  
  Find the big green "**Code**" menu button at the top of this page, then hit [Download ZIP](https://github.com/Joey79100/ten-aod_animations/archive/refs/heads/master.zip).

- Or just download the following files if you **just want the animations**:
  - [Assets/Objects/**Lara.wad2**](Assets/Objects/Lara.wad2)
  - [Engine/Scripts/Addons/**AOD_Animations.lua**](Engine/Scripts/Addons/AOD_Animations.lua)

Then keep reading.

## 2.1. Importing the animations
The animations can be found in [Assets/Objects/**Lara.wad2**](Assets/Objects/Lara.wad2).

You only need to **load this WAD into your project**, and update it from time to time.

If you want to use another outfit, simply put it above `Lara.wad2` in your WAD list (Level Settings > *Object Files*).

## 2.2. Fixes & additional features
A Lua file is provided to **fix** issues and implement **additional features**.
1. Grab [Engine/Scripts/Addons/**AOD_Animations.lua**](Engine/Scripts/Addons/AOD_Animations.lua) and put it in the same location in your game folder.
2. Open your `Engine/Scripts/Levels/{your-level-name}.lua` file, and add the following line at the very top of the file:
   ```lua
   require("Addons.AOD_Animations")
   ```

### Fix: Ladders snapping
Fixes Lara snapping up and down after stopping on ladders.  
> The engine implementation of ladders in TR2-5 includes hardcoded frame numbers. Changing the speed of ladder animations results in Lara snapping when she stops moving up or down.

_Original implementation by **Bagas**._

### Feature: Last chance grab
When running off a ledge, holding Action will make Lara turn around and grab the ledge.

_Original implementation by **shabaobab**._
_Animations extracted by **DarkLegendAOD**._

### Feature: Safe drop
When near a ledge at Lara's feet, press Action to make her safely hang from it.
Works when standing (front & back) + crouching.

> **Known issues**:
> - Safe drop triggers if you **save your game** using Action
> - Safe drop triggers **even if Lara is able to do some interaction** (eg. the player wants to push/pull a block)
> - If Lara is **standing on a pushable block**, and in front of her is another pushable block (itself sitting on a pushable block), she might trigger the safe drop animation. Happens when facing North at least in the demo level.
> 
> → _If want to disable it_ (keeping the other features of this file):
> 1. Open the [Engine/Scripts/Addons/**AOD_Animations.lua**](Engine/Scripts/Addons/AOD_Animations.lua) file
> 2. Comment the very last line of the file (ie. add two dashes and a space at the very beginning of the line).

## 2.3. Interactible objects with custom animations
The animations of some interactible objects have been edited to fit Lara's new animations.

These objects are listed below.  
You can find them in [`Assets\Objects\ObjectsInteractible.wad2`](Assets/Objects/ObjectsInteractible.wad2).

Slot               | Description                 | Remarks
-------------------|-----------------------------|----------------------------------------------------------------------------
FLOOR_TRAPDOOR1    | Trapdoor that can be lifted | -
SWITCH_TYPE1       | Classic wall switch         | -
SWITCH_TYPE3       | Electric switch             | The object's dimensions are also different!
SWITCH_TYPE5       | Valve switch                | The object's dimensions are also different!
WALL_SWITCH1       | Wall lever switch           | -
KICK_DOOR          | Kickable door               | -
PUSHPULL_DOOR      | Normal door                 | -

> __Note__: object sounds have *all* been removed from LARA's animations.  
> They are added to the *objects themselves* instead.

## 2.4. Sounds
### Basics
This package is __compatible with the default__ TEN sounds & its TR1-2-3-5 overrides.

If you want the "_full AOD experience_", you can use the resources provided in [Assets/**Sounds**](Assets/Sounds):
- The **sound catalogs** (all the XML files)
- The samples (all the WAV files sorted in subfolders)

### If you want to use the "**1 terrain type = 1 footstep sound**"

The animations are _ready to work_ with the more natural "**1 terrain type = 1 footstep sound**" approach (as opposed to the "stone + footstep sound" approach TR3-4-5 use).

You can use the `Footsteps.xml` catalog, which is setup with this approach in mind.
   1. In Tomb Editor, open your **Level settings**:
      1. In the **Sound Infos** tab, add the [`Assets\Sounds\Footsteps.xml`](Assets/Sounds/Footsteps.xml) catalog.
      2. In the **Sound Sample Paths** tab, add the path to the samples.
   2. Close your Level settings, and open your **Texture sounds** window:
      1. Assign the "**Custom 8**" type to all your **Stone** textures.  
    _This is required because **Stone** itself will not produce any sound. That's how Core Designed it._



# 3. Credits
- Direct contributions
  - [Gecko](https://trcustoms.org/users/70): Testing and error reporting for the TEN version
  - [Bagas](https://trcustoms.org/users/2785): Lua script for fixing ladders snapping
  - [Sezz](https://github.com/Sezzary): Info about TEN's direction & changes regarding animations, general improvements to Lara's handling
- Indirect contributions
  - [Krystian](https://www.trsearch.org/member/3312): Animation utilities, and help generally speaking
  - [Caesum](https://twitter.com/Caesum): Feedback and advice
  - [Daledrau](https://twitter.com/daledrau): Title screen render
  - [Mrshina](https://www.trsearch.org/member/3507): Lara's outfit
  - [The Lost Dominion team](https://www.tombraiderforums.com/showthread.php?t=196197) ([members](https://www.tombraiderforums.com/showthread.php?t=179784)) & [The Lost Dominion Revival team](https://www.tombraiderforums.com/showthread.php?t=216488): Specific AOD items (medipacks, batteries, chocolate bar, power-up, etc)
  - DarkLegendAOD: AOD animations extracted from the Tomb Raider Remastered games
  - [LoreRaider](https://www.trsearch.org/member/3718), [shabaobab](https://www.trsearch.org/member/3956), [vandersweater](https://www.trsearch.org/member/3820): Original implementation for the [last chance grab](https://www.trsearch.org/item/6228) feature
  - [Tomb Engine team](https://github.com/TombEngine/TombEngine): TombEngine
  - [Tomb Editor team](https://github.com/TombEngine/Tomb-Editor): Tomb Editor and its tools
  - Core Design & Eidos Interactive: Tomb Raider

As the [The Dark Renaissance](https://github.com/Castigavi/the-dark-renaissance) project (and before that, The Lost Dominion) was originally a private project in which I was only a member, I did not keep a credits list. I am trying to correct this, but I may be missing people here. Feel free to let me know if you know more details.


# 4. See also

- [**TRLE - Project Fix Lara**](https://github.com/Dermahn/Project-Fix-Lara-v2): Fixed Lara animations for TRLE & TRNG
- [**TRLE - AOD Animations**](https://github.com/Joey79100/trle-aod_animations): Original TRNG version of this project
