// Settings controls

(function($){
	
	$.fn.initChat = function() {
		var input = $(this);
		var chatview = $('#chatview');
		
		var esc = 27;
		var enter = 13;
		
		var closechat = function() {
			chatview.fadeOut(200, function() {
				chatview.text('');
			});
			input.val('');
		}
		
		input.blur(function(e) {
			setTimeout(function(){input.focus()}, 0.1);
		});
		
		input.keyup(function(e) {
			var k = e.keyCode;
			
			input.val(input.val().substr(0,45));
			
			if(input.val().length > 0) {
				chatview.text(input.val());
				chatview.css({
					marginLeft: (chatview.width()/2)*-1,
					marginTop: (chatview.height()/2)*-1
				});
				chatview.fadeIn(100);
			} else {
				closechat();
			}
			
			if(k == esc || k == enter) {
				if(k == enter && input.val().length > 0) {
					var sendObj = {
						type: 'message',
						value: chatview.text()
					};
					
					app.sendMessage(chatview.text());
				}
				closechat();
			}
		});
		
		input.focus();
	}
	
	$(function() {
		//$('#chat').initChat();
	});
})(jQuery);