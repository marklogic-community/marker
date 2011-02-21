/*

 admin/js/inlineEditor.js

 Copyright 2010 MarkLogic Corporation 

 Licensed under the Apache License, Version 2.0 (the "License"); 
 you may not use this file except in compliance with the License. 
 You may obtain a copy of the License at 

        http://www.apache.org/licenses/LICENSE-2.0 

 Unless required by applicable law or agreed to in writing, software 
 distributed under the License is distributed on an "AS IS" BASIS, 
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
 See the License for the specific language governing permissions and 
 limitations under the License. 

*/

$(document).ready(function(){
	rangy.init();
    // remove attr from HTML
    $("html").removeAttr("xml:base");
    $("[xml\\:base]").each(function(i){
		if($(this).attr('runtime') != 'dynamic'){
        //$(this).attr('contentEditable', 'true');
        $(this).attr('id', $(this).attr('xml:base'));
        $(this).attr('marker:field', 'xhtml');
        }
        
    });
	if (viewMode != 'http://marklogic.com/marker/published') {
		MarkerInlineEdit.init();
		var t = setTimeout("initialValueChecks()", 1000);
	}
	MarkerAdminMenu.init()
	
});

function initialValueChecks(){
	// get all the information and display errors if state is bad
	$("[marker\\:field]").each(function() {
			MarkerInlineEdit.getContentInformation( $(this).attr("id"));
		});
}
var MarkerAdminMenu = {
	pinned:true,
	init: function(){
		var menu = $('#marker-admin-menu')
	    pos = $('#marker-admin-menu').offset();
	        
	    $(window).scroll(function(){
			
			if ($(this).scrollTop() > pos.top + $('#marker-admin-menu').height() && $('#marker-admin-menu').hasClass('marker-admin-default') && MarkerAdminMenu.pinned) {
				$('#marker-admin-menu').fadeOut('fast', function(){
						$(this).removeClass('marker-admin-default').addClass('marker-admin-fixed').fadeIn('fast');
				});
			}
			else 
				if ($(this).scrollTop() <= pos.top && $('#marker-admin-menu').hasClass('marker-admin-fixed') && MarkerAdminMenu.pinned) {
					$('#marker-admin-menu').fadeOut('fast', function(){
							$(this).removeClass('marker-admin-fixed').addClass('marker-admin-default').fadeIn('fast');
					});
				}
			
	    });
		// wire up the pinned 
		if($.cookie('pinned') == "true")
			MarkerAdminMenu.pinned = true;
		else
			MarkerAdminMenu.pinned = false;
				
		$('#marker-admin-menu-left').html('');
		$('#marker-admin-menu-center').html('');
		$('#marker-admin-menu-right').html('');
		$('#marker-admin-menu-left').append("<div class='expandable-buttons-container'><div id='marker-admin-pin' class='marker_button marker_button_pin " + (MarkerAdminMenu.pinned ? 'pinned' : '') + "' onclick='MarkerAdminMenu.togglePin(this)'></div></div>");
		if(viewMode == 'http://marklogic.com/marker/published'){
			$('#marker-admin-menu-right').append("<div class='expandable-buttons-container'><div id='marker-admin-switch' class='marker_button marker_button_switch' onclick='MarkerAdminMenu.toggleViewingMode(\"EDITABLE\")'></div><div class='button-text'> VIEWING: PUBLISHED</div></div>");
		}else{
			$('#marker-admin-menu-right').append("<div class='expandable-buttons-container'><div id='marker-admin-switch' class='marker_button marker_button_switch' onclick='MarkerAdminMenu.toggleViewingMode(\"http://marklogic.com/marker/published\")'></div><div class='button-text'> VIEWING: EDITABLE</div></div>");
		}
		
		
		
	},
	togglePin: function(item){
		if(MarkerAdminMenu.pinned){
			$(item).removeClass("pinned");
			$.cookie('pinned', "false", {path: '/'});
			MarkerAdminMenu.pinned = false;
		}else{
			$(item).addClass("pinned");
			$.cookie('pinned', "true", {path: '/'});
			MarkerAdminMenu.pinned = true;
		}
	},
	toggleViewingMode: function(mode){
		$.ajax({
			type: 'POST',
			url: '/marker/ajax/change-view-mode',
			data: 'mode=' + mode,
			success: function(data){
				if(data.isSuccess == "true"){
					_show_info("Content Mgmt", "Switching to view mode: " + mode);
					window.location.href = window.location.href;
				}else{
					_show_error("Content Mgmt", "An error occurred while attempting to switch mode");
				}
			},
			error: function(data, status, error){
				_show_error("Content Mgmt", "An error occurred while attempting to switch mode : " + error);
			},
			dataType: 'json'
		});
	}
	
	
}

