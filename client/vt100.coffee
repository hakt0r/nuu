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

mblur = []
PIXI = require 'pixi.js'

VT100 = class VT100 extends EventEmitter
  line: []
  hist: []
  frame: null
  input: 'nuu console / v 0.4.68'
  cursor: x: 0, y: 0
  inputBuffer: ''
  promptActive: no
  
  constructor: (opts={}) ->
    window.vt = @
    @[k] = v for k,v of opts
    $cue => @focus()
    @frame = new PIXI.DisplayObjectContainer
    @frame.alpha = 1.0
    @frame.addChild @bg    = new PIXI.TilingSprite PIXI.Texture.fromImage 'build/imag/starfield.png', 0, 0    
    @frame.addChild @image = PIXI.Sprite.fromImage 'build/imag/nuulogo.png'
    @frame.addChild @text  = new PIXI.Text 'nuu console',
      font: "10px monospace"
      fill: 'green'
    @text.position.set 23,23
    @image.alpha = 0.2
    @bg.alpha = 0.5
    Sprite.stage.addChild @frame

    console.user = @write
    @$win = $(window)
    @$win.on 'resize', @resize
    setTimeout @resize, 100
    null

  draw : =>
    c = @cursor.x
    @text.setText @input +
      ( if @promptQuery then "\n" + @promptQuery + ": " else '' ) +
     @inputBuffer.substr(0,c) + '|' + @inputBuffer.substr(c)

  resize : =>
    x = ( w = @$win.width() ) / 2 - @image.width / 2
    y = ( h = @$win.height() ) / 2 - @image.height / 2
    @image.position.set x, y
    @bg.width = w
    @bg.height = h
    @draw()
    null

  focus : =>
    return if @focused
    @focused = yes
    Kbd.unfocus()
    $(window).on 'keydown', @keyDown
    @draw()

    Sprite.stage.addChild @frame
    @frame.alpha = 0.0
    fade = =>
      @frame.alpha += 0.1
      if @frame.alpha >= 1.0
        clearInterval i
        @frame.alpha = 1.0
    i = setInterval fade, 33
    null

  unfocus : =>
    return unless @focused
    @focused = no
    $(window).off 'keydown', @keyDown
    Kbd.focus()
    @draw()

    if @frame.alpha is 1.0
      @frame.alpha = 1.0
      fade = =>
        @frame.alpha -= 0.1
        if @frame.alpha <= 0.0
          clearInterval i
          @frame.alpha = 0.0
      i = setInterval fade, 33
      null

  write : (lines) =>
    @draw @input = lines.trim().split('\n').reverse().concat(@input).join('\n')

  prompt : (p,callback) =>
    return false if @promptActive
    @focus()
    @promptActive = yes
    @promptQuery = p
    @inputBuffer = ''
    @onReturn = callback
    @cursor.x = 0
    @draw()
    true

  keyDown : (e) =>
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
        @unfocus()
        fnc i
    else if Kbd.cmap[code] is 'esc'
      fnc null if (fnc = @onReturn)?
      @unfocus()
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

$public VT100