var ContextMenu = function(webSocketService,userTadpole) {

    var contextMenu = this;

    var functions = {
        follow : function() {
            webSocketService.sendTwitterRequest("follow",{id:contextMenu.tadpole.twitter_id});
        },
        unfollow : function() {
            webSocketService.sendTwitterRequest("unfollow",{id:contextMenu.tadpole.twitter_id});
        }
    };

    this.element;
    this.opened = false;
    this.tadpole = null;
    this.userTadpole = userTadpole;

    this.init = function() {
        if(!contextMenu.element) {
            contextMenu.element = document.createElement("div");
            contextMenu.element.id = "contextMenu";

            document.getElementById("ui").appendChild(contextMenu.element);
        }
    };

    var loadFunction = function(functionID) {
        var func = document.createElement("div");
        func.id = func.innerText = functionID;
        func.className = "item";
        func.onclick = function(e) {
            functions[this.id]();
            contextMenu.close();
            e.preventDefault();
            e.stopPropagation();
        }
        contextMenu.element.appendChild(func);
    };

    this.loadFunctions = function() {
        contextMenu.element.innerText = "";

        if(contextMenu.userTadpole.twitter_id == contextMenu.tadpole.twitter_id) {
            return false;
        }
        else if(contextMenu.tadpole.isFriend) {
            loadFunction("unfollow");
            return true;
        }
        else {
            loadFunction("follow");
            return true;
        }
    };
    
    this.open = function(x,y,tadpole) {
        contextMenu.tadpole = tadpole;
        if(contextMenu.userTadpole.authorized && contextMenu.tadpole.authorized && contextMenu.loadFunctions()) {
            contextMenu.element.style.left = x + "px";
            contextMenu.element.style.top = y + "px";
            contextMenu.element.style.display = "block";
    
            contextMenu.opened = true;
        }
    };
    this.close = function() {
        contextMenu.element.style.display = "none";

        contextMenu.opened = false;
        contextMenu.tadpole = null;
    };
    this.init();
}

