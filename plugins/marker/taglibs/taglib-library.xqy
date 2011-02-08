xquery version "1.0-ml";
module namespace taglib-library = "http://marklogic.com/marker/taglib/library";
import module namespace library = "http://marklogic.com/marker/library" at "../library/library.xqy";
declare namespace html = "http://www.w3.org/1999/xhtml";

declare function taglib-library:directory-management()
{
    <div id="main-content">
        <table id="contentlist" class="display">
            <thead>
                <tr>
                    <th>Title</th>
                    <th>Is Managed</th>

                </tr>
            </thead>
            <tbody>
             </tbody>
        </table>
        <div id="dialog-confirm" style="display:none;" title="Remove document from library management?">
            <p><span class="ui-icon ui-icon-alert" style="float:left; margin:0 7px 20px 0;">&nbsp;</span>This document will be removed from the library and all history will be lost. Are you sure?</p> 
        </div>
        <script type="text/javascript">
        function updateDirectoryLocation(location){{
            directory = location + "/";
            oTable.fnDraw();
         }}
       jQuery.fn.dataTableExt.oApi.fnSetFilteringDelay = function ( oSettings, iDelay ) {{
            var _that = this, iDelay = (typeof iDelay == 'undefined') ? 250 : iDelay;
            
            this.each( function ( i ) {{
                $.fn.dataTableExt.iApiIndex = i;
                var
                    $this = this, 
                    oTimerId = null, 
                    sPreviousSearch = null,
                    anControl = $( 'input', _that.fnSettings().aanFeatures.f );
                
                    anControl.unbind( 'keyup' ).bind( 'keyup', function() {{
                    var $$this = $this;
        
                    if (sPreviousSearch === null || sPreviousSearch != anControl.val()) {{
                        window.clearTimeout(oTimerId);
                        sPreviousSearch = anControl.val();  
                        oTimerId = window.setTimeout(function() {{
                            $.fn.dataTableExt.iApiIndex = i;
                            _that.fnFilter( anControl.val() );
                        }}, iDelay);
                    }}
                }});
                
                return this;
            }} );
            return this;
        }}
        var oTable;
        var directory = "/"
        $(document).ready(function() {{
            /* Initialise the DataTable */
            oTable = $('#contentlist').dataTable( {{
                "oLanguage": {{
                    "sSearch": "Search all columns:"
                }},
                "sPaginationType": "full_numbers",
                "bProcessing": true,
                "bServerSide": true,
                "fnServerData": function ( sSource, aoData, fnCallback ) {{
                    /* Add some extra data to the sender */
                    aoData.push( {{ "name": "directory", "value": directory }} );
                    $.getJSON( sSource, aoData, function (json) {{ 
                        /* Do whatever additional processing you want on the callback, then tell DataTables */
                        fnCallback(json);
                    }} );}},
                "sAjaxSource": "/marker/ajax/list-documents",
                "bAutoWidth":true,
                "bJQueryUI": true,
                "aoColumns" : [null, null]
            }} );
            
            oTable.fnSetFilteringDelay(500);
            
            $("#contentlist").css("width","100%");
            
  
        }});
        </script> 
    </div>
    
        
};
declare function taglib-library:directory-tree(){
    <div >
        <div class="ui-widget-header" style="padding:5px;" onclick="try{{updateDirectoryLocation('');}}catch(e){{}}">{xdmp:database-name(xdmp:database())}</div>
         <div id="directory" class="directory">
        <ul>
         <li>
         <a href="" title="">{xdmp:database-name(xdmp:database())}</a>
         <ul>
         {library:list-directories("/", 1)}
        </ul>
         </li>
        </ul>
        
        </div>
        <script type="text/javascript">
         $(function () {{
                $("#directory").jstree({{ 
                    "plugins" : [ "html_data", "ui", "themeroller"]
                }});
                $(".jstree a").live("click", function(e) {{
                    try{{
                        updateDirectoryLocation(this.title);
                    }}catch(e){{}}
               }}) 
            }});
        </script>
    </div>
};