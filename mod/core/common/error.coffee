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
  _invalid_msg:   "Invalid message!"
  _no_mount:      "This is a teapot!"
  _no_mounts:     "That seat is made up!"
  _not_mounted:   "Your're not mounted. Don't ask me why..."
  _no_steer:      "You can't steer this mount."

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
  _invalid_msg:   "Kannst du kein Deutsch? Deine Zeichenkette ist keine!"
  _no_mount:      "Der Stuhl ist kaputt... oder ausgedacht :P"
  _no_mounts:     "Das ist ne Pulle Bier oder so und kein Raumschiff; da kann man jdf. nicht einsteigen!"
  _not_mounted:   "Da brat' mir einer einen Storch, du stehst zwischen den Welten."
  _no_steer:      "Das kann man nicht lenken."
