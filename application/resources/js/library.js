// TODO: find way to reference correct directory in plugin

var _pluginDirectory = "/"

/*
	FUNCTION: library_manage
	INPUT:
		element - item to evaluate
	OUTPUT:
*/
function library_manage(element){
	
	if($(element).attr("checked")){
		// insert into managed library
		_library_insert($(element).val())
	}else{
		// confirm and remove from library if necessary
		$( "#dialog-confirm" ).dialog({
			resizable: false,
			height:140,
			modal: true,
			buttons: {
				"Unmanage document": function() {
					// call remove manage
					_library_remove($(element).val());
					$( this ).dialog( "close" );
				},
				Cancel: function() {
					_show_info("Library", "Canceled remove from library");
					$(element).attr("checked", "true");
					$( this ).dialog( "close" );
				}
			}
		});
	}
}
/*
	FUNCTION: library_insert
	INPUT:
		uri - uri to insert
	OUTPUT:
*/
function _library_insert(uri){
	$.ajax({
		type: 'POST',
		url: _pluginDirectory + 'rest/manage-document',
		data: 'uri=' + uri,
		success: function(data){
			if(data.isSuccess == "true"){
				_show_info("Manage Document", uri + " is now managed.");
			}else{
				// TODO: reset data back
				_show_error("Manage Document", "An error occurred while attempting to manage the document");
			}
		},
		error: function(data, status, error){
			_show_error("Manage Document", "An error occurred while attempting to manage the document : " + error);
			// TODO: reset data back
		},
		dataType: 'json'
	});
}
/*
	FUNCTION: library_remove
	INPUT:
		uri - uri to remove
	OUTPUT:
*/
function _library_remove(uri, element){
	$.ajax({
		type: 'POST',
		url: _pluginDirectory + 'rest/unmanage-document',
		data: 'uri=' + uri,
		success: function(data){
			if(data.isSuccess == "true"){
				_show_info("Unmanage Document", uri + " is now unmanaged.");
			}else{
				// TODO: reset data back
				_show_error("Unmanage Document", "An error occurred while attempting to unmanage the document");
			}
		},
		error: function(data, status, error){
			_show_error("Unmanage Document", "An error occurred while attempting to unmanage the document : " + error);
			// TODO: reset data back
		},
		dataType: 'json'
	});
}

function _show_error(title, message){
	var handler = $("#notification-container").notify().notify("create", "themeroller-error", { title:title, text:message }, { custom:true });

}
function _show_info(title, message){
	var handler = $("#notification-container").notify().notify("create", "themeroller-info", { title:title, text:message }, { custom:true });
}


