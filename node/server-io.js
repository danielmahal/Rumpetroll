var http = require('http');
var fs = require('fs');

var io = require('./lib/socket.io');

var httpServer = http.createServer(function(req, res) {
	fs.readFile('client-io.html', function(err, data) {
		res.writeHead(200, {'Content-Type': 'text/html'});
		res.write(data, 'utf-8');
		res.end();
	});
});

httpServer.listen(8000);

var server = io.listen(httpServer);

server.on('connection', function(connection) {
	console.log(connection.sessionId + ' connected.');
	
	var name = 'Guest ' + connection.sessionId;

	connection.client = {name: name};
	
	connection.send('Connected as: ' + name);
	connection.send('Type `name:<name>` to change your name');
	connection.broadcast(name + ' connected.');
	
	connection.on('message', function(message) {
		console.log(connection.id + ' sent message: ' + message);
		
		var matches = message.match(/(\w+):\s*(.+)/);

		if (matches) {
			command = matches[1];
			args = matches[2];
			
			if (command == "name") {
				var previousName = connection.client.name;

				connection.client.name = args;
				
				server.broadcast(previousName + ' is now know as ' + args);
			}
		} else {
			server.broadcast(connection.client.name + ': ' + message);
		}
	});
	
	server.on('disconnect', function(connection) {
		console.log(connection.id + ' disconnected.');
		
		server.broadcast(connection.client.name + ' disconnected.');
	});
});

