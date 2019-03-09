###
# ███████ ████████  █████  ██████   ██████  ███████ ███    ██
# ██         ██    ██   ██ ██   ██ ██       ██      ████   ██
# ███████    ██    ███████ ██████  ██   ███ █████   ██ ██  ██
#      ██    ██    ██   ██ ██   ██ ██    ██ ██      ██  ██ ██
# ███████    ██    ██   ██ ██   ██  ██████  ███████ ██   ████
  Essentially a port of stargen.c
  Legendary code below :)
###

class Random
  nextDouble:-> Math.random()

class Deterministic
  constructor:->
    @callCount = 0
    @value = 0.0
    @increment = Math.PI
  nextDouble:->
    ++@callCount
    @value += @increment
    @value = @value = MATH.floor @value if @value > 1.0
    @value

MATH = new class MathUtils
  @expose: [ 'E','LN10','LN2','LOG10E','LOG2E','PI','SQRT1_2','SQRT2','abs','acos','acosh','asin','asinh','atan','atan2','atanh','cbrt','ceil','clz32','cos','cosh','exp','expm1','floor','fround','hypot','imul','log','log10','log1p','log2','max','min','pow','random','round','sign','sin','sinh','sqrt','tan','tanh','trunc','E','LN10','LN2','LOG10E','LOG2E','PI','SQRT1_2','SQRT2','abs','acos','acosh','asin','asinh','atan','atan2','atanh','cbrt','ceil','clz32','cos','cosh','exp','expm1','floor','fround','hypot','imul','log','log10','log1p','log2','max','min','pow','random','round','sign','sin','sinh','sqrt','tan','tanh','trunc' ]
  constructor:(random)->
    @[k] = Math[k] for k in MathUtils.expose
    @random = random || new Random
  next_double:-> @random.nextDouble()
  next_float:-> @random.nextDouble()
  next_int:(limit)-> @random.nextInt limit
  randomNumber:(inner, outer)-> @random.nextDouble() * ( outer - inner ) + inner
  about:(value, variation)-> value + value * @randomNumber -variation, variation
  randomEccentricity:-> Math.min .99, 1.0 - Math.pow @randomNumber(0.0, 1.0), Constants.ECCENTRICITY_COEFF
  pow2:(val)-> val * val
  pow3:(val)-> val * val * val
  pow4:(val)-> val * val * val * val
  pow1_4:(val)-> Math.sqrt Math.sqrt val
  pow1_3:(val)-> Math.pow val, 1.0 / 3.0

#  ██████  ██████  ███    ██ ███████ ████████  █████  ███    ██ ████████ ███████
# ██      ██    ██ ████   ██ ██         ██    ██   ██ ████   ██    ██    ██
# ██      ██    ██ ██ ██  ██ ███████    ██    ███████ ██ ██  ██    ██    ███████
# ██      ██    ██ ██  ██ ██      ██    ██    ██   ██ ██  ██ ██    ██         ██
#  ██████  ██████  ██   ████ ███████    ██    ██   ██ ██   ████    ██    ███████

Constants = verbosity: 0x0

Constants.breathability_phrase = [ "none", "breathable", "unbreathable", "poisonous" ]

Constants.RADIANS_PER_ROTATION         = 2.0 * MATH.PI
Constants.CHANGE_IN_EARTH_ANG_VEL      = -1.3e-15

Constants.ECCENTRICITY_COEFF           = 0.077 # Eccentricity used. Dole's was 0.077
Constants.PROTOPLANET_MASS             = 1.0e-15 # Protoplanet mas in units of solar masses
Constants.SOLAR_MASS_IN_GRAMS          = 1.989e33 # Mass of Sun in grams
Constants.SOLAR_MASS_IN_KILOGRAMS      = 1.989e30 # Mass of Sun in units of kilograms
Constants.EARTH_MASS_IN_GRAMS          = 5.977e27 # Mass of Earth in grams
Constants.EARTH_RADIUS                 = 6.378e8 # Earth radius in centimeters
Constants.EARTH_DENSITY                = 5.52 # Earth density in grams per cubic centimetre
Constants.KM_EARTH_RADIUS              = 6378.0 # Earth radius in kilometres
Constants.EARTH_ACCELERATION           = 980.7 # Earth acceleration in units of centimetres per second squared
Constants.EARTH_AXIAL_TILT             = 23.4 # The axial tilt of the Earth in degrees
Constants.EARTH_EXOSPHERE_TEMP         = 1273.0 # Exospheric temperature of Earth in degrees Kelvin
Constants.SUN_MASS_IN_EARTH_MASSES     = 332775.64 # The mass of the Sun as a multiple of Earth masses
Constants.ASTEROID_MASS_LIMIT          = 0.001 # The size limit for asteroids in terms of Earth masses
Constants.EARTH_EFFECTIVE_TEMP         = 250.0 # Earth temperature in units of degrees Kelvin - was 255;
Constants.CLOUD_COVERAGE_FACTOR        = 1.839e-8 # Factor for cloud coverage in units of square kilometres per kilogram
Constants.EARTH_WATER_MASS_PER_AREA    = 3.83e15 # Mass of water for Earth for an area. In units of grams per square kilometer
Constants.EARTH_SURF_PRES_IN_MILLIBARS = 1013.25 # Surface atomspheric pressure of Earth in millibars
Constants.EARTH_SURF_PRES_IN_MMHG      = 760.0 # Surface atomspheric pressure of Earth in millimetres of mercury (Dole p. 15)
Constants.EARTH_SURF_PRES_IN_PSI       = 14.696 # Surface atomspheric pressure of Earth in pounds per square inch
Constants.EARTH_CONVECTION_FACTOR      = 0.43 # Earth convection factor from Hart, eq.20
Constants.FREEZING_POINT_OF_WATER      = 273.15 # Freezing point of water in units of degrees Kelvin
Constants.EARTH_AVERAGE_CELSIUS        = 14.0 # Average Earth Temperature in degrees Celsius
Constants.DAYS_IN_A_YEAR               = 365.256 # The number of days in an Earth year
Constants.GAS_RETENTION_THRESHOLD      = 6.0 # The retention threshold for gas as a ratio of esc vel to Constants.RMS vel
Constants.ICE_ALBEDO                   = 0.7 # The albedo value used for ice
Constants.CLOUD_ALBEDO                 = 0.52 # The albedo value used for cloud
Constants.GAS_GIANT_ALBEDO             = 0.5 # The albedo value used for a gas giant
Constants.AIRLESS_ICE_ALBEDO           = 0.5 # The albedo value used for an airless ice world
Constants.EARTH_ALBEDO                 = 0.3 # The albedo value used for Earth (was .33 for a while)
Constants.GREENHOUSE_TRIGGER_ALBEDO    = 0.2 # The albedo value used for greenhouse effect calculations
Constants.ROCKY_ALBEDO                 = 0.15 # The albedo value used for a rocky planet
Constants.ROCKY_AIRLESS_ALBEDO         = 0.07 # The albedo value used for a rocky airless planet
Constants.WATER_ALBEDO                 = 0.04 # The albedo value used for water
Constants.SECONDS_PER_HOUR             = 3600.0 # The number of seconds in an hour
Constants.CM_PER_AU                    = 1.495978707e13 # The number of centimetres in an astronomical unit
Constants.CM_PER_KM                    = 100000.0 # The number of centimetres in a kilometre
Constants.CM_PER_METER                 = 100.0 # The number of centimetres in a meter
Constants.MILLIBARS_PER_BAR            = 1000.0 # The number of millibars in a bar
Constants.GRAV_CONSTANT                = 6.672e-8 # The gravitational constant in units of dyne cm2/gram2
Constants.MOLAR_GAS_CONST              = 8314.41 # The molar gas constant in units of g*m2/=sec2*K*mol;
Constants.K                            = 50.0 # A constant representing the gas/dust ratio
Constants.B                            = 1.2e-5 # Constant used in Crit_mass calc
Constants.DUST_DENSITY_COEFF           = 0.002 # Coefficient of dust density (A in Dole's paper)
Constants.ALPHA                        = 5.0 # Constant used in density calcs
Constants.N                            = 3.0 # Constant used in density calcs
Constants.J                            = 1.46e-19 # Constant used in density calcs
Constants.INCREDIBLY_LARGE_NUMBER      = 9.9999e37 # Constant used in day-length calcs =cm2/sec2 g;
Constants.ATOMIC_HYDROGEN              = 1.0 # Atomic weight of hydrogen atom
Constants.MOL_HYDROGEN                 = 2.0 # Atomic weight of hydrogen molecule
Constants.HELIUM                       = 4.0 # Atomic weight of helium
Constants.ATOMIC_NITROGEN              = 14.0 # Atomic weight of nitrogen
Constants.ATOMIC_OXYGEN                = 16.0 # Atomic weight of oxygen
Constants.METHANE                      = 16.0 # Atomic weight of methane
Constants.AMMONIA                      = 17.0 # Atomic weight of ammonia
Constants.WATER_VAPOR                  = 18.0 # Atomic weight of water vapour
Constants.NEON                         = 20.2 # Atomic weight of neon
Constants.MOL_NITROGEN                 = 28.0 # Atomic weight of nitrogen molecule
Constants.CARBON_MONOXIDE              = 28.0 # Atomic weight of carbond monoxide
Constants.NITRIC_OXIDE                 = 30.0 # Atomic weight of nitric oxide
Constants.MOL_OXYGEN                   = 32.0 # Atomic weight of oxygen molecule
Constants.HYDROGEN_SULPHIDE            = 34.1 # Atomic weight of hydrogen sulphide
Constants.ARGON                        = 39.9 # Atomic weight of argon
Constants.CARBON_DIOXIDE               = 44.0 # Atomic weight of carbon dioxide
Constants.NITROUS_OXIDE                = 44.0 # Atomic weight of nitrous oxide
Constants.NITROGEN_DIOXIDE             = 46.0 # Atomic weight of nitrogen dioxide
Constants.OZONE                        = 48.0 # Atomic weight of ozone
Constants.SULPH_DIOXIDE                = 64.1 # Atomic weight of sulphur dioxide
Constants.SULPH_TRIOXIDE               = 80.1 # Atomic weight of sulphur trioxide
Constants.KRYPTON                      = 83.8 # Atomic weight of kyrypton
Constants.XENON                        = 131.3 # Atomic weight of xenon
Constants.AN_H                         = 1 # Atomic number of hydrogen
Constants.AN_HE                        = 2 # Atomic number of helium
Constants.AN_N                         = 7 # Atomic number of nitrogen
Constants.AN_O                         = 8 # Atomic number of oxygen
Constants.AN_F                         = 9 # Atomic number of fluorine
Constants.AN_NE                        = 10 # Atomic number of neon
Constants.AN_P                         = 15 # Atomic number of phosphorus
Constants.AN_CL                        = 17 # Atomic number of chlorine
Constants.AN_AR                        = 18 # Atomic number of argon
Constants.AN_BR                        = 35 # Atomic number of bromine
Constants.AN_KR                        = 36 # Atomic number of krypton
Constants.AN_I                         = 53 # Atomic number of iodine
Constants.AN_XE                        = 54 # Atomic number of xenon
Constants.AN_HG                        = 80 # Atomic number of mercury
Constants.AN_AT                        = 85 # Atomic number of astatine
Constants.AN_RN                        = 86 # Atomic number of radon
Constants.AN_FR                        = 87 # Atomic number of francium
Constants.AN_NH3                       = 900 # Atomic 'number' of nh3
Constants.AN_H2O                       = 901 # Atomic 'number' of h20
Constants.AN_CO2                       = 902 # Atomic 'number' of c02
Constants.AN_O3                        = 903 # Atomic 'number' of ozone
Constants.AN_CH4                       = 904 # Atomic 'number' of methan3
Constants.AN_CH3CH2OH                  = 905 # Atomic 'number' of ch3ch2oh
Constants.A1_20                        = 6.485e12 # Constant used in kothari_radius calculation
Constants.A2_20                        = 4.0032e-8 # Constant used in kothari_radius calculation
Constants.BETA_20                      = 5.71e12 # Constant used in kothari_radius calculation
Constants.JIMS_FUDGE                   = 1.004 # Correction factor to make the atmospheric calculation match the result for Earth
Constants.Q1_36                        = 1.258e19 # Constant used in cloud_fraction calculations in grams
Constants.Q2_36                        = 0.0698 # Constant used in cloud_fraction calculations in 1/Kelvin

