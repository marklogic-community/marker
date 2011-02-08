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
 : Plugin-level configuration.
 :)
module namespace this = "http://marklogic.com/plugins/marker/config";
(:
 : Change the name of this plugin if it conflicts with another XQMVC plugin.
 :)
declare variable $plugin-name as xs:string := 'marker';
(:
 : URI root for where assembled content is kept. No trailing slash.
 :)
declare variable $content-root as xs:string := '/content-root/site';
(:
 : URI default file when none specified for where assembled content is kept. No trailing slash.
 :)
declare variable $default-document as xs:string := 'template.xhtml';
(:
 : URI root for where containers are kept. No trailing slash.
 :)
declare variable $container-root as xs:string := '/content-root/containers';
(:
 : URI root for where containers are kept. No trailing slash.
 :)
declare variable $marker-bar-roles := ('marker-admin', 'marker-editor', 'marker-publisher', 'marker-user');



