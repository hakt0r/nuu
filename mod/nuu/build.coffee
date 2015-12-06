
module.exports = (c)-> depend(contrib,sources)( ->
  $s [
    mkdir 'build/imag'
    linkFilesIn 'client/gfx',   'build/imag'
    linkFilesIn 'mod/nuu/ship', 'build/imag'
    linkDirsIn  'mod/nuu/ship', 'build/ship'
  ], c )
