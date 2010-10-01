var WebSocketService = function(model, webSocket) {
	var webSocketService = this;
	
	var webSocket = webSocket;
	var model = model;
	
	this.welcomeHandler = function(data) {
		// Create userTapole
		model.userTadpole = new Tadpole();
		model.userTadpole.id = data.id;
		
		// model.userTadpole.x = Math.random() * 200 - 100;
		// model.userTadpole.y = Math.random() * 200 - 100;
		
		$('#chat').initChat();
		
		//model.userTadpole.messages.push(new Message('Yo!'));
		//model.userTadpole.messages.push(new Message('Det er her det skjer?'));
		
		model.tadpoles[model.userTadpole.id] = model.userTadpole;
		
		createWaterParticles();
	};
	
	this.updateHandler = function(data) {
		var newtp = false;
		
		if(!model.tadpoles[data.id]) {
			newtp = true;
			model.tadpoles[data.id] = new Tadpole();
			model.arrows[data.id] = new Arrow(model.tadpoles[data.id], model.camera);
		}
		
		var tadpole = model.tadpoles[data.id];
		
		if(tadpole.id == model.userTadpole.id) {
			if(!model.userTadpole.name) {
				tadpole.name = data.name;
			}
			return;
		} else {
			tadpole.name = data.name;
		}
		
		if(newtp) {
			tadpole.x = data.x;
			tadpole.y = data.y;
		} else {
			tadpole.targetX = data.x;
			tadpole.targetY = data.y;
		}
		
		tadpole.angle = data.angle;
		tadpole.momentum = data.momentum;
	}
	
	this.messageHandler = function(data) {
		var tadpole = model.tadpoles[data.id];
		if(!tadpole) {
			return;
		}
		
		tadpole.messages.push(new Message(data.message));
	}
	
	this.closedHandler = function(data) {
		if(model.tadpoles[data.id]) {
			delete model.tadpoles[data.id];
			delete model.arrows[data.id];
		}
	}
	
	this.processMessage = function(data) {
		var fn = webSocketService[data.type + 'Handler'];
		if (fn) {
			fn(data);
		}
	}
	
	this.connectionClosed = function() {
		if(!model.userTadpole) {
			model.userTadpole = new Tadpole();
			model.tadpoles[model.userTadpole.id] = model.userTadpole;
			
			createWaterParticles();
		}
		
		$('#cant-connect').fadeIn(300);
	};
	
	this.sendUpdate = function(tadpole) {
		var sendObj = {
			type: 'update',
			x: tadpole.x.toFixed(1),
			y: tadpole.y.toFixed(1),
			angle: tadpole.angle.toFixed(3),
			momentum: tadpole.momentum.toFixed(3)
		};
		
		if(tadpole.name) {
			sendObj['name'] = tadpole.name.substr(0, 30);
		}
		
		webSocket.send(JSON.stringify(sendObj));
	}
	
	this.sendMessage = function(msg) {
		var regexp = /name: ?(.+)/i;
		if(regexp.test(msg)) {
			model.userTadpole.name = msg.match(regexp)[1];
			return;
		}
		
		var sendObj = {
			type: 'message',
			message: msg.substr(0, 140)
		};
		
		webSocket.send(JSON.stringify(sendObj));
	}
	
	var createWaterParticles = function() {
		var bounds = model.camera.getBounds();
		model.waterParticles = [];
		for(var i = 0; i < 50; i++) {
			model.waterParticles.push(new WaterParticle(bounds));
		}
	}
}