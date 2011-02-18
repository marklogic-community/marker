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
declare variable $uuid := "8b1c60f4-f4b0-2b8a-8d5a-c37194b3e3d6";
declare variable $uuid2 := "8b1c60f4-f4b0-2b8a-8d5a-c37194b3e3d5";

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
                <params name="blog-name" match="1"/>
                <params name="name" match="2"/>
            </mapping>
            <mapping regex="^/blogs/([\w\-:'_]+)$" template="/blogs/blog/template.xhtml">
                <params name="name" match="1"/>
            </mapping>
            <mapping regex="^/news/([\w\-:'_]+)$" template="/news/detail/template.xhtml">
                <params name="name" match="1"/>
            </mapping>
            <mapping regex="^/events/([\w\-:'_]+)$" template="/events/detail/template.xhtml">
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
    let $config  := admin:database-add-range-element-index($config, xdmp:database(),  admin:database-range-element-index("string", "http://marklogic.com/marker", "author", "http://marklogic.com/collation/", fn:false() ))
    let $config  := admin:database-add-range-element-index($config, xdmp:database(),  admin:database-range-element-index("string", "http://marklogic.com/marker", "type", "http://marklogic.com/collation/", fn:false() ))
    let $config  := admin:database-add-range-element-index($config, xdmp:database(),  admin:database-range-element-index("string", "http://marklogic.com/marker", "category", "http://marklogic.com/collation/", fn:false() ))
    (:let $config  := admin:database-add-range-element-index($config, xdmp:database(),  admin:database-range-element-index("dateTime", "http://marklogic.com/marker", "create-date", "", fn:false() ))
    let $config  := admin:database-add-range-element-index($config, xdmp:database(),  admin:database-range-element-index("dateTime", "http://marklogic.com/marker", "update-date", "", fn:false() ))
    let $config  := admin:database-add-range-element-index($config, xdmp:database(),  admin:database-range-element-index("dateTime", "http://marklogic.com/marker", "publish-date", "", fn:false() )):)
    let $config  := admin:database-add-range-element-index($config, xdmp:database(),  admin:database-range-element-index("string", "http://marklogic.com/marker", "tag", "http://marklogic.com/collation/", fn:false() ))
    let $config  := admin:database-add-range-element-index($config, xdmp:database(),  admin:database-range-element-index("string", "", "tag", "http://marklogic.com/collation/codepoint", fn:false() ))
    let $config  := admin:database-add-range-element-index($config, xdmp:database(),  admin:database-range-element-index("date", "", "date", "", fn:false() ))
    let $_ := admin:save-configuration($config)   
    return xqmvc:template('master-template', (
                'browsertitle', 'marker Setup Complete',
                'body', xqmvc:plugin-view($cfg:plugin-name,'setup-install-view', ())
            ))
    
};
declare function install-data()
{
    let $collection := "http://marklogic.com/marker/drafts"
    let $note := "insert from setup install"
    let $permissions := (xdmp:permission('marker-admin', 'update'), xdmp:permission('marker-admin', 'read')) 
    let $content-insert := 
        dls:document-insert-and-manage(
         "/content-root/containers/site-wide/fallback.container",
         fn:true(),
            (  
            <div>Sorry. This content could not be served
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Fallback Container</marker:title>
                    <marker:name>fallback</marker:name>
                    <marker:abstract>Container for missing container</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
            </div>
            ),
         $note,
         $permissions, 
         $collection)
    let $content-insert := 
        dls:document-insert-and-manage(
         "/content-root/containers/site-wide/login-logout.container",
         fn:true(),
            (  
            <div style="position:absolute;top:5px;right:5px;width:150px;text-align:right;"> 
                <exec>
                xquery version "1.0-ml";
                import module namespace taglib-security = "http://marklogic.com/plugin/security/taglib" at "/plugins/security/taglibs/taglib-auth.xqy";
                taglib-security:login-logout()
                </exec>
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Login/Logout Container</marker:title>
                    <marker:name>login-logout</marker:name>
                    <marker:abstract>Container for authentication - dependent upon the security plugin</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
            </div>
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
         (  
         <div>
            <ul class="sf-menu sf-js-enabled sf-shadow">
                <li><a href="/" class="">﻿Home</a></li>
                <li><a href="/about-us" class="">About</a></li>
                <li><a href="/news" class="">News</a></li>
                <li><a href="/events" class="">Events</a></li>
                <li><a href="/blogs" class="">Blogs</a></li>
            </ul>
            <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>Miscellaneous</marker:type> 
                <marker:title>Main Navigatoin Container</marker:title>
                <marker:name>main-navigation</marker:name>
                <marker:abstract>Main navigation container</marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:published-date></marker:published-date>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:authors>
                </marker:authors>
                <marker:categories>
                </marker:categories>
                <marker:tags>
                </marker:tags>
            </marker:content>
        </div>
         ),  
         $note,
         $permissions, 
         $collection)
    let $content-insert := 
        dls:document-insert-and-manage(
        "/content-root/containers/blogs/blogs-navigation.container",
         fn:true(),
         (  <div runtime="dynamic">
              <exec>
              declare namespace xhtml = "http://www.w3.org/1999/xhtml"; 
              declare namespace marker="http://marklogic.com/marker";
              let $posts := 
                for $post in cts:search(fn:collection("http://marklogic.com/marker/published"),cts:element-query(xs:QName("marker:type"),"Blogs")) 
                let $title := $post/*/marker:content/marker:title/text() 
                let $author := fn:string-join($post/*/marker:content/marker:authors//marker:author/text(), ", ") 
                return 
                    <li>
                        <a href="/blogs/{{$post/*/marker:content/marker:blog/marker:blog-name/text()}}/{{$post/*/marker:content/marker:name/text()}}">{{$title}} by {{$author}}</a>
                    </li> 
              return <ul>{{$posts}}</ul>    
              </exec>
              <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>Miscellaneous</marker:type> 
                <marker:title>Blog List</marker:title>
                <marker:name>blog-navigation</marker:name>
                <marker:abstract>Container generates list of blogs by name or general</marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:published-date></marker:published-date>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:authors>
                </marker:authors>
                <marker:categories>
                </marker:categories>
                <marker:tags>
                </marker:tags>
            </marker:content>
            </div>
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
              declare variable $name external;
              let $posts := 
                for $post in cts:search(fn:collection("http://marklogic.com/marker/published"),cts:and-query((cts:element-query(xs:QName("marker:type"),"Blogs"),cts:element-query(xs:QName("marker:blog-name"),fn:string($name))))) 
                let $title := $post/*/marker:content/marker:title/text() 
                let $author := fn:string-join($post/*/marker:content/marker:authors//marker:author/text(), ", ") 
                return 
                    <li>
                        <a href="/blogs/{{$post/*/marker:content/marker:blog/marker:blog-name/text()}}/{{$post/*/marker:content/marker:name/text()}}">{{$title}} by {{$author}}</a>
                    </li> 
              return <ul>{{$posts}}</ul>    
              </exec>
              <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>Miscellaneous</marker:type> 
                <marker:title>Blog List</marker:title>
                <marker:name>blog-navigation</marker:name>
                <marker:abstract>Container generates list of blogs by name or general</marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:published-date></marker:published-date>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:authors>
                </marker:authors>
                <marker:categories>
                </marker:categories>
                <marker:tags>
                </marker:tags>
            </marker:content>
            </div>
            ),  
         $note,
         $permissions, 
         $collection)
     let $content-insert := 
        dls:document-insert-and-manage(
        "/content-root/containers/events/event-navigation.container",
         fn:true(),
         (  <div runtime="dynamic">
              <exec>
              declare namespace xhtml = "http://www.w3.org/1999/xhtml"; 
              declare namespace marker="http://marklogic.com/marker";
              let $events := 
                for $event in cts:search(fn:collection("http://marklogic.com/marker/published"),cts:element-query(xs:QName("marker:type"),"Events")) 
                let $title := $event/*/marker:content/marker:title/text() 
                let $time := fn:string-join($event/*/marker:content/marker:event/marker:start-date/text(), ", ") 
                return 
                    <li>
                        <a href="/events/{{$event/*/marker:content/marker:name/text()}}">{{$title}} on {{$time}}</a>
                    </li> 
              return <ul>{{$events}}</ul>    
              </exec>
              <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>Miscellaneous</marker:type> 
                <marker:title>Event List</marker:title>
                <marker:name>event-navigation</marker:name>
                <marker:abstract>Container generates list of events</marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:published-date></marker:published-date>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:authors>
                </marker:authors>
                <marker:categories>
                </marker:categories>
                <marker:tags>
                </marker:tags>
            </marker:content>
            </div>
            ),  
         $note,
         $permissions, 
         $collection)
     let $content-insert := 
        dls:document-insert-and-manage(
        "/content-root/containers/news/news-navigation.container",
         fn:true(),
         (  <div runtime="dynamic">
              <exec>
              declare namespace xhtml = "http://www.w3.org/1999/xhtml"; 
              declare namespace marker="http://marklogic.com/marker";
              let $news := 
                for $item in cts:search(fn:collection("http://marklogic.com/marker/published"),cts:element-query(xs:QName("marker:type"),"News")) 
                let $title := $item/*/marker:content/marker:title/text() 
                return 
                    <li>
                        <a href="/news/{{$item/*/marker:content/marker:name/text()}}">{{$title}}</a>
                    </li> 
              return <ul>{{$news}}</ul>    
              </exec>
              <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>Miscellaneous</marker:type> 
                <marker:title>News List</marker:title>
                <marker:name>news-navigation</marker:name>
                <marker:abstract>Container generates list of news</marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:published-date></marker:published-date>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:authors>
                </marker:authors>
                <marker:categories>
                </marker:categories>
                <marker:tags>
                </marker:tags>
            </marker:content>
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
                declare variable $blog-name external;
                let $doc := library:stripMeta(library:doc(fn:concat("/content-root/containers/blogs/", $blog-name, "/", $name , ".container"))/node())
                let $meta := library:marker-properties-bag(fn:concat("/content-root/containers/blogs/", $blog-name, "/", $name , ".container"))
                return 
                    <div class="blog">
                        {{library:content-header($meta)}}
                        {{$doc}}
                    </div>
                </exec>
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Blog Content</marker:title>
                    <marker:name>blog-content</marker:name>
                    <marker:abstract>Display of blog content - basic funnel for individual posts</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
            </div>
            ),  
         $note,
         $permissions, 
         $collection)
     let $content-insert := 
        dls:document-insert-and-manage(
        "/content-root/containers/news/news-content.container",
         fn:true(),
         (  <div runtime="dynamic">
                <exec>
                import module namespace library = "http://marklogic.com/marker/library" at "/plugins/marker/library/library.xqy";
                declare namespace xhtml = "http://www.w3.org/1999/xhtml";
                declare variable $name external;
                 library:doc(fn:concat("/content-root/containers/news/", $name, ".container"))
                </exec>
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>News Content</marker:title>
                    <marker:name>news-content</marker:name>
                    <marker:abstract>Display of news content - basic funnel for individual news</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
            </div>
            ),  
         $note,
         $permissions, 
         $collection)
     let $content-insert := 
        dls:document-insert-and-manage(
        "/content-root/containers/events/event-content.container",
         fn:true(),
         (  <div runtime="dynamic">
                <exec>
                import module namespace library = "http://marklogic.com/marker/library" at "/plugins/marker/library/library.xqy";
                declare namespace xhtml = "http://www.w3.org/1999/xhtml";
                declare variable $name external;
                 library:doc(fn:concat("/content-root/containers/events/", $name, ".container"))
                </exec>
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Event Content</marker:title>
                    <marker:name>event-content</marker:name>
                    <marker:abstract>Display of event content - basic funnel for individual events</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
            </div>
            ),  
         $note,
         $permissions, 
         $collection)
    let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/containers/site-wide/search.container",
         fn:true(),
         (  <div>
                <form action="/search" method="get">
                    <fieldset>
                        <legend><label for="q">Search</label></legend>
                    <input type="hidden" id="start" name="start" value="1"/>
                    <input type="text" value=" Search the site" id="q" name="q" class="default" onblur="if (this.value == '')this.value = ' Search the site';" onfocus="if (this.value == ' Search the site')this.value = '';"/>
                    </fieldset>
                </form>
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Search Form Container</marker:title>
                    <marker:name>search</marker:name>
                    <marker:abstract>Input form for search</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
            </div>
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
                     <element ns="http://marklogic.com/marker" name="type"/>
                     
                    </range>
                  </constraint> 
                  <constraint name="Author">
                    <range type="xs:string" collation="http://marklogic.com/collation/">
                     <element ns="http://marklogic.com/marker" name="author"/>
                     
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
                    let $base-doc := doc(data($result/@uri))/*/marker:content
                    let $title := 
                        if($base-doc/marker:title/text())
                        then ($base-doc/marker:title/text())
                        else (fn:concat("&amp;","nbsp;"))
                    let $type := $base-doc/marker:type/text()
                    let $item := 
                        if($type eq 'Blogs' or $type eq 'News' or $type eq 'Events')
                        then 
                            (
                            <div class="result">
                                <a href="{{fn:concat($base-doc/*/marker:realized-path/text(),fn:replace($base-doc/marker:name/text(), ' ' , '_'))}}">{{$title}}</a>
                                <p>
                                    {{
                                      for $snip in $result//search:match/node()
                                                 return
                                                        if (fn:node-name($snip) eq xs:QName("search:highlight"))
                                                        then <b>{{$snip/text()}}</b>
                                                        else $snip   
                                    }}
                                </p>
                            </div>
                            )
                        else if($type eq 'Miscellaneous')
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
                                let $properties := library:doc($found-item)/*/marker:content
                                return
                                    <div class="result">
                                        <a href="/{{fn:replace(fn:replace(fn:replace($found-item, '/content-root/site/', ''), '/template.xhtml', ''), 'template.xhtml', '')}}">{{$properties/marker:title/text()}}</a>
                                        <p>
                                            {{
                                                 for $snip in $result//search:match/node()
                                                 return
                                                        if (fn:node-name($snip) eq xs:QName("search:highlight"))
                                                        then <b>{{$snip/text()}}</b>
                                                        else $snip                                                                                                                                                                               
                                       
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
                        then 
                            <ul>
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
                                        
                                        let $link := fn:concat(fn:encode-for-uri($link), "&amp;start=1")
                                        return
                                            <li>{{$icon}}<a href="search?q={{$link}}">{{fn:lower-case($print)}}</a> [{{fn:data($val/@count)}}]</li>
                                    return (
                                                <li>
                                                    <span>{{$facet-name}}</span>
                                                    <ul>{{$facet-items[1 to 10]}}</ul>
                                                </li>  
                                            )
                                }}          
                            </ul>
                         else <ul>&#160;</ul>

                return
                    <div>
                        <div id="main">
                        <h1>Search Results</h1>
                        
                        <div class="results">
                        {{if($items) then ($items) else (fn:concat("Sorry, nothing found for your search on '", $q, "'."))}}
                        </div>
                        <div class="pagination-container">
                             {{local:pagination($results)}}
                        </div>
                        </div>
                        <div id="sub">
                            <div class="subnav">
                            <h2>Filters</h2>
                            {{$facets}}
                            </div>
                        </div>
                    </div>
                </exec>
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Search Results Container</marker:title>
                    <marker:name>search-results</marker:name>
                    <marker:abstract>Search results - includes results, paging and facets</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
            </div>
            ),
         $note,
         $permissions, 
         $collection)   
    let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/containers/site-wide/footer-navigation.container",
         fn:true(),
         (  <div>
                <p>Copyright © 2011 MarkLogic Corporation.  MARKLOGIC® is a registered trademark of MarkLogic Corporation in the United States</p>
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Footer Container</marker:title>
                    <marker:name>footer-navigation</marker:name>
                    <marker:abstract>Footer navigation container</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
            </div>
            ),
         $note,
         $permissions, 
         $collection)
    let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/containers/home/main-content.container",
         fn:true(),
         (  <div>
                <h1>Marker</h1>
                <h2>A CMS Toolkit on top of MarkLogic</h2>
                <p>Marker is a framework for building Web CMS functionality on top of MarkLogic Server. </p>  

                <p>Built on top of an MVC framework (xqmvc) with support for REST/Ajax endpoints as well, Marker provides</p>
                
                <ul>
                <li>Flexible definition of content and page templates</li> 
                <li>Storage and management of all content inside MarkLogic directly.</li>
                <li>Management and versioning of content using MarkLogic's Library Services API</li>
                <li>WYSIWYG authoring of content and layout</li>
                <li>WYSIWYG markup/annotation of content</li>
                <li>Out-of-the box, built-in full-text search, including  </li>
                <li>Result browsing and snippetting</li>
                <li>Search facets based on content type definition as well as custom/annotation</li>
                <li>User authentication via OAuth2 (Github, Facebook) including automatic creation of linked user accounts in MarkLogic.</li>
                </ul>
                <p>Beyond the CMS toolkit, Marker is built on an additional, but stand-alone, xqmvc plugin that it uses for interacting with MarkLogic security APIs.</p>
                
                <p>Marker comes with some sample content from the MarkLogic developer site and is licensed via the <a href="http://www.apache.org/licenses/LICENSE-2.0.html">Apache 2.0 open source license</a>.  More details about Marker can be found at <a href="http://developer.marklogic.com/code/marker">http://developer.marklogic.com/code/marker</a> and the code is available at <a href="http://github.com/marklogic/marker">http://github.com/marklogic/marker</a>.</p>

                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Home Page Content</marker:title>
                    <marker:name>main-content</marker:name>
                    <marker:abstract>Home Page content</marker:abstract>
                    <marker:searchable>true</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
            </div>
            ),
         $note,
         $permissions, 
         $collection)
    let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/containers/about-us/main-content.container",
         fn:true(),
         (  <div>
                <p>This is the about page.</p>
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>About Us Page Content</marker:title>
                    <marker:name>main-content</marker:name>
                    <marker:abstract>About Us Page content</marker:abstract>
                    <marker:searchable>true</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
            </div>
            ),
         $note,
         $permissions, 
         $collection)
    let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/templates/main.template",
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
                    <div id="header">
                        <xi:include href="/content-root/containers/site-wide/login-logout.container">
                            <xi:fallback>
                                <xi:include href="/content-root/containers/site-wide/fallback.container">
                                    <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                </xi:include>
                            </xi:fallback> 
                        </xi:include>
                        <xi:include href="/content-root/containers/site-wide/search.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        <div id="navigation">
                           <xi:include href="/content-root/containers/site-wide/main-navigation.container">
                            <xi:fallback>
                                <xi:include href="/content-root/containers/site-wide/fallback.container">
                                    <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                </xi:include>
                            </xi:fallback> 
                           </xi:include> 
                        </div> 
                    </div>
                    
                    <div id="content">
                        <div id="main">
                           
                        </div>
                        <div id="sub">
                            
                        </div>
                       
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
            </body>
             <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>template</marker:type> 
                <marker:title>main</marker:title>
                <marker:name>main</marker:name>
                <marker:abstract>General template for the site</marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:base-id>{$uuid}</marker:base-id>
                <marker:derived>false</marker:derived>
            </marker:content>

        </html>  
            ),
         $note,
         $permissions, 
         $collection)
  let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/templates/main-wide-content.template",
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
                    <div id="header">
                        <xi:include href="/content-root/containers/site-wide/login-logout.container">
                            <xi:fallback>
                                <xi:include href="/content-root/containers/site-wide/fallback.container">
                                    <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                </xi:include>
                            </xi:fallback> 
                        </xi:include>
                        <xi:include href="/content-root/containers/site-wide/search.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        <div id="navigation">
                           <xi:include href="/content-root/containers/site-wide/main-navigation.container">
                            <xi:fallback>
                                <xi:include href="/content-root/containers/site-wide/fallback.container">
                                    <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                </xi:include>
                            </xi:fallback> 
                           </xi:include> 
                        </div> 
                    </div>
                    
                    <div id="content">
                  
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
            </body>
             <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>template</marker:type> 
                <marker:title>main wide content</marker:title>
                <marker:name>main-wide-content</marker:name>
                <marker:abstract>General template with full width content</marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:base-id>{$uuid2}</marker:base-id>
                <marker:derived>false</marker:derived>
            </marker:content>

        </html>  
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
                        <xi:include href="/content-root/containers/site-wide/login-logout.container">
                            <xi:fallback>
                                <xi:include href="/content-root/containers/site-wide/fallback.container">
                                    <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                </xi:include>
                            </xi:fallback> 
                        </xi:include> 
                        <xi:include href="/content-root/containers/site-wide/search.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        <div id="navigation">
                       <xi:include href="/content-root/containers/site-wide/main-navigation.container">
                        <xi:fallback>
                            <xi:include href="/content-root/containers/site-wide/fallback.container">
                                <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                            </xi:include>
                        </xi:fallback> 
                       </xi:include> 
                    </div>
                    </div>
                    
                    <div id="content">
                        <div id="main">
                           <xi:include href="/content-root/containers/home/main-content.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                        <div id="sub">
                           &nbsp; 
                            
                        </div>
                        
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
            </body>
            <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>template</marker:type> 
                <marker:title>Home</marker:title>
                <marker:name>template</marker:name>
                <marker:abstract>Derived Home template </marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:base-id>{$uuid}</marker:base-id>
                <marker:derived>true</marker:derived>
            </marker:content>
        </html>  
            ),
         $note,
         $permissions, 
         $collection)
    let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/site/news/template.xhtml",
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
                        <xi:include href="/content-root/containers/site-wide/login-logout.container">
                            <xi:fallback>
                                <xi:include href="/content-root/containers/site-wide/fallback.container">
                                    <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                </xi:include>
                            </xi:fallback> 
                        </xi:include> 
                        <xi:include href="/content-root/containers/site-wide/search.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        <div id="navigation">
                       <xi:include href="/content-root/containers/site-wide/main-navigation.container">
                        <xi:fallback>
                            <xi:include href="/content-root/containers/site-wide/fallback.container">
                                <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                            </xi:include>
                        </xi:fallback> 
                       </xi:include>  
                    </div>
                    </div>
                    
                    <div id="content">
                        <div id="main">
                            <xi:include href="/content-root/containers/news/news-navigation.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                        <div id="sub">
                             
                            &nbsp;
                        </div>
                        
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
            </body>
            <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>template</marker:type> 
                <marker:title>News</marker:title>
                <marker:name>template</marker:name>
                <marker:abstract>Derived News template </marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:base-id>{$uuid}</marker:base-id>
                <marker:derived>true</marker:derived>
            </marker:content>
        </html>  
            ),
         $note,
         $permissions, 
         $collection) 
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
                         <xi:include href="/content-root/containers/site-wide/login-logout.container">
                            <xi:fallback>
                                <xi:include href="/content-root/containers/site-wide/fallback.container">
                                    <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                </xi:include>
                            </xi:fallback> 
                        </xi:include> 
                        <xi:include href="/content-root/containers/site-wide/search.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        <div id="navigation">
                       <xi:include href="/content-root/containers/site-wide/main-navigation.container">
                        <xi:fallback>
                            <xi:include href="/content-root/containers/site-wide/fallback.container">
                                <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                            </xi:include>
                        </xi:fallback> 
                       </xi:include>  
                    </div>
                   </div>
                    
                    <div id="content">
                        <div id="main">
                            <xi:include href="/content-root/containers/about-us/main-content.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                        <div id="sub">
                             
                           &nbsp; 
                        </div>
                        
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
            </body>
            <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>template</marker:type> 
                <marker:title>About Us</marker:title>
                <marker:name>template</marker:name>
                <marker:abstract>Derived About Us template </marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:base-id>{$uuid}</marker:base-id>
                <marker:derived>true</marker:derived>
            </marker:content>
        </html>  
            ),
         $note,
         $permissions, 
         $collection)     
     let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/site/news/detail/template.xhtml",
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
                        <xi:include href="/content-root/containers/site-wide/login-logout.container">
                            <xi:fallback>
                                <xi:include href="/content-root/containers/site-wide/fallback.container">
                                    <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                </xi:include>
                            </xi:fallback> 
                        </xi:include> 
                        <xi:include href="/content-root/containers/site-wide/search.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        <div id="navigation">
                       <xi:include href="/content-root/containers/site-wide/main-navigation.container">
                        <xi:fallback>
                            <xi:include href="/content-root/containers/site-wide/fallback.container">
                                <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                            </xi:include>
                        </xi:fallback> 
                       </xi:include>  
                    </div>
                    </div>
                    
                    <div id="content">
                        <div id="main">
                            <xi:include href="/content-root/containers/news/news-content.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                        <div id="sub">
                             
                          &nbsp;
                        </div>
                        
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
            </body>
            <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>template</marker:type> 
                <marker:title>News Detail</marker:title>
                <marker:name>template</marker:name>
                <marker:abstract>Derived News Detail template </marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:base-id>{$uuid}</marker:base-id>
                <marker:derived>true</marker:derived>
            </marker:content>
        </html>  
            ),
         $note,
         $permissions, 
         $collection) 
    let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/site/events/template.xhtml",
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
                        <xi:include href="/content-root/containers/site-wide/login-logout.container">
                            <xi:fallback>
                                <xi:include href="/content-root/containers/site-wide/fallback.container">
                                    <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                </xi:include>
                            </xi:fallback> 
                        </xi:include> 
                        <xi:include href="/content-root/containers/site-wide/search.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                         <div id="navigation">
                       <xi:include href="/content-root/containers/site-wide/main-navigation.container">
                        <xi:fallback>
                            <xi:include href="/content-root/containers/site-wide/fallback.container">
                                <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                            </xi:include>
                        </xi:fallback> 
                       </xi:include>  
                    </div>
                    </div>
                   
                    <div id="content">
                        <div id="main">
                            <xi:include href="/content-root/containers/events/event-navigation.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                        <div id="sub">
                             
                           &nbsp;
                        </div>
                        
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
            </body>
            <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>template</marker:type> 
                <marker:title>Events</marker:title>
                <marker:name>template</marker:name>
                <marker:abstract>Derived Event template </marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:base-id>{$uuid}</marker:base-id>
                <marker:derived>true</marker:derived>
            </marker:content>
        </html>  
            ),
         $note,
         $permissions, 
         $collection) 
     let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/site/events/detail/template.xhtml",
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
                         <xi:include href="/content-root/containers/site-wide/login-logout.container">
                            <xi:fallback>
                                <xi:include href="/content-root/containers/site-wide/fallback.container">
                                    <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                </xi:include>
                            </xi:fallback> 
                        </xi:include> 
                        <xi:include href="/content-root/containers/site-wide/search.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        <div id="navigation">
                       <xi:include href="/content-root/containers/site-wide/main-navigation.container">
                        <xi:fallback>
                            <xi:include href="/content-root/containers/site-wide/fallback.container">
                                <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                            </xi:include>
                        </xi:fallback> 
                       </xi:include>  
                    </div>
                    </div>
                    
                    <div id="content">
                        <div id="main">
                            <xi:include href="/content-root/containers/events/event-content.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                        <div id="sub">
                             
                            &nbsp;
                        </div>
                        
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
            </body>
            <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>template</marker:type> 
                <marker:title>Events Detail</marker:title>
                <marker:name>template</marker:name>
                <marker:abstract>Derived Event template </marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:base-id>{$uuid}</marker:base-id>
                <marker:derived>true</marker:derived>
            </marker:content>
        </html>  
            ),
         $note,
         $permissions, 
         $collection) 
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
                         <xi:include href="/content-root/containers/site-wide/login-logout.container">
                            <xi:fallback>
                                <xi:include href="/content-root/containers/site-wide/fallback.container">
                                    <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                </xi:include>
                            </xi:fallback> 
                        </xi:include> 
                        <xi:include href="/content-root/containers/site-wide/search.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                         <div id="navigation">
                       <xi:include href="/content-root/containers/site-wide/main-navigation.container">
                        <xi:fallback>
                            <xi:include href="/content-root/containers/site-wide/fallback.container">
                                <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                            </xi:include>
                        </xi:fallback> 
                       </xi:include>  
                    </div>
                    </div>
                   
                    <div id="content">
                        <div id="main">
                            <xi:include href="/content-root/containers/blogs/blogs-navigation.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                        <div id="sub">
                             
                         &nbsp;
                        </div>
                        
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
            </body>
             <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>template</marker:type> 
                <marker:title>Blogs</marker:title>
                <marker:name>template</marker:name>
                <marker:abstract>Derived Blogs template </marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:base-id>{$uuid}</marker:base-id>
                <marker:derived>true</marker:derived>
            </marker:content>
        </html>  
            ),
         $note,
         $permissions, 
         $collection) 
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
                         <xi:include href="/content-root/containers/site-wide/login-logout.container">
                            <xi:fallback>
                                <xi:include href="/content-root/containers/site-wide/fallback.container">
                                    <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                </xi:include>
                            </xi:fallback> 
                        </xi:include> 
                        <xi:include href="/content-root/containers/site-wide/search.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        <div id="navigation">
                       <xi:include href="/content-root/containers/site-wide/main-navigation.container">
                        <xi:fallback>
                            <xi:include href="/content-root/containers/site-wide/fallback.container">
                                <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                            </xi:include>
                        </xi:fallback> 
                       </xi:include>  
                    </div>
                    </div>
                    
                    <div id="content">
                        <div id="main">
                            <xi:include href="/content-root/containers/blogs/blog-content.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                        <div id="sub">
                             
                           &nbsp;
                        </div>
                        
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
            </body>
             <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>template</marker:type> 
                <marker:title>Blogs Detail</marker:title>
                <marker:name>template</marker:name>
                <marker:abstract>Derived Event template </marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:base-id>{$uuid}</marker:base-id>
                <marker:derived>true</marker:derived>
            </marker:content>
        </html>  
            ),
         $note,
         $permissions, 
         $collection) 
     let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/site/blogs/blog/template.xhtml",
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
                         <xi:include href="/content-root/containers/site-wide/login-logout.container">
                            <xi:fallback>
                                <xi:include href="/content-root/containers/site-wide/fallback.container">
                                    <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                </xi:include>
                            </xi:fallback> 
                        </xi:include>
                        <xi:include href="/content-root/containers/site-wide/search.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        <div id="navigation">
                       <xi:include href="/content-root/containers/site-wide/main-navigation.container">
                        <xi:fallback>
                            <xi:include href="/content-root/containers/site-wide/fallback.container">
                                <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                            </xi:include>
                        </xi:fallback> 
                       </xi:include>  
                    </div> 
                    </div>
                    
                    <div id="content">
                        <div id="main">
                            <xi:include href="/content-root/containers/blogs/blog-navigation.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        </div>
                        <div id="sub">
                             
                          &nbsp;
                        </div>
                        
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
            </body>
             <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>template</marker:type> 
                <marker:title>Blog Page</marker:title>
                <marker:name>template</marker:name>
                <marker:abstract>Derived Blog template </marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:base-id>{$uuid}</marker:base-id>
                <marker:derived>true</marker:derived>
            </marker:content>
        </html>  
            ),
         $note,
         $permissions, 
         $collection) 
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
                         <xi:include href="/content-root/containers/site-wide/login-logout.container">
                            <xi:fallback>
                                <xi:include href="/content-root/containers/site-wide/fallback.container">
                                    <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                </xi:include>
                            </xi:fallback> 
                        </xi:include> 
                        <xi:include href="/content-root/containers/site-wide/search.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                        <div id="navigation">
                       <xi:include href="/content-root/containers/site-wide/main-navigation.container">
                        <xi:fallback>
                            <xi:include href="/content-root/containers/site-wide/fallback.container">
                                <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                            </xi:include>
                        </xi:fallback> 
                       </xi:include>  
                    </div>
                    </div>
                    
                    <div id="content">
                            <xi:include href="/content-root/containers/site-wide/search-results.container">
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
            </body>
             <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>template</marker:type> 
                <marker:title>Search</marker:title>
                <marker:name>template</marker:name>
                <marker:abstract>Derived Search template </marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:base-id>{$uuid2}</marker:base-id>
                <marker:derived>true</marker:derived>
            </marker:content>
        </html>  
            ),
         $note,
         $permissions, 
         $collection) 
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
    let $meta := <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Blogs</marker:type>
                    <marker:title>{$doc/ml:Post/ml:title/text()}</marker:title>
                    <marker:name>{fn:replace($pointer/dir:filename/text(), ".xml","")}</marker:name>
                    <marker:abstract></marker:abstract>
                    <marker:searchable>true</marker:searchable>
                    <marker:published-date>{$doc/ml:Post/ml:created/text()}</marker:published-date>
                    <marker:create-date>{$doc/ml:Post/ml:created/text()}</marker:create-date>
                    <marker:update-date>{$doc/ml:Post/ml:last-updated/text()}</marker:update-date>
                    <marker:authors>
                    { 
                    for $author in $doc/ml:Post//ml:author/text()
                    return <marker:author>{$author}</marker:author>
                    }
                    </marker:authors>
                    <marker:tags>
                            {
                            for $tag in $doc//ml:tag
                            return <marker:tag>{$tag/text()}</marker:tag>
                            }
                    </marker:tags>
                    <marker:blog>
                        <marker:blog-name>general</marker:blog-name>
                        <marker:realized-path>/blogs/general/</marker:realized-path>
                    </marker:blog>
                </marker:content>
   let $docRoot := $doc/ml:Post/ml:body

    let $newXML := 
    element {fn:node-name($docRoot)} {
        $docRoot/*,
        element marker:content {$meta/* }
        
    }   
    
    return dls:document-insert-and-manage(fn:concat("/content-root/containers/blogs/general/", fn:replace($pointer/dir:filename/text(), ".xml","") ,".container"), fn:false(), <div>{$newXML/node()}</div>, (), $permissions) 
let $log := if ($xqmvc-conf:debug) then xdmp:log("Inserted Blogs") else ()
let $entries := 
    for $entry in xdmp:filesystem-directory(fn:concat($base-dir,"/plugins/marker/resources/data/events"))//dir:entry
    where (fn:ends-with($entry/dir:filename/text(), ".xml"))
    return $entry
let $log := if ($xqmvc-conf:debug) then xdmp:log("Traversed Events") else ()
let $inserts :=
    for $pointer in $entries
    let $doc := xdmp:document-get($pointer/dir:pathname/text())
    let $meta := <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Events</marker:type>
                    <marker:title>{$doc/ml:Event/ml:title/text()}</marker:title>
                    <marker:name>{fn:replace($pointer/dir:filename/text(), ".xml","")}</marker:name>
                    <marker:abstract></marker:abstract>
                    <marker:searchable>true</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:tags>
                    </marker:tags>
                    <marker:event>
                        <marker:realized-path>/events/</marker:realized-path>
                        <marker:start-date>{$doc/ml:Event/ml:details/ml:date/text()}T00:00:00-07:00</marker:start-date>
                        <marker:end-date>/events/</marker:end-date>
                        <marker:dates>
                            <marker:date>{$doc/ml:Event/ml:details/ml:date/text()}</marker:date>
                        </marker:dates>
                        <marker:latitude></marker:latitude>
                        <marker:longitude></marker:longitude>
                        <marker:location>{$doc/ml:Event/ml:details/ml:location/text()}</marker:location>
                        <marker:topic>{$doc/ml:Event/ml:details/ml:topic/text()}</marker:topic>
                    </marker:event>
                </marker:content>
    let $docRoot := $doc/ml:Event/ml:description

    let $newXML := 
    element {fn:node-name($docRoot)} {
        $docRoot/*,
        element marker:content {$meta/* }
        
    }   
    
    return dls:document-insert-and-manage(fn:concat("/content-root/containers/events/", fn:replace($pointer/dir:filename/text(), ".xml","") ,".container"), fn:false(), <div>{$newXML/node()}</div>, (), $permissions) 
let $log := if ($xqmvc-conf:debug) then xdmp:log("Inserted Events") else ()

let $entries := 
    for $entry in xdmp:filesystem-directory(fn:concat($base-dir,"/plugins/marker/resources/data/news"))//dir:entry
    where (fn:ends-with($entry/dir:filename/text(), ".xml"))
    return $entry
let $log := if ($xqmvc-conf:debug) then xdmp:log("Traversed News") else ()
let $inserts :=
    for $pointer in $entries
    let $doc := xdmp:document-get($pointer/dir:pathname/text())
    let $meta := <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>News</marker:type>
                    <marker:title>{$doc/ml:Announcement/ml:title/text()}</marker:title>
                    <marker:name>{fn:replace($pointer/dir:filename/text(), ".xml","")}</marker:name>
                    <marker:abstract></marker:abstract>
                    <marker:searchable>true</marker:searchable>
                    <marker:published-date>{$doc/ml:Announcement/ml:created/text()}</marker:published-date>
                    <marker:create-date>{$doc/ml:Announcement/ml:created/text()}</marker:create-date>
                    <marker:update-date>{$doc/ml:Announcement/ml:last-updated/text()}</marker:update-date>
                    <marker:authors>
                    { 
                    for $author in $doc/ml:Announcement//ml:author/text()
                    return <marker:author>{$author}</marker:author>
                    }
                    </marker:authors>
                    <marker:tags>
                    </marker:tags>
                    <marker:news>
                        <marker:realized-path>/news/</marker:realized-path>
                    </marker:news>
                </marker:content>
    let $docRoot := $doc/ml:Announcement/ml:body

    let $newXML := 
    element {fn:node-name($docRoot)} {
        $docRoot/*,
        element marker:content {$meta/* }
        
    }   
    
    return dls:document-insert-and-manage(fn:concat("/content-root/containers/news/", fn:replace($pointer/dir:filename/text(), ".xml","") ,".container"), fn:false(), <div>{$newXML/node()}</div>, (), $permissions) 
let $log := if ($xqmvc-conf:debug) then xdmp:log("Inserted News") else ()

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
        return dls:document-set-properties(
            fn:concat("/content-root/containers/blogs/general/", fn:replace($pointer/dir:filename/text(), ".xml","") ,".container"),
             (
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Blogs</marker:type>
                    <marker:title>{$doc/ml:Post/ml:title/text()}</marker:title>
                    <marker:name>{fn:replace($pointer/dir:filename/text(), ".xml","")}</marker:name>
                    <marker:abstract></marker:abstract>
                    <marker:searchable>true</marker:searchable>
                    <marker:published-date>{$doc/ml:Post/ml:created/text()}</marker:published-date>
                    <marker:create-date>{$doc/ml:Post/ml:created/text()}</marker:create-date>
                    <marker:update-date>{$doc/ml:Post/ml:last-updated/text()}</marker:update-date>
                    <marker:authors>
                    { 
                    for $author in $doc/ml:Post//ml:author/text()
                    return <marker:author>{$author}</marker:author>
                    }
                    </marker:authors>
                    <marker:tags>
                            {
                            for $tag in $doc//ml:tag
                            return <marker:tag>{$tag/text()}</marker:tag>
                            }
                    </marker:tags>
                    <marker:blog>
                        <marker:blog-name>general</marker:blog-name>
                        <marker:realized-path>/blogs/general/</marker:realized-path>
                    </marker:blog>
                </marker:content>
                
             )
             ) 
     let $log := if ($xqmvc-conf:debug) then xdmp:log("Set Blog Properties") else ()
     let $entries := 
        for $entry in xdmp:filesystem-directory(fn:concat($base-dir,"/plugins/marker/resources/data/events"))//dir:entry
        where (fn:ends-with($entry/dir:filename/text(), ".xml"))
        return $entry
    let $log := if ($xqmvc-conf:debug) then xdmp:log("Traversed Events") else ()
    let $inserts :=
        for $pointer in $entries
        let $doc := xdmp:document-get($pointer/dir:pathname/text())
        return dls:document-set-properties(
            fn:concat("/content-root/containers/events/", fn:replace($pointer/dir:filename/text(), ".xml","") ,".container"),
             (
                <marker:content xmlns:marker="http://marklogic.com/marker">
                        <marker:type>Events</marker:type>
                        <marker:title>{$doc/ml:Event/ml:title/text()}</marker:title>
                        <marker:name>{fn:replace($pointer/dir:filename/text(), ".xml","")}</marker:name>
                        <marker:abstract></marker:abstract>
                        <marker:searchable>true</marker:searchable>
                        <marker:published-date></marker:published-date>
                        <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                        <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                        <marker:authors>
                        </marker:authors>
                        <marker:tags>
                        </marker:tags>
                        <marker:event>
                            <marker:realized-path>/events/</marker:realized-path>
                            <marker:start-date>{$doc/ml:Event/ml:details/ml:date/text()}T00:00:00-07:00</marker:start-date>
                            <marker:end-date>/events/</marker:end-date>
                            <marker:dates>
                                <marker:date>{$doc/ml:Event/ml:details/ml:date/text()}</marker:date>
                            </marker:dates>
                            <marker:latitude></marker:latitude>
                            <marker:longitude></marker:longitude>
                            <marker:location>{$doc/ml:Event/ml:details/ml:location/text()}</marker:location>
                            <marker:topic>{$doc/ml:Event/ml:details/ml:topic/text()}</marker:topic>
                        </marker:event>
                    </marker:content>
                
             )
             ) 
     let $log := if ($xqmvc-conf:debug) then xdmp:log("Set Events Properties") else ()
     
     let $entries := 
            for $entry in xdmp:filesystem-directory(fn:concat($base-dir,"/plugins/marker/resources/data/news"))//dir:entry
            where (fn:ends-with($entry/dir:filename/text(), ".xml"))
            return $entry
     let $log := if ($xqmvc-conf:debug) then xdmp:log("Traversed News") else ()
     let $inserts :=
        for $pointer in $entries
        let $doc := xdmp:document-get($pointer/dir:pathname/text())
        return dls:document-set-properties(
            fn:concat("/content-root/containers/news/", fn:replace($pointer/dir:filename/text(), ".xml","") ,".container"),
             (
               <marker:content xmlns:marker="http://marklogic.com/marker">
                        <marker:type>News</marker:type>
                        <marker:title>{$doc/ml:Announcement/ml:title/text()}</marker:title>
                        <marker:name>{fn:replace($pointer/dir:filename/text(), ".xml","")}</marker:name>
                        <marker:abstract></marker:abstract>
                        <marker:searchable>true</marker:searchable>
                        <marker:published-date>{$doc/ml:Announcement/ml:created/text()}</marker:published-date>
                        <marker:create-date>{$doc/ml:Announcement/ml:created/text()}</marker:create-date>
                        <marker:update-date>{$doc/ml:Announcement/ml:last-updated/text()}</marker:update-date>
                        <marker:authors>
                        { 
                        for $author in $doc/ml:Announcement//ml:author/text()
                        return <marker:author>{$author}</marker:author>
                        }
                        </marker:authors>
                        <marker:tags>
                        </marker:tags>
                        <marker:news>
                            <marker:realized-path>/news/</marker:realized-path>
                        </marker:news>
                    </marker:content>
                
             )
             ) 
   
     let $log := if ($xqmvc-conf:debug) then xdmp:log("Set news Properties") else ()
     
     
  
    let $log := if ($xqmvc-conf:debug) then xdmp:log("Setting general content properties") else ()
    let $default-container :=
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Fallback Container</marker:title>
                    <marker:name>fallback</marker:name>
                    <marker:abstract>Container for missing container</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
    let $_ := dls:document-set-properties('/content-root/containers/site-wide/fallback.container', ($default-container))
    let $default-container :=
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Login/Logout Container</marker:title>
                    <marker:name>login-logout</marker:name>
                    <marker:abstract>Container for authentication - dependent upon the security plugin</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
    let $_ := dls:document-set-properties('/content-root/containers/site-wide/login-logout.container', ($default-container))
    let $default-container :=
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Footer Container</marker:title>
                    <marker:name>footer-navigation</marker:name>
                    <marker:abstract>Footer navigation container</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
    let $_ := dls:document-set-properties("/content-root/containers/site-wide/footer-navigation.container",($default-container))
    let $default-container :=
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Search Form Container</marker:title>
                    <marker:name>search</marker:name>
                    <marker:abstract>Input form for search</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
    let $_ := dls:document-set-properties("/content-root/containers/site-wide/search.container",($default-container))
    let $default-container :=
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Search Results Container</marker:title>
                    <marker:name>search-results</marker:name>
                    <marker:abstract>Search results - includes results, paging and facets</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
    let $_ := dls:document-set-properties("/content-root/containers/site-wide/search-results.container",($default-container))
    let $default-container :=
               <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>About Us Page Content</marker:title>
                    <marker:name>main-content</marker:name>
                    <marker:abstract>About Us Page content</marker:abstract>
                    <marker:searchable>true</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
    let $_ := dls:document-set-properties("/content-root/containers/about-us/main-content.container", ($default-container))
    let $default-container :=
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Home Page Content</marker:title>
                    <marker:name>main-content</marker:name>
                    <marker:abstract>Home Page content</marker:abstract>
                    <marker:searchable>true</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
    let $_ := dls:document-set-properties("/content-root/containers/home/main-content.container", ($default-container))
    let $default-container :=
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Main Navigation Container</marker:title>
                    <marker:name>main-navigation</marker:name>
                    <marker:abstract>Main navigation container</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
    let $_ := dls:document-set-properties("/content-root/containers/site-wide/main-navigation.container", ($default-container))
    let $default-template :=
                 <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>template</marker:type> 
                <marker:title>Home</marker:title>
                <marker:name>template</marker:name>
                <marker:abstract>Derived Home template </marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:base-id>{$uuid}</marker:base-id>
                <marker:derived>true</marker:derived>
            </marker:content>
    let $_ := dls:document-set-properties("/content-root/site/template.xhtml", ($default-template))
    let $default-template :=
                 <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>template</marker:type> 
                <marker:title>About Us</marker:title>
                <marker:name>template</marker:name>
                <marker:abstract>Derived About us template </marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:base-id>{$uuid}</marker:base-id>
                <marker:derived>true</marker:derived>
            </marker:content>
    let $_ := dls:document-set-properties("/content-root/site/about-us/template.xhtml", ($default-template))
     let $default-template :=
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>template</marker:type> 
                    <marker:title>main</marker:title>
                    <marker:name>main</marker:name>
                    <marker:abstract>General template for the site</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:base-id>{$uuid}</marker:base-id>
                    <marker:derived>false</marker:derived>
                </marker:content>
    let $_ := dls:document-set-properties("/content-root/templates/main.template", ($default-template))
    let $default-template :=
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>template</marker:type> 
                    <marker:title>main wide content</marker:title>
                    <marker:name>main-wide-content</marker:name>
                    <marker:abstract>General template for with content full width</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:base-id>{$uuid2}</marker:base-id>
                    <marker:derived>false</marker:derived>
                </marker:content>
    let $_ := dls:document-set-properties("/content-root/templates/main-wide-content.template", ($default-template))
    let $default-template :=
                 <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>template</marker:type> 
                <marker:title>Blogs</marker:title>
                <marker:name>template</marker:name>
                <marker:abstract>Derived blogs template </marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:base-id>{$uuid}</marker:base-id>
                <marker:derived>true</marker:derived>
            </marker:content>
    let $_ := dls:document-set-properties("/content-root/site/blogs/template.xhtml", ($default-template))
     let $default-template :=
                 <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>template</marker:type> 
                <marker:title>Events</marker:title>
                <marker:name>template</marker:name>
                <marker:abstract>Derived Events template </marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:base-id>{$uuid}</marker:base-id>
                <marker:derived>true</marker:derived>
            </marker:content>
    let $_ := dls:document-set-properties("/content-root/site/events/template.xhtml", ($default-template))
     let $default-template :=
                 <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>template</marker:type> 
                <marker:title>News</marker:title>
                <marker:name>template</marker:name>
                <marker:abstract>Derived news template </marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:base-id>{$uuid}</marker:base-id>
                <marker:derived>true</marker:derived>
            </marker:content>
    let $_ := dls:document-set-properties("/content-root/site/news/template.xhtml", ($default-template))
    let $default-template :=
                 <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>template</marker:type> 
                <marker:title>Search</marker:title>
                <marker:name>template</marker:name>
                <marker:abstract>Derived Search template </marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:base-id>{$uuid}</marker:base-id>
                <marker:derived>true</marker:derived>
            </marker:content>
    let $_ := dls:document-set-properties("/content-root/site/search/template.xhtml", ($default-template))
    let $default-template :=
                 <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>template</marker:type> 
                <marker:title>Blog Page</marker:title>
                <marker:name>template</marker:name>
                <marker:abstract>Derived Blog Page template </marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:base-id>{$uuid}</marker:base-id>
                <marker:derived>true</marker:derived>
            </marker:content>
    let $_ := dls:document-set-properties("/content-root/site/blogs/blog/template.xhtml", ($default-template))
    let $default-template :=
                 <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>template</marker:type> 
                <marker:title>Blogs Detail</marker:title>
                <marker:name>template</marker:name>
                <marker:abstract>Derived Blogs Detail template </marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:base-id>{$uuid}</marker:base-id>
                <marker:derived>true</marker:derived>
            </marker:content>
    let $_ := dls:document-set-properties("/content-root/site/blogs/detail/template.xhtml", ($default-template))
    let $default-template :=
                 <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>template</marker:type> 
                <marker:title>Events Detail</marker:title>
                <marker:name>template</marker:name>
                <marker:abstract>Derived Events template </marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:base-id>{$uuid}</marker:base-id>
                <marker:derived>true</marker:derived>
            </marker:content>
    let $_ := dls:document-set-properties("/content-root/site/events/detail/template.xhtml", ($default-template))
    let $default-template :=
                 <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>template</marker:type> 
                <marker:title>News Detail</marker:title>
                <marker:name>template</marker:name>
                <marker:abstract>Derived News template </marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:base-id>{$uuid}</marker:base-id>
                <marker:derived>true</marker:derived>
            </marker:content>
    let $_ := dls:document-set-properties("/content-root/site/news/detail/template.xhtml", ($default-template))
    let $default-container :=
            <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>Miscellaneous</marker:type> 
                <marker:title>Blog List</marker:title>
                <marker:name>blog-navigation</marker:name>
                <marker:abstract>Container generates list of blogs by name or general</marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:published-date></marker:published-date>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:authors>
                </marker:authors>
                <marker:categories>
                </marker:categories>
                <marker:tags>
                </marker:tags>
            </marker:content>
    let $_ := dls:document-set-properties("/content-root/containers/blogs/blog-navigation.container", ($default-container))
    let $default-container :=
            <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Blog Content</marker:title>
                    <marker:name>blog-content</marker:name>
                    <marker:abstract>Display of blog content - basic funnel for individual posts</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
    let $_ := dls:document-set-properties("/content-root/containers/blogs/blog-content.container", ($default-container))
    let $default-container :=
           <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>Miscellaneous</marker:type> 
                <marker:title>News List</marker:title>
                <marker:name>news-navigation</marker:name>
                <marker:abstract>Container generates list of news</marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:published-date></marker:published-date>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:authors>
                </marker:authors>
                <marker:categories>
                </marker:categories>
                <marker:tags>
                </marker:tags>
            </marker:content>
    let $_ := dls:document-set-properties("/content-root/containers/news/news-navigation.container", ($default-container))
    let $default-container :=
            <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>News Content</marker:title>
                    <marker:name>news-content</marker:name>
                    <marker:abstract>Display of news content - basic funnel for individual news</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
    let $_ := dls:document-set-properties("/content-root/containers/news/news-content.container", ($default-container))
    let $default-container :=
            <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>Miscellaneous</marker:type> 
                <marker:title>Event List</marker:title>
                <marker:name>event-navigation</marker:name>
                <marker:abstract>Container generates list of events</marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:published-date></marker:published-date>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:authors>
                </marker:authors>
                <marker:categories>
                </marker:categories>
                <marker:tags>
                </marker:tags>
            </marker:content>
    let $_ := dls:document-set-properties("/content-root/containers/events/event-navigation.container", ($default-container))
    let $default-container :=
            <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Event Content</marker:title>
                    <marker:name>event-content</marker:name>
                    <marker:abstract>Display of event content - basic funnel for individual events</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
    let $_ := dls:document-set-properties("/content-root/containers/events/event-content.container", ($default-container))
    
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
    let $entries := 
        for $entry in xdmp:filesystem-directory(fn:concat($base-dir,"/plugins/marker/resources/data/events"))//dir:entry
        where (fn:ends-with($entry/dir:filename/text(), ".xml"))
        return $entry
    let $log := if ($xqmvc-conf:debug) then xdmp:log("Grabbed events list") else ()
    let $inserts :=
        for $pointer in $entries
        return library:publishLatest(fn:concat("/content-root/containers/events/", fn:replace($pointer/dir:filename/text(), ".xml","") ,".container"))
    let $log := if ($xqmvc-conf:debug) then xdmp:log("Published latest events") else () 
    let $entries := 
        for $entry in xdmp:filesystem-directory(fn:concat($base-dir,"/plugins/marker/resources/data/news"))//dir:entry
        where (fn:ends-with($entry/dir:filename/text(), ".xml"))
        return $entry
    let $log := if ($xqmvc-conf:debug) then xdmp:log("Grabbed newa list") else ()
    let $inserts :=
        for $pointer in $entries
        return library:publishLatest(fn:concat("/content-root/containers/news/", fn:replace($pointer/dir:filename/text(), ".xml","") ,".container"))
    let $log := if ($xqmvc-conf:debug) then xdmp:log("Published latest news") else ()    
             
    let $log := if ($xqmvc-conf:debug) then xdmp:log("Publishing latest version of main content") else ()
    let $publish := library:publishLatest("/content-root/containers/site-wide/fallback.container")
    let $publish := library:publishLatest("/content-root/containers/site-wide/footer-navigation.container")
    let $publish := library:publishLatest("/content-root/containers/site-wide/search.container")
    let $publish := library:publishLatest("/content-root/containers/site-wide/search-results.container")
    let $publish := library:publishLatest("/content-root/containers/about-us/main-content.container")
    let $publish := library:publishLatest("/content-root/containers/home/main-content.container")
    let $publish := library:publishLatest("/content-root/containers/site-wide/main-navigation.container")
    let $publish := library:publishLatest("/content-root/containers/site-wide/login-logout.container")
    let $publish := library:publishLatest("/content-root/site/template.xhtml")
    let $publish := library:publishLatest("/content-root/site/about-us/template.xhtml")
    let $publish := library:publishLatest("/content-root/site/blogs/template.xhtml")
    let $publish := library:publishLatest("/content-root/site/blogs/blog/template.xhtml")
    let $publish := library:publishLatest("/content-root/site/search/template.xhtml")
    let $publish := library:publishLatest("/content-root/site/blogs/detail/template.xhtml")
    let $publish := library:publishLatest("/content-root/containers/blogs/blog-navigation.container")
    let $publish := library:publishLatest("/content-root/containers/blogs/blogs-navigation.container")
    let $publish := library:publishLatest("/content-root/containers/blogs/blog-content.container")
    let $publish := library:publishLatest("/content-root/site/news/template.xhtml")
    let $publish := library:publishLatest("/content-root/site/news/detail/template.xhtml")
    let $publish := library:publishLatest("/content-root/containers/news/news-navigation.container")
    let $publish := library:publishLatest("/content-root/containers/news/news-content.container")
    let $publish := library:publishLatest("/content-root/site/events/template.xhtml")
    let $publish := library:publishLatest("/content-root/site/events/detail/template.xhtml")
    let $publish := library:publishLatest("/content-root/containers/events/event-navigation.container")
    let $publish := library:publishLatest("/content-root/containers/events/event-content.container")
    let $log := if ($xqmvc-conf:debug) then xdmp:log("Publishing complete") else ()
    return xqmvc:template('master-template', (
                'browsertitle', 'marker Data Install Complete',
                'body', xqmvc:plugin-view($cfg:plugin-name,'setup-install-data-view', ())
            )) 
};
