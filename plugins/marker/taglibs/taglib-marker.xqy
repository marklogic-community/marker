xquery version "1.0-ml";
module namespace taglib-marker = "http://marklogic.com/marker/taglib/marker";
import module namespace security = "http://marklogic.com/security" at "/plugins/security/library/security.xqy";
import module namespace cfg = "http://marklogic.com/plugins/marker/config" at "../config/config.xqy";



declare function taglib-marker:editorJavascriptDependencies() {

    if(security:getCurrentUserRoles() eq $cfg:marker-bar-roles)
    then 
        (
        (
        (:<script>GENTICS_Aloha_base="/plugins/marker/resources/js/aloha/";</script>, 
        <script type="text/javascript" src="/plugins/marker/resources/js/aloha/aloha.js">&nbsp;</script>, 
        <script type="text/javascript" src="/plugins/marker/resources/js/aloha/plugins/com.gentics.aloha.plugins.Format/plugin.js">&nbsp;</script>, 
        <script type="text/javascript" src="/plugins/marker/resources/js/aloha/plugins/com.gentics.aloha.plugins.Table/plugin.js">&nbsp;</script>, 
        <script type="text/javascript" src="/plugins/marker/resources/js/aloha/plugins/com.gentics.aloha.plugins.List/plugin.js">&nbsp;</script>, 
        <script type="text/javascript" src="/plugins/marker/resources/js/aloha/plugins/com.gentics.aloha.plugins.Link/plugin.js">&nbsp;</script>, 
        <script type="text/javascript" src="/plugins/marker/resources/js/aloha/plugins/com.gentics.aloha.plugins.HighlightEditables/plugin.js">&nbsp;</script>, 
        <script type="text/javascript" src="/plugins/marker/resources/js/aloha/plugins/com.gentics.aloha.plugins.TOC/plugin.js">&nbsp;</script>, 
        <script type="text/javascript" src="/plugins/marker/resources/js/aloha/plugins/com.gentics.aloha.plugins.Link/delicious.js">&nbsp;</script>, 
        <script type="text/javascript" src="/plugins/marker/resources/js/aloha/plugins/com.gentics.aloha.plugins.Link/LinkList.js">&nbsp;</script>, 
        <script type="text/javascript" src="/plugins/marker/resources/js/aloha/plugins/com.gentics.aloha.plugins.Paste/plugin.js">&nbsp;</script>,
        <script type="text/javascript" src="/plugins/marker/resources/js/aloha/plugins/com.gentics.aloha.plugins.Image/plugin.js">&nbsp;</script>,
        <script type="text/javascript" src="/plugins/marker/resources/js/aloha/plugins/com.gentics.aloha.plugins.Plugin/plugin.js">&nbsp;</script>,
        <script type="text/javascript" src="/plugins/marker/resources/js/aloha/plugins/com.avalonconsult.aloha.plugins.Marker/plugin.js">&nbsp;</script>, 
        <script type="text/javascript" src="/plugins/marker/resources/js/aloha/plugins/com.gentics.aloha.plugins.Paste/wordpastehandler.js">&nbsp;</script>,:)
        <script type="text/javascript" src="/plugins/marker/resources/js/jquery-1.4.4.min.js">&nbsp;</script>,
        <script type="text/javascript" src="/application/resources/js/main.js">&nbsp;</script>,
        <script type="text/javascript" src="/plugins/marker/resources/js/jquery-ui-1.8.7.custom.min.js">&nbsp;</script>,
        <script type="text/javascript" src="/plugins/marker/resources/js/superfish.js">&nbsp;</script>,
        <script type="text/javascript" src="/plugins/marker/resources/js/colorpicker.js">&nbsp;</script>,
        <script type="text/javascript" src="/plugins/marker/resources/js/hoverIntent.js">&nbsp;</script>,
        <script type="text/javascript" src="/plugins/marker/resources/js/rangy-core.js">&nbsp;</script>,
        <script type="text/javascript" src="/plugins/marker/resources/js/rangy-selectionsaverestore.js">&nbsp;</script>,
        <script type="text/javascript"> 
            
            // initialise plugins
            jQuery(function(){{
                jQuery('ul.sf-menu').superfish();
            }});
        </script>,
        <script type="text/javascript" src="/plugins/marker/resources/js/editor.js">&nbsp;</script>,
        <script type="text/javascript" src="/plugins/marker/resources/js/jquery.cookie.js">&nbsp;</script>,
        
        <script type="text/javascript" src="/plugins/marker/resources/js/inlineEditor.js">&nbsp;</script>
        )
        )
    else
        (
        (
        <script type="text/javascript" src="/plugins/marker/resources/js/jquery-1.4.4.min.js">&nbsp;</script>,
        <script type="text/javascript" src="/application/resources/js/main.js">&nbsp;</script>,  
        <script type="text/javascript" src="/plugins/marker/resources/js/jquery-ui-1.8.7.custom.min.js">&nbsp;</script>,
        <script type="text/javascript" src="/plugins/marker/resources/js/superfish.js">&nbsp;</script>,
        <script type="text/javascript" src="/plugins/marker/resources/js/hoverIntent.js">&nbsp;</script>,
        <script type="text/javascript">
                    // initialise plugins
            jQuery(function(){{
                jQuery('ul.sf-menu').superfish();
            }});
        </script> 
        )
        )

};

declare function taglib-marker:editorCSSDependencies()
{
    (
        <link rel="stylesheet" type="text/css" href="/plugins/marker/resources/css/editor.css"/>,
        <link rel="stylesheet" type="text/css" media="screen" href="/application/resources/css/smoothness/jquery-ui-1.8.9.custom.css"/>
    )

};
declare function taglib-marker:adminBar()
{
 if(security:getCurrentUserRoles() eq $cfg:marker-bar-roles)
    then 
        (
        <style>
            body{{
                margin-top:30px;
            }}
        </style>,
        <script>var viewMode="{xdmp:get-session-field("view-mode","PUBLISHED")}";</script>,
        <div id="marker-admin"> 
            <div id="marker-admin-menu" class="marker-admin-default"> 
               <div id="marker-admin-menu-left">&nbsp;
               </div>
               <div id="marker-admin-menu-center">&nbsp;
               </div>
               <div id="marker-admin-menu-right">&nbsp;
               </div>
            </div>
        </div>
        )
    else ()
};

declare function taglib-marker:notifications()
{
    <div id="notification-container" style="display:none">
         <div id="themeroller-error" class="ui-state-error">
                <a class="ui-notify-close" href="#">
                    <span class="ui-icon ui-icon-close" style="float:right">&nbsp;</span>
                </a>
                <span style="float:left; margin:2px 5px 0 0;" class="ui-icon ui-icon-alert">&nbsp;</span>
         
                <h1>#{{title}}</h1>
                <p>#{{text}}</p>
            </div>
            <div id="themeroller-info" class="ui-state-active">
                <a class="ui-notify-close" href="#">
                    <span class="ui-icon ui-icon-close" style="float:right">&nbsp;</span>
                </a>
                <span style="float:left; margin:2px 5px 0 0;" class="ui-icon ui-icon-info">&nbsp;</span>
         
                <h1>#{{title}}</h1>
                <p>#{{text}}</p>
            </div>
 
        </div>
    

};
