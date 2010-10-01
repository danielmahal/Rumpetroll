var WaterParticle = function(bounds) {
	var waterParticle = this;
	
	this.x = 0;
	this.y = 0;
	this.z = Math.random() * 1 + 0.3;
	this.size = 1.2;
	this.opacity = Math.random() * 0.8 + 0.1;
	
	this.update = function(bounds) {
		if(waterParticle.x == 0) {
			waterParticle.x = Math.random() * (bounds[1].x * 2) - bounds[1].x;
		}
		
		if(waterParticle.y == 0) {
			waterParticle.y = Math.random() * (bounds[1].y * 2) - bounds[1].y;
		}
		
		if(waterParticle.x < bounds[0].x) {
			waterParticle.x = bounds[1].x;
		}
		
		if(waterParticle.y < bounds[0].y) {
			waterParticle.y = bounds[1].y;
		}
		
		if(waterParticle.x > bounds[1].x) {
			waterParticle.x = bounds[0].x;
		}
		
		if(waterParticle.y > bounds[1].y) {
			waterParticle.y = bounds[0].y;
		}
		
		//waterParticle.opacity += Math.random() * 0.2 - 0.1;
	};
	
	this.draw = function(context) {
		// Draw circle
		context.fillStyle = 'rgba(226,219,226,'+waterParticle.opacity+')';
		//context.fillStyle = '#fff';
		context.beginPath();
		context.arc(waterParticle.x, waterParticle.y, this.z * this.size, 0, Math.PI*2, true);
		context.closePath();
		context.fill();
	};
}
