var Camera = function(aCanvas, aContext) {
	var camera = this;
	
	var canvas = aCanvas;
	var context = aContext;
	
	this.x = 0;
	this.y = 0;
	
	this.minZoom = 1.3;
	this.maxZoom = 1.8;
	this.zoom = 1.8;
	
	this.setupContext = function() {
		var translateX = canvas.width / 2 - camera.x * camera.zoom;
		var translateY = canvas.height / 2 - camera.y * camera.zoom;
		
		// Reset transform matrix
		context.setTransform(1,0,0,1,0,0);
		context.clearRect(0,0,canvas.width, canvas.height);
		
		context.translate(translateX, translateY);
		context.scale(camera.zoom, camera.zoom);
	};
	
	this.update = function(model) {
		var targetZoom = (model.camera.maxZoom + (model.camera.minZoom - model.camera.maxZoom) * Math.min(model.userTadpole.momentum, model.userTadpole.maxMomentum) / model.userTadpole.maxMomentum);
		model.camera.zoom += (targetZoom - model.camera.zoom) / 60;
		var delta = {
			x: (model.userTadpole.x - model.camera.x) / 30,
			y: (model.userTadpole.y - model.camera.y) / 30
		}
		
		if(Math.abs(delta.x) + Math.abs(delta.y) > 0.1) {
			model.camera.x += delta.x;
			model.camera.y += delta.y;
			
			for(var i = 0, len = model.waterParticles.length; i < len; i++) {
				var wp = model.waterParticles[i];
				wp.x -= (wp.z - 1) * delta.x;
				wp.y -= (wp.z - 1) * delta.y;
			}
		}
	};
	
	// Gets bounds of current zoom level of current position
	this.getBounds = function() {
		return [
			{x: camera.x - canvas.width / 2 / camera.zoom, y: camera.y - canvas.height / 2 / camera.zoom},
			{x: camera.x + canvas.width / 2 / camera.zoom, y: camera.y + canvas.height / 2 / camera.zoom}
		];
	};
	
	// Gets bounds of minimum zoom level of current position
	this.getOuterBounds = function() {
		return [
			{x: camera.x - canvas.width / 2 / camera.minZoom, y: camera.y - canvas.height / 2 / camera.minZoom},
			{x: camera.x + canvas.width / 2 / camera.minZoom, y: camera.y + canvas.height / 2 / camera.minZoom}
		];
	};
	
	// Gets bounds of maximum zoom level of current position
	this.getInnerBounds = function() {
		return [
			{x: camera.x - canvas.width / 2 / camera.maxZoom, y: camera.y - canvas.height / 2 / camera.maxZoom},
			{x: camera.x + canvas.width / 2 / camera.maxZoom, y: camera.y + canvas.height / 2 / camera.maxZoom}
		];
	};
	
	this.startUILayer = function() {
		context.setTransform(1,0,0,1,0,0);
	}
};