
module.exports = (destinationFile,callback)->
  fs = require 'fs'
  o = '<ul class="libs">'
  d = JSON.parse fs.readFileSync 'package.json', 'utf8'
  for lib, data of targets.client.contrib
    o += """
      <li><a target="_new" href="#{data.homepage}">#{data.name} (build/#{lib})</a><span class="version">master/git<span></li>
    """
  for k in fs.readdirSync 'node_modules'
    if fs.existsSync 'node_modules/' + k + '/package.json'
      rec = JSON.parse fs.readFileSync 'node_modules/' + k + '/package.json'
      v = rec.version
    else if d.dependencies[k] then v = d.dependencies[k]
    else continue
    o += """<li><a target="_new" href="https://www.npmjs.com/package/#{k}">#{k}</a>"""
    o += """<span class="version">#{v}</span>"""
    # o += """<span class="description">#{rec.description}</span>""" if rec.description
    o += "</li>"
  o += '</ul>'
  fs.writeFileSync destinationFile, o
  callback null
