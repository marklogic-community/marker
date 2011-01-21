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
import module namespace xqmvc = "http://scholarsportal.info/xqmvc/core" at "../../../system/xqmvc.xqy";
import module namespace cfg = "http://scholarsportal.info/xqmvc/langedit/config" at "../config/config.xqy";
import module namespace render = "http://marklogic.com/plugins/render" at "../models/render-model.xqy";
declare variable $data as map:map external;

xdmp:set-response-content-type('text/html'),
$xqmvc:doctype-xhtml-1.1,
map:get($data, 'content')