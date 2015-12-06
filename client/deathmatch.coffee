###

  * c) 2007-2016 Sebastian Glaser <anx@ulzq.de>
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

Window.Ships = class ShipsWindow extends ModalListWindow
  name: 'ship'
  title: 'Ships'
  subject: Item.byType.ship
  closeKey: 'Sd'
  render: (key,val)->
    Render.Ship.call @,key, val, @close.bind @
    null

Kbd.macro 'ships',  'Ss', 'Show ships', -> new Window.Ships

Render =
  Ship: (name,item,close)->
    sprite = item.sprite
    sprite = parent.sprite if item.extends and item.extends.match and ( item.extends isnt item.name ) and parent = Item.byName[item.extends]
    @body.append entry = $ """
      <div class="list-item select-ship">
      <label>#{item.name}</label>
      <div id="ship_select_#{name}" class="ship-select noselect">
        <img class="ship_comm" src="build/ship/#{sprite}/#{sprite}_comm.png"></img>
        <button class="buy">Buy</button>
        <button class="select">Select</button>
      </div>
      </div>"""
    bBuy    = entry.find 'button.buy'
    bSelect = entry.find 'button.select'
    bSelect.click -> close NET.json.write switchShip: item.name
