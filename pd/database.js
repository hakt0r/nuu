const { spawnSync } = require("child_process");
const { yellow } = require("colors");
const {
  readFileSync,
  promises: {
    stat,
    readdir,
    mkdir,
    rmdir,
    readFile,
    unlink,
    writeFile,
    symlink,
    readlink,
  },
} = require("fs");

const { join } = require("path");

const Index = require("./index_map");
const Sync = require("./sync");
const Cursor = require("./cursor");

const exists = async (p) =>
  stat(p)
    .then((stat) => stat.isDirectory())
    .catch((e) => false);

class Database {
  constructor(opts = {}) {
    Object.assign(this, opts);
    this.ready = this.init();
    this.cache = new Map();
    this.readPromise = {};
    this.indexes = [];
    new Sync(this);
  }

  async init() {
    if (await this.create()) return this;
    if (await this.open()) return this;
    throw new Error(`pd could not open: ${this.path}`);
  }

  async create() {
    let doesExist = await exists(this.path);
    if (!this.forceCreate && doesExist) return false;
    if (doesExist) await this.purge();
    await mkdir(this.path, { recursive: true });
    if (!(await this.open())) return false;
    if (this.onCreate) await this.onCreate();
  }

  async open() {
    try {
      await readdir(this.path);
      return true;
    } catch (e) {
      console.debug(e);
    }
    return false;
  }

  async set(key, value) {
    this.cache.set(key, value);
    this.indexes.forEach((i) => i.consume([key, value]));
    return this.nextSync.add(key, value);
  }

  async all() {
    let all = this.forEach();
    let done, value, result = [];
    while (({ done, value } = await all.next())) {
      if (done) break;
      result.push(value[1]);
    }
    return result;
  }

  async each(fn) {
    let all = this.forEach();
    let done,
      value,
      result = [];
    Object.assign(this, { result });
    while (({ done, value } = await all.next())) {
      if (done) break;
      result.push(fn([value[0], value[1]]));
    }
    return Promise.all(result);
  }

  async *forEach() {
    const files = await readdir(this.path).then((files) =>
      files.map((f) => f.replace(/.json$/, ""))
    );
    const cached = Array.from(this.cache.entries());
    const uncached = files.filter((f) => !this.cache.has(f));
    for (const entry of cached) yield entry;
    for (const key of uncached) yield [key, await this.get(key)];
  }

  async get(key) {
    const cachedValue = this.cache.get(key);
    if (cachedValue !== undefined) return cachedValue;
    const beingRead = this.readPromise[key];
    if (beingRead) return beingRead;
    return (this.readPromise[key] = new Promise(async (resolve) => {
      try {
        const file = join(this.path, key + ".json");
        const data = await readFile(file, "utf-8");
        const json = JSON.parse(data);
        this.cache.set(key, json);
        this.indexes.forEach((i) => i.consume([key, json]));
        delete this.readPromise[key];
        resolve(json);
      } catch (e) {
        //console.log(e.code === 'ENOENT' ? `Cannot read: ${file}`: console.log(e))
        resolve(undefined);
      }
    }));
  }

  async getSync(key) {
    const cachedValue = this.cache.get(key);
    if (cachedValue !== undefined) return cachedValue;
    return (this.readPromise[key] = new Promise(async (resolve) => {
      try {
        const file = join(this.path, key + ".json");
        const data = readFileSync(file, "utf-8");
        const json = JSON.parse(data);
        this.cache.set(key, json);
        this.indexes.forEach((i) => i.consume([key, json]));
        resolve(json);
      } catch (e) {
        //console.log(e.code === 'ENOENT' ? `Cannot read: ${file}`: console.log(e))
        resolve(undefined);
      }
    }));
  }

  async delete(key) {
    const value = await this.get(key);
    if (value === undefined) return;
    const file = join(this.path, key + ".json");
    if (this.cache.has(key)) this.cache.delete(key);
    this.indexes.forEach((i) => i.delete(key, value));
    await unlink(file);
  }

  deleteOne(condition) {}

  async purge() {
    this.cache = new Map();
    await rmdir(this.path, { recursive: true });
    this.indexes.forEach((i) => i.purge());
    console.debug("pd purged");
  }
  find(query, opts = {}) {
    return new Cursor({$db:this, query, opts}).exec();
  }
  findOne(query, opts = {}) {
    return new Cursor({$db:this, query, opts:{ ...opts, limit: 1 }}).exec().then(s=>s.toArray()[0]);
  }

  index(keyPath, fn) {
    new Index(this, keyPath, fn);
  }
}

Database.open = (opts) => new Database(opts);
Database.create = (opts) => new Database({ ...opts, forceCreate: true });

module.exports = Database;