Constants.MMHG_TO_MILLIBARS            = Constants.EARTH_SURF_PRES_IN_MILLIBARS / Constants.EARTH_SURF_PRES_IN_MMHG
Constants.PSI_TO_MILLIBARS             = Constants.EARTH_SURF_PRES_IN_MILLIBARS / Constants.EARTH_SURF_PRES_IN_PSI
Constants.H20_ASSUMED_PRESSURE         = 47.0 * Constants.MMHG_TO_MILLIBARS
Constants.MIN_O2_IPP                   = 72.0 * Constants.MMHG_TO_MILLIBARS
Constants.MAX_O2_IPP                   = 400.0 * Constants.MMHG_TO_MILLIBARS
Constants.MAX_HE_IPP                   = 61000.0 * Constants.MMHG_TO_MILLIBARS
Constants.MAX_NE_IPP                   = 3900.0 * Constants.MMHG_TO_MILLIBARS
Constants.MAX_N2_IPP                   = 2330.0 * Constants.MMHG_TO_MILLIBARS
Constants.MAX_AR_IPP                   = 1220.0 * Constants.MMHG_TO_MILLIBARS
Constants.MAX_KR_IPP                   = 350.0 * Constants.MMHG_TO_MILLIBARS
Constants.MAX_XE_IPP                   = 160.0 * Constants.MMHG_TO_MILLIBARS
Constants.MAX_CO2_IPP                  = 7.0 * Constants.MMHG_TO_MILLIBARS
Constants.MAX_HABITABLE_PRESSURE       = 118 * Constants.PSI_TO_MILLIBARS
Constants.PPM_PRSSURE                  = Constants.EARTH_SURF_PRES_IN_MILLIBARS / 1000000.0
Constants.MAX_F_IPP                    = 0.1 * Constants.PPM_PRSSURE
Constants.MAX_CL_IPP                   = 1.0 * Constants.PPM_PRSSURE
Constants.MAX_NH3_IPP                  = 100.0 * Constants.PPM_PRSSURE
Constants.MAX_O3_IPP                   = 0.1 * Constants.PPM_PRSSURE
Constants.MAX_CH4_IPP                  = 50000.0 * Constants.PPM_PRSSURE
Constants.EARTH_AVERAGE_KELVIN         = Constants.EARTH_AVERAGE_CELSIUS + Constants.FREEZING_POINT_OF_WATER
Constants.KM_PER_AU                    = Constants.CM_PER_AU / Constants.CM_PER_KM

ChemTable = gases: [
  { num: Constants.AN_H,   symbol:   "H", name: "Hydrogen",      weight:   1.0079, melt:  14.06, boil:  20.40, density: 8.99e-05,  abunde: 0.00125893,  abunds: 27925.4,     reactivity: 1,  ipp:  0.0 }
  { num: Constants.AN_HE,  symbol:  "He", name: "Helium",        weight:   4.0026, melt:   3.46, boil:   4.20, density: 0.0001787, abunde: 7.94328e-09, abunds: 2722.7,      reactivity: 0,  ipp:  Constants.MAX_HE_IPP }
  { num: Constants.AN_N,   symbol:   "N", name: "Nitrogen",      weight:  14.0067, melt:  63.34, boil:  77.40, density: 0.0012506, abunde: 1.99526e-05, abunds: 3.13329,     reactivity: 0,  ipp:  Constants.MAX_N2_IPP }
  { num: Constants.AN_O,   symbol:   "O", name: "Oxygen",        weight:  15.9994, melt:  54.80, boil:  90.20, density: 0.001429,  abunde: 0.501187,    abunds: 23.8232,     reactivity: 10, ipp:  Constants.MAX_O2_IPP }
  { num: Constants.AN_NE,  symbol:  "Ne", name: "Neon",          weight:  20.1700, melt:  24.53, boil:  27.10, density: 0.0009,    abunde: 5.01187e-09, abunds: 3.4435e-5,   reactivity: 0,  ipp:  Constants.MAX_NE_IPP }
  { num: Constants.AN_AR,  symbol:  "Ar", name: "Argon",         weight:  39.9480, melt:  84.00, boil:  87.30, density: 0.0017824, abunde: 3.16228e-06, abunds: 0.100925,    reactivity: 0,  ipp:  Constants.MAX_AR_IPP }
  { num: Constants.AN_KR,  symbol:  "Kr", name: "Krypton",       weight:  83.8000, melt: 116.60, boil: 119.70, density: 0.003708,  abunde: 1e-10,       abunds: 4.4978e-05,  reactivity: 0,  ipp:  Constants.MAX_KR_IPP }
  { num: Constants.AN_XE,  symbol:  "Xe", name: "Xenon",         weight: 131.3000, melt: 161.30, boil: 165.00, density: 0.00588,   abunde: 3.16228e-11, abunds: 4.69894e-06, reactivity: 0,  ipp:  Constants.MAX_XE_IPP }
  { num: Constants.AN_NH3, symbol: "NH3", name: "Ammonia",       weight:  17.0000, melt: 195.46, boil: 239.66, density: 0.001,     abunde: 0.002,       abunds: 0.0001,      reactivity: 1,  ipp:  Constants.MAX_NH3_IPP }
  { num: Constants.AN_H2O, symbol: "H2O", name: "Water",         weight:  18.0000, melt: 273.16, boil: 373.16, density: 1.000,     abunde: 0.03,        abunds: 0.001,       reactivity: 0,  ipp:  0.0 }
  { num: Constants.AN_CO2, symbol: "CO2", name: "CarbonDioxide", weight:  44.0000, melt: 194.66, boil: 194.66, density: 0.001,     abunde: 0.01,        abunds: 0.0005,      reactivity: 0,  ipp:  Constants.MAX_CO2_IPP }
  { num: Constants.AN_O3,  symbol:  "O3", name: "Ozone",         weight:  48.0000, melt:  80.16, boil: 161.16, density: 0.001,     abunde: 0.001,       abunds: 0.000001,    reactivity: 2,  ipp:  Constants.MAX_O3_IPP }
  { num: Constants.AN_CH4, symbol: "CH4", name: "Methane",       weight:  16.0000, melt:  90.16, boil: 109.16, density: 0.010,     abunde: 0.005,       abunds: 0.0001,      reactivity: 1,  ipp:  Constants.MAX_CH4_IPP }
]

max_gas = ChemTable.gases.length

Starsystem = stelClasses :
  O: mass: 1500, color:"blue"
  B: mass: 16,   color:"blue white"
  A: mass: 2.1,  color:"white"
  F: mass: 1.4,  color:"yellow white"
  G: mass: 1.04, color:"yellow"
  K: mass: 0.8,  color:"orange"
  M: mass: 0.45, color:"red"

# ██████  ██    ██ ███████ ████████  █████   ██████  ██████ ██████  ███████ ████████ ███████
# ██   ██ ██    ██ ██         ██    ██   ██ ██      ██      ██   ██ ██         ██    ██
# ██   ██ ██    ██ ███████    ██    ███████ ██      ██      ██████  █████      ██    █████
# ██   ██ ██    ██      ██    ██    ██   ██ ██      ██      ██   ██ ██         ██    ██
# ██████   ██████  ███████    ██    ██   ██  ██████  ██████ ██   ██ ███████    ██    ███████

class DustHist

class DustRecord
  constructor:(@inner_edge,@outer_edge,@dust_present,@gas_present,@next_band)->

class DustAccrete
  dust_left:true
  cloud_eccentricity:0.2
  firstChild:null
  r_inner:null
  r_outer:null
  reduced_mass:null
  dust_density:null
  constructor: (@sun, @inner_limit_of_dust, @outer_limit_of_dust)->
    @dust_head = new DustRecord
    @hist_head = hist = new DustHist
    hist.dusts = @dust_head
    hist.planets = @firstChild
    hist.next = @hist_head
    @dust_head.next_band = null
    @dust_head.outer_edge = @outer_limit_of_dust
    @dust_head.inner_edge = @inner_limit_of_dust
    @dust_head.dust_present = true
    @dust_head.gas_present = true
  inner_effect_limit: (a, e, mass)-> a * (1.0 - e) * (1.0 - mass) / (1.0 + @cloud_eccentricity)
  outer_effect_limit: (a, e, mass)-> a * (1.0 + e) * (1.0 + mass) / (1.0 - @cloud_eccentricity)

DustAccrete::dust_available = (inside_range, outside_range)->
  current_dust_band = @dust_head
  while ((current_dust_band isnt null) && (current_dust_band.outer_edge < inside_range))
    current_dust_band = current_dust_band.next_band
  if current_dust_band is null
    dust_here = false
  else dust_here = current_dust_band.dust_present
  while ((current_dust_band isnt null) && (current_dust_band.inner_edge < outside_range))
    dust_here = dust_here || current_dust_band.dust_present
    current_dust_band = current_dust_band.next_band
  dust_here

