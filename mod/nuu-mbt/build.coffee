
module.exports.stages =
  sysgen: (c)-> depend(assets)(-> exec("coffee mod/nuu-mbt/sysgen.coffee")(c))
