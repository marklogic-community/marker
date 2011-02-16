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
import module namespace cfg = "http://marklogic.com/plugins/marker/config" at "../config/config.xqy";
import module namespace role = "http://marklogic.com/plugins/security/role" at "/plugins/security/models/role-model.xqy";
import module namespace authorization = "http://marklogic.com/plugins/security/authorization" at "/plugins/security/models/authorization-model.xqy";
import module namespace dls="http://marklogic.com/xdmp/dls" at "/MarkLogic/dls.xqy"; 
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
import module namespace library = "http://marklogic.com/marker/library" at "../library/library.xqy";
import module namespace mem = "http://xqdev.com/in-mem-update" at "../library/in-mem-update.xqy";
declare namespace xi="http://www.w3.org/2001/XInclude";
declare namespace dir="http://marklogic.com/xdmp/directory";
declare namespace ml="http://developer.marklogic.com/site/internal";
import module namespace xqmvc-conf = "http://scholarsportal.info/xqmvc/config" at "/application/config/config.xqy";
declare namespace marker="http://marklogic.com/marker";

declare function index()
{
    let $_ := role:createRole("marker-admin", "Admin user role for marker")
    return xqmvc:template('master-template', (
            'browsertitle', 'marker Setup',
            'body', xqmvc:plugin-view($cfg:plugin-name,'setup-index-view', ())
        ))
};
declare function install()
{
    
      
    
    let $_ := role:addRoleToRole("marker-admin","dls-admin")
    let $_ := role:addRoleToRole("marker-admin","dls-internal")
    let $_ := role:addUserToRole(xdmp:get-current-user(), "marker-admin")       
   
    let $addRoles := authorization:addPrivileges("marker-admin", 
        ("http://marklogic.com/xdmp/privileges/xdmp-invoke",
         "http://marklogic.com/xdmp/privileges/xdmp-eval",
         "http://marklogic.com/xdmp/privileges/xdmp-login",
         "http://marklogic.com/xdmp/privileges/xdmp-eval-in",
         "http://marklogic.com/xdmp/privileges/create-user",
         "http://marklogic.com/xdmp/privileges/any-uri",     
         "http://marklogic.com/xdmp/privileges/any-collection",
         "http://marklogic.com/xdmp/privileges/grant-all-roles",
         "http://marklogic.com/xdmp/privileges/get-user-names",
         "http://marklogic.com/xdmp/privileges/xdmp-value",
         "http://marklogic.com/xdmp/privileges/admin-module-read",
         "http://marklogic.com/xdmp/privileges/admin-module-write",
         "http://marklogic.com/xdmp/privileges/get-role-names",
         "http://marklogic.com/xdmp/privileges/xdmp-eval-in",
         "http://marklogic.com/xdmp/privileges/dls-user",
         "http://marklogic.com/xdmp/privileges/xdmp-filesystem-directory",
         "http://marklogic.com/xdmp/privileges/xdmp-document-get",
         "http://marklogic.com/xdmp/privileges/get-user-names"))         
    
    let $allVersionsRuleExists := fn:data(dls:retention-rules("All Versions Retention Rule")/dls:name)
    let $versionsRule := 
            if("All Versions Retention Rule" = $allVersionsRuleExists) then 
                "Rule 'All Versions Retention Rule' already exists."
            else
                let $a := (
                    dls:retention-rule-insert( 
                        dls:retention-rule(
                            "All Versions Retention Rule",
                            "Retain all versions of all documents",
                            (),
                            (),
                            "Locate all of the documents",
                            cts:and-query(())
                        )
                    )
                )    
                let $b := "Created All Versions Retention Rule." 
                return ($b)  
    let $_ := xdmp:eval("
        xquery version '1.0-ml'; 
        import module namespace sec='http://marklogic.com/xdmp/security' at '/MarkLogic/security.xqy';
        
            try{sec:protect-collection('http://marklogic.com/marker/drafts', 
                (xdmp:permission('marker-admin', 'execute'), xdmp:permission('marker-admin', 'update'))
            )}catch($e){},
             try{sec:protect-collection('http://marklogic.com/marker/published', 
                (xdmp:permission('marker-admin', 'execute'), xdmp:permission('security-anon', 'read'), xdmp:permission('marker-admin', 'update'))
             )}catch($e){}
     
        ",  
        (),
        <options xmlns="xdmp:eval"><database>{xdmp:database("Security")}</database> </options>
    )  
    let $_ := xdmp:document-insert("/plugins/marker/config.xml",
        <marker_config>
            <install-completed>true</install-completed>
            <default-page>/index.html</default-page>
        </marker_config>,
            (xdmp:permission("security-anon", "read"), xdmp:permission("marker-admin", "update"))
    )
    let $_ := xdmp:document-insert("/plugins/security/controller-mapping/marker-admin.xml",
        <role-mappings>
            <mapping mapped="1" plugin="marker" controller="ajax" action="index">marker/ajax/index</mapping>
            <mapping mapped="1" plugin="marker" controller="ajax" action="list-documents">marker/ajax/list-documents</mapping>
            <mapping mapped="1" plugin="marker" controller="ajax" action="unmanage-document">marker/ajax/unmanage-document</mapping>
            <mapping mapped="1" plugin="marker" controller="ajax" action="manage-document">marker/ajax/manage-document</mapping>
            <mapping mapped="1" plugin="marker" controller="ajax" action="update-uri-content">marker/ajax/update-uri-content</mapping>
            <mapping mapped="1" plugin="marker" controller="ajax" action="checkout-status">marker/ajax/checkout-status</mapping>
            <mapping mapped="1" plugin="marker" controller="ajax" action="checkout">marker/ajax/checkout</mapping>
            <mapping mapped="1" plugin="marker" controller="ajax" action="publish">marker/ajax/publish</mapping>
            <mapping mapped="1" plugin="marker" controller="ajax" action="unpublish">marker/ajax/unpublish</mapping>
            <mapping mapped="1" plugin="marker" controller="ajax" action="get-version-content">marker/ajax/get-version-content</mapping>
            <mapping mapped="1" plugin="marker" controller="ajax" action="get-uri-information">marker/ajax/get-uri-information</mapping>
            <mapping mapped="1" plugin="marker" controller="ajax" action="change-view-mode">marker/ajax/change-view-mode</mapping>
            <mapping mapped="1" plugin="marker" controller="library" action="list">marker/library/list</mapping>
            <mapping mapped="1" plugin="marker" controller="setup" action="index">marker/setup/index</mapping>
            <mapping mapped="1" plugin="marker" controller="setup" action="install">marker/setup/install</mapping>
            <mapping mapped="1" plugin="marker" controller="setup" action="install-data">marker/setup/install-data</mapping>
            <mapping mapped="1" plugin="marker" controller="setup" action="install-data-properties">marker/setup/install-data-properties</mapping>
            <mapping mapped="1" plugin="marker" controller="setup" action="install-data-publish">marker/setup/install-data-publish</mapping>
            <mapping mapped="1" plugin="marker" controller="render" action="index">marker/render/index</mapping>
        </role-mappings>,
            (xdmp:permission("security-anon", "read"), xdmp:permission("security-admin", "update"))
    )
   let $_ := xdmp:document-insert("/application/mapping.xml",
        <mappings>
            <mapping regex="^/blogs/([\w\-:'_]+)/([\w\-:'_]+)$" template="/blogs/detail/template.xhtml">
                <params name="name" match="1"/>
                <params name="post" match="2"/>
            </mapping>
            <mapping regex="^/blogs/([\w\-:'_]+)$" template="/blogs/template.xhtml">
                <params name="name" match="1"/>
            </mapping>
        </mappings>,
            (xdmp:permission("security-anon", "read"), xdmp:permission("security-admin", "update"), xdmp:permission("marker-admin", "update"))
    )
    
    let $config := admin:get-configuration()
    let $config := admin:database-set-uri-lexicon($config, 
            xdmp:database(), fn:true())
    let $_ := admin:save-configuration($config)
    (:reset cached roles:)
    let $_ := xdmp:set-session-field("roles",())
    let $_ := xdmp:set-session-field("init-redirect",())
    let $_ := xdmp:set-server-field("authorization:marker-admin", '')
    let $config := admin:get-configuration()
    let $config := admin:database-set-trailing-wildcard-searches($config, 
        xdmp:database(), fn:true())
    let $_ := admin:save-configuration($config)
    let $config := admin:get-configuration()
    let $config := admin:database-set-collection-lexicon($config, 
        xdmp:database(), fn:true())
    let $_ := admin:save-configuration($config)

    let $config := admin:get-configuration()  
    let $config  := admin:database-add-range-element-index($config, xdmp:database(),  admin:database-range-element-index("string", "", "marker-author", "http://marklogic.com/collation/", fn:false() ))
    let $config  := admin:database-add-range-element-index($config, xdmp:database(),  admin:database-range-element-index("string", "", "marker-type", "http://marklogic.com/collation/", fn:false() ))
    let $config  := admin:database-add-range-element-index($config, xdmp:database(),  admin:database-range-element-index("string", "", "tag", "http://marklogic.com/collation/codepoint", fn:false() ))
    let $_ := admin:save-configuration($config)   
    return xqmvc:template('master-template', (
                'browsertitle', 'marker Setup Complete',
                'body', xqmvc:plugin-view($cfg:plugin-name,'setup-install-view', ())
            ))
    
};
declare function install-data()
{
    let $collection := "http://marklogic.com/marker/drafts"
    let $collection-published := "http://marklogic.com/marker/drafts"
    let $note := "insert from setup install"
    let $permissions := (xdmp:permission('marker-admin', 'update'), xdmp:permission('marker-admin', 'read')) 
    let $content-insert := 
        dls:document-insert-and-manage(
         "/content-root/containers/site-wide/fallback.container",
         fn:true(),
         (  <div>Sorry. This content could not be served<marker-content xmlns:marker="http://marklogic.com/marker">
                    <marker-type>generic</marker-type>
                    <marker-title></marker-title>
                    <marker-name></marker-name>
                    <marker-searchable>false</marker-searchable>
                    <marker-authors>
                    </marker-authors>
                </marker-content></div>
            ),
         $note,
         $permissions, 
         $collection)
    (: document is not under mgmt in transaction yet :)     
    (:let $publish := library:publishLatest("/content-root/containers/site-wide/fallback.container"):)
    let $content-insert := 
        dls:document-insert-and-manage(
        "/content-root/containers/site-wide/main-navigation.container",
         fn:true(),
         (  <div><ul class="sf-menu sf-js-enabled sf-shadow">    <li>        <a href="/" class="">﻿Home</a>    </li>    <li>      <a href="/about-us" class="">About</a>    </li> <li>      <a href="/services" class=""><span style="line-height: 0;" id="selectionBoundary_1297201496277_583589268961798">﻿</span>Services</a>    </li> <li>      <a href="/contact-us" class="">Contact us</a>    </li>
                <li>      <a href="/blogs" class="">Blogs</a>    </li>
              </ul><marker-content xmlns:marker="http://marklogic.com/marker">
                    <marker-type>generic</marker-type>
                    <marker-title></marker-title>
                    <marker-name></marker-name>
                    <marker-searchable>false</marker-searchable>
                    <marker-authors>
                    </marker-authors>
                </marker-content></div>
            ),  
         $note,
         $permissions, 
         $collection)
 let $content-insert := 
        dls:document-insert-and-manage(
        "/content-root/containers/blogs/blog-navigation.container",
         fn:true(),
         (  <div runtime="dynamic">
              <exec>
              declare namespace xhtml = "http://www.w3.org/1999/xhtml"; 
              declare namespace marker="http://marklogic.com/marker";
              let $name := 
                if(xdmp:get-request-field("name"))
                then (xdmp:get-request-field("name")) 
                else ()
              let $posts := 
                for $post in cts:search(fn:collection("http://marklogic.com/marker/published"),cts:element-query(xs:QName("marker-type"),"blog")) 
                let $title := $post/*/marker-content/marker-title/text() 
                let $author := fn:string-join($post/*/marker-content/marker-authors//marker-author/text(), ", ") 
                let $uriEndPath := 
                    let $uri := fn:base-uri($post)
                    let $uriParts:= fn:tokenize($uri, "/")
                    return $uriParts[fn:last()]
                return 
                    <li>
                        <a href="/blogs/{{if($name) then ($name) else ($post/*/marker-content/marker-blog/marker-blog-title/text() )}}/{{$post/*/marker-content/marker-name/text()}}">{{$title}} by {{$author}}</a>
                    </li> 
              return <ul>{{$posts}}</ul>
              </exec>
              <marker-content xmlns:marker="http://marklogic.com/marker">
                    <marker-type>generic</marker-type>
                    <marker-title></marker-title>
                    <marker-name></marker-name>
                    <marker-searchable>false</marker-searchable>
                    <marker-authors>
                    </marker-authors>
                </marker-content>
            </div>
            ),  
         $note,
         $permissions, 
         $collection)
    let $content-insert := 
        dls:document-insert-and-manage(
        "/content-root/containers/blogs/blog-content.container",
         fn:true(),
         (  <div runtime="dynamic">
                <exec>
                import module namespace library = "http://marklogic.com/marker/library" at "/plugins/marker/library/library.xqy";
                declare namespace xhtml = "http://www.w3.org/1999/xhtml";
                declare variable $name external;
                declare variable $post external;
                library:doc(fn:concat("/content-root/containers/blogs/", $name, "/", $post , ".container"))
                </exec>
                <marker-content xmlns:marker="http://marklogic.com/marker">
                    <marker-type>generic</marker-type>
                    <marker-title></marker-title>
                    <marker-name></marker-name>
                    <marker-searchable>false</marker-searchable>
                    <marker-authors>
                    </marker-authors>
                </marker-content>
            </div>
            ),  
         $note,
         $permissions, 
         $collection)
    let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/containers/site-wide/search.container",
         fn:true(),
         (  <div><form action="/search" method="get"><input type="hidden" id="start" name="start" value="1"/><input type="text" id="q" name="q" /><input type="submit" value="search" /></form><marker-content xmlns:marker="http://marklogic.com/marker">
                    <marker-type>generic</marker-type>
                    <marker-title></marker-title>
                    <marker-name></marker-name>
                    <marker-searchable>false</marker-searchable>
                    <marker-authors>
                    </marker-authors>
                </marker-content></div>
            ),
         $note,
         $permissions, 
         $collection)   
    let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/containers/site-wide/search-results.container",
         fn:true(),
         (  
         <div runtime="dynamic">
                <exec>
                xquery version "1.0-ml";
                import module namespace library = "http://marklogic.com/marker/library" at "/plugins/marker/library/library.xqy";
                import module namespace dls="http://marklogic.com/xdmp/dls" at "/MarkLogic/dls.xqy";  
                import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
                declare namespace xi="http://www.w3.org/2001/XInclude";
                declare namespace marker="http://marklogic.com/marker";
                
                declare variable $options :=
                <options xmlns="http://marklogic.com/appservices/search">
                    <additional-query>
                        {
                        cts:and-query
                        (
                            (
                            cts:collection-query
                            (
                                ("http://marklogic.com/marker/published")
                            ),
                            cts:collection-query
                            (
                                ("http://marklogic.com/marker/searchable")
                            )
                            )
                        )
                        }
                  </additional-query>
                  <constraint name="Category">
                    <range type="xs:string" collation="http://marklogic.com/collation/">
                     <element ns="" name="marker-type"/>
                     
                    </range>
                  </constraint> 
                  <constraint name="Author">
                    <range type="xs:string" collation="http://marklogic.com/collation/">
                     <element ns="" name="marker-author"/>
                     
                    </range>
                  </constraint>
                  <constraint name="Tags">
                    <range type="xs:string" collation="http://marklogic.com/collation/codepoint">
                     <element ns="" name="tag"/>
                     
                    </range>
                  </constraint> 
                </options>;
                declare function local:pagination($results)
                {{
                    let $start := xs:unsignedLong($results/@start)
                    let $length := xs:unsignedLong($results/@page-length)
                    let $total := xs:unsignedLong($results/@total)
                    let $last := xs:unsignedLong($start + $length -1)
                    let $end := if ($total gt $last) then $last else $total
                    let $qtext := $results/search:qtext[1]/text()
                    let $next := if ($total gt $last) then $last + 1 else ()
                    let $previous := if (($start gt 1) and ($start - $length gt 0)) then fn:max((($start - $length),1)) else ()
                    let $next-href := 
                         if ($next) 
                         then fn:concat("/search?q=",if ($qtext) then fn:encode-for-uri($qtext) else (),"&amp;start=",$next)
                         else ()
                    let $previous-href := 
                         if ($previous)
                         then fn:concat("/search?q=",if ($qtext) then fn:encode-for-uri($qtext) else (),"&amp;start=",$previous)
                         else ()
                    let $total-pages := fn:ceiling($total div $length)
                    let $currpage := fn:ceiling($start div $length)
                    let $pagemin := 
                        fn:min(for $i in (1 to 4)
                        where ($currpage - $i) gt 0
                        return $currpage - $i)
                    let $rangestart := fn:max(($pagemin, 1))
                    let $rangeend := fn:min(($total-pages,$rangestart + 4))
                    
                    return (
                        <div class="page-status"><b>{{$start}}</b> to <b>{{$end}}</b> of {{$total}}</div>,
                        if($rangestart eq $rangeend)
                        then ()
                        else
                            <ul class="pagination"> 
                               {{ if ($previous) then <li class="previous"><a href="{{$previous-href}}" >Previous</a></li> else () }}
                               {{
                                 for $i in ($rangestart to $rangeend)
                                 let $page-start := (($length * $i) + 1) - $length
                                 let $page-href := concat("/search?q=",if ($qtext) then encode-for-uri($qtext) else (),"&amp;start=",$page-start)
                                 return 
                                    if ($i eq $currpage) 
                                    then <li class="active">{{$i}}</li>
                                    else <li><a href="{{$page-href}}">{{$i}}</a></li>
                                }}
                               {{ if ($next) then <li class="next"><a href="{{$next-href}}">Next</a></li> else ()}}
                            </ul>
                    )
                }};
                declare variable $q external;
                declare variable $start external;
                
                let $results := search:search($q, $options, xs:unsignedLong($start))
                let $total := data($results/@total)
                let $items :=
                    for $result in $results//search:result
                    let $base-uri := doc(data($result/@uri))/property::dls:version/dls:document-uri/text()
                    let $base-doc := doc(data($result/@uri))/*/marker-content
                    let $title := 
                        if($base-doc/marker-title/text())
                        then ($base-doc/marker-title/text())
                        else (fn:concat("&amp;","nbsp;"))
                    let $type := $base-doc/marker-type/text()
                    let $item := 
                        if($type eq 'blog')
                        then 
                            (
                            <div class="result">
                                <a href="{{fn:concat($base-doc/marker-blog/marker-realized-path/text(),fn:replace($base-doc/marker-name/text(), ' ' , '_'))}}">{{$title}}</a>
                                <p>
                                    {{
                                      for $snip in $result//search:match/text()
                                      return fn:concat($snip, "&#160;")  
                                    }}
                                </p>
                            </div>
                            )
                        else if($type eq 'generic')
                        then 
                            (
                            let $link-search := cts:search
                                                    (
                                                        fn:doc(), 
                                                        cts:and-query
                                                        (
                                                            (
                                                            cts:collection-query(("http://marklogic.com/marker/published")),
                                                            cts:element-attribute-value-query
                                                                (
                                                                xs:QName("xi:include"), 
                                                                xs:QName("href"), 
                                                                $base-uri
                                                                )
                                                            )
                                                        )
                                                    )/property::dls:version/dls:document-uri/text()
                            let $links :=
                                
                                for $found-item in $link-search
                                let $properties := library:doc($found-item)/*/marker-content
                                return
                                    <div class="result">
                                        <a href="/{{fn:replace(fn:replace(fn:replace($found-item, '/content-root/site/', ''), '/template.xhtml', ''), 'template.xhtml', '')}}">{{$properties/marker-title/text()}}</a>
                                        <p>
                                            {{
                                              for $snip in $result//search:match/text()
                                              return fn:concat($snip, "&#160;")  
                                            }}
                                        </p>
                                    </div>
                                    
                            return $links
                                
                            )
                        else () 
                    return $item
                let $facets :=  
                    for $facet in $results/search:facet
                    let $facet-count := fn:count($facet/search:facet-value)
                    let $facet-name := fn:data($facet/@name)
                    return
                        if($facet-count gt 0)
                        then <div class="facet">
                                <div class="purplesubheading"><img src="/application/resources/img/checkblank.gif"/>{{$facet-name}}</div>
                                {{
                                    let $facet-items :=
                                        for $val in $facet/search:facet-value
                                        let $print := if($val/text()) then $val/text() else "Unknown"
                                        let $qtext := ($results/search:qtext)
                                        let $this :=
                                            if (fn:matches($val/@name/string(),"\W"))
                                            then fn:concat('"',$val/@name/string(),'"')
                                            else if ($val/@name eq "") then '""'
                                            else $val/@name/string()
                                        let $this := fn:concat($facet/@name,':',$this)
                                        let $selected := fn:matches($qtext,$this,"i")
                                        let $icon := 
                                            if($selected)
                                            then <img src="/application/resources/img/checkmark.gif"/>
                                            else <img src="/application/resources/img/checkblank.gif"/>
                                        let $link := 
                                            if($selected)
                                            then search:remove-constraint($qtext,$this,$options)
                                            else if(fn:string-length($qtext) gt 0)
                                            then fn:concat("(",$qtext,")"," AND ",$this)
                                            else $this
                                        
                                        let $link := fn:encode-for-uri(fn:concat($link, "&amp;start=1") )
                                        return
                                            <div class="facet-value">{{$icon}}<a href="search?q={{$link}}">
                                            {{fn:lower-case($print)}}</a> [{{fn:data($val/@count)}}]</div>
                                    return (
                                                <div>{{$facet-items[1 to 10]}}</div>,
                                                if($facet-count gt 10)
                                                then (
                                                        <div class="facet-hidden" id="{{$facet-name}}">{{$facet-items[position() gt 10]}}</div>,
                                                        <div class="facet-toggle" id="{{$facet-name}}_more"><img src="/application/resources/img/checkblank.gif"/><a href="javascript:toggle('{{$facet-name}}');" class="white">more...</a></div>,
                                                        <div class="facet-toggle-hidden" id="{{$facet-name}}_less"><img src="/application/resources/img/checkblank.gif"/><a href="javascript:toggle('{{$facet-name}}');" class="white">less...</a></div>
                                                    )                             
                                                else ()   
                                            )
                                }}          
                            </div>
                         else <div>&#160;</div>

                return
                    <div>
                    <div class="facets">
                    {{$facets}}
                    </div>
                    <div class="results">
                    {{$items}}
                    </div>
                    <div class="pagination-container">
                         {{local:pagination($results)}}
                    </div>
                    </div>
                </exec>
                <marker-content xmlns:marker="http://marklogic.com/marker">
                    <marker-type>generic</marker-type>
                    <marker-title></marker-title>
                    <marker-name></marker-name>
                    <marker-searchable>false</marker-searchable>
                    <marker-authors>
                    </marker-authors>
                </marker-content>
            </div>
            ),
         $note,
         $permissions, 
         $collection)   
    let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/containers/site-wide/footer-navigation.container",
         fn:true(),
         (  <div><p>footer content here...</p><marker-content xmlns:marker="http://marklogic.com/marker">
                    <marker-type>generic</marker-type>
                    <marker-title></marker-title>
                    <marker-name></marker-name>
                    <marker-searchable>false</marker-searchable>
                    <marker-authors>
                    </marker-authors>
                </marker-content></div>
            ),
         $note,
         $permissions, 
         $collection)
    let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/containers/home/main-content.container",
         fn:true(),
         (  <div><p>This is the home page.</p><marker-content xmlns:marker="http://marklogic.com/marker">
                    <marker-type>generic</marker-type>
                    <marker-title></marker-title>
                    <marker-name></marker-name>
                    <marker-searchable>true</marker-searchable>
                    <marker-authors>
                    </marker-authors>
                </marker-content></div>
            ),
         $note,
         $permissions, 
         $collection)
    let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/containers/about-us/main-content.container",
         fn:true(),
         (  <div><p>This is the about page.</p><marker-content xmlns:marker="http://marklogic.com/marker">
                    <marker-type>generic</marker-type>
                    <marker-title></marker-title>
                    <marker-name></marker-name>
                    <marker-searchable>true</marker-searchable>
                    <marker-authors>
                    </marker-authors>
                </marker-content></div>
            ),
         $note,
         $permissions, 
         $collection)
    let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/containers/services/main-content.container",
         fn:true(),
         (  <div><p>This is the services page.</p><marker-content xmlns:marker="http://marklogic.com/marker">
                    <marker-type>generic</marker-type>
                    <marker-title></marker-title>
                    <marker-name></marker-name>
                    <marker-searchable>true</marker-searchable>
                    <marker-authors>
                    </marker-authors>
                </marker-content></div>
            ),
         $note,
         $permissions, 
         $collection)
    let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/containers/contact-us/main-content.container",
         fn:true(),
         (  <div><p>This is the contact page.</p><marker-content xmlns:marker="http://marklogic.com/marker">
                    <marker-type>generic</marker-type>
                    <marker-title></marker-title>
                    <marker-name></marker-name>
                    <marker-searchable>true</marker-searchable>
                    <marker-authors>
                    </marker-authors>
                </marker-content></div>
            ),
         $note,
         $permissions, 
         $collection) 
           
    let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/site/template.xhtml",
         fn:true(),
         (  
         <html>
            <head>
                <link rel="icon" type="image/vnd.microsoft.icon" href="/favicon.ico" />
                <link rel="shortcut icon" href="/favicon.ico" />
                <link rel="stylesheet" type="text/css" media="screen" href="/application/resources/css/style.css"/>
            </head>
            <body>
                <div id="container">
                    <div id="header" style="position:relative;">
                
                        <div style="position:absolute;top:5px;right:5px;width:150px;text-align:right;"> 
                        <exec id="1234">xquery version "1.0-ml";import module namespace taglib-security = "http://marklogic.com/plugin/security/taglib" at "/plugins/security/taglibs/taglib-auth.xqy";taglib-security:login-logout()</exec>
                        </div>
                    </div>
                    <div id="navigation">
                       <xi:include href="/content-root/containers/site-wide/main-navigation.container">
                        <xi:fallback>
                            <xi:include href="/content-root/containers/site-wide/fallback.container">
                                <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                            </xi:include>
                        </xi:fallback> 
                       </xi:include> 
                    </div>
                    <div id="content-container">
                        <div id="content">
                           <xi:include href="/content-root/containers/home/main-content.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                        <div id="aside">
                            <h3>Search</h3>
                            <xi:include href="/content-root/containers/site-wide/search.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                        <div id="footer">
                            
                            <xi:include href="/content-root/containers/site-wide/footer-navigation.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                    </div>
                </div>
            </body>
            <marker-content xmlns:marker="http://marklogic.com/marker">
                    <marker-type>template</marker-type>
                    <marker-title>Home</marker-title>
                    <marker-name></marker-name>
                    <marker-searchable>false</marker-searchable>
                    <marker-authors>
                    </marker-authors>
                </marker-content>
        </html>  
            ),
         $note,
         $permissions, 
         $collection-published)
    let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/site/services/template.xhtml",
         fn:true(),
         (  
         <html>
            <head>
                <link rel="icon" type="image/vnd.microsoft.icon" href="/favicon.ico" />
                <link rel="shortcut icon" href="/favicon.ico" />
                <link rel="stylesheet" type="text/css" media="screen" href="/application/resources/css/style.css"/>
            </head>
            <body>
                <div id="container">
                    <div id="header" style="position:relative;">
                
                        <div style="position:absolute;top:5px;right:5px;width:150px;text-align:right;"> 
                        <exec id="1234">xquery version "1.0-ml";import module namespace taglib-security = "http://marklogic.com/plugin/security/taglib" at "/plugins/security/taglibs/taglib-auth.xqy";taglib-security:login-logout()</exec>
                        </div>
                    </div>
                    <div id="navigation">
                       <xi:include href="/content-root/containers/site-wide/main-navigation.container">
                        <xi:fallback>
                            <xi:include href="/content-root/containers/site-wide/fallback.container">
                                <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                            </xi:include>
                        </xi:fallback> 
                       </xi:include>  
                    </div>
                    <div id="content-container">
                        <div id="content">
                            <xi:include href="/content-root/containers/services/main-content.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                        <div id="aside">
                             <h3>Search</h3>
                            <xi:include href="/content-root/containers/site-wide/search.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                        <div id="footer">
                            
                            <xi:include href="/content-root/containers/site-wide/footer-navigation.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                    </div>
                </div>
            </body>
            <marker-content xmlns:marker="http://marklogic.com/marker">
                    <marker-type>template</marker-type>
                    <marker-title>Services</marker-title>
                    <marker-name></marker-name>
                    <marker-searchable>false</marker-searchable>
                    <marker-authors>
                    </marker-authors>
                </marker-content>
        </html>  
            ),
         $note,
         $permissions, 
         $collection-published) 
     let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/site/about-us/template.xhtml",
         fn:true(),
         (  
         <html>
            <head>
                <link rel="icon" type="image/vnd.microsoft.icon" href="/favicon.ico" />
                <link rel="shortcut icon" href="/favicon.ico" />
                <link rel="stylesheet" type="text/css" media="screen" href="/application/resources/css/style.css"/>
            </head>
            <body>
                <div id="container">
                    <div id="header" style="position:relative;">
                
                        <div style="position:absolute;top:5px;right:5px;width:150px;text-align:right;"> 
                        <exec id="1234">xquery version "1.0-ml";import module namespace taglib-security = "http://marklogic.com/plugin/security/taglib" at "/plugins/security/taglibs/taglib-auth.xqy";taglib-security:login-logout()</exec>
                        </div>
                    </div>
                    <div id="navigation">
                       <xi:include href="/content-root/containers/site-wide/main-navigation.container">
                        <xi:fallback>
                            <xi:include href="/content-root/containers/site-wide/fallback.container">
                                <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                            </xi:include>
                        </xi:fallback> 
                       </xi:include>  
                    </div>
                    <div id="content-container">
                        <div id="content">
                            <xi:include href="/content-root/containers/about-us/main-content.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                        <div id="aside">
                             <h3>Search</h3>
                            <xi:include href="/content-root/containers/site-wide/search.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                        <div id="footer">
                            
                            <xi:include href="/content-root/containers/site-wide/footer-navigation.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                    </div>
                </div>
            </body>
            <marker-content xmlns:marker="http://marklogic.com/marker">
                    <marker-type>template</marker-type>
                    <marker-title>About Us</marker-title>
                    <marker-name></marker-name>
                    <marker-searchable>false</marker-searchable>
                    <marker-authors>
                    </marker-authors>
                </marker-content>
        </html>  
            ),
         $note,
         $permissions, 
         $collection-published) 
    let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/site/contact-us/template.xhtml",
         fn:true(),
         (  
         <html>
            <head>
                <link rel="icon" type="image/vnd.microsoft.icon" href="/favicon.ico" />
                <link rel="shortcut icon" href="/favicon.ico" />
                <link rel="stylesheet" type="text/css" media="screen" href="/application/resources/css/style.css"/>
            </head>
            <body>
                <div id="container">
                    <div id="header" style="position:relative;">
                
                        <div style="position:absolute;top:5px;right:5px;width:150px;text-align:right;"> 
                        <exec id="1234">xquery version "1.0-ml";import module namespace taglib-security = "http://marklogic.com/plugin/security/taglib" at "/plugins/security/taglibs/taglib-auth.xqy";taglib-security:login-logout()</exec>
                        </div>
                    </div>
                    <div id="navigation">
                       <xi:include href="/content-root/containers/site-wide/main-navigation.container">
                        <xi:fallback>
                            <xi:include href="/content-root/containers/site-wide/fallback.container">
                                <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                            </xi:include>
                        </xi:fallback> 
                       </xi:include>  
                    </div>
                    <div id="content-container">
                        <div id="content">
                            <xi:include href="/content-root/containers/contact-us/main-content.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                        <div id="aside">
                             <h3>Search</h3>
                            <xi:include href="/content-root/containers/site-wide/search.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                        <div id="footer">
                            
                            <xi:include href="/content-root/containers/site-wide/footer-navigation.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                    </div>
                </div>
            </body>
            <marker-content xmlns:marker="http://marklogic.com/marker">
                    <marker-type>template</marker-type>
                    <marker-title>Contact Us</marker-title>
                    <marker-name></marker-name>
                    <marker-searchable>false</marker-searchable>
                    <marker-authors>
                    </marker-authors>
                </marker-content>
        </html>  
            ),
         $note,
         $permissions, 
         $collection-published) 
  let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/site/blogs/template.xhtml",
         fn:true(),
         (  
         <html>
            <head>
                <link rel="icon" type="image/vnd.microsoft.icon" href="/favicon.ico" />
                <link rel="shortcut icon" href="/favicon.ico" />
                <link rel="stylesheet" type="text/css" media="screen" href="/application/resources/css/style.css"/>
            </head>
            <body>
                <div id="container">
                    <div id="header" style="position:relative;">
                
                        <div style="position:absolute;top:5px;right:5px;width:150px;text-align:right;"> 
                        <exec id="1234">xquery version "1.0-ml";import module namespace taglib-security = "http://marklogic.com/plugin/security/taglib" at "/plugins/security/taglibs/taglib-auth.xqy";taglib-security:login-logout()</exec>
                        </div>
                    </div>
                    <div id="navigation">
                       <xi:include href="/content-root/containers/site-wide/main-navigation.container">
                        <xi:fallback>
                            <xi:include href="/content-root/containers/site-wide/fallback.container">
                                <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                            </xi:include>
                        </xi:fallback> 
                       </xi:include>  
                    </div>
                    <div id="content-container">
                        <div id="content">
                            <xi:include href="/content-root/containers/blogs/blog-navigation.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                        <div id="aside">
                             <h3>Search</h3>
                            <xi:include href="/content-root/containers/site-wide/search.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                        <div id="footer">
                            
                            <xi:include href="/content-root/containers/site-wide/footer-navigation.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                    </div>
                </div>
            </body>
            <marker-content xmlns:marker="http://marklogic.com/marker">
                    <marker-type>template</marker-type>
                    <marker-title>Blogs</marker-title>
                    <marker-name></marker-name>
                    <marker-searchable>false</marker-searchable>
                    <marker-authors>
                    </marker-authors>
                </marker-content>
        </html>  
            ),
         $note,
         $permissions, 
         $collection-published) 
     let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/site/blogs/detail/template.xhtml",
         fn:true(),
         (  
         <html>
            <head>
                <link rel="icon" type="image/vnd.microsoft.icon" href="/favicon.ico" />
                <link rel="shortcut icon" href="/favicon.ico" />
                <link rel="stylesheet" type="text/css" media="screen" href="/application/resources/css/style.css"/>
            </head>
            <body>
                <div id="container">
                    <div id="header" style="position:relative;">
                
                        <div style="position:absolute;top:5px;right:5px;width:150px;text-align:right;"> 
                        <exec id="1234">xquery version "1.0-ml";import module namespace taglib-security = "http://marklogic.com/plugin/security/taglib" at "/plugins/security/taglibs/taglib-auth.xqy";taglib-security:login-logout()</exec>
                        </div>
                    </div>
                    <div id="navigation">
                       <xi:include href="/content-root/containers/site-wide/main-navigation.container">
                        <xi:fallback>
                            <xi:include href="/content-root/containers/site-wide/fallback.container">
                                <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                            </xi:include>
                        </xi:fallback> 
                       </xi:include>  
                    </div>
                    <div id="content-container">
                        <div id="content">
                            <xi:include href="/content-root/containers/blogs/blog-content.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                        <div id="aside">
                             <h3>Search</h3>
                            <xi:include href="/content-root/containers/site-wide/search.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                        <div id="footer">
                            
                            <xi:include href="/content-root/containers/site-wide/footer-navigation.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                    </div>
                </div>
            </body>
            <marker-content xmlns:marker="http://marklogic.com/marker">
                    <marker-type>template</marker-type>
                    <marker-title>Blogs Detail</marker-title>
                    <marker-name></marker-name>
                    <marker-searchable>false</marker-searchable>
                    <marker-authors>
                    </marker-authors>
                </marker-content>
        </html>  
            ),
         $note,
         $permissions, 
         $collection-published) 
 let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/site/search/template.xhtml",
         fn:true(),
         (  
         <html>
            <head>
                <link rel="icon" type="image/vnd.microsoft.icon" href="/favicon.ico" />
                <link rel="shortcut icon" href="/favicon.ico" />
                <link rel="stylesheet" type="text/css" media="screen" href="/application/resources/css/style.css"/>
            </head>
            <body>
                <div id="container">
                    <div id="header" style="position:relative;">
                
                        <div style="position:absolute;top:5px;right:5px;width:150px;text-align:right;"> 
                        <exec id="1234">xquery version "1.0-ml";import module namespace taglib-security = "http://marklogic.com/plugin/security/taglib" at "/plugins/security/taglibs/taglib-auth.xqy";taglib-security:login-logout()</exec>
                        </div>
                    </div>
                    <div id="navigation">
                       <xi:include href="/content-root/containers/site-wide/main-navigation.container">
                        <xi:fallback>
                            <xi:include href="/content-root/containers/site-wide/fallback.container">
                                <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                            </xi:include>
                        </xi:fallback> 
                       </xi:include>  
                    </div>
                    <div id="content-container">
                        <div id="content">
                            <xi:include href="/content-root/containers/site-wide/search-results.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                        <div id="aside">
                             <h3>Search</h3>
                            <xi:include href="/content-root/containers/site-wide/search.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                        <div id="footer">
                            
                            <xi:include href="/content-root/containers/site-wide/footer-navigation.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                    </div>
                </div>
            </body>
            <marker-content xmlns:marker="http://marklogic.com/marker">
                    <marker-type>template</marker-type>
                    <marker-title>Home</marker-title>
                    <marker-name></marker-name>
                    <marker-searchable>false</marker-searchable>
                    <marker-authors>
                    </marker-authors>
                </marker-content>
        </html>  
            ),
         $note,
         $permissions, 
         $collection-published) 
