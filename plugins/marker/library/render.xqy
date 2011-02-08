module namespace render = 'http://marklogic.com/marker/library/render';

import module namespace cfg = "http://marklogic.com/plugins/marker/config" at "../config/config.xqy";


(:
declare function render:_buildBreadcrumbHtml($start, $breadcrumb)
{
    let $pathParts := fn:reverse(fn:tokenize($start, "/"))
    let $count := fn:count($pathParts)
    return
        let $items :=
            for $part at $index in $pathParts 
            return
                if ($index eq 1) then
                (
                    <li></li>
                )                       
};:)

declare function render:buildNavHtml($start,$depth)
{
    let $current := ""
    return
        render:buildNavHtml($start, $depth, $current)
};

declare function render:buildNavHtml($start, $depth, $current)
{
    let $fixedCurrent := 
        if (fn:ends-with($current, "template.xhtml") or fn:ends-with($current, "/")) then $current
        else fn:concat($current, "/")
    let $pages := render:getChildPages($start)
    return
        if ($pages and $depth > 0) then
        (
            <ul>
            {        
                for $page in $pages    
                return
                    let $active := 
                        if ($fixedCurrent eq $page) then "active" else ""
                    let $pageParts := fn:tokenize($page, "/")
                    let $name := $pageParts[fn:count($pageParts) - 1]
                    let $li := <li class="{$active}"><a href="{$page}">{$name}</a></li>
                    let $node := fn:replace($page, "template.xhtml", "")
                    return
                        ($li, render:buildNavHtml($node, $depth - 1, $current))
            
            }    
            </ul> 
        )
        else ()       
};

declare function render:_getChildren($start, $uris)
{  
    for $uri in $uris
    return
        let $uriParts := fn:tokenize($uri, "/")
        let $uriCount := fn:count($uriParts)
        let $path := if (fn:ends-with($start, "/")) then $start else fn:concat($start, "/")
        let $pathParts := fn:tokenize($path, "/")
        let $pathCount := fn:count($pathParts)
        let $isNode := $uriParts[$uriCount] eq ""
        let $isChild := $uriCount eq $pathCount + 1
        return
            if (($isNode and $isChild) or ($pathCount eq $uriCount and fn:not($isNode))) then
                $uri
            else ()                                  
};

declare function render:_getAllStaticChildURIs($start)
{
    let $path := if (fn:ends-with($start, "/")) then $start else fn:concat($start, "/")
    return
        cts:uri-match(fn:concat($path, "*"))        
};

declare function render:getStaticChildren($start)
{
    let $uris := render:_getAllStaticChildURIs($start)
    return
        render:_getChildren($start,$uris)
};

declare function render:getChildNodes($start)
{
    let $children := render:getStaticChildren($start)
    for $child in $children
    return       
        if (fn:ends-with($child, "/")) then $child
        else ()
};

declare function render:getChildContainers($start)
{
    let $children := render:getStaticChildren($start)
    for $child in $children
    return       
        if (fn:ends-with($child, ".container")) then $child
        else ()    
};

declare function render:getStaticChildPages($start)
{
    let $children := render:getChildNodes($start)
    for $child in $children
    return
        cts:uri-match(fn:concat($child, "template.xhtml"))   
};

declare function render:getParentPage($current)
{
    let $isPage := fn:ends-with($current, "template.xhtml")
    return
        if ($isPage) then 
        (
            let $pageParts := fn:tokenize($current, "/")
            let $count := fn:count($pageParts)
            return
                fn:replace($current, fn:concat($pageParts[$count - 1], "/", $pageParts[$count]), "template.xhtml")   
        )
        else ()
         
};

declare function render:getMappings()
{
    let $mappings := fn:doc('/content-root/containers/mappings.xml')/mappings
    return
        $mappings
};

declare function render:_getAllDynamicChildURIs($start)
{
    let $mappings := render:getMappings()   
    let $regexes := $mappings/mapping/@regex
    let $uris := 
            for $regex in $regexes
            return
                fn:concat($cfg:container-root, fn:replace(fn:replace($regex, "\(.*?$", ""), "\^", ""))
    return
          fn:distinct-values($uris)
};

declare function render:getDynamicChildPages($start)
{
    let $uris := render:_getAllDynamicChildURIs($start)
    return
        render:_getChildren($start,$uris)
};

declare function render:getChildPages($start)
{
    let $staticPages := render:getStaticChildPages($start)
    let $dynamicPages := render:getDynamicChildPages($start)
    let $templates := render:getMappings()/mapping/@template
    return
        let $uniqueStaticPages := 
            for $page in $staticPages
            return
                if (fn:not(fn:index-of($templates, $page))) then $page else ()
        return
            ($dynamicPages, $uniqueStaticPages)
                
};






