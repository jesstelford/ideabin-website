var restify = require('restify'),
    fs = require('fs'),
    server,
    VERSION = "1.0.0",
    PORT = 8080;

/*
 * POST /api/v1.0.0/idea
 * GET /api/v1.0.0/idea/{id}
 * POST /api/v1.0.0/idea/{id}/comment
 * GET /api/v1.0.0/idea/{id}/comment
 */

// Check for generated keys
if (!fs.existsSync('./cert.pem') || !fs.existsSync('./key.pem')) {
  return console.error("Certificate not found.\n\nGenerate a self-signed certificate with:\n\n> make generate-certs");
}

// Initialize our server
server = restify.createServer({
  certificate: fs.readFileSync('./cert.pem'),
  key: fs.readFileSync('./key.pem'),
  name: require('./package.json').name,
  version: VERSION

  // TODO
});

// Close the connection for curl immediately
server.pre(restify.pre.userAgentConnection());

// Parse JSON bodies, etc
server.use(restify.bodyParser());

// Rate limit API requests, sends 429 Too Many Requests on throttle
server.use(restify.throttle({
  burst: 100,
  rate: 50, // requests per second
  ip: true, // throttle based on ip
  // username: true, // throttle based on req.username
  overrides: {
    '192.168.1.1': {
      rate: 0,        // unlimited
      burst: 0
    }
  }
}));

// Make sure we can respond to what was asked for (HTTP 406 if not)
server.use(restify.acceptParser(server.acceptable));

// parse the query string, but don't override params with query values of the
// same key
server.use(restify.queryParser({ mapParams: false }));

// Allow JSONP requests (will look for 'callback' or 'jsonp' query strings)
server.use(restify.jsonp());

// If client sends 'accept-encoding: gzip' header, gzip it for them!
server.use(restify.gzipResponse());



server.get('/api/v1.0.0/idea/:id', function(req, res, next) {

  res.json({foo: 'bar'});

  // Stop handling routes here
  return next(false);
});

sever.listen(PORT, function() {
  console.log('%s listening at %s', server.name, server.url);
});
