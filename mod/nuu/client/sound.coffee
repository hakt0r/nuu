###

  * c) 2007-2019 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2018 flyc0r

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
    @$.onload = resolve
    @$.onerror = reject
    resolve @ if @url.match 'blob:'
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

Sound.on = yes
Sound.chat = yes
Sound.effects = no
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

NUU.on 'gfx:ready', Sound.init = (callback)->
  Sound.radio = new RadioQueue
  list = ( Sound.load 'build/sounds/' + name for name in Sound.autoload )
  Promise.all(list)
  .then Sound.defaults
  .then callback
  return

Sound.defaults = ->
  NUU.on 'ship:hit', -> Sound['explosion1.wav'].play() if Sound.on
  NUU.on 'shot', -> Sound['laser.wav'].play() if Sound.on

# ██ ██████   █████   ██████
# ██ ██   ██ ██   ██ ██
# ██ ██████  ███████ ██
# ██ ██   ██ ██   ██ ██
# ██ ██   ██ ██   ██  ██████

$public class RadioQueue
  constructor:->
    @msg = 0
    @$ = []
    @ctx = new AudioContext latencyHint: "playback", sampleRate: 48000
    @out = @ctx.destination
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
  makeDistortionCurve:(amount)->
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
  add:(url)->
    return URL.revokeObjectURL url unless Sound.chat
    s = new Sound id:"msg#{@msg++}", url:url
    s.load().then =>
      @$.push s
      do @start
      return
    return
  start:->
    @ctx.resume()
    return if @current or 0 is @$.length
    @current = @$.pop()
    @src = @ctx.createMediaElementSource @current.$
    @src.connect @out
    @current.play()
    @current.$.onended = =>
      @src.disconnect @out
      URL.revokeObjectURL @src.url
      delete Sound[@current.id]
      @src = @current = undefined
      do @start
      return
    return

Sound.channel = 'global'

Sound.recordMessage = ->
  return unless Sound.chat
  NET.audio.write Sound.channel, await @startRecording()
  return

Sound.startRecording = -> new Promise (resolve,reject)=>
  do @abortRecording if @recording
  navigator.mediaDevices.getUserMedia audio: true
  .then (@recStream)=>
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
  URL.revokeObjectURL @lastMessageURL if @lastMessageURL
  @recStream.getAudioTracks()[0].stop();
  @aborted = @recording = @lastMessageURL = no
  return

Kbd.macro 'ptt', 'KeyX', 'Send voice',
  dn:-> setTimeout Sound.recordMessage.bind Sound
  up:-> setTimeout Sound.sendMessage  .bind Sound
