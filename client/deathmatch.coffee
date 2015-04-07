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

Kbd.macro 'items', 'Sd', 'Ships and Items', ->
  items = $ """
    <div class="about">
      <div class="tabs" id="tabs">
        <a class="close"  href="#">Close</a>
      </div>
      <div id="select-ship">

      </div>
    </div>
  """
  items.appendTo $ 'body'
  items.find('.close').on 'click', -> items.remove()
  list = items.find '#list'
  render = 
    stats: (item) -> for k,v of item
      table.append """<div><label>#{k}</label><value>#{v}</value></div>"""
    slots: (item) -> for type, slots of item
      for v in slots
        table.append """<div><label>#{type}</label><value>#{v.size}</div>"""
  for name, item of Item.byType.ship
    list.append """
      <div id="ship_select_#{name}" class="ship-select">
        <h2>#{item.name}</h2>
        <img class="ship_comm" src="build/ship/#{item.sprite.name}/#{item.sprite.name}_comm.png"></img>
        <p>#{item.info.description}</p>
      </div>"""
    table = list.find '#'+name