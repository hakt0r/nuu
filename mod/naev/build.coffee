
module.exports = (c) -> depend(dirs)( ->
  $s [
    fetch       'contrib/naev.zip', 'https://github.com/bobbens/naev/archive/master.zip'
    unzip       'contrib/naev.zip', 'contrib/naev-master'
    mkdir       'build/ship'
    link        'contrib/naev-master/dat/gfx/ARTWORK_LICENSE', 'build/ARTWORK_LICENSE.txt'
    link        'contrib/naev-master/dat/snd/SOUND_LICENSE',   'build/SOUND_LICENSE.txt'
    link        'contrib/naev-master/dat/gfx/spfx',            'build/spfx'
    linkDirsIn  'contrib/naev-master/dat/gfx/ship',            'build/ship'
    link        'contrib/naev-master/dat/gfx/outfit',          'build/outfit'
    link        'contrib/naev-master/dat/snd/sounds',          'build/sounds'
    linkFilesIn 'contrib/naev-master/dat/gfx/bkg',             'build/stel'
    linkFilesIn 'contrib/naev-master/dat/gfx/bkg/star',        'build/stel'
    linkFilesIn 'contrib/naev-master/dat/gfx/planet/space',    'build/stel'
    generate    'build/objects_naev.json',                     path.join __dirname, 'import.coffee'
  ], c )
