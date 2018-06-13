Error.byKey = {}
Error.byId = {}
Error.i18 = {}

Error.register = (opts)->
  id = 0
  for key, msg of opts
    @byKey[key] = id
    @byId[id] = msg
    @[key] = msg
    id++
  null

Error.register
  _invalid_item:  "Invalid item id :o"
  _no_handle:     "I don't have a cookie for you. :<"
  _no_fuel:       "You don't have enough fuel!"
  _no_slot_type:  "You made this slot type up!"
  _no_slot:       "This slot does not exist."
  _no_vehicle:    "You're naked!"
  _not_here:      "You can't do this here :("
  _not_in_orbit:  "You're not orbiting anything!?"
  _not_landed:    "You must land at a certified service station."
  _not_the_owner: "You don't own this ship."
  _nx_jump:       "404 - Target not found"
  _nx_target:     "404 - Target not found"

Error.i18.de =
  _invalid_item:  "Gibbet nich!"
  _no_handle:     "Beweis dich erstmal selbst! :>"
  _no_fuel:       "Nicht genug Sprit!"
  _no_slot_type:  "Den Slot-Typ hast du dir doch ausgedacht! :>"
  _no_slot:       "Den Slot kann ich nicht finden o0"
  _no_vehicle:    "Du bist Splitterfasernackt, echt jetzt! :D"
  _not_here:      "Kannst hier so nich machen, tut mir leid!"
  _not_in_orbit:  "Such dir erstmal ein Orbit..."
  _not_landed:    "Das muss der Fachmann machen. :<"
  _not_the_owner: "Das is' nich' dein Schiff o0"
  _nx_jump:       "Wohin denn bitte?"
  _nx_target:     "Wen denn bitte?"
