global.marked = require 'marked'

markdown = (src,tgt)-> (c)->
  fs.readFile src, (error,data)->
    return c error if error
    txt = do data.toString
    txt = txt.replace ' , ', ', '
    txt = txt.replace ' ,',  ', '
    while m = txt.match /Author:([^,]+), /
      txt = txt.replace m[0], "**" + m[1].trim() + "**"
    while m = txt.match /License:([^\n]+)\n/
      txt = txt.replace m[0], " (***" + m[1].trim() + "***)\n"
    txt = txt.replace /\ \ \ \ \ \ \ \*\ \*\n/g, ''
    txt = txt.replace /,\ \ \(\*\*\*PD\)\*\*\*\)/g, ' (PD)'
    txt = txt.replace /\ \*\ \*\*/g, '## **'
    txt = txt.replace '## **Bobbens', '\n## **Bobbens'
    blurb = """
    ## Licenses
    These refer to the contributors of the [NAEV](http://blog.naev.org/) project.

    """
    o = []
    authorP = author = mode1  = mode2  = null
    lines  = txt.split('\n')
    txt = n while txt isnt n = txt.replace '\n\n','\n'
    for line,i in lines
      if line.match /\#/
        authorP = author = mode1  = mode2  = null
        author = line
      if line is '   * outfit'
        mode1 = 'outfit'
      else if line is '   * planet'
        mode1 = 'planet'
      else if line is '   * commodity'
        mode1 = 'commodity'
      else if line is '     * space'
        mode2 = 'space'
      else if line is '     * store'
        mode2 = 'store'
      else if line is '     * exterior'
        mode2 = 'exterior'
      else if line.match /png$/
        n = line.replace /.* /, ''
        p = ['build',mode1,mode2,n].join '/'
        continue unless fs.existsSync p
        o.push authorP = author unless authorP
        o.push '![' + n + '](' + p + ')'

    txt = o.join '\n'
    fs.writeFile tgt.replace('html','txt'), blurb + txt, ->
    fs.writeFile tgt, marked(blurb + txt), c
    null
  null

module.exports.build = (c) ->
  console.log 'losa222d'
  depend(dirs)( ->
    console.log 'losad'
    $s [
      fetch       'contrib/naev.zip', 'https://github.com/bobbens/naev/archive/master.zip'
      unzip       'contrib/naev.zip', 'contrib/naev-master'
      mkdir       'build/ship'
      markdown    'contrib/naev-master/dat/gfx/ARTWORK_LICENSE', 'build/ARTWORK_LICENSE.html'
      markdown    'contrib/naev-master/dat/snd/SOUND_LICENSE',   'build/SOUND_LICENSE.html'
      link        'contrib/naev-master/dat/gfx/spfx',            'build/spfx'
      linkDirsIn  'contrib/naev-master/dat/gfx/ship',            'build/ship'
      link        'contrib/naev-master/dat/gfx/outfit',          'build/outfit'
      link        'contrib/naev-master/dat/snd/sounds',          'build/sounds'
      linkFilesIn 'contrib/naev-master/dat/gfx/bkg',             'build/stel'
      linkFilesIn 'contrib/naev-master/dat/gfx/bkg/star',        'build/stel'
      linkFilesIn 'contrib/naev-master/dat/gfx/planet/space',    'build/stel'
      generate    'build/objects_naev.json',                      path.join __dirname, 'import.coffee'
    ], c )
