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
 


:)
module namespace authorization = "http://marklogic.com/plugins/security/authorization";

import module namespace cfg = "http://marklogic.com/plugins/security/config" at "../config/config.xqy";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
import module namespace xqmvc-conf = "http://scholarsportal.info/xqmvc/config" at "/application/config/config.xqy";
import module namespace xqmvc = "http://scholarsportal.info/xqmvc/core" at "/system/xqmvc.xqy";

declare namespace s = "http://www.w3.org/2009/xpath-functions/analyze-string";
declare variable $plugin-dir as xs:string := fn:concat($xqmvc-conf:app-root, '/plugins');
declare variable $controller-dir as xs:string := fn:concat($xqmvc-conf:app-root, '/application/controllers');
(:~ 
 : Add a sequence of privileges to a role
 : @param $role the name of the role
 : @param $privs a sequence of privileges
 :)
declare function authorization:addPrivileges($role, $privs as item(), $securityDatabaseName as xs:string) 
{
    for $priv in $privs
    return xdmp:eval(
        fn:concat(
        "xquery version '1.0-ml'; 
        import module namespace sec='http://marklogic.com/xdmp/security' at '/MarkLogic/security.xqy';
        sec:privilege-add-roles( '", $priv, "', 'execute', ('", $role, "'))"
        ), (),
        <options xmlns="xdmp:eval"><database>{xdmp:database($securityDatabaseName)}</database> </options>)
};

declare function authorization:addPrivileges($role, $privs as item()) 
{
    authorization:addPrivileges($role, $privs, "Security") 
};

declare function authorization:getAllowedControllerActions($role)
{
    fn:doc(fn:concat("/plugins/security/controller-mapping/", $role, ".xml"))/node()
};

declare function authorization:isRoleAuthorizedForControllerAction($role, $controller, $action)
{   
    if(authorization:isInstalled($controller))
    then
        (
        let $log := if ($xqmvc-conf:debug) then xdmp:log(fn:concat("Authorizing role:", $role)) else ()
        let $log := if ($xqmvc-conf:debug) then xdmp:log(fn:concat("for:", $controller, "-", $action)) else ()
        let $mappingCache := xdmp:get-server-field(fn:concat("authorization:", $role), '')
        let $mappings :=
            if($mappingCache eq '')
            then 
            (
                let $mappingXML := authorization:getAllowedControllerActions($role)
                let $log := if ($xqmvc-conf:debug) then xdmp:log(fn:concat("mappingXML:", $mappingXML)) else ()
                return
                    if($mappingXML)
                    then 
                        (
                            let $newCache := authorization:convertMappingXMLToAuthorizationSequence($mappingXML)
                            let $_ := xdmp:set-server-field(fn:concat("authorization:", $role), $newCache)
                            return $newCache    
                        )
                    else
                        (
                        let $_ := xdmp:set-server-field(fn:concat("authorization:", $role), ("n/a"))
                        return "n/a"
                        )
            )
            else $mappingCache
        let $log := if ($xqmvc-conf:debug) then xdmp:log(fn:concat("comparing against:", fn:string-join($mappings, ","))) else ()    
        return 
            if($role eq "admin")
            then 
                (
                let $log := if ($xqmvc-conf:debug) then xdmp:log("Is admin -- allowing all access") else () 
                return fn:true()
                )
            else
                (
                (fn:concat($controller, "-", $action) eq $mappings)
                )
        )
    else
        (
        xdmp:redirect-response("/security/setup/index")
        )
};
declare function authorization:isInstalled($controller)
{
    let $installed := 
        if(xdmp:get-server-field("security-setup", fn:false()))
        then 
            (
            fn:true()
            )
        else
            (
            let $installed-flag := 
                if(fn:doc("/plugins/security/config.xml"))
                then 
                    (
                    let $log := if ($xqmvc-conf:debug) then xdmp:log("Security is installed - setting application variable") else ()
                    let $_ := xdmp:get-server-field("security-setup", fn:true())
                    return fn:true()
                    )
                else
                    (
                    if(fn:starts-with($controller,"/plugins/security/controllers/setup.xqy") or fn:starts-with($controller, "/plugins/security/controllers/error.xqy"))
                    then
                        (
                        fn:true()
                        )
                    else
                        (
                        let $log := if ($xqmvc-conf:debug) then xdmp:log("Security is not installed - redirecting") else ()
                        let $log := if ($xqmvc-conf:debug) then xdmp:log(fn:concat("Checking controller:", $controller)) else ()
                        return fn:false()
                        )
                    )
            return $installed-flag
            )
    return 
        if($installed eq fn:true())
        then 
            (
            let $log := if ($xqmvc-conf:debug) then xdmp:log("Security is installed or being installed") else ()
            return $installed
            )
        else 
            (
            let $log := if ($xqmvc-conf:debug) then xdmp:log("attempting redirect") else ()
            return $installed
            )
            
        
            
};
declare function authorization:convertMappingXMLToAuthorizationSequence($mappingXML)
{
    let $authorizationSequence :=
        for $mapping in $mappingXML//mapping
        return 
            if (fn:data($mapping/@plugin) eq "")
            then (fn:concat($controller-dir,"/", fn:data($mapping/@controller), ".xqy-",fn:data($mapping/@action)))
            else (fn:concat($plugin-dir,"/", fn:data($mapping/@plugin), "/controllers/", fn:data($mapping/@controller), ".xqy-",fn:data($mapping/@action)))
    
    return $authorizationSequence
};
