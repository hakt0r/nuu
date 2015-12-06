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

input2 = """
Actinium	0.0000000001
Aluminum	0.005
Americium	0.0000000001
Antimony	4.×10-8
Argon	0.02
Arsenic	8.×10-7
Astatine	0.0000000001
Barium	1.×10-6
Berkelium	0.0000000001
Beryllium	1.×10-7
Bismuth	7.×10-8
Bohrium	0.0000000001
Boron	1.×10-7
Bromine	7.×10-7
Cadmium	2.×10-7
Calcium	0.007
Californium	0.0000000001
Carbon	0.5
Cerium	1.×10-6
Cesium	8.×10-8
Chlorine	0.0001
Chromium	0.0015
Cobalt	0.0003
Copper	6.×10-6
Curium	0.0000000001
Darmstadtium	0.0000000001
Dubnium	0.0000000001
Dysprosium	2.×10-7
Einsteinium	0.0000000001
Erbium	2.×10-7
Europium	5.×10-8
Fermium	0.0000000001
Fluorine	0.00004
Francium	0.0000000001
Gadolinium	2.×10-7
Gallium	1.×10-6
Germanium	0.00002
Gold	6.×10-8
Hafnium	7.×10-8
Hassium	0.0000000001
Helium	23
Holmium	5.×10-8
Hydrogen	75
Indium	3.×10-8
Iodine	1.×10-7
Iridium	2.×10-7
Iron	0.11
Krypton	4.×10-6
Lanthanum	2.×10-7
Lawrencium	0.0000000001
Lead	1.×10-6
Lithium	6.×10-7
Lutetium	1.×10-8
Magnesium	0.06
Manganese	0.0008
Meitnerium	0.0000000001
Mendelevium	0.0000000001
Mercury	1.×10-7
Molybdenum	5.×10-7
Neodymium	1.×10-6
Neon	0.13
Neptunium	0.0000000001
Nickel	0.006
Niobium	2.×10-7
Nitrogen	0.1
Nobelium	0.0000000001
Osmium	3.×10-7
Oxygen	1
Palladium	2.×10-7
Phosphorus	0.0007
Platinum	5.×10-7
Plutonium	0.0000000001
Polonium	0.0000000001
Potassium	0.0003
Praseodymium	2.×10-7
Promethium	0.0000000001
Protactinium	0.0000000001
Radium	0.0000000001
Radon	0.0000000001
Rhenium	2.×10-8
Rhodium	6.×10-8
Roentgenium	0.0000000001
Rubidium	1.×10-6
Ruthenium	4.×10-7
Rutherfordium	0.0000000001
Samarium	5.×10-7
Scandium	3.×10-6
Seaborgium	0.0000000001
Selenium	3.×10-6
Silicon	0.07
Silver	6.×10-8
Sodium	0.002
Strontium	4.×10-6
Sulfur	0.05
Tantalum	8.×10-9
Technetium	0.0000000001
Tellurium	9.×10-7
Terbium	5.×10-8
Thallium	5.×10-8
Thorium	4.×10-8
Thulium	1.×10-8
Tin	4.×10-7
Titanium	0.0003
Tungsten	5.×10-8
Ununbium	0.0000000001
Ununhexium	0.0000000001
Ununoctium	0.0000000001
Ununpentium	0.0000000001
Ununquadium	0.0000000001
Ununseptium	0.0000000001
Ununtrium	0.0000000001
Uranium	2.×10-8
Vanadium	0.0001
Xenon	1.×10-6
Ytterbium	2.×10-7
Yttrium	7.×10-7
Zinc	0.00003
Zirconium	5.×10-6"""
input = """
Hydrogen	H(1)	1.007825	99.99	H(2)	2.014102	0.015
Helium	He(3)	3.016029	.00014	He(4)	4.002603	100.00
Lithium	Li(6)	6.015123	7.42	Li(7)	7.016005	92.58
Beryllium	Be(9)	9.012183	100.00
Boron	B(10)	10.012938	19.80	B(11)	11.009305	80.20
Carbon	C(12)	12.000000	98.90	C(13)	13.003355	1.10
Nitrogen	N(14)	14.003074	99.63	N(15)	15.000109	0.37
Oxygen	O(16)	15.994915	99.76	O(17)	16.999131	0.038	O(18)	17.999159	0.20
Fluorine	F(19)	18.998403	100.00
Neon	Ne(20)	19.992439	90.60	Ne(21)	20.993845	0.26	Ne(22)	21.991384	9.20
Sodium	Na(23)	22.989770	100.00
Magnesium	Mg(24)	23.985045	78.90	Mg(25)	24.985839	10.00	Mg(26)	25.982595	11.10
Aluminum	Al(27)	26.981541	100.00
Silicon	Si(28)	27.976928	92.23	Si(29)	28.976496	4.67	Si(30)	29.973772	3.10
Phosphorus	P(31)	30.973763	100.00
Sulfur	S(32)	31.972072	95.02	S(33)	32.971459	0.75	S(34)	33.967868	4.21
	S(36)	35.967079	0.020
Chlorine	Cl(35)	34.968853	75.77	Cl(37)	36.965903	24.23
Argon	Ar(36)	35.967546	0.34	Ar(38)	37.962732	0.063	Ar(40)	39.962383	99.60
Potassium	K(39)	38.963708	93.20	K(40)	39.963999	0.012	K(41)	40.961825	6.73
Calcium	Ca(40)	39.962591	96.95	Ca(42)	41.958622	0.65	Ca(43)	42.958770	0.14
	Ca(44)	43.955485	2.086	Ca(46)	45.953689	0.004	Ca(48)	47.952532	0.19
Scandium	Sc(45)	44.955914	100.00
Titanium	Ti(46)	45.952633	8.00	Ti(47)	46.951765	7.30	Ti(48)	47.947947	73.80
	Ti(49)	48.947871	5.50	Ti(50)	49.944786	5.40
Vanadium	V(50)	49.947161	0.25	V(51)	50.943963	99.75
Chromium	Cr(50)	49.946046	4.35	Cr(52)	51.940510	83.79	Cr(53)	52.940651	9.50
	Cr(54)	53.938882	2.36
Manganese	Mn(55)	54.938046	100.00
Iron	Fe(54)	53.939612	5.80	Fe(56)	55.934939	91.72	Fe(57)	56.935396	2.20
	Fe(58)	57.933278	0.28
Cobalt	Co(59)	58.933198	100.00
Nickel	Ni(58)	57.935347	68.27	Ni(60)	59.930789	26.10	Ni(61)	60.931059	1.13
	Ni(62)	61.928346	3.59	Ni(64)	63.927968	0.91
Copper	Cu(63)	62.929599	69.17	Cu(65)	64.927792	30.83
Zinc	Zn(64)	63.929145	48.60	Zn(66)	65.926035	27.90	Zn(67)	66.927129	4.10
	Zn(68)	67.924846	18.80	Zn(70)	69.925325	0.60
Gallium	Ga(69)	68.925581	60.10	Ga(71)	70.924701	39.90
Germanium	Ge(70)	69.924250	20.50	Ge(72)	71.922080	27.40	Ge(73)	72.923464	7.80
	Ge(74)	73.921179	36.50	Ge(76)	75.921403	7.80
Arsenic	As(75)	74.921596	100.00
Selenium	Se(74)	73.922477	0.90	Se(76)	75.919207	9.00	Se(77)	76.919908	7.60
	Se(78)	77.917304	23.50	Se(80)	79.916521	49.60	Se(82)	81.916709	9.40
Bromine	Br(79)	78.918336	50.69	Br(81)	80.916290	49.31
Krypton	Kr(78)	77.920397	0.35	Kr(80)	79.916375	2.25	Kr(82)	81.913483	11.60
	Kr(83)	82.914134	11.50	Kr(84)	83.911506	57.00	Kr(86)	85.910614	17.30
Rubidium	Rb(85)	84.911800	72.17	Rb(87)	86.909184	27.84
Strontium	Sr(84)	83.913428	0.56	Sr(86)	85.909273	9.86	Sr(87)	86.908902	7.00
	Sr(88)	87.905625	82.58
Yttrium	Y(89)	88.905856	100.00
Zirconium	Zr(90)	89.904708	51.45	Zr(91)	90.905644	11.27	Zr(92)	91.905039	17.17
	Zr(94)	93.906319	17.33	Zr(96)	95.908272	2.78
	Niobium	Nb(93)	92.906378	100.00
Molybdenum	Mo(92)	91.906809	14.84	Mo(94)	93.905086	9.25	Mo(95)	94.905838	15.92
	Mo(96)	95.904676	16.68	Mo(97)	96.906018	9.55	Mo(98)	97.905405	24.13
	Mo(100)	99.907473	9.63
Ruthenium	Ru(96)	95.907596	5.52	Ru(98)	97.905287	1.88	Ru(99)	98.905937	12.70
	Ru(100)	99.904218	12.60	Ru(101)	100.905581	17.00	Ru(102)	101.90434	31.60
	Ru(104)	103.905422	18.70
Rhodium	Rh(103)	102.905503	100.00
Palladium	Pd(102)	101.905609	1.02	Pd(104)	103.904026	11.14	Pd(105)	104.905075	22.33
	Pd(106)	105.903475	27.33	Pd(108)	107.903894	26.46	Pd(110)	109.905169	11.72
Silver	Ag(107)	106.905095	51.84	Ag(109)	108.904754	48.16
Cadmium	Cd(106)	105.906461	1.25	Cd(108)	107.904186	0.89	Cd(110)	109.903007	12.49	Cd(111)	110.904182	12.80
	Cd(112)	111.902761	24.13	Cd(113)	112.904401	12.22	Cd(114)	113.903361	28.73
	Cd(116)	115.904758	7.49
Indium	In(113)	112.904056	4.30	In(115)	114.903875	95.70
Tin	Sn(112)	111.904826	0.97	Sn(114)	113.902784	0.65	Sn(115)	114.903348	0.36
	Sn(116)	115.901744	14.70	Sn(117)	116.902954	7.70	Sn(118)	117.901607	24.30
	Sn(119)	118.903310	8.60	Sn(120)	119.902199	32.40	Sn(122)	121.903440	4.60
	Sn(124)	123.905271	5.60
Antimony	Sb(121)	120.903824	57.30	Sb(123)	122.904222	42.70
Tellurium	Te(120)	119.904021	0.096	Te(122)	121.903055	2.60	Te(123)	122.904278	0.91
	Te(124)	123.902825	4.82	Te(125)	124.904435	7.14	Te(126)	125.903310	18.95
	Te(128)	127.904464	31.69	Te(130)	129.906229	33.80
Iodine	I(127)	126.904477	100.00
Xenon	Xe(124)	123.905894	0.10	X(126)	125.904281	0.09
	Xe(128)	127.903531	1.91	Xe(129)	128.904780	26.40	Xe(130)	129.903510	4.10
	Xe(131)	130.905076	21.20	Xe(132)	131.904148	26.90	Xe(134)	133.905395	10.40
	Xe(136)	135.907219	8.90
Cesium	Cs(133)	132.905433	100.00
Barium	Ba(130)	129.906277	0.11	Ba(132)	131.905042	0.10	Ba(134)	133.904490	2.42
	Ba(135)	134.905668	6.59	Ba(136)	135.904556	7.85	Ba(137)	136.905816	11.23
	Ba(138)	137.905236	71.70
Lanthanum	La(138)	137.907114	0.09	La(139)	138.906355	99.91
Cerium	Ce(136)	135.907140	0.19	Ce(138)	137.905996	0.25	Ce(140)	139.905442	88.48
	Ce(142)	141.909249	11.08
Praseodymium	Pr(141)	140.907657	100.00
Neodymium	Nd(142)	141.907731	27.13	Nd(143)	142.909823	12.18	Nd(144)	143.910096	23.80
	Nd(145)	144.912582	8.30	Nd(146)	145.913126	17.19	Nd(148)	147.916901	5.76
	Nd(150)	149.920900	5.64
Samarium	Sm(144)	143.912009	3.10	Sm(147)	146.914907	15.00	Sm(148)	147.914832	11.30
	Sm(149)	148.917193	13.80	Sm(150)	149.917285	7.40	Sm(152)	151.919741	26.70
	Sm(154)	153.922218	22.70
Europium	Eu(151)	150.919860	47.80	Eu(153)	152.921243	52.20
Gadolinium	Gd(152)	151.919803	0.200	Gd(154)	153.920876	2.18	Gd(155)	154.822629	14.80
	Gd(156)	155.922130	20.47	Gd(157)	156.923967	15.65	Gd(158)	157.924111	24.84
	Gd(160)	159.927061	21.86
Terbium	Tb(159)	158.925350	100.00
Dysprosium	Dy(156)	155.924287	0.060	Dy(158)	157.924412	0.10	Dy(160)	159.925203	2.34
	Dy(161)	160.926939	18.90	Dy(162)	161.926805	25.50	Dy(163)	162.928737	24.90
	Dy(164)	163.929183	28.20
Holmium	Ho(165)	164.930332	100.00
Erbium	Er(162)	161.928787	0.14	Er(164)	163.929211	1.61	Er(166)	165.930305	33.60
	Er(167)	166.932061	22.95	Er(168)	167.932383	26.80	Er(170)	169.935476	14.90
Thulium	Tm(169)	168.934225	100.00
Ytterbium	Yb(168)	167.933908	0.13	Yb(170)	169.934774	3.05	Yb(171)	170.936338	14.30
	Yb(172)	171.936393	21.90	Yb(173)	172.938222	16.12	Yb(174)	173.938873	31.80
	Yb(176)	175.942576	12.70
Lutetium	Lu(175)	174.940785	97.40	Lu(176)	175.942694	2.60
Hafnium	Hf(174)	173.940065	0.16	Hf(176)	175.941420	5.20	Hf(177)	176.943233	18.60
	Hf(178)	177.943710	27.10	Hf(179)	178.945827	13.74	Hf(180)	179.946561	35.20
Tantalum	Ta(180)	179.947489	0.012	Ta(181)	180.948014	99.99
Tungsten	W(180)	179.946727	0.13	W(182)	181.948225	26.30	W(183)	182.950245	14.30
	W(184)	183.950953	30.67	W(186)	185.954377	28.60
Rhenium	Re(185)	184.952977	37.40	Re(187)	186.955765	62.60
Osmium	Os(184)	183.952514	0.02	Os(186)	185.953852	1.58	Os(187)	186.955762	1.60
	Os(188)	187.955850	13.30	Os(189)	188.958156	16.10	Os(190)	189.958455	26.40
	Os(192)	191.961487	41.00
Iridium	Ir(191)	190.960603	37.30	Ir(193)	192.962942	62.70
Platinum	Pt(190)	189.959937	0.010	Pt(192)	191.961049	0.79	Pt(194)	193.962679	32.90
	Pt(195)	194.964785	33.80	Pt(196)	195.964947	25.30	Pt(198)	197.967879	7.20
Gold	Au(197)	196.966560	100.00
Mercury	Hg(196)	195.965812	0.15	Hg(198)	197.966760	10.10	Hg(199)	198.968269	17.00
	Hg(200)	199.968316	23.10	Hg(201)	200.970293	13.20	Hg(202)	201.970632	29.65
	Hg(204)	203.973481	6.80
Thallium	Tl(203)	202.972336	29.52	Tl(205)	204.974410	70.48
Lead	Pb(204)	203.973037	1.40	Pb(206)	205.974455	24.10	Pb(207)	206.975885	22.10
	Pb(208)	207.976641	52.40
Bismuth	Bi(209)	208.980388	100.00
Thorium	Th(232)	232.038054	100.00
Uranium	U(234)	234.040947	0.006	U(235)	235.043925	0.72	U(238)	238.050786	99.27
"""
el = {}
for line in input.split('\n')
	# line = line.trim()
	m = line.split('\t')
	if (v = m.shift()) isnt ''
 		el[v] = e = isotopes : {}
	while v = m.shift()
		e.isotopes[v] = mass : m.shift(), isobundance : m.shift()

for line in input2.split('\n')
	m = line.split('\t')
	if el[m[0]]
		if m[1].match /×/
			t = m[1].split '\.×10-'
			s = ''; s += '0' for cc in [1...t[1]]
			el[m[0]].abundance = s
		else el[m[0]].abundance = parseFloat m[1]
	else el[m[0]] = synth : yes, abundance : 0.0

util = require 'util'
console.log util.inspect el

require('fs').writeFileSync 'elements.json', JSON.stringify el
