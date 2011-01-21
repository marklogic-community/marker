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
module namespace role = "http://marklogic.com/plugins/security/role";

import module namespace cfg = "http://marklogic.com/plugins/security/config" at "../config/config.xqy";

(:~ 
 : Create a new role in the Security database for the given database
 : @param $roleName 
 : @param $description the role description
 : @param $securityDatabaseName
 :)
declare function role:createRole($roleName, $description, $securityDatabaseName as xs:string) 
{
    let $existingRoles := role:getExistingRoles()
               
    (: create the role :)    
    return 
        if($roleName = $existingRoles) then 
            fn:concat("Role ", $roleName, " already exists")
        else
            xdmp:eval(
                fn:concat(
                "xquery version '1.0-ml'; 
                import module namespace sec='http://marklogic.com/xdmp/security' at '/MarkLogic/security.xqy';
                sec:create-role('", $roleName, "', '", $description, "', (), (), ())"), (),
                <options xmlns="xdmp:eval"><database>{xdmp:database($securityDatabaseName)}</database> </options>)        
};

declare function role:createRole($roleName, $description)
{
    role:createRole($roleName, $description, "Security") 
};

(:~
 : Return the existing roles in the Security database
 :)
declare function role:getExistingRoles($securityDatabaseName as xs:string) 
{
    xdmp:eval(
        "xquery version '1.0-ml'; fn:data(/sec:role/sec:role-name)", (),
        <options xmlns="xdmp:eval"><database>{xdmp:database($securityDatabaseName)}</database> </options>)
};

declare function role:getExistingRoles() 
{
    role:getExistingRoles("Security") 
};
declare function role:addRoleToRole($roleName, $roleToAdd, $securityDatabaseName as xs:string) 
{
    let $existingRoles := role:getRolesOfRole($roleName)
               
    return 
        if($roleName = $existingRoles) then 
            fn:concat("Role ", $roleName, " already has ", $roleToAdd, " role")
        else
            xdmp:eval(
                fn:concat(
                "xquery version '1.0-ml'; 
                import module namespace sec='http://marklogic.com/xdmp/security' at '/MarkLogic/security.xqy';
                sec:role-add-roles('", $roleName, "', '", $roleToAdd, "')"), (),
                <options xmlns="xdmp:eval"><database>{xdmp:database($securityDatabaseName)}</database> </options>)        
};

declare function role:addRoleToRole($roleName, $roleToAdd) 
{
    role:addRoleToRole($roleName, $roleToAdd, "Security") 
};

(:~
 : Return the existing roles in the Security database
 :)
declare function role:getRolesOfRole($roleName as xs:string, $securityDatabaseName as xs:string) 
{
    try {
    xdmp:eval(
        fn:concat(
        "xquery version '1.0-ml'; 
        import module namespace sec='http://marklogic.com/xdmp/security' at '/MarkLogic/security.xqy';
        sec:role-get-roles('", $roleName, "')"
        ), (),
        <options xmlns="xdmp:eval"><database>{xdmp:database($securityDatabaseName)}</database> </options>)
    } catch($err) {
        let $log := xdmp:log(fn:concat("Couldn't getRolesOfRole because Role ", $roleName, " doesn't exist! ", $err/*:message/text()))
        return ()
    }    
};

declare function role:getRolesOfRole($roleName as xs:string) 
{
    role:getRolesOfRole($roleName, "Security") 
};
