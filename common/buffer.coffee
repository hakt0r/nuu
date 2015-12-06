###

  * c) 2007-2016 Sebastian Glaser <anx@ulzq.de>
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

readFLoatLE = (mLen, nBytes) -> (offset)->
  e = m = null; nBits = -7
  eLen = nBytes * 8 - mLen - 1
  eBias = ( eMax = (1 << eLen) - 1 ) >> 1
  i = nBytes + d = -1
  s = @[offset + i]
  i += d
  e = s & (1 << -nBits) - 1
  s >>= -nBits
  nBits += eLen
  while nBits > 0
    e = e * 256 + @[offset + i]
    i += d
    nBits -= 8
  m = e & (1 << -nBits) - 1
  e >>= -nBits
  nBits += mLen
  while nBits > 0
    m = m * 256 + @[offset + i]
    i += d
    nBits -= 8
  if e == 0 then e = 1 - eBias
  else if e == eMax
    return if m then NaN else ( if s then -1 else 1 ) * Infinity
  else
    m = m + 2 ** mLen
    e = e - eBias
  return ( if s then -1 else 1 ) * m * 2 ** ( e - mLen )

writeFloatLE = (mLen, nBytes)-> (value, offset)->
  e = m = c = null; i = 0; d = 1
  eLen = nBytes * 8 - mLen - 1
  eBias = ( eMax = (1 << eLen) - 1 ) >> 1
  rt = if mLen == 23 then 2 ** (-24) - 2 ** (-77) else 0
  s = if value < 0 or value == 0 and 1 / value < 0 then 1 else 0
  value = Math.abs value
  if isNaN(value) or value == Infinity
    m = if isNaN(value) then 1 else 0
    e = eMax
  else
    e = Math.floor Math.log(value) / Math.LN2
    ( e--; c *= 2 )     if value * (c = 2 ** (-e)) < 1
    value += if e + eBias >= 1 then rt / c else rt * 2 ** ( 1 - eBias )
    ( e++; c /= 2 )     if value * c >= 2
    if e + eBias >= eMax
      ( m = 0; e = eMax )
    else if e + eBias >= 1
      m = (value * c - 1) * 2 ** mLen
      e = e + eBias
    else
      m = value * 2 ** (eBias - 1) * 2 ** mLen
      e = 0
  while mLen >= 8
    @[offset + i] = m & 0xff
    i += d; m /= 256; mLen -= 8
  e = e << mLen | m
  eLen += mLen
  while eLen > 0
    @[offset + i] = e & 0xff
    i += d; e /= 256; eLen -= 8
  @[offset + i - d] |= s * 128
  return

Uint8Array::readUInt16LE  = (offset)-> @[offset] | ( @[offset + 1] << 8 )
Uint8Array::writeUInt16LE = (value,offset)-> @[offset] = (value & 0xff); @[offset + 1] = (value >>> 8)
Uint8Array::readUInt32LE  = (offset)-> ( (@[offset]) | (@[offset + 1] << 8) | (@[offset + 2] << 16) ) + ( @[offset + 3] * 0x1000000 )
Uint8Array::writeUInt32LE = (value,offset)-> @[offset + 3] = (value >>> 24); @[offset + 2] = (value >>> 16); @[offset + 1] = (value >>> 8); @[offset] = (value & 0xff)
Uint8Array::readFloatLE   = readFLoatLE  23,4
Uint8Array::writeFloatLE  = writeFloatLE 23,4
Uint8Array::readDoubleLE  = readFLoatLE  52,8
Uint8Array::writeDoubleLE = writeFloatLE 52,8
