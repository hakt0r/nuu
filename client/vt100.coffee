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

$public class VT100 extends EventEmitter
  line: []
  hist: []
  frame: null
  input: 'nuu console / v ' + $version
  cursor: x: 0, y: 0
  inputBuffer: ''
  promptActive: no

  constructor: (opts={}) ->
    @[k] = v for k,v of opts

    @frame = Sprite.layer 'vt', new PIXI.Container
    @frame.alpha = 0.9

    @frame.addChild @text  = new PIXI.Text 'nuu console',
      fontFamily: 'monospace'
      fontSize:'10px'
      fill: 'green'
    @text.position.set 23,23

    @frame.addChild @copyright  = new PIXI.Text '(c) 2007-2016 Sebastian Glaser <anx@ulzq.de> and contributors\n
      License: GNU General Public License v3
      BACKGROUND: ESO / Serge Brunier, Frederic Tapissier\n
      http://apod.nasa.gov/apod/image/0909/milkywaypan_brunier_2048.jpg',
      fontFamily: 'monospace'
      fontSize:'10px'
      fill: 'green'

    Cache.get '/build/imag/milkyway.jpg', (url)=>
      @frame.addChildAt ( @bg = new PIXI.Sprite.fromImage '/build/imag/milkyway.jpg',0,0), 0
      @bg.alpha = 0.7
      Sprite.resize()

    Cache.get '/build/imag/nuulogo.png', (url)=>
      @frame.addChildAt ( @image = PIXI.Sprite.fromImage '/build/imag/nuulogo.png', 0, 0 ), 1
      @image.alpha = 0.2
      Sprite.resize()

    Sprite.on 'resize', @resize()
    Sprite.resize()

    console.user = @write
    null

  draw: =>
    c = @cursor.x
    @text.text = @input +
      ( if @promptQuery then "\n" + @promptQuery + ": " else '' ) +
     @inputBuffer.substr(0,c) + '|' + @inputBuffer.substr(c)

  resize: -> (wd,hg,hw,hh) =>
    @draw()
    @copyright.position.set wd - 10 - @copyright.width, hg - 10 - @copyright.height
    return unless @image
    requestAnimationFrame ( => @resize() wd,hg,hw,hh ) if @image.width is 1 or @bg.width is 1
    @center @bg   , hw, hh
    @center @image, hw, hh
    null

  center: (image,hw,hh)->
    bgOffsetH = image.width / 2
    bgOffsetV = image.height / 2
    image.position.set hw - bgOffsetH, hh - bgOffsetV

  stopAnimation: =>
    clearInterval @animation if @animation
    @animation = null

  focus: =>
    return if @focused
    Sprite.stage.addChild @frame
    @focused = yes
    Kbd.unfocus()
    $(window).on 'keydown', @keyDown
    @draw()
    requestAnimationFrame @animation = =>
      @frame.alpha += 0.1
      return requestAnimationFrame @animation if @frame.alpha < 1.0
      @frame.alpha = 1.0; @animation = null
    null

  unfocus: =>
    return unless @focused
    @focused = no
    $(window).off 'keydown', @keyDown
    Kbd.focus()
    @draw()
    requestAnimationFrame @animation = =>
      @frame.alpha -= 0.1
      return requestAnimationFrame @animation if @frame.alpha > 0.0
      @frame.alpha = 0.0; @animation = null
    null

  write: (lines) =>
    @draw @input = @input + '\n' + lines.trim()

  prompt: (p,callback) =>
    return false if @promptActive
    @focus()
    @promptActive = yes
    @promptQuery = p
    @inputBuffer = ''
    @onReturn = callback
    @cursor.x = 0
    @draw()
    true

  keyDown: (e) =>
    code = e.keyCode
    c = @cursor.x
    # console.log Kbd.cmap[code], code
    if Kbd.cmap[code] is 'return'
      if (fnc = @onReturn)?
        i = @inputBuffer
        delete @onReturn
        @write @promptQuery + ': ' + @inputBuffer
        @hist.cursor = @hist.push(@inputBuffer) - 1
        @cursor.x = 0
        @promptActive = no
        @inputBuffer  = ''
        res = fnc i unless e.shiftKey
        @unfocus()  unless res is true
    else if Kbd.cmap[code] is 'esc'
      res = fnc null if not e.shiftKey and ( fnc = @onReturn )?
      @unfocus() unless res is true
    else if Kbd.cmap[code] is 'left'
      @cursor.x = max(0,--@cursor.x)
    else if Kbd.cmap[code] is 'right'
      @cursor.x = min(@inputBuffer.length,++@cursor.x)
    else if Kbd.cmap[code] is 'up'
      @hist.cursor = max(0,--@hist.cursor)
      @inputBuffer = @hist[@hist.cursor]
      @cursor.x =  @inputBuffer.length
    else if Kbd.cmap[code] is 'down'
      @hist.cursor = min(@hist.length-1,++@hist.cursor)
      @inputBuffer = @hist[@hist.cursor]
      @cursor.x = @inputBuffer.length
    else if Kbd.cmap[code] is 'del'
      @inputBuffer = @inputBuffer.substr(0,c) + @inputBuffer.substr(c+1)
    else if Kbd.cmap[code] is 'bksp'
      @inputBuffer = @inputBuffer.substr(0,c-1) + @inputBuffer.substr(c)
      @cursor.x = max(0,--@cursor.x)
    else if Kbd.cmap[code]
      k = Kbd.cmap[code]
      k = k.toUpperCase() if e.shiftKey
      @inputBuffer = @inputBuffer.substr(0,c) + k + @inputBuffer.substr(c)
      @cursor.x++
    @draw()
    false

VT100.toggle = -> vt.prompt 'nuu #', p = (text) ->
  try console.user eval(text).toString()
  catch e then console.user ( if e and e.message then e.message else e )
  setTimeout ( new Function 'VT100.toggle()' ), 0
  true

Kbd.macro 'console', 'return', 'Show / hide console', VT100.toggle
