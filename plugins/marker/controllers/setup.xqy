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
declare namespace xi="http://www.w3.org/2001/XInclude";

declare function index()
{
    let $_ := role:createRole("marker-admin", "Admin user role for marker")
    return xqmvc:template('master-template', (
            'browsertitle', 'Marker Setup',
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
        
            sec:protect-collection('DRAFTS', 
                (xdmp:permission('marker-admin', 'execute'), xdmp:permission('marker-admin', 'update'))
            ),
            sec:protect-collection('PUBLISHED', 
                (xdmp:permission('marker-admin', 'execute'), xdmp:permission('security-anon', 'read'), xdmp:permission('marker-admin', 'update'))
            )
     
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
            <mapping mapped="1" plugin="marker" controller="setup" action="install-data-publish">marker/setup/install-data-publish</mapping>
            <mapping mapped="1" plugin="marker" controller="render" action="index">marker/render/index</mapping>
        </role-mappings>,
            (xdmp:permission("security-anon", "read"), xdmp:permission("security-admin", "update"))
    )
   let $_ := xdmp:document-insert("/application/mapping.xml",
        <mappings>
            <mapping regex="^/blogs/([\w\.-]+)/([\w\.-]+)$" template="/blogs/detail/template.xhtml">
                <params name="name" match="1"/>
                <params name="post" match="2"/>
            </mapping>
            <mapping regex="^/blogs/([\w\.-]+)$" template="/blogs/template.xhtml">
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
        
    return xqmvc:template('master-template', (
                'browsertitle', 'Marker Setup Complete',
                'body', xqmvc:plugin-view($cfg:plugin-name,'setup-install-view', ())
            ))
    
};
declare function install-data()
{
    let $collection := "DRAFTS"
    let $collection-published := "DRAFTS"
    let $note := "insert from setup install"
    let $permissions := (xdmp:permission('marker-admin', 'update'), xdmp:permission('marker-admin', 'read')) 
    let $content-insert := 
        dls:document-insert-and-manage(
         "/content-root/containers/site-wide/fallback.container",
         fn:true(),
         (  <div>Sorry. This content could not be served</div>
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
              </ul></div>
            ),  
         $note,
         $permissions, 
         $collection)
    let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/containers/site-wide/footer-navigation.container",
         fn:true(),
         (  <div><p>footer content here...</p></div>
            ),
         $note,
         $permissions, 
         $collection)
    let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/containers/home/main-content.container",
         fn:true(),
         (  <div><p>This is the home page.</p></div>
            ),
         $note,
         $permissions, 
         $collection)
    let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/containers/about-us/main-content.container",
         fn:true(),
         (  <div><p>This is the about page.</p></div>
            ),
         $note,
         $permissions, 
         $collection)
    let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/containers/services/main-content.container",
         fn:true(),
         (  <div><p>This is the services page.</p></div>
            ),
         $note,
         $permissions, 
         $collection)
    let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/containers/contact-us/main-content.container",
         fn:true(),
         (  <div><p>This is the contact page.</p></div>
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
                            <h3>Content Side Bar</h3>
                            <p>sidebar Content here</p>
                        </div>
                        <div id="footer">
                            <div style="float:right;"><exec id="12345">xquery version "1.0-ml";import module namespace taglib-security = "http://marklogic.com/plugin/security/taglib" at "/plugins/security/taglibs/taglib-auth.xqy";taglib-security:current-user()</exec></div>
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
                            <h3>Content Side Bar</h3>
                            <p>sidebar Content here</p>
                        </div>
                        <div id="footer">
                            <div style="float:right;"><exec id="12345">xquery version "1.0-ml";import module namespace taglib-security = "http://marklogic.com/plugin/security/taglib" at "/plugins/security/taglibs/taglib-auth.xqy";taglib-security:current-user()</exec></div>
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
                            <h3>Content Side Bar</h3>
                            <p>sidebar Content here</p>
                        </div>
                        <div id="footer">
                            <div style="float:right;"><exec id="12345">xquery version "1.0-ml";import module namespace taglib-security = "http://marklogic.com/plugin/security/taglib" at "/plugins/security/taglibs/taglib-auth.xqy";taglib-security:current-user()</exec></div>
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
                            <h3>Content Side Bar</h3>
                            <p>sidebar Content here</p>
                        </div>
                        <div id="footer">
                            <div style="float:right;"><exec id="12345">xquery version "1.0-ml";import module namespace taglib-security = "http://marklogic.com/plugin/security/taglib" at "/plugins/security/taglibs/taglib-auth.xqy";taglib-security:current-user()</exec></div>
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
        </html>  
            ),
         $note,
         $permissions, 
         $collection-published) 
     return xdmp:redirect-response("/marker/setup/install-data-publish")                                                          
     
};
declare function install-data-publish()
{
    let $publish := library:publishLatest("/content-root/containers/site-wide/fallback.container")
    let $publish := library:publishLatest("/content-root/containers/site-wide/footer-navigation.container")
    let $publish := library:publishLatest("/content-root/containers/contact-us/main-content.container")
    let $publish := library:publishLatest("/content-root/containers/about-us/main-content.container")
    let $publish := library:publishLatest("/content-root/containers/services/main-content.container")
    let $publish := library:publishLatest("/content-root/containers/home/main-content.container")
    let $publish := library:publishLatest("/content-root/containers/site-wide/main-navigation.container")
    let $publish := library:publishLatest("/content-root/site/template.xhtml")
    let $publish := library:publishLatest("/content-root/site/contact-us/template.xhtml")
    let $publish := library:publishLatest("/content-root/site/services/template.xhtml")
    let $publish := library:publishLatest("/content-root/site/about-us/template.xhtml")
    return xqmvc:template('master-template', (
                'browsertitle', 'Marker Data Install Complete',
                'body', xqmvc:plugin-view($cfg:plugin-name,'setup-install-data-view', ())
            )) 
};