let $log := if ($xqmvc-conf:debug) then xdmp:log("Completed base data insert") else ()
(: blogs traverse and import :)
let $base-dir :=
        let $config := admin:get-configuration()
        let $groupid := admin:group-get-id($config, "Default")
        return admin:appserver-get-root($config, admin:appserver-get-id($config, $groupid, admin:appserver-get-name($config, xdmp:server())))
let $entries := 
    for $entry in xdmp:filesystem-directory(fn:concat($base-dir,"/plugins/marker/resources/data/blogs"))//dir:entry
    where (fn:ends-with($entry/dir:filename/text(), ".xml"))
    return $entry
let $log := if ($xqmvc-conf:debug) then xdmp:log("Traversed Blogs") else ()
let $inserts :=
    for $pointer in $entries
    let $doc := xdmp:document-get($pointer/dir:pathname/text())
    let $meta := <marker-content xmlns:marker="http://marklogic.com/marker">
                    <marker-type>blog</marker-type>
                    <marker-title>{$doc/ml:Post/ml:title/text()}</marker-title>
                    <marker-name>{fn:replace($pointer/dir:filename/text(), ".xml","")}</marker-name>
                    <marker-searchable>true</marker-searchable>
                    <marker-authors>
                    <marker-author>{$doc/ml:Post/ml:author/text()}</marker-author>
                    </marker-authors>
                    <marker-blog>
                        <marker-blog-title>general</marker-blog-title>
                        <marker-realized-path>/blogs/general/</marker-realized-path>
                        <marker-tags>
                            {
                            for $tag in $doc//ml:tag
                            return <marker-tag>{$tag/text()}</marker-tag>
                            }
                        </marker-tags>
                    </marker-blog>
                </marker-content>
   let $docRoot := $doc/ml:Post/ml:body

    let $newXML := 
    element {fn:node-name($docRoot)} {
        $docRoot/*,
        element marker-content {$meta/* }
        
    }   
    
    return dls:document-insert-and-manage(fn:concat("/content-root/containers/blogs/general/", fn:replace($pointer/dir:filename/text(), ".xml","") ,".container"), fn:false(), <div>{$newXML/node()}</div>, (), $permissions) 
let $log := if ($xqmvc-conf:debug) then xdmp:log("Inserted Blogs") else ()
let $schemas := 
    for $entry in xdmp:filesystem-directory(fn:concat($base-dir,"/plugins/marker/resources/data/schemas"))//dir:entry
    where (fn:ends-with($entry/dir:filename/text(), ".xsd"))
    return $entry
let $log := if ($xqmvc-conf:debug) then xdmp:log("Traversed Schema") else ()
let $inserts :=
    for $pointer in $entries
    
    return 
        xdmp:document-insert(fn:concat("/schemas/",$pointer/dir:filename/text()), xdmp:document-get($pointer/dir:pathname/text()), $permissions)
  let $log := if ($xqmvc-conf:debug) then xdmp:log("Completed schemas insert - redirecting to properties") else ()   
    return xdmp:redirect-response("/marker/setup/install-data-properties")                                                          
     
};
declare function install-data-properties()
{
    let $log := if ($xqmvc-conf:debug) then xdmp:log("Starting properties update") else ()
    let $base-dir :=
        let $config := admin:get-configuration()
        let $groupid := admin:group-get-id($config, "Default")
        return admin:appserver-get-root($config, admin:appserver-get-id($config, $groupid, admin:appserver-get-name($config, xdmp:server())))
    
    let $entries := 
        for $entry in xdmp:filesystem-directory(fn:concat($base-dir,"/plugins/marker/resources/data/blogs"))//dir:entry
        where (fn:ends-with($entry/dir:filename/text(), ".xml"))
        return $entry
    let $log := if ($xqmvc-conf:debug) then xdmp:log("Traversed Blog list") else ()
    let $inserts :=
        for $pointer in $entries
        let $doc := xdmp:document-get($pointer/dir:pathname/text())
        let $content := $doc/ml:Post/ml:body
        return dls:document-set-properties(
            fn:concat("/content-root/containers/blogs/general/", fn:replace($pointer/dir:filename/text(), ".xml","") ,".container"),
             (
                <marker-content xmlns:marker="http://marklogic.com/marker">
                    <marker-type>blog</marker-type>
                    <marker-title>{$doc/ml:Post/ml:title/text()}</marker-title>
                    <marker-name>{fn:replace($pointer/dir:filename/text(), ".xml","")}</marker-name>
                    <marker-searchable>true</marker-searchable>
                    <marker-authors>
                    <marker-author>{$doc/ml:Post/ml:author/text()}</marker-author>
                    </marker-authors>
                    <marker-blog>
                        <marker-blog-title>general</marker-blog-title>
                        <marker-realized-path>/blogs/general/</marker-realized-path>
                        <marker-tags>
                            {
                            for $tag in $doc//ml:tag
                            return <marker-tag>{$tag/text()}</marker-tag>
                            }
                        </marker-tags>
                    </marker-blog>
                </marker-content>
                
             )
             ) 
     let $log := if ($xqmvc-conf:debug) then xdmp:log("Set Blog Properties") else ()
     let $default-container-searchable :=
                <marker-content xmlns:marker="http://marklogic.com/marker">
                    <marker-type>generic</marker-type>
                    <marker-title></marker-title>
                    <marker-name></marker-name>
                    <marker-searchable>true</marker-searchable>
                    <marker-authors>
                    </marker-authors>
                </marker-content>
     let $default-container-not-searchable :=
                <marker-content xmlns:marker="http://marklogic.com/marker">
                    <marker-type>generic</marker-type>
                    <marker-title></marker-title>
                    <marker-name></marker-name>
                    <marker-searchable>false</marker-searchable>
                    <marker-authors>
                    </marker-authors>
                </marker-content>
    
    let $log := if ($xqmvc-conf:debug) then xdmp:log("Setting general content properties") else ()
    let $_ := dls:document-set-properties('/content-root/containers/site-wide/fallback.container', ($default-container-not-searchable))
    let $_ := dls:document-set-properties("/content-root/containers/site-wide/footer-navigation.container",($default-container-not-searchable))
    let $_ := dls:document-set-properties("/content-root/containers/site-wide/search.container",($default-container-not-searchable))
    let $_ := dls:document-set-properties("/content-root/containers/site-wide/search-results.container",($default-container-not-searchable))
    let $_ := dls:document-set-properties("/content-root/containers/contact-us/main-content.container", ($default-container-searchable))
    let $_ := dls:document-set-properties("/content-root/containers/about-us/main-content.container", ($default-container-searchable))
    let $_ := dls:document-set-properties("/content-root/containers/services/main-content.container", ($default-container-searchable))
    let $_ := dls:document-set-properties("/content-root/containers/home/main-content.container", ($default-container-searchable))
    let $_ := dls:document-set-properties("/content-root/containers/site-wide/main-navigation.container", ($default-container-not-searchable))
    let $default-template :=
                <marker-content xmlns:marker="http://marklogic.com/marker">
                    <marker-type>template</marker-type>
                    <marker-title>Home</marker-title>
                    <marker-name></marker-name>
                    <marker-searchable>false</marker-searchable>
                    <marker-authors>
                    </marker-authors>
                </marker-content>
    let $_ := dls:document-set-properties("/content-root/site/template.xhtml", ($default-template))
    let $default-template :=
                <marker-content>
                    <marker-type>template</marker-type>
                    <marker-title>Contact Us</marker-title>
                    <marker-name></marker-name>
                    <marker-searchable>false</marker-searchable>
                    <marker-authors>
                    </marker-authors>
                </marker-content>
    let $_ := dls:document-set-properties("/content-root/site/contact-us/template.xhtml", ($default-template))
    let $default-template :=
                <marker-content>
                    <marker-type>template</marker-type>
                    <marker-title>Services</marker-title>
                    <marker-name></marker-name>
                    <marker-searchable>false</marker-searchable>
                    <marker-authors>
                    </marker-authors>
                </marker-content>
    let $_ := dls:document-set-properties("/content-root/site/services/template.xhtml", ($default-template))
    let $default-template :=
                <marker-content>
                    <marker-type>template</marker-type>
                    <marker-title>About Us</marker-title>
                    <marker-name></marker-name>
                    <marker-searchable>false</marker-searchable>
                    <marker-authors>
                    </marker-authors>
                </marker-content>
    let $_ := dls:document-set-properties("/content-root/site/about-us/template.xhtml", ($default-template))
    let $default-template :=
                <marker-content>
                    <marker-type>template</marker-type>
                    <marker-title>Blogs</marker-title>
                    <marker-name></marker-name>
                    <marker-searchable>false</marker-searchable>
                    <marker-authors>
                    </marker-authors>
                </marker-content>
    let $_ := dls:document-set-properties("/content-root/site/blogs/template.xhtml", ($default-template))
    let $default-template :=
                <marker-content>
                    <marker-type>template</marker-type>
                    <marker-title>Search</marker-title>
                    <marker-name></marker-name>
                    <marker-searchable>false</marker-searchable>
                    <marker-authors>
                    </marker-authors>
                </marker-content>
    let $_ := dls:document-set-properties("/content-root/site/search/template.xhtml", ($default-template))
    let $default-template :=
                <marker-content>
                    <marker-type>template</marker-type>
                    <marker-title>Blog Details</marker-title>
                    <marker-name></marker-name>
                    <marker-searchable>false</marker-searchable>
                    <marker-authors>
                    </marker-authors>
                </marker-content>
    let $_ := dls:document-set-properties("/content-root/site/blogs/detail/template.xhtml", ($default-template))
    let $_ := dls:document-set-properties("/content-root/containers/blogs/blog-navigation.container", ($default-container-not-searchable))
    let $_ := dls:document-set-properties("/content-root/containers/blogs/blog-content.container", ($default-container-not-searchable))
    let $log := if ($xqmvc-conf:debug) then xdmp:log("Completed base properties insert") else ()
    return xdmp:redirect-response("/marker/setup/install-data-publish")  
};
declare function install-data-publish()
{
    let $base-dir :=
        let $config := admin:get-configuration()
        let $groupid := admin:group-get-id($config, "Default")
        return admin:appserver-get-root($config, admin:appserver-get-id($config, $groupid, admin:appserver-get-name($config, xdmp:server())))
    
    let $entries := 
        for $entry in xdmp:filesystem-directory(fn:concat($base-dir,"/plugins/marker/resources/data/blogs"))//dir:entry
        where (fn:ends-with($entry/dir:filename/text(), ".xml"))
        return $entry
    let $log := if ($xqmvc-conf:debug) then xdmp:log("Grabbed blogs list") else ()
    let $inserts :=
        for $pointer in $entries
        return library:publishLatest(fn:concat("/content-root/containers/blogs/general/", fn:replace($pointer/dir:filename/text(), ".xml","") ,".container"))
    let $log := if ($xqmvc-conf:debug) then xdmp:log("Published latest blogs") else ()     
             
    let $log := if ($xqmvc-conf:debug) then xdmp:log("Publishing latest version of main content") else ()
    let $publish := library:publishLatest("/content-root/containers/site-wide/fallback.container")
    let $publish := library:publishLatest("/content-root/containers/site-wide/footer-navigation.container")
    let $publish := library:publishLatest("/content-root/containers/site-wide/search.container")
    let $publish := library:publishLatest("/content-root/containers/site-wide/search-results.container")
    let $publish := library:publishLatest("/content-root/containers/contact-us/main-content.container")
    let $publish := library:publishLatest("/content-root/containers/about-us/main-content.container")
    let $publish := library:publishLatest("/content-root/containers/services/main-content.container")
    let $publish := library:publishLatest("/content-root/containers/home/main-content.container")
    let $publish := library:publishLatest("/content-root/containers/site-wide/main-navigation.container")
    let $publish := library:publishLatest("/content-root/site/template.xhtml")
    let $publish := library:publishLatest("/content-root/site/contact-us/template.xhtml")
    let $publish := library:publishLatest("/content-root/site/services/template.xhtml")
    let $publish := library:publishLatest("/content-root/site/about-us/template.xhtml")
    let $publish := library:publishLatest("/content-root/site/blogs/template.xhtml")
    let $publish := library:publishLatest("/content-root/site/search/template.xhtml")
    let $publish := library:publishLatest("/content-root/site/blogs/detail/template.xhtml")
    let $publish := library:publishLatest("/content-root/containers/blogs/blog-navigation.container")
    let $publish := library:publishLatest("/content-root/containers/blogs/blog-content.container")
    let $log := if ($xqmvc-conf:debug) then xdmp:log("Publishing complete") else ()
    return xqmvc:template('master-template', (
                'browsertitle', 'marker Data Install Complete',
                'body', xqmvc:plugin-view($cfg:plugin-name,'setup-install-data-view', ())
            )) 
};