DustAccrete::update_dust_lanes = (min, max, mass,crit_mass, body_inner_bound, body_outer_bound)->
  @dust_left = false
  gas = not mass > crit_mass
  node1 = @dust_head
  while node1 isnt null
    if (node1.inner_edge < min) && (node1.outer_edge > max)
      node2 = new DustRecord
      node2.inner_edge = min
      node2.outer_edge = max
      if node1.gas_present is true then node2.gas_present = gas else node2.gas_present = false
      node2.dust_present = false
      node3 = new DustRecord
      node3.inner_edge = max
      node3.outer_edge = node1.outer_edge
      node3.gas_present = node1.gas_present
      node3.dust_present = node1.dust_present
      node3.next_band = node1.next_band
      node1.next_band = node2
      node2.next_band = node3
      node1.outer_edge = min
      node1 = node3.next_band
    else if ((node1.inner_edge < max) && (node1.outer_edge > max))
      node2 = new DustRecord
      node2.next_band = node1.next_band
      node2.dust_present = node1.dust_present
      node2.gas_present = node1.gas_present
      node2.outer_edge = node1.outer_edge
      node2.inner_edge = max
      node1.next_band = node2
      node1.outer_edge = max
      if node1.gas_present is true then node1.gas_present = gas else node1.gas_present = false
      node1.dust_present = false
      node1 = node2.next_band
    else if (node1.inner_edge < min) && (node1.outer_edge > min)
      node2 = new DustRecord
      node2.next_band = node1.next_band
      node2.dust_present = false
      if node1.gas_present is true then node2.gas_present = gas else node2.gas_present = false
      node2.outer_edge = node1.outer_edge
      node2.inner_edge = min
      node1.next_band = node2
      node1.outer_edge = min
      node1 = node2.next_band
    else if (node1.inner_edge >= min) && (node1.outer_edge <= max)
      node1.gas_present = gas if node1.gas_present is true
      node1.dust_present = false
      node1 = node1.next_band
    else if (node1.outer_edge < min) || (node1.inner_edge > max)
      node1 = node1.next_band
  node1 = @dust_head
  while node1 isnt null
    @dust_left = true if (node1.dust_present) && (((node1.outer_edge >= body_inner_bound) && (node1.inner_edge <= body_outer_bound)))
    node2 = node1.next_band
    if node2 isnt null
      if (node1.dust_present is node2.dust_present) && (node1.gas_present is node2.gas_present)
        node1.outer_edge = node2.outer_edge
        node1.next_band = node2.next_band
    node1 = node1.next_band

DustAccrete::accrete_dust = (seed_mass, new_dust, new_gas, a, e, crit_mass, body_inner_bound, body_outer_bound)->
  new_mass = seed_mass
  loop
    temp_mass = new_mass
    [ new_mass, new_dust, new_gas ] = @collect_dust new_mass, new_dust, new_gas, a, e, crit_mass, @dust_head
    break if (new_mass - temp_mass) < (0.0001 * temp_mass)
  seed_mass = seed_mass + new_mass
  @update_dust_lanes @r_inner, @r_outer, seed_mass, crit_mass, body_inner_bound, body_outer_bound
  return [ seed_mass, new_dust, new_gas ]

DustAccrete::collect_dust = (last_mass, new_dust, new_gas, a, e, crit_mass, dust_band)->
  gas_density = 0.0
  next_dust = 0
  next_gas = 0
  temp = last_mass / (1.0 + last_mass)
  @reduced_mass = MATH.pow temp, 1.0 / 4.0
  @r_inner = @inner_effect_limit a, e, @reduced_mass
  @r_outer = @outer_effect_limit a, e, @reduced_mass
  @r_inner = 0.0 if @r_inner < 0.0

  return [ 0.0, new_dust, new_gas ] if dust_band is null

  temp_density = if dust_band.dust_present is false then 0.0 else @dust_density

  if (last_mass < crit_mass) || (dust_band.gas_present is false) then mass_density = temp_density
  else
    mass_density = Constants.K * temp_density / (1.0 + MATH.sqrt(crit_mass / last_mass) * (Constants.K - 1.0))
    gas_density = mass_density - temp_density

  if (dust_band.outer_edge <= @r_inner) || (dust_band.inner_edge >= @r_outer)
    return @collect_dust last_mass, new_dust, new_gas, a, e, crit_mass, dust_band.next_band

  bandwidth = @r_outer - @r_inner

  temp1 = @r_outer - dust_band.outer_edge
  temp1 = 0.0 if temp1 < 0.0
  width = bandwidth - temp1

  temp2 = dust_band.inner_edge - @r_inner
  temp2 = 0.0 if temp2 < 0.0
  width = width - temp2

  temp = 4.0 * MATH.PI * MATH.pow(a,2.0) * @reduced_mass * (1.0 - e * (temp1 - temp2) / bandwidth)
  volume = temp * width

  new_mass  = volume * mass_density
  new_gas   = volume * gas_density
  new_dust  = new_mass - new_gas
  [ next_mass, next_dust, next_gas ] = @collect_dust last_mass, next_dust, next_gas, a, e, crit_mass, dust_band.next_band
  new_gas  = new_gas + next_gas
  new_dust = new_dust + next_dust

  [ new_mass + next_mass, new_dust, new_gas ]

DustAccrete::coalesce_planetesimals = (a, e, mass, crit_mass, dust_mass, gas_mass, stell_luminosity_ratio, body_inner_bound, body_outer_bound)->
  finished = false
  prev_planet = null

  # First we try to find an existing planet with an over-lapping orbit.
  planet = @firstChild
  while planet isnt null
    diff = planet.a - a

    if diff > 0.0
      dist1 = (a * (1.0 + e) * (1.0 + @reduced_mass)) - a
      # x aphelion
      @reduced_mass = MATH.pow((planet.mass / (1.0 + planet.mass)),(1.0 / 4.0));
      dist2 = planet.a - (planet.a * (1.0 - planet.e) * (1.0 - @reduced_mass));
    else
      dist1 = a - (a * (1.0 - e) * (1.0 - @reduced_mass));
      # x perihelion
      @reduced_mass = MATH.pow((planet.mass / (1.0 + planet.mass)),(1.0 / 4.0));
      dist2 = (planet.a * (1.0 + planet.e) * (1.0 + @reduced_mass)) - planet.a;

    if ( MATH.abs(diff) <= MATH.abs(dist1) ) || ( MATH.abs(diff) <= MATH.abs(dist2) )
      new_dust = new_gas = 0
      new_a = (planet.mass + mass) / ((planet.mass / planet.a) + (mass / a))
      temp = planet.mass * MATH.sqrt(planet.a) * MATH.sqrt(1.0 - MATH.pow(planet.e,2.0))
      temp = temp + (mass * MATH.sqrt(a) * MATH.sqrt(MATH.sqrt(1.0 - MATH.pow(e,2.0))))
      temp = temp / ((planet.mass + mass) * MATH.sqrt(new_a))
      temp = 1.0 - MATH.pow(temp,2.0)
      temp = 0.0 if (temp < 0.0) || (temp >= 1.0)
      e = MATH.sqrt temp

      finished = Utils.coalesce_moons.call planet if @sun.do_moons

      unless finished
        if Constants.verbosity & 0x0100 then console.log "Collision between two planetesimals! %d AU (%dEM) + %d AU (%dEM = %dEMd + %dEMg [%dEM]). %d AU (%d)",
          planet.a, planet.mass * Constants.SUN_MASS_IN_EARTH_MASSES, a, mass * Constants.SUN_MASS_IN_EARTH_MASSES, dust_mass * Constants.SUN_MASS_IN_EARTH_MASSES, gas_mass * Constants.SUN_MASS_IN_EARTH_MASSES, crit_mass * Constants.SUN_MASS_IN_EARTH_MASSES, new_a, e
        temp = planet.mass + mass;
        [ temp, new_dust, new_gas ] = @accrete_dust temp, new_dust, new_gas, new_a, e, stell_luminosity_ratio, body_inner_bound,body_outer_bound
        planet.a = new_a;
        planet.e = e;
        planet.mass = temp;
        planet.dust_mass += dust_mass + new_dust;
        planet.gas_mass += gas_mass + new_gas;
        planet.gas_giant = true if temp >= crit_mass
        while (planet.nextObject isnt null && planet.nextObject.a < new_a)
          nextObject = planet.nextObject;
          if planet is @firstChild then @firstChild = nextObject
          else prev_planet.nextObject = nextObject
          planet.nextObject = nextObject.nextObject
          nextObject.nextObject = planet
          prev_planet = nextObject
      finished = true
      break
    else prev_planet = planet
    planet = planet.nextObject

  return null if finished # Planetesimals didn't collide. Make it a planet.

  @sun.addChild new Planet
    sun:          @sun
    a:            a
    e:            e
    mass:         mass
    type:         "tUnknown"
    dust_mass:    dust_mass
    gas_mass:     gas_mass
    albedo:       0
    gases:        0
    surf_temp:    0
    high_temp:    0
    low_temp:     0
    max_temp:     0
    min_temp:     0
    greenhs_rise: 0
    minor_moons:  0
    gas_giant: mass >= crit_mass

DustAccrete::coalesce_moons = (a, e, mass, crit_mass, dust_mass, gas_mass, stell_luminosity_ratio, body_inner_bound, body_outer_bound)->
  existing_mass = 0.0
  planet = @
  if planet.firstChild?
    m = planet.firstChild
    while m isnt null
      existing_mass += m.mass
      m = m.nextObject
  if mass < crit_mass
    if (mass * Constants.SUN_MASS_IN_EARTH_MASSES) < 2.5 && (mass * Constants.SUN_MASS_IN_EARTH_MASSES) > .0001 && existing_mass < (planet.mass * .05)
      planet.addChild moon = new Moon
        parent:@
        planet:@
        sun:@sun
        type: 'tUnknown'
        a: a
        e: e
        mass: mass
        dust_mass: dust_mass
        gas_mass: gas_mass
        gas_giant: false
        albedo: 0
        gases: 0
        surf_temp: 0
        high_temp: 0
        low_temp: 0
        max_temp: 0
        min_temp: 0
        greenhs_rise: 0
        minor_moons: 0

      if moon.dust_mass + moon.gas_mass > planet.dust_mass + planet.gas_mass
        temp_dust = planet.dust_mass;
        temp_gas  = planet.gas_mass;
        temp_mass = planet.mass;
        planet.dust_mass = moon.dust_mass;
        planet.gas_mass  = moon.gas_mass;
        planet.mass      = moon.mass;
        moon.dust_mass   = temp_dust;
        moon.gas_mass    = temp_gas;
        moon.mass        = temp_mass;

      finished = true

      if Constants.verbosity & 0x0100 then console.log "Moon Captured... %d AU (%dEM) <- %dEM", the_planet.a, the_planet.mass * Constants.SUN_MASS_IN_EARTH_MASSES, mass * Constants.SUN_MASS_IN_EARTH_MASSES
    else
      if Constants.verbosity & 0x0100 then console.log "Moon Escapes...  %d AU (%dEM)%d %dEM%d", the_planet.a, the_planet.mass * Constants.SUN_MASS_IN_EARTH_MASSES, existing_mass < (the_planet.mass * .05) ? "" : " (big moons)", mass * Constants.SUN_MASS_IN_EARTH_MASSES, (mass * Constants.SUN_MASS_IN_EARTH_MASSES) >= 2.5 ? ", too big" : (mass * Constants.SUN_MASS_IN_EARTH_MASSES) <= .0001 ? ", too small" : ""

# ███████ ████████ ███████ ██      ██       █████  ██████
# ██         ██    ██      ██      ██      ██   ██ ██   ██
# ███████    ██    █████   ██      ██      ███████ ██████
#      ██    ██    ██      ██      ██      ██   ██ ██   ██
# ███████    ██    ███████ ███████ ███████ ██   ██ ██   ██

class Stellar
  addChild: (p)->
    a = p.a
    unless @firstChild?
      @firstChild = p
      p.nextObject = null
    else if a < @firstChild.a
      p.nextObject = @firstChild
      @firstChild = p
    else if @firstChild.nextObject is null
      @firstChild.nextObject = p
      p.nextObject = null
    else
      c = @firstChild
      while c? and c.a < a
        previous = c
        c = c.nextObject
      p.nextObject = c
      previous.nextObject = p
    return p
  countChildren: ->
    return 0 unless @firstChild
    c = 0; p = @firstChild
    ( c++; p = p.nextObject ) while p?
    c

