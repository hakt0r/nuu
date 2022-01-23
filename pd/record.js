const { v4: uuid } = require("uuid");
const util = require("util");

const SchemaRecord = ({ Schema, $schema, keys, requireds, type, defaults }) => {
  class Record {
    constructor({ id, ...fields }) {
      this.data = {};
      for (const k of keys) {
        const defaultValue = defaults[k];
        const isFunction = typeof defaultValue === "function";
        fields[k] === undefined &&
          (defaultValue && isFunction
            ? (this.data[k] = defaultValue())
            : defaultValue !== undefined &&
              (this.data[k] = clone(defaultValue)));
      }
      this.id = id || uuid();
      Object.assign(this.data, fields);
    }
    async save() {
      await this.$.ready;
      const errors = [];
      for (const k of requireds)
        if (!this.data[k]) errors.push(`required[${k}]`);
      if (errors.length > 0)
        throw new Error(`save error: ${errors.join(", ")}`);
      await this.$.set(this.id, this.data);
      return this;
    }

    delete() {
      return this.$.delete(this.id);
    }
    toJSON = () => ({ ...this.data, id: this.id });
    inspect() {
      return JSON.stringify({ ...this.data, id: this.id }, null, 2);
    }
    static each = (fn) =>
      Record.$.each(([k, r]) => fn(new Record({ id: k, ...r })));
    static forEach = (fn) => Record.$.forEach(fn);
    static all = () => Record.$.all().then((a) => a.map((r) => new Record(r)));
    static find = (query) => {
      const { $post, $filter } = Record;
      return Record.$.find(query, { $schema, $post, $filter });
    };
    static findOne = async (query) => {
      const { $post, $filter } = Record;
      const list = await Record.$.find(query, {
        limit: 1,
        $schema,
        $post,
        $filter,
      });
      return list[0];
    };
    static findById = async (id) => {
      const rec = await Record.$.get(id);
      return new Record({ ...rec, id });
    };
    static findByIdSync = async (id) => {
      const rec = await Record.$.getSync(id);
      return new Record({ ...rec, id });
    };
    static $filter = (cursor) => cursor.toArray();
    static $post = async (id, value, cursor) => {
      if (cursor._populate)
        await Promise.all(
          cursor._populate.map(async (field) => {
            const descriptor = this.$.Model?.fields?.[field];
            if (
              !descriptor ||
              descriptor.type !== $schema.constructor.Types.ObjectId
            )
              return;
            value[field] = await Schema.Types[descriptor.ref].findById(
              value[field]
            );
            //console.log(field, value[field], descriptor);
            return;
          })
        );
      return new Record({ id, ...value });
    };
    static delete = (query) => Record.$.delete(query);
    static deleteOne = (query) => Record.$.deleteOne(query);
  }
  Object.assign(Record.prototype, $schema.methods);

  Object.defineProperties(Record.prototype, {
    $schema: { enumerable: false, value: $schema },
    toJSON: { enumerable: false, value: Record.prototype.toJSON },
    toString: { enumerable: false, value: Record.prototype.toString },
    [util.inspect.custom]: {
      enumerable: false,
      value: Record.prototype.inspect,
    },
    data: { enumerable: false, writable: true },
  });
  return Record;
};

function clone(value) {
  if (typeof value === "object") return JSON.parse(JSON.stringify(value));
  return value;
}

module.exports = SchemaRecord;
