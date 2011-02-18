xquery version "1.0-ml";
module namespace library = "http://marklogic.com/marker/library";
import module namespace dls = "http://marklogic.com/xdmp/dls" at "/MarkLogic/dls.xqy";
import module namespace security = "http://marklogic.com/security" at "/plugins/security/library/security.xqy";
import module namespace util = "http://marklogic.com/marker/util" at "util.xqy";
import module namespace mem = "http://xqdev.com/in-mem-update" at "in-mem-update.xqy";
import module namespace functx = "http://www.functx.com" at '/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy';
import module namespace xqmvc-conf = "http://scholarsportal.info/xqmvc/config" at "/application/config/config.xqy";
declare namespace html = "http://www.w3.org/1999/xhtml";
declare namespace marker="http://marklogic.com/marker";

declare function library:list-documents($directory, $depth, $filter, $start, $length){
    let $log := xdmp:log("in library:list-documents")
    let $end := $start + $length -1
    return
    (
        cts:search(fn:doc(), 
        cts:and-query((
            cts:directory-query($directory, $depth), fn:concat($filter, "*"))))[$start to $end]
    )
};

declare function library:count-documents($directory, $depth, $filter){
    (:fn:count(cts:search(xdmp:directory($directory, $depth),
                    cts:element-word-query(xs:QName("html:title"), fn:concat($filter, "*"),
                    ("wildcarded", "whitespace-insensitive")))):)
    fn:count(cts:search(fn:doc(), 
        cts:and-query((
            cts:directory-query($directory, $depth), fn:concat($filter, "*")))))
                    
};

declare function library:manage($uri, $manageNote){
    let $log := xdmp:log("in library:manage with note.")
    return (
        xdmp:eval(
            fn:concat(
                library:_import(), 
                "
                declare variable $uri as xs:string external;
                declare variable $manageNote as xs:string external;
                dls:document-manage($uri, fn:false(), $manageNote)
                "
            ),
            (xs:QName("uri"), $uri, xs:QName("manageNote"), $manageNote)
        )
    )    
};
declare function library:unmanage($uri){
    let $log := xdmp:log("in library:unmanage.")
    return (
        xdmp:eval(fn:concat(library:_import(), "dls:document-unmanage('", $uri, "', fn:false(), fn:true())"))
    )
};
declare function library:is-managed($uri){
    let $log := xdmp:log("in library:unmanage.")
    return (
        xdmp:eval(fn:concat(library:_import(), "dls:document-is-managed('", $uri, "')"))
    )
};
declare function library:list-directories($start, $starting-depth){
    let $start :=
        if ($start eq "/")
        then ("/")
        else (fn:concat($start, "/"))
    let $uris := cts:uri-match(fn:concat($start, "*/"))
    let $first-level := 
        for $node in $uris
        return fn:tokenize($node,"/")[$starting-depth + 1]    
    for $node in fn:distinct-values($first-level)
    let $children := 
        let $next-level := $starting-depth + 1
        let $child := 
            if ($starting-depth eq 1)
            then (library:list-directories(fn:concat($start, $node),$next-level))
            else 
            (
                <li>
                <a href="{fn:concat($start, $node)}" title="{fn:concat($start, $node)}">{$node}</a>
                {
                if(library:list-directories(fn:concat($start, $node),$next-level) ne "")
                then (<ul>{library:list-directories(fn:concat($start, $node),$next-level)}</ul>)
                else ()
                }
                </li>
            ) 
        return $child
    return
        if($starting-depth eq 1)
        then 
        (
            <li>
            <a href="/{$node}" title="/{$node}">{$node}</a>
            {
            if($children) 
            then (<ul>{$children}</ul>)
            else ()
            }
            </li>
        )
        else $children
}; 
(:~
 : Make a call to insert and Manage. This IS NOT DONE WITHIN AN EVAL becuase
 : haven't figured out how to pass the permissions variable through to be bound
 :)
