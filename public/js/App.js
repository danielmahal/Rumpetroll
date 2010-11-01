

var App = function(aSettings, aCanvas) {
	var app = this;
	
	var 	model,
			canvas,
			context,
			webSocket,
			webSocketService,
			mouse = {x: 0, y: 0, worldx: 0, worldy: 0, tadpole:null},
			keyNav = {x: 0,y: 0,currentX: 0, currentY: 0, active: false},
			messageQuota = 5
	;
	
	app.update = function() {
	  if (messageQuota < 5 && model.userTadpole.age % 50 == 0) { messageQuota++; }
	  
		// Update usertadpole
		if(keyNav.x != 0 || keyNav.y != 0) {
			model.userTadpole.userUpdate(model.tadpoles, model.userTadpole.x + keyNav.x,model.userTadpole.y + keyNav.y);
		}
		else if(!keyNav.active) {
			var mvp = getMouseWorldPosition();
			mouse.worldx = mvp.x;
			mouse.worldy = mvp.y;
            //console.log("worldx: " + mouse.worldx);
            //console.log("worldy: " + mouse.worldy);
			model.userTadpole.userUpdate(model.tadpoles, mouse.worldx, mouse.worldy);
		}
        else model.userTadpole.userUpdate(model.tadpoles, model.userTadpole.x + keyNav.currentX,model.userTadpole.y + keyNav.currentY)
		
		if(model.userTadpole.age % 6 == 0 && model.userTadpole.changed > 1 && webSocketService.hasConnection) {
			model.userTadpole.changed = 0;
			webSocketService.sendUpdate(model.userTadpole);
		}
		
		model.camera.update(model);
		
		// Update tadpoles
		for(id in model.tadpoles) {
			model.tadpoles[id].update(mouse,model.userTadpole.friends);
		}
		
		// Update waterParticles
		for(i in model.waterParticles) {
			model.waterParticles[i].update(model.camera.getOuterBounds(), model.camera.zoom);
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
        app.tryRestoreSession();
	};
	
	app.onSocketClose = function(e) {
		//console.log('Socket closed!', e);
		webSocketService.connectionClosed();
	};
	
	app.onSocketMessage = function(e) {
		try {
			var data = JSON.parse(e.data);
			webSocketService.processMessage(data);
		} catch(e) {}
	};
	
	app.sendMessage = function(msg) {
	  
	  if (messageQuota>0) {
	    messageQuota--;
	    webSocketService.sendMessage(msg);
	  }
	}
	
	app.authorize = function(token,verifier) {
		webSocketService.authorize(token,verifier);
	}
    app.deauthorize = function() {
        delete localStorage["request_token"];
        delete localStorage["request_verifier"];
        webSocketService.deauthorize();
    }

    app.tryRestoreSession = function() {
        if(localStorage["request_token"] && localStorage["request_verifier"]) {
            app.authorize(localStorage["request_token"], localStorage["request_verifier"]);
        }
    }
	
	app.mousedown = function(e) {
		mouse.clicking = true;
        keyNav.active = false;
        if(model.userTadpole.contextMenu && model.userTadpole.contextMenu.opened && e.target.className != "item") {
            model.userTadpole.contextMenu.close();
            return false;
        }

		if(mouse.tadpole && mouse.tadpole.hover && mouse.tadpole.onclick(e)) {
            return false;
		}

		if(model.userTadpole && e.which == 1) {
			model.userTadpole.momentum = model.userTadpole.targetMomentum = model.userTadpole.maxMomentum;
		}

	};

	app.mouseup = function(e) {
		if(model.userTadpole && e.which == 1) {
			model.userTadpole.targetMomentum = 0;
		}
	};
	
    app.oncontextmenu = function(e) {
   		if(mouse.tadpole && mouse.tadpole.hover && model.userTadpole.authorized) {            
            model.userTadpole.contextMenu.open(e.clientX,e.clientY,mouse.tadpole);
            return false;
		}
    };

	app.mousemove = function(e) {
		mouse.x = e.clientX;
		mouse.y = e.clientY;
	};
   
    keyNav.validKeyCode = function(keyCode) {
        return keyCode == keys.up || keyCode == keys.down || keyCode == keys.left || keyCode == keys.right;
    }; 
   
	app.keydown = function(e) {
        if(keyNav.validKeyCode(e.keyCode)) {
		    switch(e.keyCode) {
                case keys.up:
    			    keyNav.y = -1;
                    break;
            	case keys.down:
			        keyNav.y = 1;
                    break;
    		    case keys.left:
	    		    keyNav.x = -1;
                    break;
		        case keys.right:
    			    keyNav.x = 1;
                    break;
		    }
            e.preventDefault();
			model.userTadpole.momentum = model.userTadpole.targetMomentum = model.userTadpole.maxMomentum;
            keyNav.currentX = keyNav.x;
            keyNav.currentY = keyNav.y;
            keyNav.active = true;
        }
	};

	app.keyup = function(e) {
        if(keyNav.validKeyCode(e.keyCode)) {
		    if(e.keyCode == keys.up || e.keyCode == keys.down) {
			    keyNav.y = 0;
		    }
		    else if(e.keyCode == keys.left || e.keyCode == keys.right) {
			    keyNav.x = 0;
		    }

		    if(keyNav.x == 0 && keyNav.y == 0) {
        		model.userTadpole.targetMomentum = 0;
		    }
    	    e.preventDefault();
        }
	};
	
	app.touchstart = function(e) {
	  e.preventDefault();
	  mouse.clicking = true;		
		
		if(model.userTadpole) {
			model.userTadpole.momentum = model.userTadpole.targetMomentum = model.userTadpole.maxMomentum;
		}
		
		var touch = e.changedTouches.item(0);
    if (touch) {
      mouse.x = touch.clientX;
  		mouse.y = touch.clientY;      
    }    
	}
	app.touchend = function(e) {
	  if(model.userTadpole) {
			model.userTadpole.targetMomentum = 0;
		}
	}
	app.touchmove = function(e) {
	  e.preventDefault();
    
    var touch = e.changedTouches.item(0);
    if (touch) {
      mouse.x = touch.clientX;
  		mouse.y = touch.clientY;      
    }		
	}
	
	
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
		model.settings = aSettings;
		
		model.userTadpole = new Tadpole();
		model.userTadpole.id = -1;
		model.userTadpole.friends = [];
		model.tadpoles[model.userTadpole.id] = model.userTadpole;


		model.waterParticles = [];
		for(var i = 0; i < 150; i++) {
			model.waterParticles.push(new WaterParticle());
		}
		
		model.camera = new Camera(canvas, context, model.userTadpole.x, model.userTadpole.y);
		
		model.arrows = {};
		
		webSocket 				= new WebSocket( model.settings.socketServer );
		webSocket.onopen 		= app.onSocketOpen;
		webSocket.onclose		= app.onSocketClose;
		webSocket.onmessage 	= app.onSocketMessage;
		
		webSocketService		= new WebSocketService(model, webSocket);
	})();
}
