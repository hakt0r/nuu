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

$public class Asset
  @meta: {}
  @outfit: {}
  @stel: {}
  @ship: {}

  @loadSprite: (url) ->
    if ( @img = Asset[url] )
      meta = Asset.meta['build/'+url]
      @size = meta.width
      @show()
    else
      @img = Asset.imag.loading.src
      Cache.get url, (cached) =>
        Asset[url] = cached
        Asset.loadSprite.call @, url

  @loadTile: (url,dest='img',callback) ->
    if ( @[dest] = Asset[url] )
      meta = Asset.meta['build/'+url]
      @size = ( meta.width - ( meta.width % @cols ) ) / @cols
      @count = @cols * @rows
      @updateTile @show()
      callback null if callback
    else
      @[dest] = Asset.imag.loading.src
      Cache.get url, (cached) =>
        Asset[url] = cached
        Asset.loadTile.call @, url, dest, callback

  @loadAnimation: (url) -> 
    if ( @img = Asset[url] )
      meta = Asset.meta['build/'+url]
      @size = ( meta.width - ( meta.width % 6 ) ) / 6
      @count = 36
      @updateTile @show()
    else
      @img = Asset.imag.loading.src
      Cache.get url, (cached) =>
        Asset[url] = new Animation name, cached, Asset.meta['build/'+url]
        Asset.loadAnimation.call @, url

  @init: (callback) =>
    async.parallel [
      (c)=> $.ajax('/build/images.json').success (result) =>
        @meta[file] = meta for file, meta of result
        c null
      (c) => @imag 'nuulogo',   -> c null
      (c) => @imag 'nuuseal',   -> c null
      (c) => @imag 'starfield', -> c null
      (c) => @imag 'parallax',  -> c null
      (c) => @imag 'loading'  , -> c null
      (c) -> Sound.init c
    ], ->
      console.log 'NUU.assets.ready'
      app.emit 'assets:ready'

  @waiting = {}
  @load: (type,name,url,callback) =>
    if ( rec = @[type][name] )
      if typeof rec is 'object' or rec.listen is 'done'
        callback rec.obj
      else rec.listen.push callback
    else
      rec = @[type][name] = obj: null, listen: [callback], url: "#{type}/#{url}.png"
      Cache.get rec.url, (objURL) =>
        return console.log "LoadFailed:", rec unless objURL
        rec.obj = img = new Image
        img.src = objURL
        img.onload = ->
          cb img for cb in rec.listen
          rec.listen = 'done'
          null
        null
    null

  @imag: (name, callback) ->
    @load 'imag', name, name, (img) =>
      @['imag'][name] = img
      callback null
      null
    null

  @outfit: (name, callback) =>
    @load 'outfit', name, name, (img) => callback img
    null

app.on 'cache:ready', Asset.init