declare function library:insert($uri as xs:string, $doc as node(),  $note as xs:string){
    let $log := xdmp:log("in library:insert.")
    let $collection := "http://marklogic.com/marker/drafts"
    let $permissions := (xdmp:permission('marker-admin', 'update'), xdmp:permission('marker-admin', 'read')) 
    return dls:document-insert-and-manage($uri, fn:false(), $doc, $note, $permissions, $collection)
    (:
    let $collection := "http://marklogic.com/marker/drafts"
    return
        xdmp:eval(
            fn:concat(
                library:_import(), 
                "
                declare variable $uri as xs:string external;
                declare variable $doc as node() external;
                declare variable $collection as xs:string external;
                declare variable $note as xs:string external;
                dls:document-insert-and-manage($uri, fn:true(), $doc, $note, 
                    (xdmp:permission('mkp-anon', 'read'), xdmp:permission('marker-admin', 'update')) , $collection)
                "
            ),
            (xs:QName("uri"), $uri, xs:QName("doc"), $doc, xs:QName("note"), $note, xs:QName("collection"), $collection)
        )    
    :)    
    
};
declare function library:update($uri as xs:string, $doc as node(), $note as xs:string){
    (:place in meta data -- for search faceting only :)
    let $meta := library:insertMeta($doc, $uri)
    let $return := xdmp:eval(
        fn:concat(
            library:_import(), 
            "
            declare variable $uri as xs:string external;
            declare variable $doc as node() external;
            declare variable $note as xs:string external;
            dls:document-update($uri, $doc, $note, fn:true(), (xdmp:permission('marker-admin', 'update'), xdmp:permission('marker-admin', 'read')) )
            "
        ),
        (xs:QName("uri"), $uri, xs:QName("doc"), $doc, xs:QName("note"), $note)
    )

    return $return
 
};
declare function library:unmanageAndDelete($uris){
    for $uri in $uris
    let $unpublish := (xdmp:eval(
        fn:concat(library:_import(), 
            "import module namespace library = 'http://marklogic.avalonconsult.com/marker/library' at 'library.xqy'; library:unpublish('", 
            $uri, "')")))
    let $unmanage :=  (xdmp:eval(
        fn:concat(library:_import(), "dls:document-unmanage('", $uri, "', fn:false(), fn:true())"))
    )
    return
        xdmp:document-delete($uri)
};


declare function library:checkout($uri) {
    xdmp:eval(
        fn:concat(library:_import(), "dls:document-checkout('", $uri, "', fn:false())"))
}; 

declare function library:checkin($uri) {
    xdmp:eval(
        fn:concat(library:_import(), "dls:document-checkin('", $uri, "', fn:false())"))
}; 
declare function library:add($uri) {
    xdmp:eval(
        fn:concat(library:_import(), "dls:document-manage('", $uri, "', fn:false())")
    )    
}; 


declare function library:documentHistory($uri) {
    xdmp:eval(
        fn:concat(library:_import(), "dls:document-history('", $uri, "')")
    )
};

declare function library:checkoutStatus($uri) {
    xdmp:eval(
        fn:concat(library:_import(), "dls:document-checkout-status('", $uri, "')")
    )
};

(:~
 : call fn:doc but wrapped in an eval 
 :)
declare function library:docInEval($uri) {
    xdmp:eval(
        fn:concat(library:_import(), "fn:doc('", $uri, "')")
    )
};

