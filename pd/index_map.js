
module.exports = class Index {

  constructor(db, keyPath) {

    this.db = db;
    this.keyPath = keyPath;
    this.map = new Map();
    const k = keyPath.split(".");
    const n = "by" + k.map((v) => v[0].toUpperCase() + v.substring(1)).join("");
    this.readPath = eval(`(k,o) => o?.['${k.join("']?.['")}']`);

    this.consume = ([k, o]) => {
      console.log('i+',k);
      const v = this.readPath(k, o);
      let set = this.map.get(v);
      if (set) set.add(k);
      else {
        set = new Set();
        set.add(k);
        this.map.set(v, set);
      }
    };

    db[n] = this;
    db.indexes.push(this);

    this.initialized = db
      .each(this.consume)
      .then(
        (o) => console.debug("indexed", keyPath, Object.keys(this.map)) || true
      );
  }

  delete(k,o) {
    const v = this.readPath(k, o);
    let set = this.map.get(v);
    if (set) set.delete(k);
  }

  purge(k,o) {
    this.map = new Map();
  }

  all() {
    const values = Array.from(this.map.values());
    return Promise.all(
      values.map((set) => Array.from(set).map((k) => this.db.get(k))).flat()
    );
  }

  keys() {
    const values = Array.from(this.map.values());
    return Promise.all(
      values.map((set) => Array.from(set)).flat()
    );
  }

  each(fn) {
    const values = Array.from(this.map.values());
    return Promise.all(
      values
        .map((set) =>
          Array.from(set).map(async (k) => await fn(k, await this.db.get(k)))
        )
        .flat()
    );
  }
}
