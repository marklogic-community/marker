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
module namespace security = "http://marklogic.com/security";
import module namespace xqmvc-conf = "http://scholarsportal.info/xqmvc/config" at "/application/config/config.xqy";

declare function security:getUsername($user_id) as xs:string {

        xdmp:eval(
            "
            xquery version '1.0-ml';
            import module namespace sec='http://marklogic.com/xdmp/security' at '/MarkLogic/security.xqy';
            declare variable $author_id as xs:unsignedLong external;
            sec:user-get-description(sec:get-user-names($author_id)[1]/text())
            ",
            (xs:QName("author_id"), $user_id),
            <options xmlns="xdmp:eval"><database>{xdmp:database("Security")}</database> </options>)

};
declare function security:getCurrentUserRoles() 
{   
    let $roles := xdmp:get-session-field("roles",())
    let $roleNames :=
        for $role in $roles/text()
        return fn:string($role)
    let $log := if ($xqmvc-conf:debug) then xdmp:log(fn:concat("Roles for current user:", fn:string-join($roleNames,","))) else ()
    return $roleNames
};