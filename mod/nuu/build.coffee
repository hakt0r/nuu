
module.exports.build = (c)-> depend(contrib,sources)( ->
  $s [
    mkdir       'build/imag'
    link        'mod/nuu/sprites/objects_nuu.json', 'build/objects_nuu.json'
    link        'mod/nuu/sprites/sprites_nuu.json', 'build/imag/sprites_nuu.json'
    link        'mod/nuu/client/gui.css',           'build/gui.css'
    linkFilesIn 'mod/nuu/artwork',                  'build/imag'
    linkFlatten 'mod/nuu/sprites',                  'build/gfx'
  ], c )
