###

  * c) 2007-2018 Sebastian Glaser <anx@ulzq.de>
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
