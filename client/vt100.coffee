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

$public class VT100 extends Window
  line: []
  hist: []
  frame: null
  input: 'nuu console / v ' + $version + '<span class="right">(c) 2007-2018 Sebastian Glaser &lt;anx@ulzq.de&gt; / (c) 2007-2008 flyc0r</span>' +
    '<span class="right">GNU General Public License v3 / see license screen (alt-L)</span>'
  cursor: x: 0, y: 0
  inputBuffer: ''
  promptActive: no

  constructor: (opts={}) ->
    super
    @$.addClass 'vt full'
    console.user = @write
    null

  draw: =>
    c = @cursor.x
    p = if @promptQuery then "\n" + @promptQuery + ": " else ''
    b = @inputBuffer
    b = b.replace /./g, "*" if @stars
    b = b.substr(0,c) + '<i class="vt-cursor"></i>' + b.substr c
    @body.html @input + p + b
    @$[0].scroll top: @body.height()

  stopAnimation: =>
    clearInterval @animation if @animation
    @animation = null

  write: (lines) =>
    @draw @input = @input + '\n' + lines

  status: (p,t)->
    do @show
    if @lastSP and ( @lastSP isnt p or @lastST isnt t )
      log @lastSP+':', @lastST
    @inputBuffer = t+'\n'
    @cursor.x = t.length + 1
    @draw @promptQuery = p
    @lastSP = p; @lastST = t

  prompt: (p,callback,override) =>
    log @lastSP+':', @lastST if @lastSP and not @stars; @lastST = @lastSP = null
    return false if @promptActive unless override or p.override
    if typeof p is 'object'
      @stars = p.stars || false
      @overrideKeys = p.key
      callback = p.then
      p = p.p
    @focus()
    @promptActive = yes
    @promptQuery = p
    @inputBuffer = ''
    @onReturn = =>
      log @lastSP+':', @lastST if @lastSP and not @stars; @lastST = @lastSP = null
      return true if true is callback.apply @, arguments
      @promptQuery = 'nuu#'
      @hide()
      false
    @cursor.x = 0
    @draw()
    true

  keyHandler: (e) =>
    # allow some browser-wide shortcuts that would otherwise not work
    return if e.ctrlKey and e.code is 'KeyR' if isClient
    return if e.ctrlKey and e.code is 'KeyL' if isClient
    return if true is @overrideKeys e if @overrideKeys
    key = e.code
    key = 'c' + key if e.ctrlKey
    key = 'a' + key if e.altKey
    key = 's' + key if e.shiftKey
    code = e.keyCode
    c = @cursor.x
    console.log Kbd.cmap[code], code, e.code, e.ctrlKey, e, e.char
    if key is 'Enter'
      if (fnc = @onReturn)?
        i = @inputBuffer
        delete @onReturn
        @write @promptQuery + ': ' + if @stars then @inputBuffer.replace(/./g,'*') else @inputBuffer
        @hist.cursor = @hist.push(@inputBuffer) - 1
        @cursor.x = 0
        @promptActive = no
        @inputBuffer  = ''
        res = fnc i unless e.shiftKey
        @hide() unless res is true
    else if key is 'Escape' or key is 'sEscape' or key is 'Backquote'
      res = fnc null if not e.shiftKey and ( fnc = @onReturn )?
      @hide() unless res is true
    else if key is 'ArrowLeft'
      @cursor.x = max(0,--@cursor.x)
    else if key is 'ArrowRight'
      @cursor.x = min(@inputBuffer.length,++@cursor.x)
    else if key is 'ArrowUp'
      @hist.cursor = max(0,--@hist.cursor)
      @inputBuffer = @hist[@hist.cursor]
      @cursor.x =  @inputBuffer.length
    else if key is 'ArrowDown'
      @hist.cursor = min(@hist.length-1,++@hist.cursor)
      @inputBuffer = @hist[@hist.cursor]
      @cursor.x = @inputBuffer.length
    else if key is 'Delete'
      @inputBuffer = @inputBuffer.substr(0,c) + @inputBuffer.substr(c+1)
    else if key is 'aDelete'
      @inputBuffer = @inputBuffer.substr(0,c)
      @cursor.x = @inputBuffer.length
    else if key is 'Backspace'
      @inputBuffer = @inputBuffer.substr(0,c-1) + @inputBuffer.substr(c)
      @cursor.x = max(0,--@cursor.x)
    else if key is 'aBackspace'
      @inputBuffer = @inputBuffer.substr(c)
      @cursor.x = 0
    else if Kbd.cmap[code]
      k = Kbd.cmap[code]
      k = k.toUpperCase() if e.shiftKey
      @inputBuffer = @inputBuffer.substr(0,c) + k + @inputBuffer.substr(c)
      @cursor.x++
    @draw()
    false

VT100.toggle = ->
  vt.show()
  vt.prompt 'nuu #', p = (text) ->
    return false unless text
    try
      v = eval(text)
      console.user v.toString() if v?
    catch e
      console.user ( if e and e.message then e.message else e )
      true
    setTimeout ( new Function 'VT100.toggle()' ), 0
    true

Kbd.macro 'console', 'Backquote', 'Show / hide console', VT100.toggle
