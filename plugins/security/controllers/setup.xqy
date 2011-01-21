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
 
module namespace xqmvc-controller = "http://scholarsportal.info/xqmvc/controller";
import module namespace xqmvc = "http://scholarsportal.info/xqmvc/core" at "/system/xqmvc.xqy";

import module namespace oauth2 = "oauth2" at "../library/oauth2.xqy";
import module namespace user = "http://marklogic.com/plugins/security/user" at "../models/user-model.xqy";
import module namespace role = "http://marklogic.com/plugins/security/role" at "../models/role-model.xqy";
import module namespace authorization = "http://marklogic.com/plugins/security/authorization" at "../models/authorization-model.xqy";
import module namespace plugin-cfg = "http://marklogic.com/plugins/security/config" at "../config/config.xqy";
import module namespace application-cfg = "http://scholarsportal.info/xqmvc/config" at "/application/config/config.xqy";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
declare namespace xdmphttp="xdmp:http";
declare namespace s = "http://www.w3.org/2009/xpath-functions/analyze-string";

declare function index()
{
    let $_ := role:createRole("oauth-anon", "Anonymous user role for oauth")
    let $_ := role:createRole("oauth-user", "Base user role for oauth")
    let $_ := role:createRole("oauth-admin", "Admin user role for oauth")
    
    let $addRoles := authorization:addPrivileges("oauth-anon", 
        ("http://marklogic.com/xdmp/privileges/xdmp-invoke",
         "http://marklogic.com/xdmp/privileges/xdmp-eval",
         "http://marklogic.com/xdmp/privileges/xdmp-login",
         "http://marklogic.com/xdmp/privileges/xdmp-eval-in",
         "http://marklogic.com/xdmp/privileges/create-user",
         "http://marklogic.com/xdmp/privileges/any-uri",     
         "http://marklogic.com/xdmp/privileges/any-collection",
         "http://marklogic.com/xdmp/privileges/grant-all-roles",
         "http://marklogic.com/xdmp/privileges/get-user-names",
         "http://marklogic.com/xdmp/privileges/get-role-names",
         "http://marklogic.com/xdmp/privileges/xdmp-get-server-field",
         "http://marklogic.com/xdmp/privileges/xdmp-set-server-field",
         "http://marklogic.com/xdmp/privileges/xdmp-set-session-field",
         "http://marklogic.com/xdmp/privileges/xdmp-get-session-field",
         "http://marklogic.com/xdmp/privileges/xdmp-value"))           
    
    let $existingUsers := user:getExistingUsers()
    let $oauth-user-user := 
        if("oauth-anon" = $existingUsers) then 
            "User oauth-anon already exists"
        else
            xdmp:eval(
                "xquery version '1.0-ml'; 
                import module namespace sec='http://marklogic.com/xdmp/security' at '/MarkLogic/security.xqy';
                sec:create-user('oauth-anon', 'OAuth2 Anonymous User', 'password', 'oauth-anon', (), ())", (),
                <options xmlns="xdmp:eval"><database>{xdmp:database("Security")}</database> </options>)     
    
    let $_ := role:addRoleToRole("oauth-user", "oauth-anon")
    let $_ := role:addRoleToRole("oauth-admin", "oauth-user")
    
    let $_ := xdmp:document-insert("/plugins/security/config.xml",
        <oauth_config>
            <provider name="facebook">
                <id>162088510505521</id>
                <secret>1566bfe43e0f0aa91c6d259040f2e284</secret>
                <access_token_url>https://graph.facebook.com/oauth/access_token</access_token_url>
                <authorize_url>https://graph.facebook.com/oauth/authorize</authorize_url>
                <redirect_url>http://localhost:8100/security/authentication/facebook</redirect_url>
            </provider>
            <provider name="github">
                <id>47df013b281952796da7</id>
                <secret>b4482d5ac4e7f629ad20d08c2ff9b895ceb8b745</secret>
                <access_token_url>https://github.com/login/oauth/access_token</access_token_url>
                <authorize_url>https://github.com/login/oauth/authorize</authorize_url>
                <redirect_url>http://localhost:8100/security/authentication/github</redirect_url>
            </provider>
        </oauth_config>,
            (xdmp:permission("oauth-anon", "read"), xdmp:permission("oauth-admin", "update"))
    )
    let $_ := xdmp:document-insert("/plugins/security/controller-mapping/oauth-admin.xml",
        <role-mappings>
            <mapping mapped="1" plugin="security" controller="setup" action="index">security/setup/index</mapping>
            <mapping mapped="1" plugin="security" controller="authentication" action="index">security/authentication/index</mapping>
            <mapping mapped="1" plugin="security" controller="authentication" action="facebook">security/authentication/facebook</mapping>
            <mapping mapped="1" plugin="security" controller="authentication" action="github">security/authentication/github</mapping>
            <mapping mapped="1" plugin="security" controller="authentication" action="_authenticate">security/authentication/_authenticate</mapping>
            <mapping mapped="1" plugin="security" controller="authentication" action="logout">security/authentication/logout</mapping>
            <mapping mapped="1" plugin="" controller="welcome" action="index">/welcome/index</mapping>
            <mapping mapped="1" plugin="" controller="welcome" action="restricted">/welcome/restricted</mapping>
            <mapping mapped="1" plugin="marker" controller="setup" action="index">marker/setup/index</mapping>
            <mapping mapped="1" plugin="marker" controller="render" action="index">marker/render/index</mapping>
        </role-mappings>,
            (xdmp:permission("oauth-anon", "read"), xdmp:permission("oauth-admin", "update"))
    )
    let $_ := xdmp:document-insert("/plugins/security/controller-mapping/oauth-user.xml",
        <role-mappings>
            <mapping mapped="1" plugin="security" controller="setup" action="index">security/setup/index</mapping>
            <mapping mapped="1" plugin="security" controller="authentication" action="index">security/authentication/index</mapping>
            <mapping mapped="1" plugin="security" controller="authentication" action="facebook">security/authentication/facebook</mapping>
            <mapping mapped="1" plugin="security" controller="authentication" action="github">security/authentication/github</mapping>
            <mapping mapped="1" plugin="security" controller="authentication" action="_authenticate">security/authentication/_authenticate</mapping>
            <mapping mapped="1" plugin="security" controller="authentication" action="logout">security/authentication/logout</mapping>
            <mapping mapped="1" plugin="" controller="welcome" action="index">/welcome/index</mapping>
            <mapping mapped="1" plugin="" controller="welcome" action="restricted">/welcome/restricted</mapping>
            <mapping mapped="1" plugin="marker" controller="setup" action="index">marker/setup/index</mapping>
            <mapping mapped="1" plugin="marker" controller="render" action="index">marker/render/index</mapping>
        </role-mappings>,
            (xdmp:permission("oauth-anon", "read"), xdmp:permission("oauth-admin", "update"))
    )
    let $_ := xdmp:document-insert("/plugins/security/controller-mapping/oauth-anon.xml",
        <role-mappings>
            <mapping mapped="1" plugin="security" controller="authentication" action="index">security/authentication/index</mapping>
            <mapping mapped="1" plugin="security" controller="authentication" action="facebook">security/authentication/facebook</mapping>
            <mapping mapped="1" plugin="security" controller="authentication" action="github">security/authentication/github</mapping>
            <mapping mapped="1" plugin="security" controller="authentication" action="_authenticate">security/authentication/_authenticate</mapping>
            <mapping mapped="1" plugin="security" controller="authentication" action="logout">security/authentication/logout</mapping>
            <mapping mapped="1" plugin="" controller="welcome" action="index">/welcome/index</mapping>
            <mapping mapped="1" plugin="marker" controller="render" action="index">marker/render/index</mapping>
        </role-mappings>,
            (xdmp:permission("oauth-anon", "read"), xdmp:permission("oauth-admin", "update"))
    )
    (: add mod to change config for authentication-action :)
    return ("complete")
    
};



