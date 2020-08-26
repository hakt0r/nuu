Window.About = class AboutWindow extends Window
  title: 'About NUU / License'
  closeKey:'aKeyH'
  constructor:->
    super()
    @$.addClass 'about full'
    @$.append $ """
      <div class="tabs" id="tabs">
        <a class="tabbtn" href="#game">Game</a>
        <a class="tabbtn" href="#node">Libraries</a>
        <a class="tabbtn" href="#artwork">Artwork</a>
        <a class="tabbtn" href="#sounds">Sounds</a>
        <a class="close"  href="#">Close</a>
      </div>
      <div class="tab" id="game">
        <img src="/build/imag/logo_2018_2.svg">
        <p><ul class="copyrights">
          <li>c) 2007-2020 Sebastian Glaser <anx@ulzq.de></li>
          <li>c) 2007-2020 flyc0r</li>
        </ul></p>

        <p class="desc">The nuu project intends to use all the asset files
        according to their respective licenses.</p>

        <p class="desc">nuu currently uses the graphics and sound assets of
        the excellent naev project, which in turn are partly attributable to the
        Vega Strike project.</p>

        <p class="desc">All assets are downloaded from their source repo to
        the contrib folder during the build process and LICENSE information is
        copied to the build directory as well as being made available in the
        client's about screen and the server splash.</p>
      </div>
      <div class="tab" id="node" data-src="/build/node_packages.html"></div>
      <div class="tab" id="artwork" data-src="/build/ARTWORK_LICENSE.html"></div>
      <div class="tab" id="sounds"  data-src="/build/SOUND_LICENSE.html"></div>
    """
    @$.find('.close').on 'click', => @close()
    @tabs = @$.find '.tab'
    @tabs.each (k,i) =>
      src = $(i).attr 'data-src'
      console.log src
      return unless src
      $.get src, (data,s,x) => $(i).html data
    btns = @$.find '.tabbtn'
    w = @
    btns.on 'click', -> w.activate @href
    @activate '#game'
  activate: (name) ->
    @tabs.css 'display', 'none'
    name = name.replace(/.*#/,'')
    console.log name
    $('#'+name).css 'display', 'block'

Kbd.macro 'about',   'aKeyH', 'Show about / license',  -> new Window.About
