xquery version "1.0-ml";

(:


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

:)


module namespace xqmvc-controller = "http://scholarsportal.info/xqmvc/controller";
import module namespace xqmvc = "http://scholarsportal.info/xqmvc/core" at "../../../system/xqmvc.xqy";
import module namespace cfg = "http://marklogic.com/plugins/marker/config" at "../config/config.xqy";
import module namespace xqmvc-cfg = "http://scholarsportal.info/xqmvc/config" at "/application/config/config.xqy";
import module namespace marker = "http://marklogic.com/marker" at "../library/marker.xqy";
import module namespace render = "http://marklogic.com/plugins/marker/render" at "../models/render-model.xqy";


(: Main controller for all CMS based requests :)
declare function index()
{
     let $uri := 
        if(xdmp:get-request-field("path"))
        then (
            if(fn:ends-with(xdmp:get-request-field("path"), "/"))
            then (fn:concat(xdmp:get-request-field("path"), $cfg:default-document))
            else if(fn:ends-with(xdmp:get-request-field("path"),$cfg:default-document))
            then (xdmp:get-request-field("path"))
            else (fn:concat(xdmp:get-request-field("path"), "/",$cfg:default-document))
            )
        else (
            if(xdmp:get-request-field($xqmvc-cfg:plugin-querystring-field))
            then fn:concat("/",xdmp:get-request-field($xqmvc-cfg:plugin-querystring-field), "/",xdmp:get-request-field($xqmvc-cfg:controller-querystring-field), "/",xdmp:get-request-field($xqmvc-cfg:function-querystring-field))
            else fn:concat("/",xdmp:get-request-field($xqmvc-cfg:controller-querystring-field), "/",xdmp:get-request-field($xqmvc-cfg:function-querystring-field))
            )
     
     let $full-uri := fn:concat($cfg:content-root,$uri)
     
     
     let $log := if ($xqmvc-cfg:debug) then xdmp:log(fn:concat("render path: ",$full-uri)) else ()
     return
        ( 
        xqmvc:plugin-template($cfg:plugin-name, 'render-template', ('content', render:display-content($full-uri)))
        )
};
