xquery version "1.0-ml";

(:
 : Copyright 2009 Ontario Council of University Libraries
 : 
 : Licensed under the Apache License, Version 2.0 (the "License");
 : you may not use this file except in compliance with the License.
 : You may obtain a copy of the License at
 : 
 :    http://www.apache.org/licenses/LICENSE-2.0
 : 
 : Unless required by applicable law or agreed to in writing, software
 : distributed under the License is distributed on an "AS IS" BASIS,
 : WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 : See the License for the specific language governing permissions and
 : limitations under the License.
 :)
 
(:~
 : A module to create/edit/delete phrases from a database of languages.
 :)
module namespace render = "http://marklogic.com/plugins/marker/render";

import module namespace cfg = "http://marklogic.com/plugins/marker/config" at "../config/config.xqy";
import module namespace xqmvc-conf = "http://scholarsportal.info/xqmvc/config" at "/application/config/config.xqy";
import module namespace xinc = "http://marklogic.com/xinclude" at "/MarkLogic/xinclude/xinclude.xqy";
import module namespace mem = "http://xqdev.com/in-mem-update" at "../library/in-mem-update.xqy";
import module namespace taglib-marker = "http://marklogic.com/marker/taglib/marker" at "../taglibs/taglib-marker.xqy";
import module namespace marker-lib = "http://marklogic.com/marker" at "../library/marker.xqy";
import module namespace library = "http://marklogic.com/marker/library" at "../library/library.xqy";
import module namespace security = "http://marklogic.com/security" at "/plugins/security/library/security.xqy";
import module namespace functx = "http://www.functx.com" at '/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy';

import module namespace dls = 'http://marklogic.com/xdmp/dls' at '/MarkLogic/dls.xqy'; 
declare namespace marker = "http://marklogic.com/plugins/marker";

declare function display-content($uri){
    let $log := if ($xqmvc-conf:debug) then xdmp:log(fn:concat("Loading requested uri:", $uri)) else ()
     let $log := if ($xqmvc-conf:debug) then xdmp:log(fn:concat("Loading mode:", xdmp:get-session-field("view-mode"))) else ()
    (: check if viewing published or library :)
    let $content :=
        try{
            if(xdmp:get-session-field("view-mode",library:collection-name()) eq library:collection-name())
            then dls:node-expand(library:doc($uri)/*,cts:collection-query((library:collection-name())))
            else dls:node-expand(library:doc($uri)/*,())
        }catch ($e){
            let $log := xdmp:log(fn:concat("Missing published content for uri : ",$uri , " error:", fn:string($e)), "error")
            return 
                (
                if(xdmp:get-current-user() ne "security-anon" and security:getCurrentUserRoles() eq $cfg:marker-bar-roles)
                then
                    (
                    let $log := if ($xqmvc-conf:debug) then xdmp:log(fn:concat("In marker role switching to editable:", $uri)) else ()
                    let $_ := xdmp:set-session-field("view-mode", "EDITABLE")
                    return dls:node-expand(fn:doc($uri)/node(),())
                    )
                else
                    (
                    let $log := if ($xqmvc-conf:debug) then xdmp:log(fn:concat("Not logged in -- redirecting:", $uri)) else ()
                    (: for security redirect  - TODO - finish :)
                    let $_ := xdmp:set-session-field("redirect", fn:replace(fn:replace($uri, $cfg:default-document, ''),$cfg:content-root,''))
                    return ()
                    )
                )
            
        } 
    let $log := if ($xqmvc-conf:debug) then xdmp:log(fn:concat("Base content:", xdmp:quote($content))) else ()   
    let $log := if ($xqmvc-conf:debug) then xdmp:log(fn:concat("Injecting content:", $uri)) else ()
    let $log := if ($xqmvc-conf:debug) then xdmp:log(fn:concat("Initial redirect set to:", xdmp:get-session-field("init-redirect"))) else ()   
    let $injectedContent := mem:node-insert-child($content//head,taglib-marker:editorJavascriptDependencies())
    let $log := if ($xqmvc-conf:debug) then xdmp:log("Injected javascript") else ()
    let $injectedContent := mem:node-insert-child($injectedContent//head,taglib-marker:editorCSSDependencies())
    let $log := if ($xqmvc-conf:debug) then xdmp:log("Injected css") else ()
    let $injectedContent := mem:node-insert-after($injectedContent//body,taglib-marker:adminBar())
    let $log := if ($xqmvc-conf:debug) then xdmp:log("Injected admin bar") else ()
    let $injectedContent := mem:node-insert-after($injectedContent//body,taglib-marker:notifications())
    let $log := if ($xqmvc-conf:debug) then xdmp:log("Injected notifications") else ()
    let $params :=
        for $name in xdmp:get-request-field-names()
        let $log := if ($xqmvc-conf:debug) then xdmp:log(fn:concat("param:", $name, " value:", xdmp:get-request-field(fn:string($name)))) else ()
        return (xs:QName(fn:string($name)), xdmp:get-request-field(fn:string($name)))
    let $injectedContent := _resolveDynamicContent($injectedContent,$params)
    let $log := if ($xqmvc-conf:debug) then xdmp:log("Injected dynamic content") else ()
    
    return 
        if ($injectedContent)
        then 
            (
            library:stripMeta($injectedContent)
            )
        else 
            (
            (: for install only on the init redirect :)
            if(xdmp:get-session-field("init-redirect"))
            then
                (
                xdmp:redirect-response(xdmp:get-session-field("init-redirect"))
                )
            else
                (
                xdmp:redirect-response("/security/error/not-authorized")
                )
            ) 
};
declare function _resolveDynamicContent($doc, $params)
{
    let $dynamicDoc := 
        if (($doc//exec)[1])
        then 
            (
            
            let $exec := fn:replace(fn:replace(xdmp:quote(($doc//exec)[1]), "<exec.*?>", ""), "</exec>", "")
            let $rendered := xdmp:eval($exec, $params)
            let $log := if ($xqmvc-conf:debug) then xdmp:log(fn:concat("Exec statement:", xdmp:quote($exec))) else ()
            let $log := if ($xqmvc-conf:debug) then xdmp:log(fn:concat("rendered:", xdmp:quote($rendered))) else ()
                (:let $rendered := xdmp:eval(fn:string(($doc//exec/text())[1])):)
            return
                ( 
                if(($doc//exec/text())[2])
                then 
                    (
                        if ($rendered) then 
                            _resolveDynamicContent(mem:node-replace(($doc//exec)[1],$rendered) , $params)
                        else 
                            _resolveDynamicContent(mem:node-replace(($doc//exec)[1], <p>There was a problem with this region</p>), $params)
                    )
                else 
                    (
                        if ($rendered) then 
                            mem:node-replace(($doc//exec)[1],$rendered)
                        else 
                            mem:node-replace(($doc//exec)[1],<p>There was a problem with this region</p>)
                    )
                )
            )
        else ($doc)
    return 
        $dynamicDoc   
};