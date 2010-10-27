var ContextMenu = function(webSocketService) {

    var contextMenu = this;

    var options = {
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

    this.init = function() {
        if(!contextMenu.element) {

            contextMenu.element = document.createElement("div");
            contextMenu.element.id = "contextMenu";

            for(var i in options) {
                var currentOption = document.createElement("div");

                currentOption.id = currentOption.innerText = i;
                currentOption.className = "item";

                currentOption.onclick = function(e) {
                    options[this.id]();
                    contextMenu.close();
                    e.stopPropagation();
                    return false;
                };

                contextMenu.element.appendChild(currentOption);
            }

            document.getElementById("ui").appendChild(contextMenu.element);
        }
    };
    this.open = function(x,y,tadpole) {
        contextMenu.element.style.left = x + "px";
        contextMenu.element.style.top = y + "px";
        contextMenu.element.style.display = "block";

        contextMenu.opened = true;
        contextMenu.tadpole = tadpole;
    }
    this.close = function() {
        contextMenu.element.style.display = "none";

        contextMenu.opened = false;
        contextMenu.tadpole = null;
    };
    this.init();
}

