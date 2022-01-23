
const Database = require("./database");
const Schema = require("./schema");

async function monogoImport() {
  require("dotenv").config();
  var MongoClient = require("mongodb").MongoClient;
  const c = await MongoClient.connect(process.env.DB, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  });
  const d = await c.db("ax-zone");
  const collections = (await (await d.listCollections()).toArray()).map(
    (c) => c.name
  );
  const db = {}, all = {}, list = {};
  await Promise.all( collections.map(async (c) => {
    const cname = c[0].toUpperCase() + c.replace(/s$/,'').substring(1);
    const q = await d.collection(c).find();
    all[c] = await q.toArray();
    db[c] = Database.create({ path: "config/" + c, stringify: [null, 2] });
    await db[c].ready;
    all[c].forEach(v=>list[v._id] =v);
    console.log( cname.blue.bold );
  }));
  const getRefId = o => o?.name || o?.fqdn || o?._id;
  const getRefs = o => Object.entries(o).forEach(getRef(o));
  const getRef = o => ([k,v]) => {
    if ( v?.toString()?.length == 24 ) o[k] = getRefId(list[v]);
    else if ( Array.isArray(v) ) v.forEach((x,k)=>getRef(v)([k,x]));
    else if ( typeof v === 'object' ) getRefs(v);
  }
  await Promise.all( collections.map((c) => all[c].map(({ _id, __v, ...item }) => {
    const name = getRefId({_id,...item});
    getRefs(item);
    console.log(' -'.bold, c.blue.bold, _id.toString().match(/(.{4})$/)[1], name );
    return db[c].set(name, item);
  })));
}


monogoImport();