var Tadpole = function(id) {
	var self = this;
	
	self.id = id;
	self.name = '';
	
	self.pos = {x: 0, y: 0};
	self.drive = {x: 0, y: 0};
	self.momentum = 0;
	self.angle = 0;
	
	self.update = function(data) {
		self.name = (data.name || 'Guest ' + id).substr(0, 45);
		
		self.pos.x = data.x || 0;
		self.pos.y = data.y || 0;
		self.drive.x = data.vx || 0;
		self.drive.y = data.vy || 0;
		self.momentum = data.momentum || 0;
		self.angle = data.angle || 0;
	}
}

exports.Tadpole = Tadpole;