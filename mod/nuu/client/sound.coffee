###

  * c) 2007-2020 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2020 flyc0r

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

NUU.on 'settings:apply', ->
  Sound.on      = NUU.settings.sound
  Sound.effects = NUU.settings.soundEffects
  if Sound.chat = NUU.settings.soundChat
    HUD.updateTopBar 'channel', """<span class="active">##{Sound.channel}</span>"""
  return

$public class Sound
  volume:1
  constructor:(opts={})->
    Object.assign @, opts
    @load().then opts.callback if opts.callback
    Sound[@id] = @
  load:-> new Promise (resolve,reject)=>
    return reject new Error 'URL required' unless @url
    @$ = document.createElement 'audio'
    @$.src = @url
    @$.onloadeddata = =>
      @loaded = true
      do resolve
    @$.onerror = reject
    @$.volume = @volume || 1
    # resolve @ if @url.match 'blob:'
    return
  play:->
    return unless Sound.on
    return if @effect and not Sound.effects
    @$.play()
  loop:->
    @ctx = new AudioContext latencyHint: "playback", sampleRate: 48000
    @ctx.resume()
    @src = @ctx.createMediaElementSource @$
    @src.connect @ctx.destination
    @$.loop = true
    @$.play()

Sound.init = (callback)->
  Sound.radio = new Radio
  await Promise.all ( Sound.load 'build/sounds/' + name for name in Sound.autoload )
  Sound.defaults()
  callback() if callback
  # Sound.gestureThief()
  return
NUU.on 'gfx:ready', Sound.init

Sound.on = yes
Sound.chat = no
Sound.effects = yes
Sound.volume = 1

Sound.autoload = ['afb_disengage.wav','afterburner.wav','autocannon.ogg',
  'bansheeexp.ogg','beam0.wav','beam_off0.wav','compression.ogg',
  'empexplode.ogg','engine.wav','explosion0.wav','explosion1.wav',
  'explosion2.wav','grenade.wav','grenadefire.ogg','hail.ogg',
  'hyperspace_engine.ogg','hyperspace_jump.ogg','hyperspace_powerdown.ogg',
  'hyperspace_powerup.ogg','hyperspace_powerupjump.ogg','ion.wav','jump.wav',
  'laser.wav','lrgexp0.ogg','mace.wav','mass.wav','medexp0.ogg','medexp1.ogg',
  'missile.wav','nav.wav','neutron.wav','plasma.wav','ripper.ogg','seeker.wav',
  'target.wav']

