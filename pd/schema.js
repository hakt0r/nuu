const Database = require("./database");
const SchemaRecord = require('./record');

Database.model = ({ db, name, path = name, schema }) => {
  db = db ? db : Database.open({ path });
  db.Model = schema;
  schema.Record.$ = db;
  schema.Record.prototype.$ = db;
  schema.indexes.forEach((key) => db.index(key));
  Object.assign(schema.Record.prototype, schema.methods);
  Schema.Types[name] = schema.Record;
  return schema.Record;
};




class Schema {
  constructor({ methods = {}, ...fields }) {
    Object.entries(fields).map(([k,v]) => fields[k] = typeof v === 'object' && !Array.isArray(v) ? v : {type:v});
    const keys = Object.keys(fields), type = {}, defaults = {};
    keys.forEach((k) => (type[k] = fields[k]?.type || fields[k]));
    keys.forEach((k) => (defaults[k] = fields[k]?.default));
    const requireds = keys.filter((k) => fields[k]?.required);
    this.indexes = keys.filter((k) => fields[k]?.index);
    this.methods = methods;
    this.$on = {};
    const Record = SchemaRecord({Schema,$schema:this,keys,requireds,type,defaults});
    this.Record = Record;
    Object.assign(this, {fields,requireds,defaults,type,Record});
    keys.forEach( key => {
      Object.defineProperty(this.Record.prototype, key, {
        get: function(){ return this.data[key]; },
        set: function(v){ this.data[key] = v; this.$changed = true; },
        enumerable: true
      });
    });
  }
  virtual = (key, fn) => {
    setImmediate(()=> Object.defineProperty(this.Record.prototype, key, fns));
    let fns = {}, ctx = {
      get: (get) => { fns = {...fns,get}; return ctx; },
      set: (set) => { fns = {...fns,set}; return ctx; },
      virtual: this.virtual
    };
    return ctx;
  }
  pre( event, callback ){
    this.$on[event] ? this.$on[event].push(callback) : ( this.$on[event] = [callback] );
  }
  isArray(key){
    const type = this.fields[key]?.type;
    return Array === type || Array.isArray(type);
  }
}

const ObjectId = Symbol("PD_OBJREF");

Schema.type = [String, Number, Boolean, Object, Array];

Schema.Types = {
  String,
  Number,
  Boolean,
  Object,
  Array,
  ObjectId,
};

module.exports = Schema;
