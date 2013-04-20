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

VT100 = class VT100 extends EventEmitter
  frame: null
  line : []
  hist : []
  cursor : x : 0, y: 0
  
  motionblur:->
    for i in [0...9]
      clearTimeout mblur[i] if mblur[i] 
      mblur[i] = $timeout 50+i*50, @sprite.draw

  constructor: (options={}) ->
    wd = hg = hw = hh = 0; $c = null
    window.vt = @

    Sprite.layer 'vt', draw : (c,@sprite) => # spritesurface inited
      @frame$ = $c = $ c.canvas
      c.strokeStyle = "black"
      console.user = @write
      $cue -> Sprite.vt.draw()
      return => # drawing function
        c.font = "10px monospace"
        c.globalAlpha = 0.3 unless @__prompt
        c.fillStyle = 'black'
        c.fillRect 0,0,wd,hg

        if (i = Sprite.imag.nuulogo) and Sprite.imag.nuulogo.constructor.name is 'HTMLImageElement'
          c.drawImage i, wd/2 - i.naturalWidth/2, 100 # draw logo

        if (i = Sprite.lastload)
          c.drawImage i, wd/2 - i.naturalWidth/2, 300 # draw loadimg

        oy = if @__prompt then 24 else 12
        ct = 0

        c.fillStyle = "green"
        for i,l of @line
          c.strokeText l, 5, hg - oy - i * 12
          c.fillText   l, 5, hg - oy - i * 12
          break if ct++ is 40

        if @__prompt
          cw = c.measureText('w').width
          c.fillStyle = "grey"
          c.fillRect (@cursor.x+@__query.length+3) * cw, hg - 20, cw, 10
          c.fillStyle = "green"
          l = @__query + ': ' + @__input
          c.strokeText l, 5, hg - 12
          c.fillText   l, 5, hg - 12

    @[k] = v for k,v of options

    _resize = =>
      wd = _win.width();  hw = wd / 2
      hg = _win.height(); hh = hg / 2
      $c.css 'width', wd+'px'
      $c.attr 'width', wd
      $c.css 'height', hg+'px'
      $c.attr 'height', hg
      @sprite.draw()
      null

    _win = $ window
    _win.on 'resize', _resize
    _resize()
    @focus()
  
  focus : =>
    return if @focused
    @focused = yes
    Kbd.unfocus()
    $(window).on 'keydown', @__dn
    @frame$.fadeIn()

  unfocus : =>
    return unless @focused
    @focused = no
    $(window).off 'keydown', @__dn
    Kbd.focus()
    @frame$.fadeOut()

  write : (lines) =>
    @line = lines.trim().split('\n').reverse().concat @line
    @sprite.draw(); @motionblur()

  prompt : (p,callback) =>
    return false if @__prompt
    @focus()
    @__prompt = yes
    @__query = p
    @__input = ''
    @onReturn = callback
    @cursor.x = 0
    @sprite.draw(); @motionblur()
    true

  __prompt : no
  __input : ''
  __dn : (e) =>
    code = e.keyCode
    # console.log Kbd.cmap[code], code
    if Kbd.cmap[code] is 'del'
    else if Kbd.cmap[code] is 'return'
      if (fnc = @onReturn)?
        i = @__input
        delete @onReturn
        @write @__query + ': ' + @__input
        @hist.cursor = @hist.push(@__input) - 1
        @cursor.x = 0
        @__prompt = no
        @__input  = ''
        @unfocus()
        fnc i
    else if Kbd.cmap[code] is 'up'
      @hist.cursor = max(0,--@hist.cursor)
      @__input = @hist[@hist.cursor]
      @cursor.x =  @__input.length
    else if Kbd.cmap[code] is 'down'
      @hist.cursor = min(@hist.length-1,++@hist.cursor)
      @__input = @hist[@hist.cursor]
      @cursor.x =  @__input.length
    else if Kbd.cmap[code] is 'esc'
      @unfocus()
    else if Kbd.cmap[code] is 'bksp'
      @__input = @__input.substr 0, @__input.length - 1
      @cursor.x = max(0,--@cursor.x)
    else if Kbd.cmap[code]
      k = Kbd.cmap[code]
      k = k.toUpperCase() if e.shiftKey
      @__input += k
      @cursor.x++
    @sprite.draw(); @motionblur()
    return true

$public VT100