# ███████ ████████  █████  ██████
# ██         ██    ██   ██ ██   ██
# ███████    ██    ███████ ██████
#      ██    ██    ██   ██ ██   ██
# ███████    ██    ██   ██ ██   ██

window.Star = class Star extends Stellar
  seed: 0
  constructor: (opts={})->
    @system_name = "Unknown"
    @[k] = v for k,v of opts
    @type_counts = []
    @mass = MATH.randomNumber 0.7, 1.4 if not @mass? or ( ( @mass < 0.2 ) or ( @mass > 1.5 ) )
    outer_dust_limit = Utils.stellar_dust_limit @mass
    @outer_planet_limit = 0
    @dust_density_coeff = Constants.DUST_DENSITY_COEFF
    @luminosity  = Utils.luminosity @mass unless @luminosity > 0
    @r_ecosphere = MATH.sqrt @luminosity
    @life         = 1.0e10 * ( @mass / @luminosity )
    if @use_seed_system
      @firstChild = @seed_system
      @age = 5.0e9
    else
      min_age = 1.0e9
      max_age = 6.0e9
      max_age = @life if @life < max_age
      @age = MATH.randomNumber min_age, max_age
      @distributeMass 0.0, outer_dust_limit, @outer_planet_limit, @dust_density_coeff
      @generatePlanets not @use_seed_system?

Star::distributeMass = (inner_dust, outer_dust, @outer_planet_limit, @dust_density_coeff)->
  seeds = @seed_system; stell_mass_ratio = @mass; stell_luminosity_ratio = @luminosity
  acc = new DustAccrete @, inner_dust, outer_dust
  planet_inner_bound = Utils.nearest_planet stell_mass_ratio
  planet_outer_bound = if @outer_planet_limit is 0 then Utils.farthest_planet stell_mass_ratio else @outer_planet_limit
  while acc.dust_left
    if seeds?
      a = seeds.a;
      e = seeds.e;
      seeds = seeds.nextObject
    else
      a = MATH.randomNumber planet_inner_bound, planet_outer_bound
      e = MATH.randomEccentricity()
    mass = Constants.PROTOPLANET_MASS
    dust_mass = 0
    gas_mass  = 0
    if Constants.verbosity & 0x0200 then process.stdout.write "Checking " + a + ' AU'
    if acc.dust_available acc.inner_effect_limit(a, e, mass), acc.outer_effect_limit(a, e, mass)
      if Constants.verbosity & 0x0200 then process.stdout.write ""
      if Constants.verbosity & 0x0100 then console.log "Injecting protoplanet at", a, "AU."
      acc.dust_density = @dust_density_coeff * MATH.sqrt(stell_mass_ratio) * MATH.exp(-Constants.ALPHA * MATH.pow(a,(1.0 / Constants.N)));
      crit_mass = Utils.critical_limit a,e,stell_luminosity_ratio
      [ mass, dust_mass, gas_mass ] = acc.accrete_dust mass, dust_mass, gas_mass, a,e,crit_mass, planet_inner_bound, planet_outer_bound
      dust_mass += Constants.PROTOPLANET_MASS
      if mass >= Constants.PROTOPLANET_MASS
        acc.coalesce_planetesimals a, e, mass,crit_mass, dust_mass, gas_mass, stell_luminosity_ratio, planet_inner_bound,planet_outer_bound
      else if Constants.verbosity & 0x0100 then console.log ".. failed due to large neighbor."
    else if Constants.verbosity & 0x0200 then console.log ".. failed."
  return acc.firstChild

Star::generatePlanets = (random_tilt)->
  planet = @firstChild; planets = 0
  while planet?
    # planet = new Planet sun:@, tilt: random_tilt, moon:false
    planets++
    planet.moons = 0
    planet.id = @system_name + ' ' + planets
    planet.check_planet()
    moon = planet.firstChild
    while moon?
      moons++
      moon_id = @id + "." + moons
      Planet::check_planet.call moon, moon_id, true
      moon = moon.nextObject
    planet = planet.nextObject
  null

# ██████  ██       █████  ███    ██ ███████ ████████
# ██   ██ ██      ██   ██ ████   ██ ██         ██
# ██████  ██      ███████ ██ ██  ██ █████      ██
# ██      ██      ██   ██ ██  ██ ██ ██         ██
# ██      ███████ ██   ██ ██   ████ ███████    ██

class Planet extends Stellar
  constructor: (opts={})->
    @[k] = v for k,v of opts
    @planet_no = @sun.countChildren() + 1
    @id = @sun.system_name + " " + @planet_no
    console.log 'New Planet >', @id
    @atmosphere      = []
    @gases           = 0
    @surf_temp       = 0
    @high_temp       = 0
    @low_temp        = 0
    @max_temp        = 0
    @min_temp        = 0
    @greenhs_rise    = 0
    @resonant_period = false
    @orbit_zone      = Utils.orb_zone @sun.luminosity, @a
    @orb_period      = Utils.period @a, @mass, @sun.mass
    @axial_tilt      = if @random_tilt then Utils.inclination @a else 0
    @exospheric_temp = Constants.EARTH_EXOSPHERE_TEMP / ( MATH.pow2 @a / @sun.r_ecosphere )
    @rms_velocity    = Utils.rms_vel Constants.MOL_NITROGEN, @exospheric_temp
    @core_radius     = Utils.kothari_radius @dust_mass, false, @orbit_zone
    ###
      Calculate the radius as a gas giant, to verify it will retain gas.
      Then if mass > Earth, it's at least 5% gas and retains He, it's
      some flavor of gas giant.
    ###
    @density         = Utils.empirical_density(@mass,@a, @sun.r_ecosphere, true);
    @radius          = Utils.volume_radius(@mass,@density);
    @surf_accel      = Utils.acceleration(@mass,@radius);
    @surf_grav       = Utils.gravity(@surf_accel);
    @molec_weight    = Utils.min_molec_weight.call @

    if ( ((@mass * Constants.SUN_MASS_IN_EARTH_MASSES) > 1.0)&&((@gas_mass / @mass) > 0.05)&&(Utils.min_molec_weight.call(@) <= 4.0))
      if ((@gas_mass / @mass) < 0.20)
           @type = 'tSubSubGasGiant'
      else if ((@mass * Constants.SUN_MASS_IN_EARTH_MASSES) < 20.0)
           @type = 'tSubGasGiant'
      else @type = 'tGasGiant'
    else # If not, it's rocky.
      @radius    = Utils.kothari_radius @mass, false, @orbit_zone
      @density   = Utils. volume_density @mass, @radius

      @surf_accel = Utils.acceleration @mass,@radius
      @surf_grav  = Utils.gravity @surf_accel

      if (@gas_mass / @mass) > 0.000001
        h2_mass = @gas_mass * 0.85;
        he_mass = (@gas_mass - h2_mass) * 0.999;
        h2_loss = 0.0;
        he_loss = 0.0;
        h2_life = Utils.gas_life.call @, Constants.MOL_HYDROGEN
        he_life = Utils.gas_life.call @, Constants.HELIUM

        if (h2_life < @sun.age)
          h2_loss      = (1.0 - (1.0 / exp(@sun.age / h2_life))) * h2_mass
          @gas_mass   -= h2_loss
          @mass       -= h2_loss
          @surf_accel  = Utils.acceleration @mass, @radius
          @surf_grav   = Utils.gravity @surf_accel

        if (he_life < @sun.age)
          he_loss      = (1.0 - (1.0 / MATH.exp(@sun.age / he_life))) * he_mass
          @gas_mass   -= he_loss
          @mass       -= he_loss
          @surf_accel  = Utils.acceleration @mass,@radius
          @surf_grav   = Utils.gravity @surf_accel

        # if (((h2_loss + he_loss) > .000001) && Constants.verbosity & 0x0080)
        #   console.log, "%d\tLosing gas: H2: %d Constants.EM, He: %d Constants.EM",
        #     @id,
        #     h2_loss * Constants.SUN_MASS_IN_EARTH_MASSES, he_loss * Constants.SUN_MASS_IN_EARTH_MASSES);

    @day = Utils.day_length.call @
    @esc_velocity = Utils.escape_vel @mass, @radius

    if ((@type is 'tGasGiant') || (@type is 'tSubGasGiant') || (@type is 'tSubSubGasGiant'))
      @greenhouse_effect      = false;
      @volatile_gas_inventory = Constants.INCREDIBLY_LARGE_NUMBER;
      @surf_pressure          = Constants.INCREDIBLY_LARGE_NUMBER;
      @boil_point             = Constants.INCREDIBLY_LARGE_NUMBER;
      @surf_temp              = Constants.INCREDIBLY_LARGE_NUMBER;
      @greenhs_rise           = 0;
      @albedo                 = MATH.about Constants.GAS_GIANT_ALBEDO, 0.1
      @hydrosphere            = 1.0
      @cloud_cover            = 1.0
      @ice_cover              = 0.0
      @surf_grav              = Utils.gravity @surf_accel
      @molec_weight           = Utils.min_molec_weight.call @
      @surf_grav              = Constants.INCREDIBLY_LARGE_NUMBER;
      @estimated_temp         = Utils.est_temp(@sun.r_ecosphere, @a,  @albedo);
      @estimated_terr_temp    = Utils.est_temp(@sun.r_ecosphere, @a,  Constants.EARTH_ALBEDO);
      temp                    = @estimated_terr_temp
      if ((temp >= Constants.FREEZING_POINT_OF_WATER) && (temp <= Constants.EARTH_AVERAGE_KELVIN + 10.0) && (@sun.age > 2.0e9)) then @sun.habitable_jovians++
      if Constants.verbosity & 0x8000 then console.log "%d\t%d (%dEM %d By)%d with earth-like temperature (%d C, %d F, %d C Earth).",
        @id,
        if @type is 'tGasGiant' then "Jovian" else if @type is 'tSubGasGiant' then "Sub-Jovian" else if @type is 'tSubSubGasGiant' then "Gas Dwarf" else "Big",
        @mass * Constants.SUN_MASS_IN_EARTH_MASSES, @sun.age /1.0e9, @firstChild is null ? "" : " Constants.WITH Constants.MOON", temp - Constants.FREEZING_POINT_OF_WATER, 32 + ((temp - Constants.FREEZING_POINT_OF_WATER) * 1.8),
        temp - Constants.EARTH_AVERAGE_KELVIN
    else
      @estimated_temp         = Utils.est_temp @sun.r_ecosphere, @a,  Constants.EARTH_ALBEDO
      @estimated_terr_temp    = Utils.est_temp @sun.r_ecosphere, @a,  Constants.EARTH_ALBEDO
      @surf_grav              = Utils.gravity @surf_accel
      @molec_weight           = Utils.min_molec_weight.call @
      @greenhouse_effect      = Utils.grnhouse @sun.r_ecosphere, @a
      @volatile_gas_inventory = Utils.vol_inventory(
        @mass, @esc_velocity, @rms_velocity, @sun.mass, @orbit_zone, @greenhouse_effect, (@gas_mass / @mass) > 0.000001);
      @surf_pressure          = Utils.pressure(@volatile_gas_inventory, @radius, @surf_grav);

      @boil_point = if @surf_pressure is 0.0 then 0.0 else Utils.boiling_point @surf_pressure
      Utils.iterate_surface_temp.call @

    if @sun.do_gases && (@max_temp >= Constants.FREEZING_POINT_OF_WATER) && (@min_temp <= @boil_point)
      Utils.calculate_gases.call @

    ###
    * Next we assign a type to the planet.
    ###

    if (@surf_pressure < 1.0)
      if (!@is_moon && ((@mass * Constants.SUN_MASS_IN_EARTH_MASSES) < Constants.ASTEROID_MASS_LIMIT))
        @type = 'tAsteroids'
      else @type = 'tRock'
    else if ((@surf_pressure > 6000.0) && (@molec_weight <= 2.0)) # Retains Hydrogen
      @type = 'tSubSubGasGiant'
      @gases = 0;
      @atmosphere = null
    else # Atmospheres:
      if parseInt(@day) is parseInt(@orb_period * 24.0) || @resonant_period then @type = 't1Face'
      else if (@hydrosphere >= 0.95) then @type = 'tWater'
      else if (@ice_cover >= 0.95)   then @type = 'tIce'
      else if (@hydrosphere > 0.05)  then @type = 'tTerrestrial'
      # else <5% water
      else if @max_temp > @boil_point then @type = 'tVenusian'
      else if 0.0001 < @gas_mass / @mass # Accreted gas
        @type = 'tIce'
        @ice_cover = 1.0                     # or liquid water
                                             # Make it an Ice World
      else if (@surf_pressure <= 250.0) then @type = 'tMartian'
      else if (@surf_temp < Constants.FREEZING_POINT_OF_WATER) then @type = 'tIce'
      else
        @type = 'tUnknown'
        if Constants.verbosity & 0x0001 then console.log "%d\tp=%d\tm=%d\tg=%d\tt=%d\t%d\t Unknown %d", @type, @surf_pressure, @mass * Constants.SUN_MASS_IN_EARTH_MASSES,
          @surf_grav,
          @surf_temp  - Constants.EARTH_AVERAGE_KELVIN,
          @id,
          @day is (@orb_period * 24.0) || if @resonant_period then "(1-Face)" else ""

    if @sun.do_moons and not @is_moon
      if @firstChild isnt null
        n = 0
        ptr = @firstChild
        while ptr?
          if .000001 < ptr.mass * Constants.SUN_MASS_IN_EARTH_MASSES
            roche_limit = 0.0
            hill_sphere = 0.0
            ptr.a = @a
            ptr.e = @e
            n++
            moon_id = @id + "." + n
            Utils.generate_planet ptr, n, sun, random_tilt, moon_id, true # Adjusts ptr.density
            roche_limit = 2.44 * @radius * MATH.pow (@density / ptr.density), (1.0 / 3.0)
            hill_sphere = @a * Constants.KM_PER_AU * MATH.pow (@mass / (3.0 * @sun.mass)), (1.0 / 3.0)
            if (roche_limit * 3.0) < hill_sphere
              ptr.moon_a = MATH.randomNumber(roche_limit * 1.5, hill_sphere / 2.0) / Constants.KM_PER_AU
              ptr.moon_e = MATH.randomEccentricity()
            else
              ptr.moon_a = 0
              ptr.moon_e = 0
          ptr = ptr.nextObject