(: ########################################################################### :)
(: PUBLISHING FUNCTIONS :)
(: ########################################################################### :)

(:~
 : Given a sequence of version URIs, publish all of these versions of each document
 : If there is a version of the same document already published, unpublish it 1st
 : 
 : When "publish" is referred to, we mean that it is put into the PUBLISHED collection
 : unpublish removes content from this collection
 : @param $version_uris - sequence of uris of versions of managed documents to publish
 :)
declare function library:publish($version_uris as item()*) {
    for $uri in $version_uris
    let $doc := fn:doc($uri)
    let $managed_base_uri := $doc/node()/property::dls:version/dls:document-uri/text()
    let $existing :=  library:publishedDoc($managed_base_uri)
    let $unpublishExisting := if($existing) then library:unpublishVersion((xdmp:node-uri($existing)))  else ()
    let $addPermissions := library:applyPermissions($uri, (xdmp:permission('security-anon', 'read')))
    let $addPermissions := library:applyPermissions($uri, (xdmp:permission('marker-admin', 'update')))
    let $addPermissions := library:applyPermissions($uri, (xdmp:permission('marker-admin', 'read')))
    
    let $searchable := 
        if(fn:doc($managed_base_uri)/property::marker:content/marker:searchable/text() eq 'true')
        then  
            (
            library:applyCollections($uri, ("http://marklogic.com/marker/searchable"))
            )
        else 
            (
            )
    return
        library:applyCollections($uri, ("http://marklogic.com/marker/published"))
};
declare function library:applyProperties($uri, $properties){
    let $eval-statement :=
        fn:concat (library:_import(), "declare variable $properties external;declare variable $uri external;", "dls:document-set-properties($uri, $properties)")
    return xdmp:eval($eval-statement,(xs:QName("properties"), $properties, xs:QName("uri"), $uri ))

};
declare function library:applyPermissions($uri, $permissions){
    let $eval-statement :=
        fn:concat (library:_import(), "declare variable $permissions external;declare variable $uri external;", "dls:document-add-permissions($uri, $permissions)")
    return xdmp:eval($eval-statement,(xs:QName("permissions"), ($permissions), xs:QName("uri"), $uri ))

};
declare function library:applyCollections($uri, $collections){
    let $eval-statement :=
        fn:concat (library:_import(), "declare variable $collections external;declare variable $uri external;", "dls:document-add-collections($uri, $collections)")
    return xdmp:eval($eval-statement,(xs:QName("collections"), ($collections), xs:QName("uri"), $uri ))

};
declare function library:removePermissions($uri, $permissions){
    let $eval-statement :=
        fn:concat (library:_import(), "declare variable $permissions external;declare variable $uri external;", "dls:document-remove-permissions($uri, $permissions)")
    return xdmp:eval($eval-statement,(xs:QName("permissions"), ($permissions), xs:QName("uri"), $uri ))

};
declare function library:removeCollections($uri, $collections){
    let $eval-statement :=
        fn:concat (library:_import(), "declare variable $collections external;declare variable $uri external;", "dls:document-remove-collections($uri, $collections)")
    return xdmp:eval($eval-statement,(xs:QName("collections"), ($collections), xs:QName("uri"), $uri ))

};
declare function library:insertMeta($doc, $uri)
{ 
    let $log := if ($xqmvc-conf:debug) then xdmp:log(fn:concat("Insert meta on base:", xdmp:quote($doc) )) else ()
    let $log := if ($xqmvc-conf:debug) then xdmp:log(fn:concat("Insert meta child on node name:", fn:node-name($doc/node()) )) else ()
    let $newXML := 
    element {fn:node-name($doc/node())} {
        $doc/node(),
        element marker:content {fn:doc(library:getManagedDocUri($uri))/property::marker:content/* }
        
    }   
    return $newXML
   
};
declare function library:stripMeta($doc as node())
{ 
    
    (:let $log := if ($xqmvc-conf:debug) then xdmp:log(fn:concat("pre cleaning:", xdmp:quote($doc) )) else ():)
    let $cleaned := functx:remove-elements-deep($doc,"content")
    (:let $log := if ($xqmvc-conf:debug) then xdmp:log(fn:concat("post cleaning:", xdmp:quote($doc) )) else ():)
    return $cleaned
    
   
};

declare function library:publishLatest($uri) {
    (: TODO check if it's in the draft collection probably :)
        
    let $latest_version_uri := library:latestVersionUri($uri)
    let $log:= xdmp:log(fn:concat("latest: ", $latest_version_uri))    
    let $log:= xdmp:log(fn:concat("uri: ", $uri))            
    return library:publish($latest_version_uri)    
    
};

declare function library:latestVersionUri($uri) {
    let $latest_version_num :=
        (
        for $version in dls:document-history($uri)/dls:version
        order by fn:number($version//dls:version-id/text()) descending
        return $version//dls:version-id/text()
        )[1]
        
        
    return dls:document-version-uri($uri, $latest_version_num)
};

declare function library:unpublish($uris as item()*) {
    for $uri in $uris
    return
        let $published_doc := library:publishedDoc($uri)
        return
            if($published_doc) 
            then (
                let $log := if ($xqmvc-conf:debug) then xdmp:log(fn:concat("Is published doc -- unpublishing uri:", $uri )) else ()
                let $published_version_uri := xdmp:node-uri($published_doc)
                return library:unpublishVersion($published_version_uri)  
                )      
            else
                (
                let $log := if ($xqmvc-conf:debug) then xdmp:log(fn:concat("Is not published doc -- not unpublishing:", $uri )) else ()
                return ()
                )
};

declare function library:latestPublishedDocAuthor($uri) {
    let $author_id := doc($uri)/property::dls:version/dls:author/text()
    return
        if($author_id) then
            security:getUsername($author_id)
        else 
            ()
    
};

(:~
 : Given a sequence of version URIs, unpublish all of these versions of each document
 :)
declare function library:unpublishVersion($version_uris as item()*) {
    for $uri in $version_uris
    return
        let $removePermissions :=  library:removePermissions($uri, (xdmp:permission('security-anon', 'read')))
        let $removeSearchable := library:removeCollections($uri, ("http://marklogic.com/marker/searchable"))
        return  library:removeCollections($uri, ("http://marklogic.com/marker/published"))        
};

(:~
 : Given the base URI of a managed piece of content, return the document of the node
 : of the version that is published
 :)
declare function library:publishedDoc($uri) {
    fn:collection("http://marklogic.com/marker/published")[property::dls:version/dls:document-uri = $uri] 
};


(:~
 : Test if any version of the managed document is published
 :)
declare function library:isPublished($uri) {
    if( library:publishedDoc($uri)) then
        fn:true()
    else
        fn:false()
};


declare function library:publishedState($uri) {
    let $doc := library:publishedDoc($uri)
    let $published_uri := if($doc) then xdmp:node-uri($doc) else ()
    let $latest := library:latestVersionUri($uri)
    return
        if($doc) then
            if($latest ne $published_uri) then
                "stale"
            else
                "published"
        else
            "unpublished"
};


declare function library:getManagedDocUri($uri) {
    let $doc := fn:doc($uri)
    let $managed_uri := $doc/property::dls:version/dls:document-uri/text()
    let $managed_uri := if($managed_uri) then $managed_uri else $uri
    return $managed_uri
};

(:~
 : Given a manage content url (e.g. /content/123456.xml) return the appropriate
 : version of the document based on what stage collection is being viewed and 
 : what's published
 :
 : @param $uri a manage content url (e.g. /content/123456.xml) - NOT A VERSIONED URI
 :)
declare function library:doc($uri) {
    let $doc := fn:root(library:collection()[property::dls:version/dls:document-uri = $uri][1])
    return
        if($doc) then 
            $doc 
        else 
            let $managedDocInCollection := library:collection-name() = xdmp:document-get-collections($uri)
            return
                if($managedDocInCollection) then
                    fn:doc($uri)
                else
                    ()
};

declare function library:marker-properties-bag($uri) {
    let $base-uri := library:getManagedDocUri($uri)
    let $eval-statement := fn:concat(library:_import(), "declare namespace marker='http://marklogic.com/marker';", "fn:doc('", $base-uri, "')/property::marker:content")
    return xdmp:eval
        (
        $eval-statement,
        (), 
        <options xmlns="xdmp:eval">
            <user-id>{xdmp:user("admin")}</user-id>
        </options>
        )
};

declare function library:content-header($properties-bag) {

   let $log := if ($xqmvc-conf:debug) then xdmp:log(fn:concat("content-header:", xdmp:quote($properties-bag) )) else ()
   return <div class="content-header">
        {
        if($properties-bag/marker:title)
        then ( <h2>{$properties-bag/marker:title/text()}</h2>)
        else ()
        }
       
        {
        if($properties-bag/marker:publish-date)
        then (<div class="date">{fn:format-dateTime($properties-bag/marker:publish-date/text(),"[Y01]/[M01]/[D01]")}</div>)
        else ()
        }
        {
        if($properties-bag//marker:author)
        then (<div class="author">By {fn:string-join($properties-bag//marker:author/text(), ", ")}</div>)
        else ()
        }
        &nbsp;
    </div>
};

(:~ 
 : Get the collection to be used when querying for content
 : THIS or library:collection-name() SHOULD BE USED WHEN BUILDING ANY QUERY FOR MANAGED CONTENT
 :)
declare function library:collection()  {
    fn:collection( library:collection-name() )
};

(:~ 
 : Get the collection nameto be used when querying for content
 : THIS or library:collection() SHOULD BE USED WHEN BUILDING ANY QUERY FOR MANAGED CONTENT 
 :)
declare function library:collection-name() as xs:string {
    "http://marklogic.com/marker/published"
};

(:~
 : Check if the published collection is being viewed
 :)
declare function library:isViewingPublished() {
    if(library:collection-name() = "http://marklogic.com/marker/published") then
        fn:true()
    else
        fn:false()
};

(:~
 : Get the best URL for the content URI. 
 : This is either the default URI based on detail type or should also take
 : into account friendly urls and navigation structures to figure out the 
 : best choice
 :)
declare function library:contentUrl($uri) {
    
    (: TODO: add friendly URL and nav structure logic 1st :)

    let $doc := fn:doc($uri)
    let $managedDocUri := $doc/property::dls:version/dls:document-uri
    let $uri := if($managedDocUri) then $managedDocUri else $uri
    let $type := $doc/node()/fn:name()
    let $content_id := fn:tokenize( fn:tokenize($uri, "/")[3], "\.")[1]
    return
        fn:concat("/", $type, "/", $content_id)
};

(:
 :
 :  gets list of doc versions and uri. 
 :
 :)
declare function library:versionHistory($uri) {
    let $published_doc := library:publishedDoc($uri)
    let $published_uri := if($published_doc) then xdmp:node-uri($published_doc) else ()
    return
    <versions>
        {
        for $version in dls:document-history($uri)/dls:version
          let $version_num := $version/dls:version-id/text()
          let $created := $version/dls:created/text()
          let $author_id := $version/dls:author/text()
          let $author := security:getUsername($author_id)
          
                
          let $note := $version/dls:annotation/text()
          let $version_uri := xdmp:node-uri(dls:document-version($uri, $version_num))
          let $published := $published_uri eq $version_uri
          return 
            <version>
                <version-number>{$version_num}</version-number>
                <created>{$created}</created>                
                <author>{$author}</author>
                <published>{$published}</published>
                <version-uri>{$version_uri}</version-uri>
            </version>  
        }        
    </versions>
};

declare function library:getContainerVersionContent($uri) {

    let $doc := fn:doc($uri)/div/node()
    return
       $doc
};








(: ########################################################################### :)
(: PRIVATE FUNCTIONS :)
(: ########################################################################### :)

declare function library:_import() {
    "xquery version '1.0-ml';
     import module namespace dls = 'http://marklogic.com/xdmp/dls' at '/MarkLogic/dls.xqy'; " 
};
