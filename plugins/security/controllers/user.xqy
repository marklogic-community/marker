xquery version "1.0-ml";

(:
 : Copyright 2010 Avalon Consulting LLC
 :)
 
module namespace xqmvc-controller = "http://scholarsportal.info/xqmvc/controller";
import module namespace xqmvc = "http://scholarsportal.info/xqmvc/core" at "/system/xqmvc.xqy";

import module namespace oauth2 = "oauth2" at "../library/oauth2.xqy";
import module namespace user = "http://marklogic.com/plugins/security/user" at "../models/user-model.xqy";
import module namespace plugin-cfg = "http://marklogic.com/plugins/security/config" at "../config/config.xqy";
import module namespace application-cfg = "http://scholarsportal.info/xqmvc/config" at "/application/config/config.xqy";
declare namespace xdmphttp="xdmp:http";

declare function index()
{
    ()
};





