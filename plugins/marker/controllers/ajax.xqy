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
import module namespace xqmvc = "http://scholarsportal.info/xqmvc/core" at "/system/xqmvc.xqy";

import module namespace library-model = "http://marklogic.com/marker/model/library" at "../models/library-model.xqy";
import module namespace library = "http://marklogic.com/marker/library" at "../library/library.xqy";

declare function index()
{
    list-documents()
};
declare function list-documents()
{
    let $directory := xdmp:get-request-field("directory", "/")
    let $depth := "infinity"
    let $echo := xdmp:get-request-field("sEcho", "1")
    let $filter := xdmp:get-request-field("sSearch", "")
    let $start := xs:unsignedLong( xdmp:get-request-field("iDisplayStart", "0")) + 1
    let $length := xs:unsignedLong( xdmp:get-request-field("iDisplayLength","10"))
    
    return 
        (
        xdmp:set-response-content-type("application/json"),
        library-model:json-list-documents($directory, $depth, $echo,$filter,$start,$length)
        )
        
};
declare function unmanage-document()
{
    let $uri := xdmp:get-request-field("uri", "")
    return 
        (
        xdmp:set-response-content-type("application/json"),
        library-model:json-unmanage($uri)
        )
        
};
declare function manage-document()
{
    let $uri := xdmp:get-request-field("uri", "")
    return 
        (
        xdmp:set-response-content-type("application/json"),
        library-model:json-manage($uri)
        )
        
};
declare function update-uri-content()
{
    let $uri := xdmp:get-request-field("uri")
    let $content := xdmp:get-request-field("content")
    return 
        (
        xdmp:set-response-content-type("application/json"),
        library-model:json-update-uri-content($uri, $content)
        )
        
};
declare function checkout-status()
{
    let $uri := xdmp:get-request-field("uri")
    return 
        (
        xdmp:set-response-content-type("application/json"),
        library-model:json-checkout-status($uri)
        )
        
};
declare function checkout()
{
    let $uri := xdmp:get-request-field("uri")
    return 
        (
        xdmp:set-response-content-type("application/json"),
        library-model:json-checkout($uri)
        )
        
};
declare function checkin()
{
    let $uri := xdmp:get-request-field("uri")
    return 
        (
        xdmp:set-response-content-type("application/json"),
        library-model:json-checkin($uri)
        )
        
};
declare function publish()
{
    let $uri := xdmp:get-request-field("uri")
    return 
        (
        xdmp:set-response-content-type("application/json"),
        library-model:json-publish($uri)
        )
        
};
declare function unpublish()
{
    let $uri := xdmp:get-request-field("uri")
    return 
        (
        xdmp:set-response-content-type("application/json"),
        library-model:json-unpublish($uri)
        )
        
};
declare function get-version-content()
{
    let $uri := xdmp:get-request-field("uri")
    return 
        (
        xdmp:set-response-content-type("text/html"),
        library-model:get-version-content($uri)
        )
        
};
declare function get-uri-information()
{
    let $uri := xdmp:get-request-field("uri")
    return 
        (
        xdmp:set-response-content-type("application/json"),
        library-model:json-get-uri-information($uri)
        )
};
declare function change-view-mode()
{
    let $mode := xdmp:get-request-field("mode")
    return 
        (
        xdmp:set-response-content-type("application/json"),
        library-model:json-change-view-mode($mode)
        )
};
