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
module namespace oauth2 = "oauth2";
declare namespace xdmphttp="xdmp:http";
import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";
import module namespace user = "http://marklogic.com/plugins/security/user" at "../models/user-model.xqy";

(:~
 : Fetch the user profile info for the given provider, basically a router function
 : @param $provider the provider name corresponding the provider config setup
 : @param $oauth_token_data the oauth2 access_token for the current users session
 : @return the provider-data node() block
 :)
declare function oauth2:getUserProfileInfo($provider, $oauth_token_data)  {
    let $access_token := map:get($oauth_token_data, "access_token")    
    return
    if($provider = "facebook") then
        oauth2:facebookUserProfileInfo($access_token) 
    else
        oauth2:githubUserProfileInfo($access_token) 
};

(:~
 : Given the user_data map, get the request token and call to Facebook to get profile information
 : populate the profile information in the map (see within for those values
 :) 
declare function oauth2:facebookUserProfileInfo($access_token)  {
    let $profile_url := fn:concat("https://graph.facebook.com/me?access_token=", $access_token)
    let $cmd := fn:concat("xquery version '1.0-ml'; xdmp:http-get('", 
                          $profile_url, 
                          "', <options xmlns='xdmp:http-get'><format xmlns='xdmp:document-get'>text</format></options>)")
    let $profile_response :=  xdmp:eval($cmd)
    return
        if($profile_response[1]/xdmphttp:code/text() eq "200") then
            let $json_response := $profile_response[2]
            let $map_response := xdmp:from-json($profile_response[2])
            let $provider_user_data :=
                <provider-data name="facebook">
                    <id>{map:get($map_response,"id")}</id>
                    <name>{map:get($map_response,"name")}</name>
                    <link>{map:get($map_response,"link")}</link>
                    <gender>{map:get($map_response,"gender")}</gender>
                    <picture>{fn:concat("http://graph.facebook.com/", map:get($map_response,"id"), "/picture" )}</picture>
                </provider-data>
            return
                $provider_user_data
        else 
            ()
    
};

(:~
 : Given the user_data map, get the request token and call to Facebook to get profile information
 : populate the profile information in the map (see within for those values
 :) 
declare function oauth2:githubUserProfileInfo($access_token)  {
    let $profile_url := fn:concat("https://github.com/api/v2/xml/user/show?access_token=", $access_token)
    let $cmd := fn:concat("xquery version '1.0-ml'; xdmp:http-get('", 
                          $profile_url, 
                          "')")
    let $profile_response :=  xdmp:eval($cmd)
    return
        if($profile_response[1]/xdmphttp:code/text() eq "200") then
            let $xml_response := $profile_response[2]
            let $provider_user_data :=
                <provider-data name="github">
                    <id>{$xml_response/user/login/text()}</id>
                    <name>{$xml_response/user/name/text()}</name>
                    <link>{fn:concat("http://github.com/", $xml_response/user/login/text())}</link>
                    <picture>{fn:concat("http://www.gravatar.com/avatar/", $xml_response/user/gravatar-id/text())}</picture>
                </provider-data>
            return
                $provider_user_data
        else 
            ()
    
};

(:~
 : Parse the response text of an outh2 access token request into the token and 
 : expiration date
 : @param $responseText response text of the access token request
 : @return map containing access_token, expires
 :)
declare function oauth2:parseAccessToken($responseText) as item()+ {
   let $params := fn:tokenize($responseText, "&amp;")
   let $access_token := fn:tokenize($params[1], "=")[2]
   let $expires_seconds := if($params[2]) then fn:tokenize($params[2], "=")[2] else ()
   let $expires := if($params[2]) then fn:current-dateTime() + xs:dayTimeDuration(fn:concat("PT", $expires_seconds, "S")) else ()
   let $user_data := map:map()
   let $key := map:put($user_data, "access_token", $access_token)
   let $key := map:put($user_data, "expires", $expires)
   return $user_data
};


(:~
 : Given a provider name and provider user Id, look for a MarkLogic user that's mapped to that provider
 : identity
 :)
declare function oauth2:getOrCreateUserByProvider($providerName as xs:string, 
                                                      $providerUserId as xs:string,
                                                      $providerUserData as node()) 
{                                                  
    let $userDetails :=  /user/provider-data[id/text() eq $providerUserId and @name = $providerName]
    return  
        if($userDetails) then
            fn:doc(xdmp:node-uri($userDetails))/user/@name
        else 
            (: if the user could not be found then create it :)
            let $fullName := $providerUserData/name/text()
            let $description := fn:concat($providerName, " User ", $fullName, " (", $providerUserId, ")")
            let $username := fn:concat($providerName, "_", $providerUserId)
            let $password := xs:string(xdmp:hash32($username))
            let $newuser := user:createNewUser($username, $password, $description, ("oauth-user"), $providerName, $providerUserId)
            let $usermapping := oauth2:mapUserToAuthProvider($username, $providerName, $providerUserId, $providerUserData)
            return
                $username
};

(:~
 : Map a MarkLogic user to an auth provider. Create the provider data block
 : with details about the user from the auth provider
 : @param $markLogicUsername the username of the MarkLogic database user in the security database
 : @param $providerName the provider name corresponding to the provider config
 : @param $providerUserId the unique user id from the provider
 : @param $providerUserData node() block representing the user profile data from the provider
 : 
 :)
declare function oauth2:mapUserToAuthProvider($markLogicUsername as xs:string, 
                                              $providerName as xs:string, 
                                              $providerUserId as xs:string,
                                              $providerUserData as node()) 
{
    let $pathToUserDetail := fn:concat("/users/", $markLogicUsername, ".xml")
    let $userDetail := xdmp:unpath($pathToUserDetail)/user
 
    return
        if($userDetail) then
            if($userDetail/provider-data[@name = $providerName]) then
                xdmp:node-replace($userDetail/provider-data[@name = $providerName], $providerUserData)
               else
                xdmp:node-insert-child($userDetail,$providerUserData)
        else
            xdmp:document-insert($pathToUserDetail,
                element user { 
                    attribute name { $markLogicUsername },
                    $providerUserData
                },
                (xdmp:permission("oauth-anon", "read"), xdmp:permission("oauth-admin", "update"))
            )          
};

declare function oauth2:loginAsMarkLogicUser($username) 
{
    xdmp:eval(
        fn:concat("xquery version '1.0-ml'; xdmp:login('", $username, "')")    
    )
};
