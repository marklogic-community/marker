xquery version "1.0-ml";

(:
 : Copyright 2010 Avalon Consulting LLC
 :)
 
module namespace xqmvc-controller = "http://scholarsportal.info/xqmvc/controller";
import module namespace xqmvc = "http://scholarsportal.info/xqmvc/core" at "/system/xqmvc.xqy";

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
    xqmvc:template('master-template', (
                'browsertitle', 'Security Setup',
                'body', xqmvc:plugin-view($plugin-cfg:plugin-name,'setup-index-view', ())
            ))
};
declare function install()
{
    let $_ := role:createRole("security-anon", "Anonymous user role for security")
    let $_ := role:createRole("security-user", "Base user role for security")
    let $_ := role:createRole("security-admin", "Admin user role for security")
    
    let $addRoles := authorization:addPrivileges("security-anon", 
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
         "http://marklogic.com/xdmp/privileges/xdmp-value",
         "http://marklogic.com/xdmp/privileges/xdmp-user-roles",
         "http://marklogic.com/xdmp/privileges/xdmp-get-session-field-names"))  
    let $addRoles := authorization:addPrivileges("security-admin", 
       ("http://marklogic.com/xdmp/privileges/admin-module-read",
             "http://marklogic.com/xdmp/privileges/admin-module-write",
             "http://marklogic.com/xdmp/privileges/get-role-names",
             "http://marklogic.com/xdmp/privileges/xdmp-eval-in",
             "http://marklogic.com/xdmp/privileges/dls-user",
             "http://marklogic.com/xdmp/privileges/xdmp-filesystem-directory",
             "http://marklogic.com/xdmp/privileges/xdmp-document-get",
             "http://marklogic.com/xdmp/privileges/get-user-names",
             "http://marklogic.com/xdmp/privileges/xdmp-filesystem-file"))         
    
    let $existingUsers := user:getExistingUsers()
    let $security-user-user := 
        if("security-anon" = $existingUsers) then 
            "User security-anon already exists"
        else
            xdmp:eval(
                "xquery version '1.0-ml'; 
                import module namespace sec='http://marklogic.com/xdmp/security' at '/MarkLogic/security.xqy';
                sec:create-user('security-anon', 'Security Anonymous User', 'password', 'security-anon', (), ())", (),
                <options xmlns="xdmp:eval"><database>{xdmp:database("Security")}</database> </options>)     
    
    let $_ := role:addRoleToRole("security-user", "security-anon")
    let $_ := role:addRoleToRole("security-admin", "security-user")
    let $_ := role:addRoleToRole("security-admin", "security")
   
    let $_ := xdmp:document-insert("/plugins/security/controller-mapping/security-user.xml",
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
            (xdmp:permission("security-anon", "read"), xdmp:permission("security-admin", "update"))
    )
    let $_ := xdmp:document-insert("/plugins/security/controller-mapping/security-anon.xml",
        <role-mappings>
            <mapping mapped="1" plugin="security" controller="authentication" action="index">security/authentication/index</mapping>
            <mapping mapped="1" plugin="security" controller="authentication" action="facebook">security/authentication/facebook</mapping>
            <mapping mapped="1" plugin="security" controller="authentication" action="github">security/authentication/github</mapping>
            <mapping mapped="1" plugin="security" controller="authentication" action="_authenticate">security/authentication/_authenticate</mapping>
            <mapping mapped="1" plugin="security" controller="authentication" action="logout">security/authentication/logout</mapping>
            <mapping mapped="1" plugin="security" controller="error" action="not-authorized">security/error/not-authorized</mapping>
            <mapping mapped="1" plugin="" controller="welcome" action="index">/welcome/index</mapping>
            <mapping mapped="1" plugin="marker" controller="render" action="index">marker/render/index</mapping>
        </role-mappings>,
            (xdmp:permission("security-anon", "read"), xdmp:permission("security-admin", "update"))
    )
    let $config := admin:get-configuration()
    let $config := admin:appserver-set-authentication($config, xdmp:server(), "application-level")
    let $_ :=  admin:save-configuration($config)
    let $config := admin:get-configuration()
    let $config := admin:appserver-set-default-user($config, xdmp:server(),
                                                                     xdmp:eval('
                                                                                  xquery version "1.0-ml";
                                                                                  import module "http://marklogic.com/xdmp/security" 
                                                                            at "/MarkLogic/security.xqy"; 
                                                                              sec:uid-for-name("security-anon")', (),  
                                                                       <options xmlns="xdmp:eval">
                                                                         <database>{xdmp:security-database()}</database>
                                                                       </options>))
    let $_ :=  admin:save-configuration($config)
    
    let $_ := xdmp:document-insert("/plugins/security/config.xml",
        <security_config>
            <install-completed>true</install-completed>
            <admin-user-completed>false</admin-user-completed>
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
        </security_config>,
            (xdmp:permission("security-anon", "read"), xdmp:permission("security-admin", "update"))
    )
    (:let $_ := xdmp:logout():)
    let $_ := for $name in xdmp:get-session-field-names()
                return xdmp:set-session-field($name,()) 
    return xqmvc:template('master-template', (
                'browsertitle', 'Security Setup Complete',
                'body', xqmvc:plugin-view($plugin-cfg:plugin-name,'setup-install-view', ())
            ))
    
};



