
class Cursor {
  constructor({ $schema, $db, query, opts = {} }) {
    Object.assign(this, { $schema, $db, ...opts });
    this.limit = this.limit || Infinity;
    this._populate = [];
    const { $or, $and, ...fields } = query;
    if (!$or && !$and) this.query = this.evaluate(fields);
    if ($or) this.query = this.$or($or);
    if ($and) this.query = this.$and([$and]);
    this.query = this.query || "true";
    //console.debug("QUERY:", this.query);
  }
  exec() {
    const test = eval(`([key,json]) => { return ${this.query}; }`);
    const done = new Promise(async (resolve) => {
      let all = this.$db.forEach();
      let count = 0,
        done,
        value;
      const result = new Map();
      Object.assign(this, { result });
      while (({ done, value } = await all.next())) {
        if (done) break;
        if (!test(value)) continue;
        let [id, record] = value;
        this.$post && ( record = await this.$post(id, record, this) );
        result.set(id, record);
        if (count++ > this.limit) break;
      }
      resolve(this.$filter ? this.$filter.call(this, this) : this);
    });
    this.done = new Proxy(done, {
      get: (_, key) => {
        const target = !!done[key] ? done : this;
        const value = target[key];
        if (!!value && typeof value === "function") return value.bind(target);
        return value;
      },
    });
    return this.done;
  }
  populate(...rules) {
    this._populate = [...this._populate, ...rules];
    return this.done;
  }
  async toArray() {
    return Array.from(this.result.values());
  }
  $logical(operator, operands, path = "json") {
    if (operands.length === 0) return "";
    return `(${operands
      .map((rules) => this.evaluate(rules, path))
      .filter((s) => !!s)
      .join(`) ${operator} (`)})`;
  }
  $and = (operands, path) => this.$logical("&&", operands, path);
  $or = (operands, path) => this.$logical("||", operands, path);
  evaluate(rules, path = "json") {
    const accessor = (k) => [path, "[" + JSON.stringify(k) + "]"].join("?.");
    const entries = Object.entries(rules);
    if (entries.length === 0) return "";
    const match = (path, key, rule) => {
      switch (key) {
        case "$regex":
          return `!! (${rule.toString()}).test(${path})`;
        default:
          return `${path} === ${JSON.stringify(rule)}`;
      }
    };
    return `(${entries
      .map(([key, rule]) => {
        const path = accessor(key);
        if (rule instanceof RegExp) return match(path, key, rule);
        if (this.$schema.isArray(key))
          return `${path}?.some(value => ${match("value", key, rule)})`;
        //else if ( this.schema.isObject(path) )
        return match(path, key, rule);
      })
      .join("")})`;
  }
}

module.exports = Cursor;
