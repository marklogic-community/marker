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
module namespace user = "http://marklogic.com/plugins/security/user";
import module namespace cfg = "http://marklogic.com/plugins/security/config" at "../config/config.xqy";
import module namespace xqmvc-cfg = "http://scholarsportal.info/xqmvc/config" at "/application/config/config.xqy";


declare function user:createNewUser($markLogicUsername as xs:string, 
                                          $userPassword as xs:string,
                                          $userDescription as xs:string,
                                          $role as xs:string,
                                          $providerName as xs:string, 
                                          $providerUserId as xs:string,
                                          $securityDatabaseName as xs:string) 
{
    let $existingUsers := user:getExistingUsers()
    let $log := xdmp:log("createNewUser")                    
    return 
        if($markLogicUsername = $existingUsers) then 
            fn:concat("User ", $markLogicUsername, " already exists")
        else
            try {
                xdmp:eval(
                    fn:concat(
                    "xquery version '1.0-ml'; 
                    import module namespace sec='http://marklogic.com/xdmp/security' at '/MarkLogic/security.xqy';
                    sec:create-user('", $markLogicUsername, "', '", $userDescription, "', '", $userPassword, "', '", $role, "', (), ())"), (),
                    <options xmlns="xdmp:eval">
                        <database>{xdmp:database($securityDatabaseName)}</database> 
                    </options>)  
            } catch($e) {
                let $log := xdmp:log(fn:concat("FAILED TO CREATE USER. Error: ", $e/*:message[1]/text()))
                return "User could not be created!!"
            } 
                                      
};

declare function user:createNewUser($markLogicUsername as xs:string, 
                                          $userPassword as xs:string,
                                          $userDescription as xs:string,
                                          $role as xs:string,
                                          $providerName as xs:string, 
                                          $providerUserId as xs:string) 
{
    user:createNewUser($markLogicUsername, $userPassword, $userDescription, $role, $providerName, $providerUserId, "Security")   
};


(:~
 : Return the existing users in the Security database
 :)
declare function user:getExistingUsers($securityDatabaseName as xs:string) 
{
    xdmp:eval(
        "xquery version '1.0-ml'; fn:data(/sec:user/sec:user-name)", (),
        <options xmlns="xdmp:eval"><database>{xdmp:database($securityDatabaseName)}</database> </options>)
};

declare function user:getExistingUsers() 
{
    user:getExistingUsers("Security")
};