Sound.load = (path)-> return new Promise (resolve)->
  name   = path.replace(/^.*\//,'')
  folder = path.replace(/\/[^\/]+$/,'').replace(/^.*\//,'')
  Cache.get path, (objURL)->
    new Sound(id:name, url:objURL, autoPlay:no, volume:1, effect:yes).load().then resolve
  return

Sound.defaults = ->
  NUU.on 'ship:hit', -> Sound['explosion1.wav'].play() if Sound.on
  NUU.on 'shot', -> Sound['laser.wav'].play() if Sound.on

# TODO: Steal login gesture ( click on login or enter )
# Convince browser to play network messages from moment
# of login. According to docs ctx.resume() should
# suffice, but sth. is wrong, obviously.

Sound.gestureThief = ->
  splashSound = ->
    @radio.init()
    @radio.ctx.resume()
    @radio.add Sound['hail.ogg'].url, volume:0.01, keep:yes
    @recStream = await navigator.mediaDevices.getUserMedia audio: true
    @recorder = new MediaRecorder @recStream, mimeType: 'audio/webm'
    @recorder.ondataavailable = (e)=>
      return resolve false if @aborted
      @recording = no; @recStream.getAudioTracks()[0].stop();
    @recorder.start()
    setTimeout ( => @recorder.stop() ), 1000
    document.removeEventListener 'mousedown', splashSoundBound, passive:no, once:yes, capture:yes
    document.removeEventListener 'keydown',   splashSoundBound, passive:no, once:yes, capture:yes
  splashSoundBound = splashSound.bind Sound
  document.addEventListener 'mousedown', splashSoundBound, passive:no, once:yes, capture:yes
  document.addEventListener 'keydown',  splashSoundBound, passive:no, once:yes, capture:yes

# ██ ██████   █████   ██████
# ██ ██   ██ ██   ██ ██
# ██ ██████  ███████ ██
# ██ ██   ██ ██   ██ ██
# ██ ██   ██ ██   ██  ██████

$public class Radio
  constructor:->
    @msg = 0
    @$ = []
  init:->
    @ctx = new AudioContext latencyHint: "playback", sampleRate: 48000
    @out = @ctx.destination
    # @add Sound['hail.ogg'].url, volume:0.1, keep:yes
    return unless Sound.radioEffect
    @out = @band = @ctx.createBiquadFilter()
    @band.type = "bandpass"
    @band.frequency.value = 3001
    @band.gain.value = .55
    @band.connect @dist = @ctx.createWaveShaper()
    @dist.curve = @makeDistortionCurve .75
    @dist.connect @gain = @ctx.createGain()
    @gain.gain.value = 1
    @gain.connect @ctx.destination

Radio::makeDistortionCurve = (amount)->
  k = `typeof amount === 'number' ? amount : 0`
  n_samples = 44100
  curve = new Float32Array n_samples
  deg = Math.PI / 180
  i = 0
  while i < n_samples
    x = i * 2 / n_samples - 1
    curve[i] = (3 + k) * x * 20 * deg / (Math.PI + k * Math.abs(x))
    ++i
  curve

Radio::add = (url,opts={})->
  unless Sound.chat
    URL.revokeObjectURL url unless opts.keep
    return
  opts.volume = 1 unless opts.volume
  opts.id = "msg#{@msg++}"
  opts.url = url
  s = new Sound opts
  await s.load()
  @$.push s
  do @play
  return

Radio::play = ->
  @ctx.resume()
  return do @cleanAndNext if @current and @current.$.buffered.length is 0
  return                  if 0 is @$.length
  @current = @$.pop()
  @src = @ctx.createMediaElementSource @current.$
  @src.connect @out
  @current.$.play()
  console.log @current
  HUD.updateTopBar 'channel', """<span class="active">##{Sound.channel}</span><span class=user>#{
    if n = @current.nick then '@'+n else '$nuu'
  }</span>"""
  @current.$.onended = @current.$.onerror = => do @cleanAndNext
  setTimeout ( => do @play ), 100
  return

Radio::cleanAndNext = ->
  HUD.updateTopBar 'channel', """<span class="active">##{Sound.channel}</span>"""
  @src.disconnect @out
  URL.revokeObjectURL @src.url
  delete Sound[@current.id]
  @src = @current = undefined
  do @play
  return

Sound.channel = 'global'

Sound.recordMessage = ->
  return unless Sound.chat
  HUD.updateTopBar 'channel', """<span class="speaking">##{Sound.channel} 🎙</span>"""
  NET.audio.write Sound.channel, await @startRecording()
  HUD.updateTopBar 'channel', """<span class="active">##{Sound.channel}</span>"""
  return

Sound.startRecording = -> new Promise (resolve,reject)=>
  do @abortRecording if @recording
  @recStream = await navigator.mediaDevices.getUserMedia audio: true
  @recorder = new MediaRecorder @recStream, mimeType: 'audio/webm'
  @recorder.ondataavailable = (e)=>
    return resolve false if @aborted
    @recording = no; @recStream.getAudioTracks()[0].stop();
    resolve e.data
  @recorder.start()

Sound.sendMessage = ->
  do @recorder.stop if @recorder and 'inactive' isnt @recorder.state
  return

Sound.abortRecording = ->
  return unless @recording
  @aborted = true
  do @recorder.stop
  @recStream.getAudioTracks()[0].stop();
  @aborted = @recording = no
  return

Kbd.macro 'ptt', 'KeyX', 'Send voice',
  dn:->
    Sound.radio.ctx.resume()
    setTimeout Sound.recordMessage.bind Sound
  up:-> setTimeout Sound.sendMessage.bind Sound

Kbd.macro 'pttPlay', 'cKeyX', 'Play radio', ->
  Sound.radio.ctx.resume()
  Sound.radio.play()

Kbd.macro 'pttToggle', 'sKeyX', 'Toggle radio', ->
  if NUU.settings.soundChat = Sound.chat = not Sound.chat
       HUD.updateTopBar 'channel', """<span class="active">##{Sound.channel}</span>"""
  else HUD.updateTopBar 'channel', """<span class="inactive">##{Sound.channel}</span>"""
  do NUU.saveSettings
  return

Kbd.macro 'pttChannel', 'aKeyX', 'Set channel', up:->
  vt.prompt 'channel', ( (c)->
    HUD.updateTopBar 'channel', """#<span class="active">#{Sound.channel = c}</span>""" if Sound.chat
    return
  ), yes
  return
