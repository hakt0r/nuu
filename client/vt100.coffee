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

PIXI = require 'pixi.js'

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

    @frame = Sprite.layer 'vt', new PIXI.DisplayObjectContainer
    @frame.alpha = 1.0
    @frame.addChild @bg    = new PIXI.TilingSprite PIXI.Texture.fromImage 'build/imag/starfield.png', 0, 0    
    @frame.addChild @text  = new PIXI.Text 'nuu console',
      font: "10px monospace"
      fill: 'green'
    @text.position.set 23,23
    @bg.alpha = 0.5

    app.on 'assets:ready', =>
      @frame.addChildAt (@image = PIXI.Sprite.fromImage Asset.imag.nuulogo.src), 1
      @image.alpha = 0.2
      Sprite.resize()

    Sprite.on 'resize', @resize()
    console.user = @write
    null

  draw: =>
    c = @cursor.x
    @text.setText @input +
      ( if @promptQuery then "\n" + @promptQuery + ": " else '' ) +
     @inputBuffer.substr(0,c) + '|' + @inputBuffer.substr(c)

  resize: -> (wd,hg,hw,hh) =>
    @draw()
    @bg.width = wd
    @bg.height = hg
    return unless @image
    $timeout( 33, => @resize() wd,hg,hw,hh ) if @image.width is 1
    @bgOffsetH = @image.width / 2
    @bgOffsetV = @image.height / 2
    @image.position.set hw - @bgOffsetH, hh - @bgOffsetV
    null

  stopAnimation: =>
    clearInterval @animation if @animation
    @animation = null

  focus: =>
    return if @focused
    @focused = yes
    Kbd.unfocus()
    $(window).on 'keydown', @keyDown
    @draw()

    @stopAnimation()
    @animation = $interval 33, fade = =>
      @frame.alpha += 0.1
      @stopAnimation @frame.alpha = 1.0 if @frame.alpha >= 1.0
    null

  unfocus: =>
    return unless @focused
    @focused = no
    $(window).off 'keydown', @keyDown
    Kbd.focus()
    @draw()

    @stopAnimation()
    @animation = $interval 33, fade = =>
      @frame.alpha -= 0.1
      @stopAnimation @frame.alpha = 0.0 if @frame.alpha <= 0.0
    null

  write: (lines) =>
    @draw @input = lines.trim().split('\n').reverse().concat(@input).join('\n')

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

Kbd.macro 'console', 'return', 'Show / hide console', ->
  vt.prompt 'nuu #', (text) ->
    console.user eval(text).toString()

$static 'vt', new VT100
