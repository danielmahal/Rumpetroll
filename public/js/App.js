

var App = function(aCanvas) {
	var app = this;
	
	var 	model,
			canvas,
			context,
			webSocket,
			webSocketService,
			mouse = {x: 0, y: 0, worldx: 0, worldy: 0}
	;
	
	app.update = function() {
		// Update usertadpole
		if(model.userTadpole) {
			var mvp = getMouseWorldPosition();
			mouse.worldx = mvp.x;
			mouse.worldy = mvp.y;
			
			model.userTadpole.setAngle(mouse.worldx, mouse.worldy);
			
			model.userTadpole.userUpdate(model.tadpoles);
			
			if(model.userTadpole.age % 6 == 0) {
				webSocketService.sendUpdate(model.userTadpole);
			}
			
			model.camera.update(model);
		}
		
		// Update tadpoles
		for(id in model.tadpoles) {
			model.tadpoles[id].update();
		}
		
		// Update waterParticles
		for(i in model.waterParticles) {
			model.waterParticles[i].update(model.camera.getOuterBounds());
		}
		
		// Update arrows
		for(i in model.arrows) {
			var cameraBounds = model.camera.getBounds();
			var arrow = model.arrows[i];
			arrow.update();
		}
	};
	
	
	
	app.draw = function() {
		model.camera.setupContext();
		
		// Draw waterParticles
		for(i in model.waterParticles) {
			model.waterParticles[i].draw(context);
		}
		
		// Draw tadpoles
		for(id in model.tadpoles) {
			model.tadpoles[id].draw(context);
		}
		
		// Start UI layer (reset transform matrix)
		model.camera.startUILayer();
		
		// Draw arrows
		for(i in model.arrows) {
			model.arrows[i].draw(context, canvas);
		}
	};
	
	
	
	
	app.onSocketOpen = function(e) {
		console.log('Socket opened!', e);
	};
	
	app.onSocketClose = function(e) {
		console.log('Socket closed!', e);
		webSocketService.connectionClosed();
	};
	
	app.onSocketMessage = function(e) {
		webSocketService.processMessage(JSON.parse(e.data));
	};
	
	app.sendMessage = function(msg) {
		webSocketService.sendMessage(msg);
	}
	
	app.mousedown = function(e) {
		mouse.clicking = true;
		
		if(model.userTadpole && e.which == 1) {
			model.userTadpole.momentum = model.userTadpole.targetMomentum = model.userTadpole.maxMomentum;
		}
	};
	
	app.mouseup = function(e) {
		if(model.userTadpole && e.which == 1) {
			model.userTadpole.targetMomentum = 0;
		}
	};
	
	app.mousemove = function(e) {
		mouse.x = e.clientX;
		mouse.y = e.clientY;
	};
	
	
	
	app.resize = function(e) {
		resizeCanvas();
	};
	
	var getMouseWorldPosition = function() {
		return {
			x: (mouse.x + (model.camera.x * model.camera.zoom - canvas.width / 2)) / model.camera.zoom,
			y: (mouse.y + (model.camera.y * model.camera.zoom  - canvas.height / 2)) / model.camera.zoom
		}
	}
	
	var resizeCanvas = function() {
		canvas.width = window.innerWidth;
		canvas.height = window.innerHeight;
	};
	
	// Constructor
	(function(){
		canvas = aCanvas;
		context = canvas.getContext('2d');
		resizeCanvas();
		
		model = new Model();
		model.camera = new Camera(canvas, context);
		
		model.arrows = {};
		
		webSocket 				= new WebSocket('ws://rumpetroll.six12.co:8180');
		webSocket.onopen 		= app.onSocketOpen;
		webSocket.onclose		= app.onSocketClose;
		webSocket.onmessage 	= app.onSocketMessage;
		
		webSocketService		= new WebSocketService(model, webSocket);
	})();
}
