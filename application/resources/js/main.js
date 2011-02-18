/* developer.marklogic.com custom js */
if(typeof jQuery != 'undefined') {
    $(function() {
        $('body').addClass('jsenabled'); // this class is applied to have a selector to add functionality with CSS later on that would only make sense if JS is actually enabled/available
        if(jQuery().defaultvalue) {
            $("#s_inp, #ds_inp, #kw_inp").defaultvalue(
                "Search the site",
                "Search current document",
                "Search documents by keyword"
            );
        }
        $("#s_inp").addClass("default");
                        $("#s_inp").focus(function() {$("#s_inp").removeClass("default");} );
                        $("#s_inp").blur(function() {
                            if ($("#s_inp").val() == "Search the site" || $("#s_inp").val() == "")
                                $("#s_inp").addClass("default");
                });
        $('#sub > div:last-child').addClass('last'); // only supposed to add some last-child functionality to IE
        if(jQuery().tabs) {
          $('#special_intro > div').hide();
                    $('#special_intro .nav').tabs('#special_intro > div',{
                        //effect: 'fade',
                tabs: 'li'
            });
        }
        // accordion style menu
        $('#sub .subnav.closed h2, #sub .subnav.closed li span').each(function() {
            if(!($(this).next().children().is('.current'))) {
                $(this).addClass('closed').next().hide();
            }
        })
        
        $('#sub .current').parents().show();
        $('#sub .subnav h2, #sub .subnav li span').click(function() {
            $(this).toggleClass('closed').next().toggle();
        });



        $('.hide-if-href-empty').each(function() {
            if ( $(this).attr('href') == "" ) {
                $(this).hide();
            }
        });




 


     

      // new functions should be added here
   });
}


/*
 * jQuery Notify UI Widget 1.4
 * Copyright (c) 2010 Eric Hynds
 *
 * http://www.erichynds.com/jquery/a-jquery-ui-growl-ubuntu-notification-widget/
 *
 * Depends:
 *   - jQuery 1.4
 *   - jQuery UI 1.8 widget factory
 *
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 *
*/
$().ready(function(){
(function($){

$.widget("ech.notify", {
	options: {
		speed: 500,
		expires: 5000,
		stack: 'below',
		custom: false
	},
	_create: function(){
		var self = this;
		this.templates = {};
		this.keys = [];

		// build and save templates
		this.element.addClass("ui-notify").children().addClass("ui-notify-message ui-notify-message-style").each(function(i){
			var key = this.id || i;
			self.keys.push(key);
			self.templates[key] = $(this).removeAttr("id").wrap("<div></div>").parent().html(); // because $(this).andSelf().html() no workie
		}).end().empty().show();
	},
	create: function(template, msg, opts){
		if(typeof template === "object"){
			opts = msg;
			msg = template;
			template = null;
		}

		var tpl = this.templates[ template || this.keys[0]];

		// remove default styling class if rolling w/ custom classes
		if(opts && opts.custom){
			tpl = $(tpl).removeClass("ui-notify-message-style").wrap("<div></div>").parent().html();
		}

		// return a new notification instance
		return new $.ech.notify.instance(this)._create(msg, $.extend({}, this.options, opts), tpl);
	}
});

$().ready(function(){
	var q = getParameterByName("q") 
	if(q && q != undefined ){
		try{
			$("#q").val(q);
			
		}catch(e){}
	}
	$( "input.search-button" ).button({
            icons: {
                primary: "ui-icon-locked"
            },
            text: false
        });
	$("input.search-button").button(
			{
				icons: {
					primary: "ui-icon ui-icon-search"
				},
				text:false
			});
});

function getParameterByName( name )
{
  name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
  var regexS = "[\\?&]"+name+"=([^&#]*)";
  var regex = new RegExp( regexS );
  var results = regex.exec( window.location.href );
  if( results == null )
    return "";
  else
    return decodeURIComponent(results[1].replace(/\+/g, " "));
}

// instance constructor
$.extend($.ech.notify, {
	instance: function(widget){
		this.parent = widget;
		this.isOpen = false;
	}
});

// instance methods
$.extend($.ech.notify.instance.prototype, {
	_create: function(params, options, template){
		this.options = options;

		var self = this,

			// build html template
			html = template.replace(/#(?:\{|%7B)(.*?)(?:\}|%7D)/g, function($1, $2){
				return ($2 in params) ? params[$2] : '';
			}),

			// the actual message
			m = (this.element = $(html)),

			// close link
			closelink = m.find(".ui-notify-close");

		// clickable?
		if(typeof this.options.click === "function"){
			m.addClass("ui-notify-click").bind("click", function(e){
				self._trigger("click", e, self);
			});
		}

		// show close link?
		if(closelink.length){
			closelink.bind("click", function(){
				self.close();
				return false;
			});
		}

		this.open();

		// auto expire?
		if(typeof options.expires === "number"){
			window.setTimeout(function(){
				self.close();
			}, options.expires);
		}

		return this;
	},
	close: function(){
		var self = this, speed = this.options.speed;

		this.element.fadeTo(speed, 0).slideUp(speed, function(){
			self._trigger("close");
			self.isOpen = false;
		});

		return this;
	},
	open: function(){
		if(this.isOpen || this._trigger("beforeopen") === false){
			return this;
		}

		var self = this;

		this.element[this.options.stack === 'above' ? 'prependTo' : 'appendTo'](this.parent.element).css({ display:"none", opacity:"" }).fadeIn(this.options.speed, function(){
			self._trigger("open");
			self.isOpen = true;
		});

		return this;
	},
	widget: function(){
		return this.element;
	},
	_trigger: function(type, e, instance){
		return this.parent._trigger.call( this, type, e, instance );
	}
});

})(jQuery);
});

function _show_error(title, message, expires){
	if(!expires)
		var expires = 5000;
	var handler = $("#notification-container").notify().notify("create", "themeroller-error", { title:title, text:message }, { custom:true, expires:expires });

}
function _show_info(title, message){
	var handler = $("#notification-container").notify().notify("create", "themeroller-info", { title:title, text:message }, { custom:true });
}