// library for setting up inline editing controls and submitting create and updates of content
var MarkerInlineEdit = {
	currentFocus:null,
	contentInformation:new Object(),
	focusedId:null,
	debug:false,
	selectedImage:'',
	selectedLink:'',
	savedSelection:null,
	init: function() {
		var originalValues = new Array();
		

		
		
		
		// insert the inline editor
		var basicEditor = "";
		basicEditor = "<div id='marker-editor-container'><div id='marker-editor'>" + 
		 	"<ul><li><a href='#tabs-1'>Format</a></li><li><a href='#tabs-2'>Insert</a></li><li><a href='#tabs-3'>Image</a></li><li><a href='#tabs-4'>Content Mgmt</a></li><li style='float:right'><div class='expandable-buttons-container' style='background-color:#fff;'><div cmdValue='contentmgmt' class='save-button marker_button marker_button_save' onclick='MarkerInlineEdit.save(MarkerInlineEdit.focusedId, MarkerInlineEdit.prepareData(MarkerInlineEdit.currentFocus));'></div><div cmdValue='contentmgmt' class='checkin-button marker_button marker_button_checkin' onclick='MarkerInlineEdit.checkin(MarkerInlineEdit.focusedId);'></div><div cmdValue='contentmgmt' class='checkout-button marker_button marker_button_checkout' onclick='MarkerInlineEdit.checkout(MarkerInlineEdit.focusedId);'></div></div></li></ul>" +
			"<div id='tabs-1' class='tab'></div>" + 
			"<div id='tabs-2' class='tab'></div>" +
			"<div id='tabs-3' class='tab'></div>" +
			"<div id='tabs-4' class='tab'></div>" +
			"</div></div>"
		$("body").append(basicEditor);
		$('#tabs-1').append("<div class='three-col-buttons-container'>" +
							"<div value='Bold' id='bold' class='marker_button marker_button_bold'></div>" +
							"<div value='Italic' id='italic' class='marker_button marker_button_italic'></div>" +
							"<div value='Underline' id='underline' class='marker_button marker_button_underline'></div>" +
							"<div value='&lt;strike&gt;' id='strikeThrough' class='marker_button marker_button_strikethrough'></div>" +
							"<div value='&lt;sub&gt;' id='subscript' class='marker_button marker_button_sub'></div>" +
							"<div value='&lt;sup&gt;' id='superscript' class='marker_button marker_button_sup'></div>" +
							"</div>" + 
							"<div class='color-buttons-container'>" +
							"<div value='backColor' id='backColor' class='marker_button marker_button_backcolorpicker' cmdValue='transparent' class='marker_button'><div class='palette'></div></div>" +
							"<div value='MarkerInlineEdit.selectedBackColor' id='backColorSelector' class='marker_button_sm marker_button_downarrow' target='#backColor' cmdValue='colorpicker'></div>" +
							"<div value='foreColor' id='foreColor' class='marker_button marker_button_forecolorpicker' cmdValue='#000000' class='marker_button'><div class='palette'></div></div>" +
							"<div value='MarkerInlineEdit.selectedForeColor' id='foreColorSelector' class='marker_button_sm marker_button_downarrow' target='#foreColor' cmdValue='colorpicker'></div>" +
							"</div>" +
							"<div class='expandable-buttons-container'>" +
							"<div value='&lt;ul&gt;' id='insertunorderedlist' class='marker_button marker_button_bullist'></div>" +
							"<div value='&lt;ol&gt;' id='insertorderedlist' class='marker_button marker_button_numlist'></div>" +
							"</div>" +
							"<div class='expandable-buttons-container'>" +
							"<div value='indent' id='indent' class='marker_button marker_button_indent'></div>" +
							"<div value='outdent' id='outdent' class='marker_button marker_button_outdent'></div>" +
							"<div value='justifyLeft' id='justifyLeft' class='marker_button marker_button_justifyleft'></div>" +
							"<div value='justifyCenter' id='justifyCenter' class='marker_button marker_button_justifycenter'></div>" +
							"<div value='justifyRight' id='justifyRight' class='marker_button marker_button_justifyright'></div>" +
							"</div>" +
							"<div class='expandable-buttons-container'>" +
							"<div value='undo' id='undo' class='marker_button marker_button_undo'></div>" +
							"<div value='redo' id='redo' class='marker_button  marker_button_redo'></div>" +
							"<div value='removeFormat' id='removeFormat' class='marker_button marker_button_removeformat'></div>" +
							"</div>" +
							"<div class='expandable-buttons-container'>" + 
							"<div value='&lt;h1&gt;' cmdValue='&lt;h1&gt;'  id='formatBlock' class='marker_button marker_button_h1'></div>" +
							"<div value='&lt;h2&gt;' cmdValue='&lt;h2&gt;' id='formatBlock' class='marker_button marker_button_h2'></div>" +
							"<div value='&lt;h3&gt;' cmdValue='&lt;h3&gt;' id='formatBlock' class='marker_button marker_button_h3'></div>" +
							"<div value='&lt;h4&gt;' cmdValue='&lt;h4&gt;' id='formatBlock' class='marker_button marker_button_h4'></div>" +
							"<div value='&lt;h5&gt;' cmdValue='&lt;h5&gt;' id='formatBlock' class='marker_button marker_button_h5'></div>" +
							"<div value='&lt;h6&gt;' cmdValue='&lt;h6&gt;' id='formatBlock' class='marker_button marker_button_h6'></div>" +
							"<div value='&lt;p&gt;' cmdValue='&lt;p&gt;' id='formatBlock' class='marker_button marker_button_p'></div>" +
							"<div value='&lt;pre&gt;' cmdValue='&lt;pre&gt;' id='formatBlock' class='marker_button marker_button_pre	'></div>" +
							"</div>" +
							"<div class='expandable-buttons-container'>" +
							"<div value='&lt;a&gt;' id='unLink' cmdValue='' class='marker_button  marker_button_unlink'></div>" + 
							"</div>" +
							"<div class='expandable-buttons-container'>" +
							"<div value='Code Toggle' class='marker_button marker_button_code' onclick='MarkerInlineEdit.rawToggle()'></div>" +
							"</div>" +
							
							"");
		$('#tabs-2').append("<div style='display:none;' class='confirm-buttons two-col-buttons-container'>" +
						"<div value='confirm' id='confirm-button' class='marker_button marker_button_confirm' onclick=''></div>" +
						"<div value='cancel' class='marker_button marker_button_cancel' onclick='MarkerInlineEdit.resetInsertDetails();'></div>" +
						"</div><div class='insert-buttons two-col-buttons-container'>" + 
						"<div value='Table Insert' class='marker_button marker_button_table' onclick='MarkerInlineEdit.buildTableForm(\"#insert-details\")'></div>" +
						"<div value='Image Insert' class='marker_button marker_button_image' onclick='MarkerInlineEdit.buildImageInsertForm(\"#insert-details\")'></div>" +
						"<div value='Link Insert' class='marker_button  marker_button_link' onclick='MarkerInlineEdit.buildLinkInsertForm(\"#insert-details\")'></div>" +
						"</div>" +
							//separator
							"<div id='insert-details' class='not-handle'></div>" 
							
						);
		$('#tabs-3').append("<div class='confirm-buttons two-col-buttons-container'>" +
						"<div value='confirm' class='marker_button marker_button_confirm' onclick='$(MarkerInlineEdit.selectedImage.image).attr({src:$(\"#image-src\").val(), width:$(\"#image-width\").val(), height:$(\"#image-height\").val()});$(\"#marker-editor\").tabs(\"select\", 0);$(\"#marker-editor\").tabs(\"disable\", 2);'></div>" +
						"<div value='cancel' class='marker_button marker_button_cancel' onclick='$(MarkerInlineEdit.selectedImage.image).attr({src:MarkerInlineEdit.selectedImage.src, width:MarkerInlineEdit.selectedImage.width, height:MarkerInlineEdit.selectedImage.height});$(\"#marker-editor\").tabs(\"select\", 0);$(\"#marker-editor\").tabs(\"disable\", 2);'></div>" +
						"</div>" +
						"<div class='image-buttons two-col-buttons-container'>" + 
						"<div class='marker_button marker_button_img_align_none' onclick='$(MarkerInlineEdit.selectedImage.image).removeClass(\"alignCenter alignLeft alignRight\");'></div>" +
						"<div class='marker_button marker_button_img_align_left' onclick='$(MarkerInlineEdit.selectedImage.image).removeClass(\"alignCenter alignLeft alignRight\").addClass(\"alignLeft\");'></div>" +
						"<div class='marker_button marker_button_img_align_center' onclick='$(MarkerInlineEdit.selectedImage.image).removeClass(\"alignCenter alignLeft alignRight\").addClass(\"alignCenter\");'></div>" +
						"<div class='marker_button marker_button_img_align_right' onclick='$(MarkerInlineEdit.selectedImage.image).removeClass(\"alignCenter alignLeft alignRight\").addClass(\"alignRight\");'></div></div>" +
							//separator
						"<div id='image-details' class='not-handle'>" + 
						"<div style='width:100%;float:left;'>URL:<input style='width:85%;' type='text' id='image-src' value='http://' /></div>" +
						"<div id='image-size-slider' style='width:30%;float:left;margin-top:6px;margin-left:2px;'></div><div style='width:30%;float:left;margin-left:2px;'>Width:<input type='text' id='image-width' value='0' size='4'/></div>" +
						"<div style='width:35%;float:right;'>Height:<input type='text' id='image-height' value='0' size='4'/></div>" +
						"</div>" 
						);
		$('#tabs-4').append(
						"<div class='image-buttons two-col-buttons-container'>" + 
						"<div cmdValue='contentmgmt' class='save-button marker_button marker_button_save' onclick='MarkerInlineEdit.save(MarkerInlineEdit.focusedId, MarkerInlineEdit.prepareData(MarkerInlineEdit.currentFocus));'></div><div cmdValue='contentmgmt' class='checkin-button marker_button marker_button_checkin' onclick='MarkerInlineEdit.checkin(MarkerInlineEdit.focusedId);'></div><div cmdValue='contentmgmt' class='checkout-button marker_button marker_button_checkout' onclick='MarkerInlineEdit.checkout(MarkerInlineEdit.focusedId);'></div><div value='tag' cmdValue='tag' id='insertHTML' class='marker_button marker_button_tag'></div></div>" +
							//separator
						"<div id='content-details' class='not-handle'>" + 
						
						"</div>" 
						);

		$( "#image-size-slider" ).slider({
			orientation: "horizontal",
			min: -1000,
			max: 1000,
			value: 0,
			slide: function( event, ui ) {
				if(MarkerInlineEdit.debug)MarkerInlineEdit.debugLogMessage("adjusting image : " + ui.value);
				var aspectRatio =  MarkerInlineEdit.selectedImage.height/MarkerInlineEdit.selectedImage.width;
				var width = MarkerInlineEdit.selectedImage.width + ui.value > 0 ? MarkerInlineEdit.selectedImage.width + ui.value : 0;
				var height = parseInt(width * aspectRatio > 0 ? width * aspectRatio : 0);
				$("#image-width").val(width);
				$("#image-height").val(height);
				$(MarkerInlineEdit.selectedImage.image).attr("width", width);
				$(MarkerInlineEdit.selectedImage.image).attr("height",height);
			}
		});
		if(MarkerInlineEdit.debug){
			var debugContainer = "<div id='debug-container'><div id='clear-output' onclick='$(\"#debug-output ul\").html(\"\");'>Clear Output</div><div id='debug-output'><ul>" + 
		 	
			"</ul></div></div>"
			$("body").append(debugContainer);
			//initialize the editor
			$("#debug-container").draggable();
		}
		
		
		//set up image clicks
		$("[marker\\:field]").each(function(){
			if(MarkerInlineEdit.debug)MarkerInlineEdit.debugLogMessage("Setting live click event for " + "#" + $(this).attr("id") + " img");
			$("img", this).live('click',function(event){
					if(MarkerInlineEdit.debug)MarkerInlineEdit.debugLogMessage("Clicked image " + $(this).attr("src"));
					MarkerInlineEdit.selectedImage = {
						image: this,
						width: $(this).width(),
						height: $(this).height(),
						src: $(this).attr("src")
					};
					$("#marker-editor").tabs("enable", 2);
					$("#image-width").val(MarkerInlineEdit.selectedImage.width);
					$("#image-height").val(MarkerInlineEdit.selectedImage.height);
					$("#image-src").val(MarkerInlineEdit.selectedImage.src);
					$("#marker-editor").tabs("select", 2);
					
			});
			if(MarkerInlineEdit.debug)MarkerInlineEdit.debugLogMessage("Setting live click event for " + "#" + $(this).attr("id") + " a");
			$("a", this).live('click',function(event){
					if(MarkerInlineEdit.debug)MarkerInlineEdit.debugLogMessage("Clicked url " + $(this).attr("href"));
					$("#marker-editor").tabs("select", 1);
					MarkerInlineEdit.selectedLink = this;
					MarkerInlineEdit.buildLinkInsertForm("#insert-details", true);
					$("#link-url").val($(this).attr("href"));
			});
			
		});
		$("[marker\\:field]").each(function() {
			// store the original value
			var value =  $(this).html();
			var fieldType = $(this).attr("marker:field");
			var fieldName = $(this).attr("name");
			var fieldLabel = $(this).attr("label");
			
			originalValues[$(this).parent().attr("name") ] = value;
			if (fieldType == "xhtml") {
				$(this).html( "<marker:wrapper><div contenteditable='true' class='marker-editable' pointer='" + $(this).attr("id") + "'>" + value + '</div></marker:wrapper>' );	
				$(this).click(function(){
					if($('#rich-editor-controls').length < 1)
						
					if(!$("#bar").hasClass("lock"))
						$("#bar").addClass("lock");		
				});	

			} else {
				$(this).html( "<div contenteditable='true' class='marker-editable' style='display:inline;'>" + value + '</div>' );	
				$(this).click(function(){ 
					$('#rich-editor-controls').remove(); 
					if($("#bar").hasClass("lock"))
						$("#bar").removeClass("lock");		
				});								
			}
	
			
			var el = $(this).children(":first");
			


			//el.inlineEdit();
			
			/*
			if(fieldType == "string") {
				el.click(function(e){
					var inputElement = $('<div></div>')
						.addClass('marker-inline')
						.append($('<label/>').html(fieldLabel + " (" + fieldName + ")"))
						.append($('<input/>').attr({ type: "text", value: value}).addClass('marker-inline-textbox'))
						.keyup(function() { 
							el.html($(this).find('input').val());
						});
					$.fn.colorbox({html: inputElement, opacity: 0.5});
				});			
			} else 
			*/
			/*
			if(fieldType == "xhtml") {
				el.click(function(e){
					var value =  $(this).html();
					var inputElement = $('<textarea></textarea>')
						.addClass('marker-inline')
						.attr({ id: "marker-inline-tinymce"}).addClass('marker-inline-tinymce tinymce').val(value);
					$.fn.colorbox({html: inputElement, opacity: 0.5});
					MarkerInlineEdit.initializeTinymceEditor(inputElement, el);
					
					//$.fn.colorbox.resize();
				});			
				
			}
			*/	
			el.hover(
				function(e){
					el.addClass("hover-editable");
					
                                                                 // Recipe demo looks a little nicer without this.
					var title = $(this).parent().attr("label") ; // + " (" + $(this).parent().attr("name") + ")";
		           
		          	
					
				},
				function() {
					el.removeClass("hover-editable");
					
				}
			).mouseup(
		        function(e) {
					if(MarkerInlineEdit.debug)MarkerInlineEdit.debugLogMessage("mouseup - saving selection") ;
					//rangy.removeMarkers(MarkerInlineEdit.savedSelection)
					//MarkerInlineEdit.savedSelection = rangy.saveSelection();
				
				}
		    ).mousedown(
		        function(e) {
					if(MarkerInlineEdit.debug)MarkerInlineEdit.debugLogMessage("mousedown - saving selection") ;
					//rangy.removeMarkers(MarkerInlineEdit.savedSelection)
					//MarkerInlineEdit.savedSelection = rangy.saveSelection();
				
				}
		    )
			.keyup(
		        function(e) {
					if(MarkerInlineEdit.debug)MarkerInlineEdit.debugLogMessage("keyup - saving selection") ;
					//rangy.removeMarkers(MarkerInlineEdit.savedSelection)
					//MarkerInlineEdit.savedSelection = rangy.saveSelection();
				
				}
		    )
			.keydown(
		        function(e) {
					if(MarkerInlineEdit.debug)MarkerInlineEdit.debugLogMessage("keydown - saving selection") ;
					//rangy.removeMarkers(MarkerInlineEdit.savedSelection)
					//MarkerInlineEdit.savedSelection = rangy.saveSelection();
				
				}
		    ).focus(
		        function(e) {
					if(MarkerInlineEdit.debug)MarkerInlineEdit.debugLogMessage("focus - saving selection") ;
					//rangy.removeMarkers(MarkerInlineEdit.savedSelection)
					//MarkerInlineEdit.savedSelection = rangy.saveSelection();
				
				}
		    )
			.blur(
				function() {
					if(MarkerInlineEdit.debug)MarkerInlineEdit.debugLogMessage("Blurring - saving selection") ;
					//rangy.removeMarkers(MarkerInlineEdit.savedSelection)
					//MarkerInlineEdit.savedSelection = rangy.saveSelection();
					// some cases where errent br tags are getting added to content editable regions
//					$(this).html( $(this).html().replace("<br>", "") );
//					if($(this).text() == "")
//						$(this).html("[-]");
				}
			).click(
				function(){
					
					var position = el.offset();
					if(MarkerInlineEdit.debug)MarkerInlineEdit.debugLogMessage("Content Editable clicked : " + el.parent().attr("id"));
					if (el.parent().attr("id") != MarkerInlineEdit.focusedId) {
						
						MarkerInlineEdit.focusedId = el.parent().attr("id")
						$('#marker-editor-container').hide();
						
						// hide tags if dynamic content
						if(el.parent().attr("runtime") == "dynamic"){
							$("#marker-editor").tabs("select", 3);
							$("#marker-editor").tabs("disable", 0);
							$("#marker-editor").tabs("disable", 1);
						$("#marker-editor").tabs("disable", 2);	
						}
						
						
						if(MarkerInlineEdit.debug)MarkerInlineEdit.debugLogMessage("Hiding editor");
						$('#marker-editor-container').css({
							position: 'absolute',
							top: (position.top < 130 ? position.top + 130 : position.top - 130),
							left: position.left - 25
						});
						if(MarkerInlineEdit.debug)MarkerInlineEdit.debugLogMessage("Moved editor to top:" + (position.top < 130 ? position.top + 130 : position.top - 130).toString() + " left:" +  (position.left - 25).toString());
						$('#marker-editor-container').show(200);
						
						MarkerInlineEdit.clearContentInformation();
						// get content information
						if(MarkerInlineEdit.debug)MarkerInlineEdit.debugLogMessage("checking for data on : " + el.parent().attr("id"));
						if(!(MarkerInlineEdit.contentInformation[el.parent().attr("id")])){
							MarkerInlineEdit.getContentInformation(el.parent().attr("id"));	
						}else{
							MarkerInlineEdit.parseContentInformation(el.parent().attr("id"));
						}
						
					}
					//check for selected tab and reset to context tab
					var tabIndex = $("#marker-editor").tabs( "option", "selected" );
					if(MarkerInlineEdit.debug)MarkerInlineEdit.debugLogMessage("Current selected tab:" + tabIndex);
					if(tabIndex == 2){
						if(MarkerInlineEdit.debug)MarkerInlineEdit.debugLogMessage("Reseting tabs based off image losing focus");
						$("#marker-editor").tabs("select", 0);
						$("#marker-editor").tabs("disable", 2);
					
					}
					
				}
			);
		});		
		
		$(".marker_button").live('click', function(){ 
			
			var cmd = $(this).attr("id");
			var bool = false;
			var value = $(this).attr('cmdValue') || null;
			if (value == 'promptUser')
				value = prompt($(this).attr('promptText'));
			if (value != 'colorpicker' && value != 'contentmgmt' && cmd) {
				if(MarkerInlineEdit.debug)MarkerInlineEdit.debugLogMessage("Button click - executing : " + cmd + " values=" + (value ? value.replace('<', '').replace('</').replace('>'):'null')) ;
				//rangy.restoreSelection(MarkerInlineEdit.savedSelection);
				//MarkerInlineEdit.savedSelection = rangy.saveSelection();
				//rangy.removeMarkers(MarkerInlineEdit.savedSelection);
				if(cmd == 'insertHTML' && value== 'tag'){
					
					value = "<tag>" + rangy.getSelection() + "</tag>";
					
				}
				var returnValue = document.execCommand(cmd, bool, value);
			}
		});
		$(".marker_button_sm").each(function(){
			if($(this).attr('cmdValue')=='colorpicker'){
				var target = $(this).attr('target');
				$(target + ' div.palette').css("background-color", $(target).attr("cmdValue"));
				$(this).ColorPicker({
					onSubmit: function(hsb, hex, rgb, el) {
						$(target + ' div.palette').css("background-color", "#" + hex);
						$(target).attr("cmdValue", "#" + hex); 
						$(el).val(hex);
						$(el).ColorPickerHide();
						$(MarkerInlineEdit.currentFocus).focus();
						rangy.restoreSelection(MarkerInlineEdit.savedSelection);
					}
				});
				$(this).click(function(){
					MarkerInlineEdit.savedSelection = rangy.saveSelection();
				});
			}
		});
		

		$('.marker-editable').focus( function() {
		    MarkerInlineEdit.currentFocus = this;
		}).blur( function() {		
		    //MarkerInlineEdit.currentFocus = null;		
		}); 
		//initialize the editor
		$("#marker-editor-container").draggable({ cancel: "div.not-handle" });
		$("#marker-editor").tabs();
		// hide the image tab
		$("#marker-editor").tabs("disable", 2);
		
	},
	
	prepareData: function(element) {
		var data = '';
		if(MarkerInlineEdit.debug)MarkerInlineEdit.debugLogMessage("Preparing data for " + $(element).attr("pointer")) ;
		if($(element).attr("contenteditable") == "false") {
			MarkerInlineEdit.rawToggle($(element));
		}
		data = $(element).html();
		data = data.replace(/<br>+/g, "<br/>");
		data = data.replace(/\n/g, '');
		data = data.replace(/\t/g, '');
		data = data.replace("&nbsp;",' ');
		$(element).html(data);
			
		return data;
	},
	
	/** 
	 * this below is the function you need from:
	 * http://stackoverflow.com/questions/1865563/
	 * set-cursor-at-a-length-of-14-onfocus-of-a-textbox
	 */
    setCursor: function(node,pos){
	    var node = (typeof node == "string" || node instanceof String) ? document.getElementById(node) : node;
        if(!node){
            return false;
        }else if(node.createTextRange){
            var textRange = node.createTextRange();
            textRange.collapse(true);
            textRange.moveEnd(pos);
            textRange.moveStart(pos);
            textRange.select();
            return true;
        }else if(node.setSelectionRange){
            node.setSelectionRange(pos,pos);
            return true;
        }
        return false;
    },
	debugLogMessage: function(message){
		$("#debug-output ul").prepend("<li>" + new Date().toTimeString().substring(0,8) + " : " + message + "</li>");
	},
	showConfirmButtons: function(){
		MarkerInlineEdit.savedSelection = rangy.saveSelection();
		$(".insert-buttons").hide();
		$(".confirm-buttons").show();
		
	},
	resetInsertDetails: function(){
		if(MarkerInlineEdit.debug)MarkerInlineEdit.debugLogMessage("Resetting insert details");
		$("#insert-details").html('');
		$(".insert-buttons").show();
		$("#tabs-2 .confirm-buttons").hide();
		$("#confirm-button").unbind("click");
		rangy.removeMarkers(MarkerInlineEdit.savedSelection);
		
	},
	buildTableForm: function(node){
		
		MarkerInlineEdit.showConfirmButtons();
		$(node).html('');
		var tableForm = "<div style='width:66%;float:left;'>Columns:<input type='text' id='table-cols' value='3' size='1'/></div>" +
		"<div style='width:34%;float:left;'>Rows:<input type='text' id='table-rows' value='3' size='1'/></div>" +
		"<div style='width:33%;float:left;'>Border:<input type='text' id='table-border' value='1' size='1'/></div>" +
		"<div style='width:33%;float:left;'>Padding:<input type='text' id='table-padding' value='2' size='1'/></div>" +
		"<div style='width:34%;float:left;'>Spacing:<input type='text' id='table-spacing' value='2' size='1'/></div>"
		$(node).append(tableForm);
		$("#confirm-button").click(function (){
			if(MarkerInlineEdit.debug)MarkerInlineEdit.debugLogMessage("Inserting table");
			$(MarkerInlineEdit.currentFocus).focus();
			rangy.restoreSelection(MarkerInlineEdit.savedSelection);
			var returnValue = document.execCommand("insertHTML",false,MarkerInlineEdit.buildTableHtml($("#table-cols").val(),$("#table-rows").val(),$("#table-border").val(),$("#table-padding").val(),$("#table-spacing").val()));	
			MarkerInlineEdit.resetInsertDetails();
		});
		
	},
	buildImageInsertForm: function(node){
		MarkerInlineEdit.showConfirmButtons();
		$(node).html('');
		var imageInsertForm = "<div style='width:100%;float:left;'>URL:<input style='width:90%;' type='text' id='image-url' value='http://' size='40'/></div>" 
		$(node).append(imageInsertForm);
		$("#confirm-button").click(function (){
			if(MarkerInlineEdit.debug)MarkerInlineEdit.debugLogMessage("Inserting image from " + $("#image-url").val());
			$(MarkerInlineEdit.currentFocus).focus();
			rangy.restoreSelection(MarkerInlineEdit.savedSelection);
			var returnValue = document.execCommand("insertImage",false,$("#image-url").val().toString());	
			MarkerInlineEdit.resetInsertDetails();
		});
		
	},
	buildLinkInsertForm: function(node, existing){
		if(!existing)
			var existing = false;
		MarkerInlineEdit.showConfirmButtons();
		$(node).html('');
		var linkInsertForm = "<div style='width:100%;float:left;'>URL:<input style='width:90%;' type='text' id='link-url' value='http://' size='40'/></div>" 
		$(node).append(linkInsertForm);
		$("#confirm-button").click(function (){
			if (existing) {
				if (MarkerInlineEdit.debug) 
					MarkerInlineEdit.debugLogMessage("Updating link to " + $("#link-url").val());
				$(MarkerInlineEdit.selectedLink).attr("href", $("#link-url").val());
				$(MarkerInlineEdit.currentFocus).focus();
				rangy.restoreSelection(MarkerInlineEdit.savedSelection);
			}
			else {
				if (MarkerInlineEdit.debug) 
					MarkerInlineEdit.debugLogMessage("Inserting link from " + $("#link-url").val());
				$(MarkerInlineEdit.currentFocus).focus();
				rangy.restoreSelection(MarkerInlineEdit.savedSelection);
				var returnValue = document.execCommand("createLink", false, $("#link-url").val().toString());
			}
			MarkerInlineEdit.resetInsertDetails();
		});
		
	},
	buildImageEditForm: function(node){
		MarkerInlineEdit.showConfirmButtons();
		$(node).html('');
		var imageForm = "<div style='width:66%;float:left;'>Width:<input type='text' id='table-cols' value='3' size='1'/></div>" +
		"<div style='width:34%;float:left;'>Height:<input type='text' id='table-rows' value='3' size='1'/></div>" +
		"<div id='slider-horizontal' style='width:100%;'></div>" 
		$(node).append(imageForm);
		$("#confirm-button").click(function (){
			var returnValue = document.execCommand("insertHTML",false,MarkerInlineEdit.buildTableHtml($("#table-cols").val(),$("#table-rows").val(),$("#table-border").val(),$("#table-padding").val(),$("#table-spacing").val()));	
			MarkerInlineEdit.resetInsertDetails();
		});
		
	},
	buildTableHtml: function(cols, rows, border, cellpadding, cellspacing){
		var tableData = "";
		tableData += "<table border='" + border + "' cellpadding='" + cellpadding + "' cellspacing='" + cellspacing + "'>";
		for(y = 0; y < rows; y++){
			tableData += "<tr>";
			for(x = 0; x < cols; x++)
				tableData += "<td></td>";
			tableData += "</tr>";
		}
		tableData += "</table>";
		return tableData;
	},
	rawToggle: function(focusedElement) {
	   	if ( focusedElement === undefined ) {
			focusedElement = MarkerInlineEdit.currentFocus;
   		}
		
		if($(focusedElement).attr("contenteditable") == "true") {
			var current = $(focusedElement).html()
			var width = $(focusedElement).width()
			var height = $(focusedElement).height()
			$(focusedElement).attr("contenteditable", false);
			$(focusedElement).html("<textarea>" + current + "</textarea>");
			$(focusedElement).children("textarea").width(width);
			$(focusedElement).children("textarea").height(height);
			
		} else {
			var current = $(focusedElement).children("textarea").val();
			$(focusedElement).html(current);
			$(focusedElement).attr("contenteditable", true);
		}

	},
	clearContentInformation: function(){
		$(".save-button").hide();
		$(".checkout-button").hide();
		$(".checkin-button").hide();
	},
	getContentInformation: function(uri){
		$.ajax({
			type: 'POST',
			url: '/marker/ajax/get-uri-information',
			data: 'uri=' + uri,
			success: function(data){
				if(data.status.length > 0){
					MarkerInlineEdit.contentInformation[uri] = data;
					MarkerInlineEdit.parseContentInformation(uri);
//					_show_info("Content Mgmt", "Updated Information for " + uri);
				}else{
					// TODO: reset data back
					_show_error("Content Mgmt", "An error occurred while attempting to get content information");
				}
			},
			error: function(data, status, error){
				_show_error("Content Mgmt", "An error occurred while attempting to get content information : " + error);
				// TODO: reset data back
			},
			dataType: 'json'
		});
	},
	save: function(uri, content){
		
		$.ajax({
			type: 'POST',
			url: '/marker/ajax/update-uri-content',
			data: 'uri=' + uri + "&content=" + content,
			success: function(data){
				if(data.isSuccess == "true"){
					MarkerInlineEdit.getContentInformation(uri);
					_show_info("Content Mgmt", "Successful save for " + uri);
				}else{
					// TODO: reset data back
					_show_error("Content Mgmt", "An error occurred while attempting to save");
				}
			},
			error: function(data, status, error){
				_show_error("Content Mgmt", "An error occurred while attempting to save : " + error);
				// TODO: reset data back
			},
			dataType: 'json'
		});
	},
	checkin: function(uri){
		$.ajax({
			type: 'POST',
			url: '/marker/ajax/checkin',
			data: 'uri=' + uri,
			success: function(data){
				if(data.isSuccess == "true"){
					MarkerInlineEdit.getContentInformation(uri);
					_show_info("Content Mgmt", "Successful checkin for " + uri);
				}else{
					// TODO: reset data back
					_show_error("Content Mgmt", "An error occurred while attempting to checkin");
				}
			},
			error: function(data, status, error){
				_show_error("Content Mgmt", "An error occurred while attempting to checkin : " + error);
				// TODO: reset data back
			},
			dataType: 'json'
		});
	},
	checkout: function(uri){
		$.ajax({
			type: 'POST',
			url: '/marker/ajax/checkout',
			data: 'uri=' + uri,
			success: function(data){
				if(data.isSuccess == "true"){
					MarkerInlineEdit.getContentInformation(uri);
					_show_info("Content Mgmt", "Successful checkout for " + uri);
				}else{
					// TODO: reset data back
					_show_error("Content Mgmt", "An error occurred while attempting to checkout");
				}
			},
			error: function(data, status, error){
				_show_error("Content Mgmt", "An error occurred while attempting to checkout : " + error);
				// TODO: reset data back
			},
			dataType: 'json'
		});
	},
	publishVersion: function(baseUri, versionUri){
		$.ajax({
			type: 'POST',
			url: '/marker/ajax/publish',
			data: 'uri=' + versionUri,
			success: function(data){
				if(data.isSuccess == "true"){
					MarkerInlineEdit.getContentInformation(baseUri);
					_show_info("Content Mgmt", "Successful publish for " + baseUri);
				}else{
					// TODO: reset data back
					_show_error("Content Mgmt", "An error occurred while attempting to publish");
				}
			},
			error: function(data, status, error){
				_show_error("Content Mgmt", "An error occurred while attempting to publish : " + error);
				// TODO: reset data back
			},
			dataType: 'json'
		});
	},
	unpublishVersion: function(baseUri){
		$.ajax({
			type: 'POST',
			url: '/marker/ajax/unpublish',
			data: 'uri=' + baseUri,
			success: function(data){
				if(data.isSuccess == "true"){
					MarkerInlineEdit.getContentInformation(baseUri);
					_show_info("Content Mgmt", "Successful unpublish for " + baseUri);
				}else{
					// TODO: reset data back
					_show_error("Content Mgmt", "An error occurred while attempting to unpublish");
				}
			},
			error: function(data, status, error){
				_show_error("Content Mgmt", "An error occurred while attempting to unpublish : " + error);
				// TODO: reset data back
			},
			dataType: 'json'
		});
	},
	getContainerVersionContent: function(uri){
		$.ajax({
			type: 'POST',
			url: '/marker/ajax/get-version-content',
			data: 'uri=' + uri,
			success: function(data){
				$(MarkerInlineEdit.currentFocus).html(data);
				_show_info("Content Mgmt", "Successful update to " + uri);
			},
			error: function(data, status, error){
				_show_error("Content Mgmt", "An error occurred while attempting to update content to version : " + error);
				// TODO: reset data back
			}
		});
	},
	parseContentInformation: function(uri){
		var data = MarkerInlineEdit.contentInformation[uri];
		if(data){
			if(data.status == "in"){
				$(".save-button").hide();
				$(".checkout-button").show();
				$(".checkin-button").hide();
			}else{
				$(".save-button").show();
				$(".checkout-button").hide();
				$(".checkin-button").show();
			}
			$("#content-details").html("");
			$("#content-details").append(data.history);
			if(data.isPublished == "false"){
				$("[xml\\:base = '" + uri + "']").addClass("error-focus");
				_show_error("Content Mgmt", uri + " is not published. Users cannot view this template's content.", 60000);
				
			}else{
				$("[xml\\:base = '" + uri + "']").removeClass("error-focus");
			}
			
		}else{
			_show_error("Content Mgmt", "No information available for : " + uri);	
		}
	}
};




