
NUU.on 'debug', ->
  Kbd.macro 'build',  'KeyB', 'Show debug build menu', -> new Window.dbgStation
  Kbd.macro 'ships', 'sKeyB', 'Show debug ship menu',  -> new Window.dbgShips

Window.dbgShips = class DebugShipWindow extends ModalListWindow
  name: 'dbg_ship'
  title: 'Ships'
  subject: Item.byType.ship
  closeKey: 'sKeyS'
  fetch:(done)->
    NET.json.write unlocks:''
    NET.once 'unlocks', (@filter)=>
      window.UNLOCKS = @filter
      done @subject
    null
  render: (key,val)->
    Render.Ship.call @, key, val, @close.bind @ if @filter[val.name]
    null

Window.dbgStation = class DebugBuildWindow extends ModalListWindow
  name: 'dbg_build'
  title: 'Station'
  subject: Item.byType.station
  closeKey: 'aKeyS'
  render: (key,val)->
    Render.Station.call @,key, val, @close.bind @
    null
