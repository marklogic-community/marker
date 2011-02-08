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

declare function index()
{
    
    let $_ := role:createRole("marker-admin", "Admin user role for marker")  
    let $_ := role:addRoleToRole("dls-user", "security-anon") 
    let $_ := role:addRoleToRole("dls-admin", "marker-admin")
    let $_ := role:addRoleToRole("dls-internal", "marker-admin")       
   
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
                            15,
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
        try {
            sec:protect-collection('DRAFTS', 
                xdmp:permission('marker-admin', 'execute')
            ),
            sec:protect-collection('PUBLISHED', 
                (xdmp:permission('marker-admin', 'execute'), xdmp:permission('security-anon', 'read'))
            )
            } catch ($err) {
            ()
        }
        ",  
        (),
        <options xmlns="xdmp:eval"><database>{xdmp:database("Security")}</database> </options>
    )  
    let $_ := xdmp:document-insert("/plugins/marker/config.xml",
        <marker_config>
            <install-completed>false</install-completed>
            <default-page>/index.html</default-page>
        </marker_config>,
            (xdmp:permission("security-anon", "read"), xdmp:permission("marker-admin", "update"))
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
    let $_ := admin:database-set-uri-lexicon($config, 
            xdmp:database(), fn:true())
    let $_ := admin:database-set-trailing-wildcard-searches($config, 
        xdmp:database(), fn:true())
    return ("complete")
};