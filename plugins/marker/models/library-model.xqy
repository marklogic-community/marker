xquery version "1.0-ml";
module namespace library-model = "http://marklogic.com/marker/model/library";
import module namespace library = "http://marklogic.com/marker/library" at "../library/library.xqy";
import module namespace dls = "http://marklogic.com/xdmp/dls" at "/MarkLogic/dls.xqy";
import module namespace xqmvc-conf = "http://scholarsportal.info/xqmvc/config" at "/application/config/config.xqy";
declare namespace html = "http://www.w3.org/1999/xhtml";


(: ########################################################################### :)
(: AJAX Formatted responses - might want to break this into its own library :)
(: ########################################################################### :)
declare function library-model:json-get-uri-information($uri){
    try{
        let $status := 
            if(library:checkoutStatus($uri))
            then (fn:string("out"))
            else (fn:string("in"))

        let $history := 
                        let $versions := 
                            for $version in library:versionHistory($uri)//version 
                            order by xs:integer($version/version-number/text()) descending
                            
                            return <tr class="{if ($version/published/text() eq 'false') then ('unpublished') else ('published')}">
                                        <td><div cmdValue="contentmgmt" class="marker_button marker_button_view" onclick="MarkerInlineEdit.getContainerVersionContent('{$version/version-uri/text()}');"></div></td>
                                        <td>{$version/version-number/text()}</td>
                                        <td>{fn:format-date(xs:date(fn:substring($version/created/text(),1, 10)),"[M1]/[D1]/[Y01]")}</td>
                                        <td>{$version/author/text()}</td>
                                        {
                                        if ($version/published/text() eq 'false')
                                        then
                                            (
                                                <td><div cmdValue="contentmgmt" class="marker_button marker_button_publish" onclick="MarkerInlineEdit.publishVersion('{$uri}','{$version/version-uri/text()}');"></div></td>
                                            )
                                        else
                                            (
                                                <td><div cmdValue="contentmgmt" class="marker_button marker_button_cancel" onclick="MarkerInlineEdit.unpublishVersion('{$uri}');"></div></td>
                                            )     
                                        }
                                    </tr>  
                        return <table class="ui-widget">
                                    <thead class="ui-widget-header">
                                        <tr><th>View</th><th>#</th><th>Date</th><th>By</th><th>Publish</th></tr>
                                    </thead>
                                    <tbody class="ui-widget-content">
                                        {for $item in $versions return $item}
                                    </tbody>
                                </table>
        let $isPublished := 
            if(library:isPublished($uri))
            then (fn:string("true"))
            else (fn:string("false"))
        let $cleaned-history := fn:replace(xdmp:to-json($history),'"','\\"')
        let $json-history := fn:substring(fn:substring($cleaned-history,3),1, fn:string-length($cleaned-history) - 4)
        return fn:concat("{&quot;status&quot;:", xdmp:to-json($status), ",&quot;isPublished&quot;:", xdmp:to-json($isPublished), ",&quot;history&quot;:&quot;",$json-history , "&quot;}")

        
    }
    catch ($e){
        let $log := xdmp:log(fn:concat("in library:unmanage : ",  fn:string($e)), "error")
        return fn:concat("{&quot;isSuccess&quot;:&quot;",fn:false(), "&quot;}")
    }
};
declare function library-model:json-checkout-status($uri){
    try{
        let $exec := library:checkoutStatus($uri)
        
        return 
            if($exec)
            then (fn:concat("{&quot;status&quot;:&quot;","out", "&quot;}"))
            else (fn:concat("{&quot;status&quot;:&quot;","in", "&quot;}"))
        
    }
    catch ($e){
        let $log := xdmp:log(fn:concat("in library:unmanage : ",  fn:string($e)), "error")
        return fn:concat("{&quot;isSuccess&quot;:&quot;",fn:false(), "&quot;}")
    }
};
declare function library-model:json-checkout($uri){
    try{
        let $exec := library:checkout($uri)
        return fn:concat("{&quot;isSuccess&quot;:&quot;",fn:true(), "&quot;}")
    }
    catch ($e){
        let $log := xdmp:log(fn:concat("in library:unmanage : ",  fn:string($e)), "error")
        return fn:concat("{&quot;isSuccess&quot;:&quot;",fn:false(), "&quot;}")
    }
};
declare function library-model:json-publish($uri){
    try{
        let $exec := library:publish($uri)
        return fn:concat("{&quot;isSuccess&quot;:&quot;",fn:true(), "&quot;}")
    }
    catch ($e){
        let $log := xdmp:log(fn:concat("in library:unmanage : ",  fn:string($e)), "error")
        return fn:concat("{&quot;isSuccess&quot;:&quot;",fn:false(), "&quot;}")
    }
};
declare function library-model:json-unpublish($uri){
    try{
        let $exec := library:unpublish($uri)
        return fn:concat("{&quot;isSuccess&quot;:&quot;",fn:true(), "&quot;}")
    }
    catch ($e){
        let $log := xdmp:log(fn:concat("in library:unmanage : ",  fn:string($e)), "error")
        return fn:concat("{&quot;isSuccess&quot;:&quot;",fn:false(), "&quot;}")
    }
};
declare function library-model:json-checkin($uri){
    try{
        let $exec := library:checkin($uri)
        return fn:concat("{&quot;isSuccess&quot;:&quot;",fn:true(), "&quot;}")
    }
    catch ($e){
        let $log := xdmp:log(fn:concat("in library:unmanage : ",  fn:string($e)), "error")
        return fn:concat("{&quot;isSuccess&quot;:&quot;",fn:false(), "&quot;}")
    }
};
declare function library-model:json-unmanage($uri){
    try{
        let $exec := library:unmanage($uri)
        return fn:concat("{&quot;isSuccess&quot;:&quot;",fn:true(), "&quot;}")
    }
    catch ($e){
        let $log := xdmp:log(fn:concat("in library:unmanage : ",  fn:string($e)), "error")
        return fn:concat("{&quot;isSuccess&quot;:&quot;",fn:false(), "&quot;}")
    }
};
declare function library-model:json-manage($uri){
    try{
        let $exec := library:manage($uri,"Inserted")
        return fn:concat("{&quot;isSuccess&quot;:&quot;",fn:true(), "&quot;}")
    }
    catch ($e){
        let $log := xdmp:log(fn:concat("in library:manage : ",  fn:string($e)), "error")
        return fn:concat("{&quot;isSuccess&quot;:&quot;",fn:false(), "&quot;}")
    }
};
declare function library-model:json-change-view-mode($mode){
    try{
        let $exec := xdmp:set-session-field("view-mode",$mode)
        return fn:concat("{&quot;isSuccess&quot;:&quot;",fn:true(), "&quot;}")
    }
    catch ($e){
        let $log := xdmp:log(fn:concat("in library:manage : ",  fn:string($e)), "error")
        return fn:concat("{&quot;isSuccess&quot;:&quot;",fn:false(), "&quot;}")
    }
};
declare function library-model:json-list-documents($directory, $depth, $echo, $filter, $start, $length){
    let $log := xdmp:log("in library:json-list-documents")
    let $total := library:count-documents($directory, $depth, $filter)
    let $data :=
        for $item at $i in library:list-documents($directory, $depth, $filter, $start, $length)
            let $uri := fn:document-uri($item)
            let $is-managed := fn:string(xdmp:quote(
                        element input {
                        attribute type { "checkbox" },
                        attribute class { "form-checkbox" },
                        attribute name { "is-managed" },
                        (
                        if(dls:document-is-managed($uri)) 
                        then (attribute checked { "checked" })
                        else ()
                        ),
                        attribute onclick { "library_manage(this);" },
                        attribute value { $uri }}))
(:            let $view_uri := comoms-dls:contentUrl($uri)
            let $edit_uri := fn:concat(comoms-dls:contentUrl($uri), "?edit=true")
            let $managed_doc_uri := comoms-dls:getManagedDocUri($uri)
            let $title := fn:string(xdmp:quote(
                        element a {
                        attribute href { $view_uri },
                        $item//title/text()
                        }))
            let $author := fn:string(comoms-dls:latestPublishedDocAuthor($uri))
            let $checkbox := fn:string(xdmp:quote(
                        element input {
                        attribute type { "checkbox" },
                        attribute class { "form-checkbox" },
                        attribute name { "uri" },
                        attribute value { $uri }}))
            let $edit := fn:string(xdmp:quote( element a { attribute href { $edit_uri
                        }, "Edit"} ))
            let $history := fn:string(xdmp:quote( element a { attribute href {
                        fn:concat("javascript:showHistory('", $uri, "');") }, "History"} ))
 :)
        return
 (:           xdmp:to-json((
                        $checkbox,
                        $title,
                        $item/node()/name(),
                        $author,
                        comoms-dls:publishedState($managed_doc_uri),
                        element small {
                        comoms-util:formatShortDateTime(xs:dateTime($item/property::prop:last-modified/text()))
                        },
                        fn:concat($edit, "&amp;nbsp;", $history)
                        ))
 :)
            xdmp:to-json((
                        $uri,
                        $is-managed
                        ))
    let $dataString := fn:string-join($data, ",")
    return
        (
        
        fn:concat("{",
        "&quot;sEcho&quot;: ", $echo, ", &quot;iTotalRecords&quot;:", $total,
        ", &quot;iTotalDisplayRecords&quot;:", $total,
        ", ", "&quot;aaData&quot;:[", $dataString, "]", "}")
        )
};

declare function library-model:json-update-uri-content($uri, $content){
    try{
        let $content := xdmp:unquote(fn:concat("<div>",fn:replace($content,"<br>","<br/>"),"</div>"), "", ("repair-full"))
        let $log := if ($xqmvc-conf:debug) then xdmp:log(fn:concat("Updating requested uri:", $uri )) else ()
        let $log := if ($xqmvc-conf:debug) then xdmp:log(fn:concat("content:", $content)) else ()
        let $exec := library:update($uri,$content, "Update from UI")
        return fn:concat("{&quot;isSuccess&quot;:&quot;",fn:true(), "&quot;}")
    }
    catch ($e){
        let $log := xdmp:log(fn:concat("in library:manage : ",  fn:string($e)), "error")
        return fn:concat("{&quot;isSuccess&quot;:&quot;",fn:false(), "&quot;}")
    }
};

declare function library-model:get-version-content($uri){
    try{
        let $exec := library:getContainerVersionContent($uri)
        return $exec
    }
    catch ($e){
        let $log := xdmp:log(fn:concat("in get-version-content : ",  fn:string($e)), "error")
        return fn:concat("{&quot;isSuccess&quot;:&quot;",fn:false(), "&quot;}")
    }
};

(: ########################################################################### :)
(: PRIVATE FUNCTIONS :)
(: ########################################################################### :)

declare function library-model:_import() {
    "xquery version '1.0-ml';
     import module namespace dls = 'http://marklogic.com/xdmp/dls' at '/MarkLogic/dls.xqy'; " 
};