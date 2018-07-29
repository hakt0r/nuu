
$static 'ab2str', (buf) ->
  String.fromCharCode.apply null, new Uint16Array(buf)

$static 'str2ab', (str) ->
  buf = new ArrayBuffer(str.length * 2) # 2 bytes for each char
  bufView = new Uint16Array(buf)
  i = 0
  strLen = str.length

  while i < strLen
    bufView[i] = str.charCodeAt(i)
    i++
  buf

Array.shuffle = (o) ->
  j = undefined
  x = undefined
  i = o.length
  while i
    j = Math.floor(Math.random() * i)
    x = o[--i]
    o[i] = o[j]
    o[j] = x
  o
