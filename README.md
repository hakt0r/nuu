# nuu

NUU is to be an open-source (massive) multiplayer game of space trade and combat: [demo](http://nuu.hakt0r.de/). That means it's free :P

It's **not finished yet, not secure, okay for LAN** and probably will stay that way for a long time ;)
Still **somewhat playable** and I do my best to not break master :D
100% pure JavaScript in its current incarnation, runs a NodeJS backend and targets Chrom(e|ium) as the frontend.

It's excellent open-source cousin [naev](http://blog.naev.org/) currently lends NUU it's **assets**. It's a very nice singleplayer game packed with ages of fun and it is still being extended and improved. Like **naev**, NUU is heavily inspired by [Ambrosia Software](http://www.ambrosiasw.com/)'s [Escape Velocity](http://www.ambrosiasw.com/games/evn/). Still worth it's money. And just so it happens - naev uses assets which in turn are partly attributable to the [Vega Strike](http://vegastrike.sourceforge.net) project. So everyone's related :> A **strong pointer** to [Spacewar!](http://en.wikipedia.org/wiki/Spacewar_(video_game)) should also be cast, explaining the continuous efforts to enable gravity in a playable way :) (at least we have funky orbits now :>)

A tip of the hat should also be extended to [Endless Sky](https://github.com/endless-sky/endless-sky) another excellent EV-esque open-source project.

## **Screenshots**

| <img src="https://raw.githubusercontent.com/hakt0r/nuu/master/screenshot0.png" height="200"/> | <img src="https://raw.githubusercontent.com/hakt0r/nuu/master/screenshot1.png" height="200"/> | <img src="https://raw.githubusercontent.com/hakt0r/nuu/master/screenshot3.png" height="200"/> |

## Intro

  **The 22nd - mankind at it's best**. Despite numerous warnings and attempts to prevent it -
  dating back into the early 21st - ***Earth has been overrun by the drones it's own creation***.
  But you know... we had used it all up and left a stinking pile garbage there -
  which covered most of the surface. So we weren't going to use it that much anymore...

  But now ***Her Majesty the Kernel*** has conquered ***Luna*** and is scheming to take the last human
  strongholds: ***Mars*** and the colonies of the ***Jupiter-system***!!!
  For the past few months we've been struggling to keep the human race afloat and breathing...

## Features

  * Multiplayer Ships
    - Dock with another ship
      - Let other players dock
      - EVA using your EXS-01 Exosuit
    - Take the helm
    - Man a turret
    - Sit in a fighter ready to be launched into mayhem
    - Engine burns and jumps consume fuel, regeneration
  * Weapons
    - Missiles ***dumb*** and ***seeker***
    - Beams ***short-range*** but deadly
    - Projectiles ***plasma***, ***blasters*** or ***real-metal***
    - Fighter Bays ***AI escorts or real players***
  * Loot ***applies for all inhabitants of a vehicle***
    - Cargo Boxes: ***Items*** (upgrade blueprints, one level per collect)
    - Asteroids: ***Resources*** (crafting/building/trading)
    - Ships: collect debris of ***each ship*** type to reverse-engineer their blueprints
  * Trader AI's for Loot
  * Drones in seek-and-destroy mode

## Building

    sudo npm -g install coffeescript
    npm install
    coffee tools/build.coffee deps

## Running the server

    coffee tools/build.coffee run

To debug the server (with the nodejs debugger) just replace **run** with **debug**.

## To play

  Direct you browser to the following url, once the game is loaded you will be prompted to login.

    http://localhost:9999/

  * Right now we only support Chrome/Chromium (Firefox works sometimes ;)
  * Enable **WebGL** for the best gfx-experience (chrome://flags)
  * The first login registers your user (blank password works)
  * Press 'h' for help ;)

## Mouse

* Toggle mouse-turn (on by default) using the Z button (on QWERTY)

| **Left Button**                 | |
| --------: | :-------------------- |
| **none**  | Accelerate            |
| **ctrl**  | Retro                 |
| **shift** | Boost                 |
| **alt**   | Match target speed    |

| **Middle Button**               | |
| --------: | :-------------------- |
| **none**  | Target closest        |
| **ctrl**  | Target closest enemy  |
| **shift** | Target next class     |
| **alt**   | Toggle scanner        |

| **Right Button**                | |
| --------: | :-------------------- |
| **none**  | Trigger primary       |
| **ctrl**  | Trigger secondary     |
| **shift** | Weapon next primary   |
| **alt**   | Weapon next secondary |

## Keyboard

These are the default keybindings as found on as US/QWERTY-keyboard. You can change them in the Help-dialog.

| **Key**         | **Function**                |
| --------------: | :-------------------------- |
| shift-ArrowUp   | Boost                       |
| shift-Z         | Autopilot                   |
| C               | Capture closest             |
| shift-C         | Capture target              |
| ArrowDown       | Decelerate                  |
| J               | Jump to target              |
| Q               | Land / Dock / Enter Orbit   |
| shift-Tab       | Launch / Undock             |
| shift-Q         | Leave vehicle               |
| M               | Next mount                  |
| Digit1          | Next weapon (primary)       |
| Digit2          | Next weapon (secondary)     |
| L               | Open Settings dialog        |
| shift-Digit1    | Previous weapon (primary)   |
| shift-Digit2    | Previous weapon (secondary) |
| Space           | Primary trigger             |
| X               | Secondary trigger           |
| shift-Enter     | Show / hide console         |
| shift-Slash     | Show about / license        |
| O               | Show main menu              |
| H               | Show help                   |
| R               | Target closest asteroid     |
| E               | Target closest enemy        |
| U               | Target closest target       |
| D               | Target next                 |
| W               | Target next class           |
| shift-W         | Target nothing              |
| A               | Target prev                 |
| S               | Target prev class           |
| Tab             | Toggle Land / Dock / Orbit  |
| Z               | Toggle mouseturning         |
| Enter           | Toggle Scanner              |
| alt-Enter       | Toggle Scanner FS           |
| ArrowLeft       | Turn left                   |
| ArrowRight      | Turn right                  |
| Equal           | Zoom scanner in             |
| Minus           | Zoom scanner out            |
| shift-Backquote | Debug                       |

## Copyrights

  * c) 1999-2002 Sebastian Glaser <anx@ulzq.de> (as EVArena)
  * c) 2003-2004 Sebastian Glaser <anx@ulzq.de> (as U)
  * c) 2006 Sebastian Glaser <anx@ulzq.de> (as Uu)
  * c) 2007-2018 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2018 flyc0r

  The nuu project intends to use all the asset files according to
  their respective licenses.

  nuu currently uses the graphics and sound assets of the excellent
  naev project, which in turn are partly attributable to the
  Vega Strike project.

  All assets are downloaded from their source repo to the contrib
  folder during the build process and LICENSE information is copied
  to the build directory, as well as being made available in the
  client's about-screen and the server-splash.

## Licensed under GNU GPLv3

nuu is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

nuu is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this software; see the file COPYING.  If not, write to
the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA 02111-1307 USA

http://www.gnu.org/licenses/gpl.html

## Clarifications regarding commercial use

Besides the fact that NUU is **not production-quality code** and is not recommended for commercial use at the time being, you are - within the boundaries of the GNU GPLv3 - explicitly allowed to run and modify NUU for commercial purposes. This does not include any assets like images or sounds, which have their own respective licenses.
Keep in mind to share patches to the source-code, uphold the license, and respect the attribution rights of the original authors of code and assets.

**TLDR: This game is mostly an engine, any derivate engine must be GPLv3 or higher. Simple as pie.**
