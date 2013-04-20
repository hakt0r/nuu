###
  The ususal upfance of console.log
###

console.rlog   = console.log
console.rerror = console.error

console.error = (args...)->
  args.unshift '['+'nuu'.red.inverse+']'
  @rlog.apply console, args

console.log = (args...)->
  args.unshift '['+'nuu'.blue.inverse+']'
  @rlog.apply console, args

console.debug = (args...) -> # if argv.debug
  args.unshift '['+'nuu'.blue.inverse+']'
  @rlog.apply console, args 

console.dump = (msg='Error',error) ->
  @rlog.call console, '['+'nuu'.red.inverse+':'+msg.red.inverse+']', error.stack.white.bold
  process.exit 42
