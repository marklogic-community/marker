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
module namespace marker = "http://marklogic.com/marker";

import module namespace mem = "http://xqdev.com/in-mem-update" 
          at "in-mem-update.xqy";
import module namespace security = "http://marklogic.com/security" 
          at "/plugins/security/library/security.xqy"; 
import module namespace library = "http://marklogic.com/marker/library" 
          at "library.xqy"; 
import module namespace util = "http://marklogic.com/marker/util"
          at "util.xqy"; 

(: ######################################################################### :)
(: ## CONTENT TYPE DEFINITION FUNCTIONS #################################### :)
(: ######################################################################### :)

(:~
 : Get the content type dictionary
 : @return content-type-dictionary node()
 :)
declare function marker:getContentTypeDictionary() as node()? {
    (: TODO replace with lookup by config property and URL? :)
    /content-type-dictionary
};


(:~
 : Return a content-type definition for a specified type
 : 
 : @param $type xs:string type name, one of those returned by getListOfContentTypes() or /admin/content
 : @return a content-type node for the given $type
:)
declare function marker:getContentTypeDefinition($type) {

    let $type-node := marker:getContentTypeDictionary()/content-types/content-type[@name eq $type]   
    return    
        element content-type { 
            $type-node/@*,       
            for $el in $type-node/element/text()
            let $el-def := /content-type-dictionary/element-types/element-type[@name eq $el]
            return 
                $el-def
        }
};

declare function marker:getContentTypeNames() {
    for $type in marker:getContentTypeDictionary()/content-types/content-type  
    return
        $type/@name  
};

(:~
 : Return list of configured content types
 :
 : Results looks like this:
 : <content-types> 
 :  <content-type name="article" label="Article"/> 
 :  <content-type name="recipe" label="Recipe"/> 
 : </content-types>
 :
 :)
declare function marker:getContentTypes() {
    element content-types {
        for $content-type in marker:getContentTypeDictionary()/content-types/content-type
        return 
            element content-type {
                $content-type/@*
            }
    }
};

(: ######################################################################### :)
(: ## CONTENT CREATION and UPDATE FUNCTIONS ################################ :)
(: ######################################################################### :)

(:~
 : Create a new piece of content (document in the MarkLogic database) assuming
 : the type is passed, look for the element fields as request parameters
 :
 : @param type the type of content, matching a type in the content type dictionary
 : @return
 :)
declare function marker:createContentByParameters($type) {

    (: ensure that a directory exists for content :)
    (: TODO make the content root configurable :)
    try {
        xdmp:directory-create("/content/")
    } 
    catch($ex) {()},
      
    (: TODO friendly URL mapping ?? :)
    
    
    (: First generate a placeholder piece of content with all of the structure :)
    let $doc := marker:generateNewContentItem($type)
    
    (: Get the sequence of request parameters and recursively walk through the parameters
       updating the doc in memory as we go. This needs to be recursive since the result of
       the in memory update is the updated document which needs to get passed to the next
       call to replace the value in the next parameter
     :)
    let $updatedDoc := marker:_updateElementsRecursivelyByParameters(xdmp:get-request-field-names(), $doc)

    (: create an optimistically unqiue uri for the content :)
    let $hash := xdmp:hash32( fn:concat( xs:string(fn:current-dateTime()), fn:data($updatedDoc)))
    let $uri := fn:concat("/content/", $hash, ".xml")

    (: namespace ??? :)
    (: validation ??? :)
    

    (: adding comoms-dls call :)
    let $note := "Adding doc to be managed."
    let $insert := library:insert($uri, $updatedDoc, $note)
    let $log := xdmp:log("between insert and manage.", "info")
    return 
        $uri
    (:
    
    return (xdmp:document-insert($uri, $updatedDoc,
        (xdmp:permission("mkp-anon", "read"), xdmp:permission("mkp-admin", "update"))), $uri)   
    :)
};




(:~
 : Given a type of content, generate the node structure
 :)
declare function marker:generateNewContentItem($type) {
    let $ctd := marker:getContentTypeDefinition($type)
    let $doc := marker:_printPlaceholderElements($ctd)
    return $doc
};







(: ######################################################################### :)
(: ## PRIVATE FUNCTIONS #################################################### :)
(: ######################################################################### :)


(:~
 : Recursive function that walks the content type definition nodes
 : and generates the stubbed out content type
 :)
declare function marker:_printPlaceholderElements($node) {
    if($node/element-type) then
        let $el-name := fn:data($node/@name)
        let $el-label := fn:data($node/@label)
        let $el-type := fn:data($node/@type)
        return
            element {$el-name} { 
                attribute type { $el-type },
                attribute label { $el-label },
                for $el in $node/element-type
                return
                    marker:_printPlaceholderElements($el)
            }
    else
            let $el-name := fn:data($node/@name)
            let $el-label := fn:data($node/@label)
            let $el-type := fn:data($node/@type)
            return
                element {$el-name} { 
                    attribute type { $el-type },
                    attribute label { $el-label },
                    if($el-type eq "dateTime") then
                        fn:current-dateTime()
                    else
                        "[-]"
                }
};    
    
(:~
 : Recursively walk the element-type node structure to find the element-type
 : node that's specified as a string deliminated by a "/"
 : 
 : IN: a/b/c
 : OUT (after recursion) c
 :)    
declare function marker:_getElementTypeByHierarchy($hierarchy, $node) {
    if(fn:count($hierarchy) gt 1) then
        marker:_getElementTypeByHierarchy($hierarchy[2 to fn:last()],$node/element-type[@name eq $hierarchy[1]])
    else
        (: for elements of type list, the list item may be delimiated in the parameter by # and the number in the list :)
        $node/element-type[@name eq fn:tokenize($hierarchy[1], "#")[1]]
};



(:
 : given a sequence of request parameter names, recursively grab the value of each 
 : parameter and update each corresponding node in memory, passing the updated document
 : though on each recursive call, finally bubbling up the completely updated node
 : FOR NEW DOCUMENTS NOT IN THE DATABASE YET, UPDATE IN MEMORY
 : Relies on in-mem-update.xqy library - http://github.com/marklogic/commons/blob/master/memupdate
 : 
 : @param $params sequence of parameters to recursively stop through
 : @param $doc the xml node to update
 :)
declare function marker:_updateElementsRecursivelyByParameters($params, $doc) {
    let $param := $params[1]
    return
        let $val := xdmp:get-request-field($param)
        let $val := if($val = "[-]") then "" else $val
        (:
        let $log := xdmp:log(fn:concat("in _updateElementsRecursivelyByParameters, param = ", $param))
        let $log := xdmp:log(fn:concat("val = ", $val))
        :)
        let $el :=  xdmp:unpath(fn:concat("$doc", "/", $param)) 
        let $type := $el/@type
        let $val := if($type = "xhtml") then xdmp:unquote(fn:concat("<wrapper>", $val, "</wrapper>"), "", ("repair-full"))/wrapper/* else $val
        let $val := if($type = "number") then fn:number($val) else $val
        let $log := xdmp:log(fn:concat("element = ", xdmp:quote($el)))

        return 
            if($el) then
                let $replacement := element {$el/fn:name()} { $el/@*, $val}
                let $updatedDoc := mem:node-replace($el, $replacement)
                return
                    if(fn:count($params) > 1) then
                        marker:_updateElementsRecursivelyByParameters($params[2 to fn:last()], $updatedDoc)
                    else
                        $updatedDoc
            else
                if(fn:count($params) > 1) then
                    marker:_updateElementsRecursivelyByParameters($params[2 to fn:last()], $doc)
                else
                    $doc
};



declare function marker:_isEditMode() {
    let $is_edit_mode := xdmp:get-request-field("edit") eq "true" or  fn:starts-with(xdmp:get-request-field("origpath"), "/admin/content/create")
    let $log := xdmp:log(fn:concat("isEditMode: ", $is_edit_mode), "debug")
    let $log := xdmp:log(fn:concat("path: ", xdmp:get-request-path()), "debug")
    return
        (:$is_edit_mode:)
        fn:true()
};

declare function marker:_cleanupField($type, $value) {
        (: if the field is xhtml, do some cleanup based on what tinymce does :)
        let $value := if($type = "xhtml" and $value instance of node() and fn:count($value/*) > 0) then $value/* else $value
        (: let $value := if($type = "xhtml" and fn:count($value) > 1) then <p>{$value}</p> else $value :)
        let $value := if(fn:not($type = "xhtml")) then fn:string($value) else $value
        return $value
};

