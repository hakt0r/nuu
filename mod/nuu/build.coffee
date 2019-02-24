
module.exports.build = (c)-> depend(contrib,sources)( ->
  $s [
    mkdir       'build/imag'
    link        'mod/nuu/sprites/objects_nuu.json', 'build/objects_nuu.json'
    link        'mod/nuu/sprites/sprites_nuu.json', 'build/imag/sprites_nuu.json'
    link        'mod/nuu/client/gui.css',           'build/gui.css'
    linkFilesIn 'mod/nuu/artwork',                  'build/imag'
    convFilesIn 'mod/nuu/sprites/com',              'build/gfx'
    convFilesIn 'mod/nuu/sprites/gov',              'build/gfx'
    linkFlatten 'mod/nuu/sprites',                  'build/gfx'
    (c)-> c null, await iconsFrom 'mod/nuu/artwork/icon_2018.png', 'build/'
  ], c )
