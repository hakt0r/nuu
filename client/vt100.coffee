###

  * c) 2007-2018 Sebastian Glaser <anx@ulzq.de>
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

    @frame.addChild @bg = new PIXI.Graphics
    @bg.alpha = 0

    @frame.addChild @text = new PIXI.Text 'nuu console',
      fontFamily: 'monospace'
      fontSize:'12px'
      fill: 'green'
      breakWords: yes
      wordWrap: yes
      wordWrapWidth: 500

    @frame.addChild @copyright  = new PIXI.Text """
      (c) 2007-2018 Sebastian Glaser <anx@ulzq.de>
      Code: GNU General Public License v3
      Contrib: (press ? for details)
    """, fontFamily: 'monospace', fontSize:'12px', fill: 'green'

    Cache.get '/build/imag/nuulogo.png', (url)=>
      @frame.addChildAt ( @image = PIXI.Sprite.fromImage '/build/imag/nuulogo.png', 0, 0 ), 1
      # @image.alpha = 0.2
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
    @copyright.position.set 10, 10
    return unless @image
    requestAnimationFrame ( => @resize() wd,hg,hw,hh ) if @image.width is 1 # or @bg.width is 1
    @center @image, hw, hh
    @text.position.set 40, hh/2 + @image.height + 40
    @text.style.wordWrapWidth = wd - 40
    @bg.position.set 20, hh/2+@image.height+20
    @bg.width = w = wd - 40
    @bg.height = h = hg - (hh/2+@image.height) - 40
    @bg.clear()
    @bg.beginFill 0x000000
    @bg.drawRoundedRect 0,0,w,h,5
    @bg.endFill()
    # @center @bg   , hw, hh
    null

  center: (image,hw,hh)->
    # image.anchor.set [0.5,0.5]
    # image.position.set hw, hh
    bgOffsetH = image.width / 2
    bgOffsetV = image.height / 2
    image.position.set hw - bgOffsetH, hh/2 - bgOffsetV

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

VT100.toggle = ->
  vt.bg.alpha = 0.95
  vt.prompt 'nuu #', p = (text) ->
    try console.user eval(text).toString()
    catch e then console.user ( if e and e.message then e.message else e )
    setTimeout ( new Function 'VT100.toggle()' ), 0
    true

Kbd.macro 'console', 'Sreturn', 'Show / hide console', VT100.toggle
