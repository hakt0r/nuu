
module.exports.build = (c)-> depend(contrib,sources)( ->
  $s [
    mkdir 'build'
  ], c )