#            if Constants.verbosity & 0x40000 console.log,
#"   Roche limit: R = %d, rM = %d, rm = %d -> %d km"
#"   Hill Sphere: a = %d, m = %d, M = %d -> %d km"
#"%d Moon orbit: a = %d km, e = %d",
#@radius, @density, ptr->density,
#roche_limit,
#@a * Constants.KM_PER_AU, @mass * Constants.SOLAR_MASS_IN_KILOGRAMS, @sun.mass * Constants.SOLAR_MASS_IN_KILOGRAMS,
#hill_sphere,
#moon_id,
#ptr->moon_a * Constants.KM_PER_AU, ptr->moon_e
#);
#}
#



#if Constants.verbosity & 0x1000
#{
#console.log, "  %d: (%7.2LfEM) %d %dEM",
#@id,
#@mass * Constants.SUN_MASS_IN_EARTH_MASSES,
#n,
#ptr->mass * Constants.SUN_MASS_IN_EARTH_MASSES);

Planet.typeByTypeId = 0:'tUnknown', 1:'tRock', 2:'tVenusian', 3:'tTerrestrial', 4:'tSubSubGasGiant', 5:'tSubGasGiant', 6:'tGasGiant', 7:'tMartian', 8:'tWater', 9:'tIce', 10:'tAsteroids', 11:'t1Face'
Planet.typeByName = tUnknown:0, tRock:1, tVenusian:2, tTerrestrial:3, tSubSubGasGiant:4, tSubGasGiant:5, tGasGiant:6, tMartian:7, tWater:8, tIce:9, tAsteroids:10, t1Face:11

Planet::check_planet = ->
  tIndex = Planet.typeByTypeId[@type]
  tIndex = 0 unless tIndex
  ++@type_count if @sun.type_counts[tIndex] == 0
  ++@sun.type_counts[tIndex]

  # Check for and list planets with breathable atmospheres
  breathe = Utils.breathability.call @

  if ( breathe is 'BREATHABLE' ) and ( not @resonant_period ) && ( parseInt(@day) isnt parseInt(@orb_period * 24.0) )
    list_it = false
    llumination = MATH.pow2(1.0 / @a) * @sun.luminosity
    @sun.habitable++

    if min_breathable_temp > @surf_temp
      min_breathable_temp = @surf_temp;
      list_it = true if Constants.verbosity & 0x0002

    if max_breathable_temp < @surf_temp
      max_breathable_temp = @surf_temp;
      list_it = true if Constants.verbosity & 0x0002

    if min_breathable_g > @surf_grav
      min_breathable_g = @surf_grav;
      list_it = true if Constants.verbosity & 0x0002

    if max_breathable_g < @surf_grav
      max_breathable_g = @surf_grav;
      list_it = true if Constants.verbosity & 0x0002

    if min_breathable_l > illumination
      min_breathable_l = illumination;
      list_it = true if Constants.verbosity & 0x0002

    if max_breathable_l < illumination
      max_breathable_l = illumination;
      list_it = true if Constants.verbosity & 0x0002

    if @type == 'tTerrestrial'
      if min_breathable_terrestrial_g > @surf_grav
        min_breathable_terrestrial_g = @surf_grav;
        list_it = true if Constants.verbosity & 0x0002

      if max_breathable_terrestrial_g < @surf_grav
        max_breathable_terrestrial_g = @surf_grav;
        list_it = true if Constants.verbosity & 0x0002

      if min_breathable_terrestrial_l > illumination
        min_breathable_terrestrial_l = illumination;
        list_it = true if Constants.verbosity & 0x0002

      if max_breathable_terrestrial_l < illumination
        max_breathable_terrestrial_l = illumination;
        list_it = true if Constants.verbosity & 0x0002

    if min_breathable_p > @surf_pressure
      min_breathable_p = @surf_pressure
      list_it = true if Constants.verbosity & 0x0002

    if max_breathable_p < @surf_pressure
      max_breathable_p = @surf_pressure;
      list_it = true if Constants.verbosity & 0x0002

    if Constants.verbosity & 0x0004
      list_it = true

    if list_it then console.log "%d\tp=%d\tm=%d\tg=%d\tt=%d\tl=%d\t%d", @type, @surf_pressure, @mass * Constants.SUN_MASS_IN_EARTH_MASSES, @surf_grav, @surf_temp  - Constants.EARTH_AVERAGE_KELVIN, illumination, @id

  if @is_moon and max_moon_mass < @mass
    max_moon_mass = @mass
    if Constants.verbosity & 0x0002 then console.log "%d\tp=%d\tm=%d\tg=%d\tt=%d\t%d Moon Mass", @type, @surf_pressure, @mass * Constants.SUN_MASS_IN_EARTH_MASSES, @surf_grav, @surf_temp  - Constants.EARTH_AVERAGE_KELVIN, @id

  if ( ( Constants.verbosity & 0x0800 ) && (@dust_mass * Constants.SUN_MASS_IN_EARTH_MASSES >= 0.0006) && (@gas_mass * Constants.SUN_MASS_IN_EARTH_MASSES >= 0.0006) && (@type isnt 'tGasGiant') && (@type isnt 'tSubGasGiant') )
    core_size = parseInt ( 50.0 * @core_radius ) / @radius
    if core_size <= 49 then console.log "%d\tp=%d\tr=%d\tm=%d\t%d\t%d", @type, @core_radius, @radius, @mass * Constants.SUN_MASS_IN_EARTH_MASSES, @id, 50-core_size

  rel_temp   = @surf_temp - Constants.FREEZING_POINT_OF_WATER - Constants.EARTH_AVERAGE_CELSIUS
  seas       = @hydrosphere * 100.0
  clouds     = @cloud_cover * 100.0
  pressure   = @surf_pressure / Constants.EARTH_SURF_PRES_IN_MILLIBARS
  ice        = @ice_cover * 100.0
  gravity    = @surf_grav;
  breathe    = Utils.breathability.call @

  earthlike = (
    (gravity  >= .8) &&
    (gravity  <= 1.2) &&
    (rel_temp >= -2.0) &&
    (rel_temp <= 3.0) &&
    (ice      <= 10.0) &&
    (pressure >= 0.5) &&
    (pressure <= 2.0) &&
    (clouds   >= 40.0) &&
    (clouds   <= 80.0) &&
    (seas     >= 50.0) &&
    (seas     <= 80.0) &&
    (@type    isnt 'tWater') &&
    (breathe  == 'BREATHABLE') )
  @sun.earthlike++ if earthlike
  if     Constants.verbosity & 0x0008 then console.log "%d\tp=%d\tm=%d\tg=%d\tt=%d\t%d %d\tEarth-like", @type, @surf_pressure, @mass * Constants.SUN_MASS_IN_EARTH_MASSES, @surf_grav, @surf_temp  - Constants.EARTH_AVERAGE_KELVIN, @sun.habitable, @id
  else if Constants.verbosity & 0x0008 && earthlike then console.log "%d\tp=%d\tm=%d\tg=%d\tt=%d\t%d\tSphinx-like", @type, @surf_pressure, @mass * Constants.SUN_MASS_IN_EARTH_MASSES, @surf_grav, @surf_temp  - Constants.EARTH_AVERAGE_KELVIN, @id

# ███    ███  ██████   ██████  ███    ██
# ████  ████ ██    ██ ██    ██ ████   ██
# ██ ████ ██ ██    ██ ██    ██ ██ ██  ██
# ██  ██  ██ ██    ██ ██    ██ ██  ██ ██
# ██      ██  ██████   ██████  ██   ████

class Moon extends Planet
  constructor:(@sun,opts={})->
    @is_moon = true
    super opts

Utils = {}


# ██    ██ ████████ ██ ██      ███████
# ██    ██    ██    ██ ██      ██
# ██    ██    ██    ██ ██      ███████
# ██    ██    ██    ██ ██           ██
#  ██████     ██    ██ ███████ ███████

