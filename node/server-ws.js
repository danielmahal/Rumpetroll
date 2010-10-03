var http = require('http');
var fs = require('fs');

var ws = require('./lib/websocket-server/lib/ws');

var httpServer = http.createServer(function(req, res) {
	fs.readFile('client-ws.html', function(err, data) {
		res.writeHead(200, {'Content-Type': 'text/html'});
		res.write(data, 'utf-8');
		res.end();
	});
});

var server = ws.createServer(httpServer);

server.addListener('listening', function() {
	console.log(process.pid + ' listening for connections.');
});

server.addListener('connection', function(connection) {
	console.log(connection.id + ' connected.');
	
	var name = 'Guest ' + connection.id;

	connection.storage.set('name', name);
	
	connection.send('Connected as: ' + name);
	connection.send('Type `name:<name>` to change your name');
	connection.broadcast(name + ' connected.');
	
	connection.addListener('message', function(message) {
		console.log(connection.id + ' sent message: ' + message);
		
		var matches = message.match(/(\w+):\s*(.+)/);

		if (matches) {
			command = matches[1];
			args = matches[2];
			
			if (command == "name") {
				var previousName = connection.storage.get('name');

				connection.storage.set('name', args);
				
				server.broadcast(previousName + ' is now know as ' + args);
			}
		} else {
			server.broadcast(connection.storage.get('name') + ': ' + message);
		}
	});
	
	server.addListener('close', function(connection) {
		console.log(connection.id + ' disconnected.');
		
		server.broadcast(connection.storage.get('name') + ' disconnected.');
	});
});

server.listen(8000);