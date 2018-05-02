uri = require 'url'
fs = require 'fs'
http = require 'http'
https = require 'https'
DOMParser = require('xmldom').DOMParser

class NodeURLHandler
    @get: (urlstr, headers, timeout, logger, cb) ->
        url = uri.parse(urlstr)
        httpModule = if url.protocol is 'https:' then https else http
        if url.protocol is 'file:'
            fs.readFile url.pathname, 'utf8', (err, data) ->
                return cb(err) if (err)
                xml = new DOMParser().parseFromString(data)
                cb(null, xml)
        else
            data = ''
            options =
                host: url.hostname
                path: url.path
                port: url.port
                headers: headers
            req = httpModule.get options, (res) ->
                res.on 'data', (chunk) ->
                    data += chunk
                res.on 'end', ->
                    xml = new DOMParser().parseFromString(data)
                    unless xml?.documentElement? and xml.documentElement.nodeName is "VAST"
                         logger.error("Error while parsing VAST received for URL: '" + urlstr + "' got: '" + data + "'");
                    cb(null, xml)
            req.setTimeout timeout, () ->
                cb('Request timeout')
            req.on 'error', (err) ->
                cb(err)

module.exports = NodeURLHandler