Utils.stellar_dust_limit = (stell_mass_ratio)-> 200.0 * MATH.pow(stell_mass_ratio,(1.0 / 3.0))
Utils.nearest_planet = (stell_mass_ratio)-> 0.3 * MATH.pow(stell_mass_ratio,(1.0 / 3.0))
Utils.farthest_planet = (stell_mass_ratio)-> 50.0 * MATH.pow(stell_mass_ratio,(1.0 / 3.0))

Utils.calculate_gases = ->
  if @surf_pressure > 0
    n = 0; totamount = 0; gases = ChemTable.gases
    amount = new Array max_gas + 1
    pressure = @surf_pressure / Constants.MILLIBARS_PER_BAR;

    for i in [0..max_gas-1]
      yp = gases[i].boil / ( 373.0 * (( MATH.log( pressure + 0.001) / -5050.5 ) + ( 1.0 / 373.0 ) ))

      if ((yp >= 0 && yp < @low_temp) && (gases[i].weight >= @molec_weight))
        vrms  = Utils.rms_vel.call @, gases[i].weight, @exospheric_temp
        pvrms = MATH.pow 1 / (1 + vrms / @esc_velocity), @sun.age / 1e9
        abund = gases[i].abunds # gases[i].abunde
        react = 1.0
        fract = 1.0
        pres2 = 1.0

        if gases[i].symbol is "Ar"
          react = .15 * @sun.age/4e9;
        else if gases[i].symbol is "He"
          abund = abund * (0.001 + (@gas_mass / @mass));
          pres2 = (0.75 + pressure);
          react = MATH.pow 1 / (1 + gases[i].reactivity), @sun.age/2e9 * pres2
        else if gases[i].symbol is "O" || gases[i].symbol is "O2" && @sun.age > 2e9 && @surf_temp > 270 && @surf_temp < 400
          pres2 = 0.89 + pressure / 4 # Breathable - M: .6 -1.8
          react = MATH.pow 1 / (1 + gases[i].reactivity), MATH.pow(@sun.age/2e9, 0.25) * pres2
        else if gases[i].symbol is "CO2" && @sun.age > 2e9 && @surf_temp > 270 && @surf_temp < 400
          pres2 = (0.75 + pressure);
          react = MATH.pow 1 / (1 + gases[i].reactivity), MATH.pow(@sun.age/2e9, 0.5) * pres2
          react *= 1.5;
        else
          pres2 = 0.75 + pressure
          react = MATH.pow 1 / (1 + gases[i].reactivity), @sun.age/2e9 * pres2
        fract = 1 - ( @molec_weight / gases[i].weight )
        amount[i] = abund * pvrms * react * fract
        if (Constants.verbosity & 0x4000) && ( gases[i].symbol is "O" || gases[i].symbol is "N" || gases[i].symbol is "Ar" || gases[i].symbol is "He" || gases[i].symbol is "CO2" ) then console.log "%d %d, %d = a %d * p %d * r %d * p2 %d * f %d\t(%d%%)\n", @mass * SUN_MASS_IN_EARTH_MASSES, gases[i].symbol, amount[i], abund, pvrms, react, pres2, fract, 100.0 * (@gas_mass / @mass)
        totamount += amount[i]
        n++ if amount[i] > 0.0
      else amount[i] = 0.0;
    if n > 0
      @gases = n
      @atmosphere = []
      @atmosphere[i] = {} for i in [0...max_gas]
      n = 0
      for i in [0..max_gas-1]
        if amount[i] > 0.0
          @atmosphere[n].num = gases[i].num;
          @atmosphere[n].surf_pressure = @surf_pressure * amount[i] / totamount;
          if Constants.verbosity & 0x2000 and (@atmosphere[n].num == AN_O) && Utils.inspired_partial_pressure(@surf_pressure,@atmosphere[n].surf_pressure) > gases[i].max_ipp then console.log "%d\t Poisoned by O2\n", planet_id
          n++

      # qsort(@atmosphere, @gases, sizeof(gas), diminishing_pressure);

      if Constants.verbosity & 0x0010
        console.log "\n%d (%d AU) gases:\n", planet_id, @a
        for i in [0..@gases]
          console.log "%d: %d, %d\n", @atmosphere[i].num, @atmosphere[i].surf_pressure, 100.0 * (@atmosphere[i].surf_pressure / @surf_pressure)
  null

###
  Orbital radius is in Constants.AU, eccentricity is unitless, and the stellar luminosity ratio is with respect to the sun.
  The value returned is the mass at which the planet begins to accrete gas as well as dust, and is in units of solar masses.
###

Utils.critical_limit = (orb_radius, eccentricity, stell_luminosity_ratio)->
  perihelion_dist = orb_radius - orb_radius * eccentricity
  temp = perihelion_dist * MATH.sqrt stell_luminosity_ratio
  Constants.B * MATH.pow temp, -0.75

Utils.luminosity = (mass_ratio)->
  n = if mass_ratio < 1.0 then n = 1.75 * ( mass_ratio - 0.1 ) + 3.325 else 0.5 * ( 2.0 - mass_ratio ) + 4.4
  MATH.pow mass_ratio, n

###
  This function, given the orbital radius of a planet in Constants.AU, returns
  the orbital 'zone' of the particle.
###

Utils.orb_zone = (luminosity, orb_radius)->
  if      orb_radius < 4.0  * MATH.sqrt luminosity then return 1
  else if orb_radius < 15.0 * MATH.sqrt luminosity then return 2
  else return 3

###
  The mass is in units of solar masses, and the density is in units
  of grams/cc.  The radius returned is in units of km.
###

Utils.volume_radius = (mass, density)->
  mass   = mass * Constants.SOLAR_MASS_IN_GRAMS;
  volume = mass / density;
  return MATH.pow( (3.0 * volume) / (4.0 * MATH.PI), (1.0 / 3.0) ) / Constants.CM_PER_KM

###
  Returns the radius of the planet in kilometers.
  The mass passed in is in units of solar masses.
  This formula is listed as eq.9 in Fogg's article, although some typos
  crop up in that eq.  See "The Internal Constitution of Planets", by
  Dr. D. S. Kothari, Mon. Not. of the Royal Astronomical Society, vol 96
  pp.833-843, 1936 for the derivation.  Specifically, this is Kothari's
  eq.23, which appears on page 840.
###

Utils.kothari_radius = (mass, giant, zone)->
  [ atomic_weight, atomic_num ] = switch zone
    when 1 then ( if giant then [ 9.5,  4.5 ] else [ 15.0, 8.0 ] )
    when 2 then ( if giant then [ 2.47, 2.0 ] else [ 10.0, 5.0 ] )
    else        ( if giant then [ 7.0,  4.0 ] else [ 10.0, 5.0 ] )

  temp1 = atomic_weight * atomic_num;
  temp = (2.0 * Constants.BETA_20 * MATH.pow( Constants.SOLAR_MASS_IN_GRAMS,(1.0 / 3.0))) / (Constants.A1_20 * MATH.pow(temp1, (1.0 / 3.0)))
  temp2 = Constants.A2_20 * MATH.pow(atomic_weight,(4.0 / 3.0)) * MATH.pow(Constants.SOLAR_MASS_IN_GRAMS,(2.0 / 3.0))
  temp2 = temp2 * MATH.pow(mass,(2.0 / 3.0))
  temp2 = temp2 / (Constants.A1_20 * MATH.pow2(atomic_num))
  temp2 = 1.0 + temp2
  temp = temp / temp2
  temp = (temp * MATH.pow(mass,(1.0 / 3.0))) / Constants.CM_PER_KM

  temp /= Constants.JIMS_FUDGE; # Make Earth = actual earth
  return temp

###
  The mass passed in is in units of solar masses, and the orbital radius is in units of Constants.AU.
  The density is returned in units of grams/cc.
###

Utils.empirical_density = (mass, orb_radius, r_ecosphere, gas_giant)->
  temp = MATH.pow mass * Constants.SUN_MASS_IN_EARTH_MASSES, 1.0 / 8.0
  temp = temp * MATH.pow1_4 r_ecosphere / orb_radius
  if gas_giant then temp * 1.2 else temp * 5.5

###
  The mass passed in is in units of solar masses, and the equatorial radius is in km.
  The density is returned in units of grams/cc.
###

Utils.volume_density =(mass, equat_radius)->
  mass = mass * Constants.SOLAR_MASS_IN_GRAMS
  equat_radius = equat_radius * Constants.CM_PER_KM
  volume = ( 4.0 * MATH.PI * MATH.pow3 equat_radius ) / 3.0
  mass / volume

###
  The separation is in units of AU, and both masses are in units of solar masses.
  The period returned is in terms of Earth days.
###

Utils.period = (separation, small_mass, large_mass)->
  Constants.DAYS_IN_A_YEAR * MATH.sqrt MATH.pow3(separation) / (small_mass + large_mass)

###
  Fogg's information for this routine came from Dole "Habitable Planets for Man",
    Blaisdell Publishing Company, Constants.NY, 1964.
  From this, he came up with his eq.12, which is the equation for the 'base_angular_velocity' below.
  He then used an equation for the change in angular velocity per time (dw/dt)
    from P. Goldreich and S. Soter's paper "Q in the Solar System" in Icarus, vol 5, pp.375-389 (1966).

  Using as a comparison the change in angular velocity for the Earth,
    Fogg has come up with an approximation for our new planet (his eq.13) and take that into account.
    This is used to find 'change_in_angular_velocity' below. Input parameters are mass (in solar masses), radius (in Km),
    orbital period (in days), orbital radius (in Constants.AU), density (in g/cc), eccentricity,
    and whether it is a gas giant or not.

  The length of the day is returned in units of hours.
###

Utils.day_length = ->
  stopped = false
  year_in_hours = @orb_period * 24.0
  planetary_mass_in_grams = @mass * Constants.SOLAR_MASS_IN_GRAMS
  equatorial_radius_in_cm = @radius * Constants.CM_PER_KM
  giant   = @type is 'tGasGiant' || @type is 'tSubGasGiant' || @type is 'tSubSubGasGiant'
  @resonant_period = false # Warning: Modify the planet
  k2 = if giant then 0.24 else 0.33
  base_angular_velocity = MATH.sqrt 2.0 * Constants.J * (planetary_mass_in_grams) / (k2 * MATH.pow2(equatorial_radius_in_cm))
  # This next calculation determines how much the planet's rotation is slowed by the presence of the star.
  change_in_angular_velocity = Constants.CHANGE_IN_EARTH_ANG_VEL *
                 (@density / Constants.EARTH_DENSITY) *
                 (equatorial_radius_in_cm / Constants.EARTH_RADIUS) *
                 (Constants.EARTH_MASS_IN_GRAMS / planetary_mass_in_grams) *
                 MATH.pow(@sun.mass, 2.0) *
                 (1.0 / MATH.pow(@a, 6.0))
  ang_velocity = base_angular_velocity + (change_in_angular_velocity * @sun.age);
  # Now we change from rad/sec to hours/rotation.
  if ang_velocity <= 0.0
       stopped = true
       day_in_hours = Constants.INCREDIBLY_LARGE_NUMBER
  else day_in_hours = Constants.RADIANS_PER_ROTATION / ( Constants.SECONDS_PER_HOUR * ang_velocity )
  if ( day_in_hours >= year_in_hours ) || stopped
    if @e > 0.1
      spin_resonance_factor = (1.0 - @e) / (1.0 + @e)
      @resonant_period   = true;
      return spin_resonance_factor * year_in_hours
    else return year_in_hours
  return day_in_hours

