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
 
 Marklogic Marker created/contributed by Avalon Consulting, LLC http://avalonconsult.com

:)
 
(:~
 : A module to create/edit/delete phrases from a database of languages.
 :)
module namespace render = "http://marklogic.com/plugins/marker/render";

import module namespace cfg = "http://marklogic.com/plugins/marker/config" at "../config/config.xqy";
import module namespace xqmvc-conf = "http://scholarsportal.info/xqmvc/config" at "/application/config/config.xqy";

declare namespace marker = "http://marklogic.com/plugins/marker";

declare function display-content($uri){
    (:<html><body>{$uri}</body></html>:)
    (:xdmp:log(fn:replace(fn:doc($uri), "<\?xml.*\?>" , "")):)
    (: check for dynamic bits :)
    let $log := if ($xqmvc-conf:debug) then xdmp:log(fn:concat("Loading uri:", $uri)) else ()
    return fn:doc($uri)/node()
};