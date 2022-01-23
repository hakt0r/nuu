
require('colors')
const { join } = require("path");
const { promises: { writeFile } } = require("fs");

module.exports = class Sync {
  constructor(db, prev) {
    this.db = db;
    this.value = {};
    this.promise = new Promise((resolve) => (this.resolve = resolve));
    if (prev) this.prev = prev;
    else {
      this.prev = { promise: Promise.resolve() };
      db.nextSync = this;
    }
  }
  add(key, value) {
    this.value[key] = value;
    this.trigger || (this.trigger = setImmediate(this.write));
    return this.promise;
  }
  write = async () => {
    const { db, prev, value } = this;
    const { path, stringify = [] } = db;
    const time = Date.now();
    const recs = Object.entries(value);
    db.nextSync = new Sync(db, this);
    this.add = () => console.error("pd writing to a dead sync");
    await prev.promise;
    await Promise.all(
      recs.map(([key, value]) => {
        const file = join(path, key + ".json");
        const json = JSON.stringify(value, ...stringify);
        return writeFile(file, json);
      })
    );
    console.debug(
      `${'pd'.gray} ${this.db.path.white.bold} ${'sync complete:'.gray}`,
      Math.round(recs.length / ((Date.now() - time) / 1000)),
      "r/s".gray
    );
    this.resolve(true);
  };
}