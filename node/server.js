var http = require('http');
var fs = require('fs');
var ws = require('./lib/ws');
var Tadpole = require('./tadpole').Tadpole;

var server = ws.createServer();

var merge = function(source, destination) {
	for (var property in source) {
		destination[property] = source[property];
	}
}

server.addListener('listening', function() {
	console.log(process.pid + ' listening for connections.');
});

server.addListener('connection', function(connection) {
	console.log(connection.id + ' connected.');
	
	connection.tadpole = new Tadpole(connection.id);
	connection.send(JSON.stringify({type: 'welcome', id: connection.id}));
	
	connection.addListener('message', function(message) {
		console.log(connection.id + ' sent message: ' + message);

		var data = JSON.parse(message);
		
		switch (data.type) {
			case 'update':
				connection.tadpole.update(data);
				
				server.broadcast(JSON.stringify(merge(connection.tadpole, {type: 'update'})));
				break;
			case 'message':
				// TODO: Do db magic
				var message = data.message.substr(0, 45);

				server.broadcast(JSON.stringify({type: 'message', id: connection.id, message: message}));
				break;
		}
	});
	
	server.addListener('close', function(connection) {
		console.log(connection.id + ' disconnected.');
		
		server.broadcast(JSON.stringify({type: 'closed', id: connection.id}));
	});
});

server.listen(8180);