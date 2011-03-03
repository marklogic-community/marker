xquery version "1.0-ml";
(:

 Copyright 2010 MarkLogic Corporation 
 Copyright 2009 Ontario Council of University Libraries

 Licensed under the Apache License, Version 2.0 (the "License"); 
 you may not use this file except in compliance with the License. 
 You may obtain a copy of the License at 

        http://www.apache.org/licenses/LICENSE-2.0 

 Unless required by applicable law or agreed to in writing, software 
 distributed under the License is distributed on an "AS IS" BASIS, 
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
 See the License for the specific language governing permissions and 
 limitations under the License. 
 


:)
import module namespace xqmvc = "http://scholarsportal.info/xqmvc/core" at "../../system/xqmvc.xqy";
import module namespace taglib-security = "http://marklogic.com/plugin/security/taglib" at "/plugins/security/taglibs/taglib-auth.xqy";
import module namespace taglib-plugins = "http://marklogic.com/xqmvc/taglib/plugins" at "/application/taglibs/taglib-plugins.xqy";
   

declare variable $data as map:map external;

xdmp:set-response-content-type('text/html'),

$xqmvc:doctype-xhtml-1.1,

<html>
    <head>
        <title>{ map:get($data, 'browsertitle') }</title>
        <script type="text/javascript" src="{ $xqmvc:resource-dir }/js/jquery-1.4.4.min.js">&nbsp;</script>
        <script type="text/javascript" src="{ $xqmvc:resource-dir }/js/jquery-ui-1.8.7.custom.min.js">&nbsp;</script>
        <script type="text/javascript" src="{ $xqmvc:resource-dir }/js/jquery.dataTables.min.js">&nbsp;</script>
        <script type="text/javascript" src="{ $xqmvc:resource-dir }/js/library.js">&nbsp;</script>
        <script type="text/javascript" src="{ $xqmvc:resource-dir }/js/main.js">&nbsp;</script>
        
        <script type="text/javascript" src="{ $xqmvc:resource-dir }/js/jquery.jstree.js">&nbsp;</script>
        <link rel="stylesheet" type="text/css" media="screen" href="{ $xqmvc:resource-dir }/css/style.css"/>
        <link rel="stylesheet" type="text/css" media="screen" href="{ $xqmvc:resource-dir }/css/smoothness/jquery-ui-1.8.9.custom.css"/>
        <link rel="shortcut icon" type="image/vnd.microsoft.icon" href="http://drbeddow.com/wp-content/themes/thistle/favicon.ico" />
    </head>
    <body>
    <div id="wrap">
    <div id="container">
      <div id="header" style="position:relative;">
        <h1 id="blog-title"><a href="http://github.com/marklogic/xqmvc">XQMVC</a></h1>
        <p id="blog-desc"><span>Application bootstrap and installation</span></p>
        <div style="position:absolute;top:5px;right:5px;width:150px;text-align:right;"> {taglib-security:login-logout()}</div>
        <div id="navigation">
        <ul>
          &nbsp;   
        </ul>
      </div>
    </div>
    
    <div id="col-wrap">
      <div id="content">
        <div>{ map:get($data, 'body') }</div>
      </div>

      <div id="sidebar">
          <div class="sidebar-top">&#160; </div>
          <ul class="xoxo"> 
                <h2>Administration</h2> 
                {taglib-plugins:plugins-list()} 
          </ul>
          <div class="sidebar-bottom"> &#160;</div>
       </div>
    </div>
    <div id="footer">
       <p>Copyright © 2010-11 MarkLogic Corporation, All rights reserved.</p>
    </div>
</div>
</div>
   
      
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
       
    </body>
</html>
