var Color = function(r,g,b,a) {
    this.r = r || 255;
    this.g = g || 255;
    this.b = b || 255;
    this.a = a || 1;
    
    this.clone = function() {
        return new Color(this.r,this.g,this.b,this.a);
    };
    
    this.toString = function() {
        return "rgba(" + this.r.toFixed(0) + "," + this.g.toFixed(0) + "," + this.b.toFixed(0) + "," +this.a + ")";
    };
};
var FadingColor = function(color,rate) {
    var fadingColor = this;
    this.currentColor = color.clone();
    this.targetColor = color.clone();
    this.rate = rate;
    
    var increment = function(currentVar,targetVar) {
        if(Math.abs(currentVar - targetVar) <= rate) {
            return currentVar;
        }
        if(currentVar < targetVar) {
            return currentVar + fadingColor.rate;
        }
        else if(currentVar > targetVar) {
            return currentVar - fadingColor.rate;
        }
        else return currentVar;
    };
    
    this.nextIncrement = function() {
        fadingColor.currentColor.r = increment(fadingColor.currentColor.r,fadingColor.targetColor.r);
        fadingColor.currentColor.g = increment(fadingColor.currentColor.g,fadingColor.targetColor.g);
        fadingColor.currentColor.b = increment(fadingColor.currentColor.b,fadingColor.targetColor.b);
        return fadingColor.currentColor;
    };
    
};

var statusColors = {
    none:  new Color(226,219,226),
    hover: new Color(182, 243, 237),
    follower: new Color(255,200,126)
};
