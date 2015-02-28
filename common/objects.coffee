###

  * c) 2007-2015 Sebastian Glaser <anx@ulzq.de>
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

class Debris extends $obj
  @byId : {}
  constructor : (opts) ->
    super opts
    Debris.byId[@id] = @

class Cargo extends Debris
  item : null

class Asteroid extends Debris
  @byId : {}
  constructor : (opts={}) ->
    super opts
    if isClient
      @img = Sprite.imag.loading
      if Sprite.stel[name = @sprite] then @img = Sprite.stel[name]
      else Sprite.load 'stel', name, name, (img) => @img = img
    else
      @resource = []
      @x = -100000000 + floor random() * 200000000
      @y = -100000000 + floor random() * 200000000
      @mx = -5 + random() * 10
      @my = -5 + random() * 10
      @size = max 10, floor random() * 73
      id = @size - 10
      id = '0' + id if id < 10
      @sprite = 'asteroid-D' + id
    Asteroid.byId[@id] = @
    @state = 0
    State.change @, moving
    # @resource.push Elements.random().name for i in [0...@size]

stelSize = '000':150,'001':150,'002':150,'003':150,A00:450,A01:450,A02:450,A03:450,A04:450,'asteroid-D00':57,'asteroid-D01':65,'asteroid-D02':59,'asteroid-D03':59,'asteroid-D04':63,'asteroid-D05':64,'asteroid-D06':62,'asteroid-D07':56,'asteroid-D08':59,'asteroid-D09':55,'asteroid-D10':51,'asteroid-D11':57,'asteroid-D12':61,'asteroid-D13':71,'asteroid-D14':70,'asteroid-D15':55,'asteroid-D16':52,'asteroid-D17':30,'asteroid-D18':30,'asteroid-D19':30,'asteroid-D20':30,'asteroid-D21':57,'asteroid-D22':51,'asteroid-D23':51,'asteroid-D24':53,'asteroid-D25':39,'asteroid-D26':38,'asteroid-D27':41,'asteroid-D28':37,'asteroid-D29':37,'asteroid-D30':41,'asteroid-D31':39,'asteroid-D32':36,'asteroid-D33':39,'asteroid-D34':39,'asteroid-D35':41,'asteroid-D36':37,'asteroid-D37':40,'asteroid-D38':39,'asteroid-D39':42,'asteroid-D40':42,'asteroid-D41':40,'asteroid-D42':39,'asteroid-D43':41,'asteroid-D44':33,'asteroid-D45':39,'asteroid-D46':33,'asteroid-D47':39,'asteroid-D48':34,'asteroid-D49':34,'asteroid-D50':34,'asteroid-D51':29,'asteroid-D52':28,'asteroid-D53':34,'asteroid-D54':29,'asteroid-D55':33,'asteroid-D56':28,'asteroid-D57':31,'asteroid-D58':28,'asteroid-D59':33,'asteroid-D60':31,'asteroid-D61':28,'asteroid-D62':41,'asteroid-D63':38,blue01:676,blue02:800,blue04:800,C00:450,C01:450,D00:150,D01:150,D02:150,D03:95,D04:86,D05:86,D06:98,D07:86,G00:480,G01:450,G02:450,G03:450,green01:800,green02:880,H00:420,H01:450,H02:400,H03:500,H04:550,I00:1175,I01:811,I02:791,I03:900,I04:1000,I05:1500,I06:1440,I07:996,J00:600,J01:600,J02:600,J03:550,J04:600,J05:600,J06:600,J07:650,J08:550,J09:840,jumpbuoy:90,K00:450,K02:480,K03:480,K04:480,K05:512,L00:450,M00:480,M01:400,M02:450,M03:480,M04:480,M05:380,M06:480,M07:480,M08:480,M09:480,M10:600,M11:512,M12:512,M13:512,'moon-A00':122,'moon-A01':112,'moon-C00':50,'moon-C01':100,'moon-D00':60,'moon-D01':50,'moon-D02':110,'moon-G00':96,'moon-G01':87,'moon-H00':96,'moon-H01':84,'moon-H02':96,'moon-I00':160,'moon-I01':147,'moon-J00':120,'moon-J01':104,'moon-J02':124,'moon-K00':52,'moon-L00':89,'moon-M00':96,'moon-M01':96,'moon-M02':116,'moon-M03':64,'moon-M04':82,'moon-M05':96,'moon-M06':100,'moon-O00':118,'moon-O01':73,'moon-P00':96,'moon-P01':96,'moon-P02':84,'moon-P03':150,'moon-X00':150,nebula02:1024,nebula04:1024,nebula10:1024,nebula12:1024,nebula16:1024,nebula17:1024,nebula19:1024,nebula20:800,nebula21:1169,nebula22:1024,nebula23:1280,nebula24:1600,nebula25:1280,nebula26:1024,nebula27:1280,nebula28:1024,nebula29:1024,nebula30:1600,nebula31:1600,nebula32:1024,nebula33:1600,nebula34:1600,O00:458,O01:480,O02:480,O03:500,O04:400,O05:512,orange01:700,orange02:800,orange05:1000,P00:400,P01:300,P02:450,P03:500,P04:450,P05:512,redgiant01:1000,redgiant02:900,S00:480,S01:480,'station-agriculture':150,'station-battlestation':150,'station-commerce2':225,'station-commerce3':175,'station-commerce':150,'station-cylinder':150,'station-fleetbase2':225,'station-fleetbase3':200,'station-fleetbase':150,'station-powerplant':150,'station-shipyard2':225,'station-shipyard':150,'station-sphere':150,white01:800,white02:800,wrath:420,X00:480,X01:480,Y00:480,yellow01:800,yellow02:960,zalek_hq:256

class Stellar extends $obj
  @byId : {}
  constructor : (opts={}) ->
    super opts
    @size = stelSize[@sprite]
    @x = 0 if @state is fixed
    @y = 0
    @relto = $obj.byId[@relto]
    if isClient
      @img = Sprite.imag.loading
      name = @sprite
      if Sprite.stel[name] then @img = Sprite.stel[name]
      else Sprite.load 'stel', name, name, (img) =>
        @img = img
        Sprite.main.updateSprite 'stel', @
    Stellar.byId[@id] = @
    State.change @, @state

  toJSON : ->
    return id:@id,x:@x,y:@y,orbit:@orbit,sprite:@sprite,name:@name,state:@state,relto:@relto.id

$public Stellar, Debris, Cargo, Asteroid