###

  * c) 2007-2015 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2008 flyc0r

  This file is part of NUU.

  NUU is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  NUU is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with NUU.  If not, see <http://www.gnu.org/licenses/>.

###

Kbd.macro 'about', 'S/', 'Show about screen / License', ->
  about = $ """
    <div class="about">
      <div class="tabs" id="tabs">
        <a class="tabbtn" href="#game">Game</a>
        <a class="tabbtn" href="#node">Libraries</a>
        <a class="tabbtn" href="#artwork">Artwork</a>
        <a class="tabbtn" href="#sounds">Sounds</a>
        <a class="close"  href="#">Close</a>
      </div>
      <div class="tab" id="game">
        <img src="/build/imag/nuulogo.png">
        <p/><ul>
          <li>c) 2007-2015 Sebastian Glaser <anx@ulzq.de></li>
          <li>c) 2007-2008 flyc0r</li>
        </ul>

        <p/>The nuu project intends to use all the asset files according to
        their respective licenses.

        <p/>nuu currently uses the graphics and sound assets of the excellent
        naev project, which in turn are partly attributable to the
        Vega Strike project.

        <p/>All assets are downloaded from their source repo to the contrib
        folder during the build process and LICENSE information is copied
        to the build directory as well as being made available in the
        client's about screen and the server splash.
      </div>
      <div class="tab" id="node" data-src="/build/node_packages.html"></div>
      <div class="tab pre" id="artwork" data-src="/build/ARTWORK_LICENSE.txt"></div>
      <div class="tab pre" id="sounds"  data-src="/build/SOUND_LICENSE.txt"></div>
    </div>
  """
  about.appendTo $ 'body'
  about.find('.close').on 'click', -> about.remove()
  tabs = about.find '.tab'
  tabs.each (k,i) -> if (src = $(i).attr 'data-src' )
    $.get src, (data,s,x) -> $(i).html data
  activate = (name) ->
    tabs.css 'display', 'none'
    $('#'+name.replace(/.*#/,'')).css 'display', 'block'
  btns = about.find '.tabbtn'
  btns.on 'click', -> activate @href
  activate '#game'
