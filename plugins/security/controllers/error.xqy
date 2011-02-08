xquery version "1.0-ml";

(:
 : Copyright 2010 Avalon Consulting LLC
 :)
 
module namespace xqmvc-controller = "http://scholarsportal.info/xqmvc/controller";
import module namespace xqmvc = "http://scholarsportal.info/xqmvc/core" at "/system/xqmvc.xqy";

import module namespace oauth2 = "oauth2" at "../library/oauth2.xqy";
import module namespace plugin-cfg = "http://marklogic.com/plugins/security/config" at "../config/config.xqy";
import module namespace xqmvc-conf = "http://scholarsportal.info/xqmvc/config" at "/application/config/config.xqy";
import module namespace authorization = "http://marklogic.com/plugins/security/authorization" at "../models/authorization-model.xqy";

declare function index()
{
    ""
};


declare function not-found()
{
    ""
};
declare function not-authorized()
{
    if(authorization:isInstalled(""))
    then 
        (    
        xqmvc:template('master-template', (
            'browsertitle', '401 - Not authorized',
            'body', 'Sorry! You do not have access to requested page. Please login and try again.')
        )
        )
    else
        (
        xdmp:redirect-response("/security/setup/index")
        )
    
};