###
  The orbital radius is expected in units of Astronomical Units (Constants.AU).
  Inclination is returned in units of degrees.
###

Utils.inclination = (orb_radius)->
  parseInt ( MATH.pow orb_radius, 0.2 ) * ( MATH.about Constants.EARTH_AXIAL_TILT, 0.4 ) % 360

###
  This function implements the escape velocity calculation.
  Note that it appears that Fogg's eq.15 is incorrect.
  The mass is in units of solar mass, the radius in kilometers, and the velocity returned is in cm/sec.
###

Utils.escape_vel = (mass, radius)->
  mass_in_grams = mass * Constants.SOLAR_MASS_IN_GRAMS;
  radius_in_cm = radius * Constants.CM_PER_KM;
  MATH.sqrt 2.0 * Constants.GRAV_CONSTANT * mass_in_grams / radius_in_cm

###
  This is Fogg's eq.16. The molecular weight (usually assumed to be Constants.N2) is used as the basis
    of the Root Mean Square (Constants.RMS) velocity of the molecule or atom.
  The velocity returned is in cm/sec.
  Orbital radius is in A.U.(ie: in units of the earth's orbital radius).
###

Utils.rms_vel = (molecular_weight, exospheric_temp)->
  MATH.sqrt ((3.0 * Constants.MOLAR_GAS_CONST * exospheric_temp) / molecular_weight) * Constants.CM_PER_METER

###
  This function returns the smallest molecular weight retained by the body,
    which is useful for determining the atmosphere composition.
  Mass is in units of solar masses, and equatorial radius is in units of kilometers.
###

Utils.molecule_limit = (mass, equat_radius, exospheric_temp)->
  esc_velocity = @escape_vel mass, equat_radius
  ( 3.0 * Constants.MOLAR_GAS_CONST * exospheric_temp ) / MATH.pow2 esc_velocity / Constants.GAS_RETENTION_THRESHOLD / Constants.CM_PER_METER

###
  This function calculates the surface acceleration of a planet.
  The mass is in units of solar masses, the radius in terms of km, and the acceleration is returned in units of cm/sec2.
###

Utils.acceleration = (mass, radius)->
   Constants.GRAV_CONSTANT * (mass * Constants.SOLAR_MASS_IN_GRAMS) / MATH.pow2 radius * Constants.CM_PER_KM

###
  This function calculates the surface gravity of a planet.
  The acceleration is in units of cm/sec2, and the gravity is returned in units of Earth gravities.
###

Utils.gravity = (acceleration)-> acceleration / Constants.EARTH_ACCELERATION

###
  This implements Fogg's eq.17.  The 'inventory' returned is unitless.
###

Utils.vol_inventory = (mass, escape_vel, rms_vel, stellar_mass, zone, greenhouse_effect, accreted_gas)->
  return if ( velocity_ratio = escape_vel / rms_vel ) >= Constants.GAS_RETENTION_THRESHOLD
    switch zone
      when 1 then proportion_const = 140000.0
      when 2 then proportion_const = 75000.0
      when 3 then proportion_const = 250.0
      else proportion_const = 0.0; console.error "Error: orbital zone not initialized correctly!"
    earth_units = mass * Constants.SUN_MASS_IN_EARTH_MASSES
    temp1 = (proportion_const * earth_units) / stellar_mass
    temp2 = MATH.about temp1, 0.2
    if greenhouse_effect || accreted_gas then temp2
    else temp2 / 140.0 # 100 -> 140 Constants.JLB
  else 0.0

###
  This implements Fogg's eq.18.  The pressure returned is in units of millibars (mb).
  The gravity is in units of Earth gravities, the radius in units of kilometers.
  Constants.JLB: Aparently this assumed that earth pressure = 1000mb.
  I've added a fudge factor (Constants.EARTH_SURF_PRES_IN_MILLIBARS / 1000.) to correct for that
###

Utils.pressure = (volatile_gas_inventory, equat_radius, gravity)->
  equat_radius = Constants.KM_EARTH_RADIUS / equat_radius;
  volatile_gas_inventory * gravity * ( Constants.EARTH_SURF_PRES_IN_MILLIBARS / 1000.0 ) / MATH.pow2 equat_radius

###
  This function returns the boiling point of water in an atmosphere of pressure 'surf_pressure', given in millibars.
  The boiling point is returned in units of Kelvin. This is Fogg's eq.21.
###

Utils.boiling_point = (surf_pressure)->
  surface_pressure_in_bars = surf_pressure / Constants.MILLIBARS_PER_BAR
  n = ( MATH.log(surface_pressure_in_bars) / -5050.5 ) + ( 1.0 / 373.0 )
  return 1.0 / n

###
  Given the volatile gas inventory and planetary radius of a planet (in Km),
    this function returns the fraction of the planet covered with water.
  I have changed the function very slightly:
    the fraction of Earth's surface covered by water is 71%, not 75% as Fogg used.
 This function is Fogg's eq.22.
###

Utils.hydro_fraction = (volatile_gas_inventory, planet_radius)->
  MATH.min 1.0, ( 0.71 * volatile_gas_inventory / 1000.0 ) * MATH.pow2 Constants.KM_EARTH_RADIUS / planet_radius

###
  Given the surface temperature of a planet (in Kelvin), this function returns the fraction of cloud cover available.
  I have modified it slightly using constants and relationships from Glass's book
    "Introduction to Planetary Geology", p.46.
  The 'CLOUD_COVERAGE_FACTOR' is the amount of surface area on Earth covered by one Kg. of cloud.
  This is Fogg's eq.23. This equation is Hart's eq.3. See Hart in "Icarus" (vol 33, pp23 - 39, 1978) for an explanation.
###

Utils.cloud_fraction = (surf_temp, smallest_MW_retained, equat_radius, hydro_fraction)->
  if smallest_MW_retained > Constants.WATER_VAPOR then return 0.0
  surf_area = 4.0 * MATH.PI * MATH.pow2 equat_radius
  hydro_mass = hydro_fraction * surf_area * Constants.EARTH_WATER_MASS_PER_AREA
  water_vapor_in_kg = 0.00000001 * hydro_mass * MATH.exp Constants.Q2_36 * surf_temp - Constants.EARTH_AVERAGE_KELVIN
  MATH.min 1.0, Constants.CLOUD_COVERAGE_FACTOR * water_vapor_in_kg / surf_area

###
  Given the surface temperature of a planet (in Kelvin), this function returns the fraction of the planet's surface covered by ice.
  I have changed a constant from 70 to 90 in order to bring it more in line with the fraction of the Earth's surface covered with ice, which is approximatly .016 (=1.6%).
  This is Fogg's eq.24. See Hart[24] in Icarus vol.33, p.28 for an explanation.
###

Utils.ice_fraction = (hydro_fraction, surf_temp)->
  if (surf_temp > 328.0) then surf_temp = 328.0;
  temp = MATH.pow ((328.0 - surf_temp) / 90.0), 5.0
  if temp > 1.5 * hydro_fraction then temp = 1.5 * hydro_fraction
  MATH.min 1.0, temp

###
  The ecosphere radius is given in Constants.AU, the orbital radius in Constants.AU, and the temperature returned is in Kelvin.
  This is Fogg's eq.19.
###

Utils.eff_temp = (ecosphere_radius, orb_radius, albedo)->
  MATH.sqrt(ecosphere_radius / orb_radius) * MATH.pow1_4((1.0 - albedo) / (1.0 - Constants.EARTH_ALBEDO)) * Constants.EARTH_EFFECTIVE_TEMP

Utils.est_temp = (ecosphere_radius, orb_radius, albedo)->
  MATH.sqrt(ecosphere_radius / orb_radius) * MATH.pow1_4((1.0 - albedo) / (1.0 - Constants.EARTH_ALBEDO)) * Constants.EARTH_AVERAGE_KELVIN

###
  The new definition is based on the inital surface temperature and what state water is in.
  If it's too hot, the water will never condense out of the atmosphere, rain down and form an ocean.
  The albedo used here was chosen so that the boundary is about the same as the old method Neither zone,
  nor r_greenhouse are used in this version - Constants.JLB
###

Utils.grnhouse = (r_ecosphere, orb_radius)->
   @eff_temp(r_ecosphere, orb_radius, Constants.GREENHOUSE_TRIGGER_ALBEDO) > Constants.FREEZING_POINT_OF_WATER

###
  The effective temperature given is in units of Kelvin,
    as is the rise in temperature produced by the greenhouse effect, which is returned.
  I tuned this by changing a pow(x,.25) to pow(x,.4) to match Venus - Constants.JLB
  This is Fogg's eq.20, and is also Hart's eq.20 in his "Evolution of Earth's Atmosphere" article.
###

Utils.green_rise = (optical_depth, effective_temp, surf_pressure)->
  convection_factor = Constants.EARTH_CONVECTION_FACTOR * MATH.pow surf_pressure / Constants.EARTH_SURF_PRES_IN_MILLIBARS, 0.4
  rise = (MATH.pow1_4(1.0 + 0.75 * optical_depth) - 1.0) * effective_temp * convection_factor
  MATH.max 0.0, rise

###
  The surface temperature passed in is in units of Kelvin.
  The cloud adjustment is the fraction of cloud cover obscuring each of the three major components of albedo that lie below the clouds.
###

Utils.planet_albedo = (water_fraction, cloud_fraction, ice_fraction, surf_pressure)->
  rock_fraction = 1.0 - water_fraction - ice_fraction
  components  = 0.0
  components += 1.0 if water_fraction > 0.0
  components += 1.0 if ice_fraction   > 0.0
  components += 1.0 if rock_fraction  > 0.0
  cloud_adjustment = cloud_fraction / components
  rock_fraction  = if rock_fraction  >= cloud_adjustment then rock_fraction  - cloud_adjustment else 0.0
  water_fraction = if water_fraction >  cloud_adjustment then water_fraction - cloud_adjustment else 0.0
  ice_fraction   = if ice_fraction   >  cloud_adjustment then ice_fraction   - cloud_adjustment else 0.0
  cloud_part     = cloud_fraction * Constants.CLOUD_ALBEDO
  if surf_pressure is 0.0
    rock_part = rock_fraction * Constants.ROCKY_AIRLESS_ALBEDO
    ice_part = ice_fraction * Constants.AIRLESS_ICE_ALBEDO
    water_part = 0;
  else
    rock_part = rock_fraction * Constants.ROCKY_ALBEDO
    water_part = water_fraction * Constants.WATER_ALBEDO
    ice_part = ice_fraction * Constants.ICE_ALBEDO
  return cloud_part + rock_part + water_part + ice_part

###
  This function returns the dimensionless quantity of optical depth,
    which is useful in determining the amount of greenhouse effect on a planet.
###

Utils.opacity = (molecular_weight, surf_pressure)->
  optical_depth  = 0.0
  optical_depth += 3.0  if (molecular_weight >= 0.0) && (molecular_weight < 10.0)
  optical_depth += 2.34 if (molecular_weight >= 10.0) && (molecular_weight < 20.0)
  optical_depth += 1.0  if (molecular_weight >= 20.0) && (molecular_weight < 30.0)
  optical_depth += 0.15 if (molecular_weight >= 30.0) && (molecular_weight < 45.0)
  optical_depth += 0.05 if (molecular_weight >= 45.0) && (molecular_weight < 100.0)
  if (surf_pressure >= (70.0 * Constants.EARTH_SURF_PRES_IN_MILLIBARS)) then optical_depth *= 8.333;
  else if (surf_pressure >= (50.0 * Constants.EARTH_SURF_PRES_IN_MILLIBARS)) then optical_depth *= 6.666;
  else if (surf_pressure >= (30.0 * Constants.EARTH_SURF_PRES_IN_MILLIBARS)) then optical_depth *= 3.333;
  else if (surf_pressure >= (10.0 * Constants.EARTH_SURF_PRES_IN_MILLIBARS)) then optical_depth *= 2.0;
  else if (surf_pressure >= (5.0 * Constants.EARTH_SURF_PRES_IN_MILLIBARS)) then optical_depth *= 1.5;
  optical_depth

###
  Calculates the number of years it takes for 1/e of a gas to escape from a planet's atmosphere.
  Taken from Dole p. 34. He cites Jeans (1916) & Jones (1923)
###

Utils.gas_life = (molecular_weight)->
  v = Utils.rms_vel.call @, molecular_weight, @exospheric_temp
  g = @surf_grav * Constants.EARTH_ACCELERATION
  r = @radius * Constants.CM_PER_KM
  t = ( MATH.pow3(v) / (2.0 * MATH.pow2(g) * r) ) * MATH.exp (3.0 * g * r) / MATH.pow2(v)
  years = t / (Constants.SECONDS_PER_HOUR * 24.0 * Constants.DAYS_IN_A_YEAR)
  if years > 2.0e10 then Constants.INCREDIBLY_LARGE_NUMBER else years

Utils.min_molec_weight = ->
  loops   = 0
  mass    = @mass
  radius  = @radius
  temp    = @exospheric_temp
  target  = 5.0e9
  guess_1 = Utils.molecule_limit mass, radius, temp
  guess_2 = guess_1
  life    = Utils.gas_life.call @, guess_1
  target = @sun.age if null isnt @sun
  if life > target
    while ((life > target) && (loops++ < 25))
      guess_1 = guess_1 / 2.0
      life = Utils.gas_life.call @, guess_1
  else
    while ((life < target) && (loops++ < 25))
      guess_2 = guess_2 * 2.0;
      life = Utils.gas_life.call @, guess_2
  loops = 0
  while (((guess_2 - guess_1) > 0.1) && (loops++ < 25))
    guess_3 = (guess_1 + guess_2) / 2.0;
    life = Utils.gas_life.call @, guess_3
    if life < target then guess_1 = guess_3
    else guess_2 = guess_3
  life = Utils.gas_life.call @, guess_2
  return guess_2

###
 The temperature calculated is in degrees Kelvin.
 Quantities already known which are used in these calculations:
###

Utils.calculate_surface_temp = (first, last_water, last_clouds, last_ice, last_temp, last_albedo)->
  boil_off = false
  if first
    @albedo = Constants.EARTH_ALBEDO
    effective_temp = Utils.eff_temp @sun.r_ecosphere, @a, @albedo
    greenhouse_temp = Utils.green_rise Utils.opacity(@molec_weight,@surf_pressure), effective_temp, @surf_pressure
    @surf_temp = effective_temp + greenhouse_temp;
    Utils.set_temp_range.call @
  if @greenhouse_effect && @max_temp < @boil_point
    if Constants.verbosity & 0x0010 then console.log "Deluge: %d %d max (%d) < boil (%d)", @sun.name, @planet_no, @max_temp, @boil_point
    @greenhouse_effect = 0
    @volatile_gas_inventory = Utils.vol_inventory @mass, @esc_velocity, @rms_velocity, @sun.mass, @orbit_zone, @greenhouse_effect, (@gas_mass / @mass) > 0.000001
    @surf_pressure = Utils.pressure @volatile_gas_inventory, @radius, @surf_grav
    @boil_point = Utils.boiling_point @surf_pressure
  @hydrosphere = Utils.hydro_fraction @volatile_gas_inventory,@radius
  @cloud_cover = Utils.cloud_fraction @surf_temp, @molec_weight, @radius, @hydrosphere
  @ice_cover = Utils.ice_fraction @hydrosphere, @surf_temp
  @cloud_cover  = 1.0 if @greenhouse_effect && @surf_pressure > 0.0

  if (@high_temp >= @boil_point) && ( not first) && not ( ( parseInt(@day) is parseInt(@orb_period * 24.0)) || @resonant_period )
    @hydrosphere  = 0.0
    boil_off = true
    @cloud_cover = if ( @molec_weight > Constants.WATER_VAPOR ) then 0.0 else 1.0
  @hydrosphere  = 0.0 if @surf_temp < ( Constants.FREEZING_POINT_OF_WATER - 3.0 )
  @albedo = Utils.planet_albedo @hydrosphere, @cloud_cover, @ice_cover, @surf_pressure
  effective_temp = Utils.eff_temp(@sun.r_ecosphere, @a, @albedo);
  greenhouse_temp = Utils.green_rise Utils.opacity(@molec_weight, @surf_pressure), effective_temp, @surf_pressure
  @surf_temp = effective_temp + greenhouse_temp
  unless first
    @hydrosphere = (@hydrosphere + (last_water * 2))  / 3 unless boil_off
    @cloud_cover = (@cloud_cover + (last_clouds * 2)) / 3
    @ice_cover = (@ice_cover   + (last_ice * 2))    / 3
    @albedo = (@albedo      + (last_albedo * 2)) / 3
    @surf_temp = (@surf_temp   + (last_temp * 2))   / 3
  Utils.set_temp_range.call @
  if Constants.verbosity * 0x0200 then console.log "%d AU: %d = %d ef + %d gh%d (W: %d (%d) C: %d (%d) I: %d A: (%d))", @a, @surf_temp - Constants.FREEZING_POINT_OF_WATER, effective_temp - Constants.FREEZING_POINT_OF_WATER, greenhouse_temp, (@greenhouse_effect) ? '*' :' ', @hydrosphere, null, @cloud_cover, null, @ice_cover, @albedo

Utils.iterate_surface_temp = ->
  count = 0
  initial_temp = Utils.est_temp @sun.r_ecosphere, @a, @albedo
  h2_life  = Utils.gas_life.call @, Constants.MOL_HYDROGEN
  h2o_life = Utils.gas_life.call @, Constants.WATER_VAPOR
  n2_life  = Utils.gas_life.call @, Constants.MOL_NITROGEN
  n_life   = Utils.gas_life.call @, Constants.ATOMIC_NITROGEN
  if Constants.verbosity & 0x20000 then console.log "%d:                     %d it [%d re %d a %d alb]", @planet_no, initial_temp, @sun.r_ecosphere, @a, @albedo
  if Constants.verbosity & 0x0040  then console.log "\nGas lifetimes: H2 - %d, H2O - %d, N - %d, N2 - %d", h2_life, h2o_life, n_life, n2_life
  Utils.calculate_surface_temp.call @, true, 0, 0, 0, 0, 0
  for count in [0..25]
    last_water = @hydrosphere
    last_clouds = @cloud_cover
    last_ice = @ice_cover
    last_temp = @surf_temp
    last_albedo = @albedo
    Utils.calculate_surface_temp.call @, false, last_water, last_clouds, last_ice, last_temp, last_albedo
    break if 0.25 > MATH.abs @surf_temp - last_temp
  @greenhs_rise = @surf_temp - initial_temp
  if Constants.verbosity & 0x20000 then console.log "%d: %d gh = %d (%d C) st - %d it [%d re %d a %d alb]", @planet_no, @greenhs_rise, @surf_temp, @surf_temp - Constants.FREEZING_POINT_OF_WATER, initial_temp, @sun.r_ecosphere, @a, @albedo

###
  Inspired partial pressure, taking into account humidification of the air in the nasal passage and throat.
  This formula is on Dole's p. 14
###

Utils.inspired_partial_pressure = (surf_pressure, gas_pressure)->
  pH2O = Constants.H20_ASSUMED_PRESSURE
  fraction = gas_pressure / surf_pressure
  ( surf_pressure - pH2O ) * fraction

###
  This function uses figures on the maximum inspired partial pressures of Oxygen,
    other atmospheric and traces gases as laid out on pages 15, 16 and 18
    of Dole's Habitable Planets for Man to derive breathability of the planet's atmosphere. Constants.JLB
###

Utils.breathability = ->
  gases = ChemTable.gases
  oxygen_ok = false; index = 0
  return 'NONE' if @gases is 0
  for index in [0..@gases]
    gas_no = 0
    ipp = Utils.inspired_partial_pressure @surf_pressure, @atmosphere[index].surf_pressure
    gas_no = n for n in [0..max_gas-1] when gases[n].num is @atmosphere[index].num
    return 'POISONOUS' if ipp > gases[gas_no].max_ipp
    oxygen_ok = ((ipp >= Constants.MIN_O2_IPP) && (ipp <= Constants.MAX_O2_IPP)) if (@atmosphere[index].num is Constants.AN_O)
  if (oxygen_ok) then 'BREATHABLE' else 'UNBREATHABLE'

###
  function for 'soft limiting' temperatures
###

Utils.lim = (x)-> x / MATH.sqrt MATH.sqrt 1 + x*x*x*x
Utils.soft = (v, max, min)->
  dv = v - min;
  dm = max - min;
  ( Utils.lim(2*dv/dm-1) + 1 ) / 2 * dm + min

Utils.set_temp_range = ->
  pressmod = 1 / MATH.sqrt 1 + 20 * @surf_pressure / 1000.0
  ppmod    = 1 / MATH.sqrt 10 + 5 * @surf_pressure / 1000.0
  tiltmod  = MATH.abs(MATH.cos(@axial_tilt * MATH.PI/180) * MATH.pow(1 + @e, 2))
  daymod   = 1 / (200/@day + 1)
  mh = MATH.pow(1 + daymod, pressmod)
  ml = MATH.pow(1 - daymod, pressmod)
  hi = mh * @surf_temp
  lo = ml * @surf_temp
  sh = hi + MATH.pow (100+hi) * tiltmod, MATH.sqrt ppmod
  wl = lo - MATH.pow (150+lo) * tiltmod, MATH.sqrt ppmod
  max = @surf_temp + MATH.sqrt(@surf_temp) * 10
  min = @surf_temp / MATH.sqrt @day + 24
  lo = min if (lo < min)
  wl = 0   if (wl < 0)
  @high_temp = Utils.soft hi, max, min
  @low_temp  = Utils.soft lo, max, min
  @max_temp  = Utils.soft sh, max, min
  @min_temp  = Utils.soft wl, max, min
