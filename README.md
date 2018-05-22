## nuu
NUU is to be an open-source (massive) multiplayer game of space trade and combat: [demo](http://nuu.hakt0r.de/). That means it's free :P

It's **not finished yet, not secure, okay for LAN** and probably will stay that way for a long time ;)
Still **somewhat playable** and I do my best to not break master :D
100% pure JavaScript in its current incarnation, runs a NodeJS backend and targets Chrom(e|ium) as the frontend.

It's excellent open-source cousin [naev](http://blog.naev.org/) currently lends NUU it's **assets**. It's a very nice singleplayer game packed with ages of fun and it is still being extended and improved.

Like **naev**, NUU heavily inspired by [Ambrosia Software](http://www.ambrosiasw.com/)'s [Escape Velocity](http://www.ambrosiasw.com/games/evn/). Still worth it's money.

A **strong pointer** to [Spacewar!](http://en.wikipedia.org/wiki/Spacewar_(video_game)) should also be cast, explaining the continuous efforts to enable gravity in a playable way :) (at least we have funkey orbits now :>)

![screenshot](https://raw.githubusercontent.com/hakt0r/nuu/master/screenshot.png "NUU in action - screenshot")

### Features
  * Trader AI's for Loot
  * Fighter Bays
    - AI escorts or real players
  * Multiplayer Ships
    - Dock with another ship, or let other players dock
    - Take the helm, man turret, or sit in a fighter ready to be launched into mayhem

### Building

    sudo npm -g install coffeescript
    npm install
    coffee tools/build.coffee deps

### Running the server

    coffee tools/build.coffee run

To debug the server (with the nodejs debugger) just replace **run** with **debug**.

### To play

  Direct you browser to the following url, once the game is loaded you will be prompted to login.

    http://localhost:9999/

  * Right now we only support Chrome/Chromium (Firefox works sometimes ;)
  * Enable **WebGL** for the best gfx-experience (chrome://flags)
  * The first login registers your user (blank password works)
  * Press 'h' for help ;)

### Copyrights

  * c) 2007-2018 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2008 flyc0r

  The nuu project intends to use all the asset files according to
  their respective licenses.

  nuu currently uses the graphics and sound assets of the excellent
  naev project, which in turn are partly attributable to the
  Vega Strike project.

  All assets are downloaded from their source repo to the contrib
  folder during the build process and LICENSE information is copied
  to the build directory, as well as being made available in the
  client's about-screen and the server-splash.

### Licensed under GNU GPLv3

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

### Clarifications regarding commercial use

Besides the fact that NUU is **not production-quality code** and is not recommended for commercial use at the time being, you are - within the boundaries of the GNU GPLv3 - explicitly allowed to run and modify NUU for commercial purposes. This does not include any assets like images or sounds, which have their own respective licenses.
Keep in mind to share patches to the source-code, uphold the license, and respect the attribution rights of the original authors of code and assets.

**TLDR: This game is mostly an engine, any derivate engine must be GPLv3 or higher. Simple as pie.**
