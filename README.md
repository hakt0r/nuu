## nuu - space game :D
NUU is to be a (massive) multiplayer game heavily inspired by [Ambrosia Software](http://www.ambrosiasw.com/)'s "[Escape Velocity](http://www.ambrosiasw.com/games/evn/)" and it's excellent open-source clone "[naev](http://blog.naev.org/)". It's not finished yet and probably will stay that way for a long time ;)

### Building

    npm install
    coffee tools/build.coffee deps
  
### Running the server

    coffee tools/build.coffee run
  
To debug the server (with the nodejs debugger) just replace **run** with **debug**.

### To play

  Direct you browser to the following url, once the game is loaded you will be prompted to login.

    http://localhost:9999/

  * Right now we only support Chrome/Chromium
  * Enable **WebGL** for the best gfx-experience (chrome://flags)

### Copyrights

  * c) 2007-2015 Sebastian Glaser <anx@ulzq.de>
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