//TODO - this was inlined and should be replaced when we have a UI design, or if used
//       included appropriately

/**
Vertigo Tip by www.vertigo-project.com
Requires jQuery
*/

this.vtip = function() {    
    this.xOffset = -10; // x distance from mouse
    this.yOffset = 10; // y distance from mouse       
    
    $(".vtip").unbind().hover(    
        function(e) {
            this.t = this.title;
            this.title = ''; 
            this.top = (e.pageY + yOffset); this.left = (e.pageX + xOffset);
            
            $('body').append( '<p id="vtip"><img id="vtipArrow" />' + this.t + '</p>' );
                        
            $('p#vtip #vtipArrow').attr("src", 'images/vtip_arrow.png');
            $('p#vtip').css("top", this.top+"px").css("left", this.left+"px").fadeIn("slow");
            
        },
        function() {
            this.title = this.t;
            $("p#vtip").fadeOut("slow").remove();
        }
    ).mousemove(
        function(e) {
            this.top = (e.pageY + yOffset);
            this.left = (e.pageX + xOffset);
                         
            $("p#vtip").css("top", this.top+"px").css("left", this.left+"px");
        }
    );            
    
};
jQuery.fn.aPosition = function() {
thisLeft = this.offset().left;
thisTop = this.offset().top; 
thisParent = this.parent();
parentLeft = thisParent.offset().left;
parentTop = thisParent.offset().top;
return {
left: thisLeft-parentLeft, 
top: thisTop-parentTop
}
}
//jQuery(document).ready(function($){vtip();}) 
