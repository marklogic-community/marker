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
import module namespace plugin-cfg = "http://marklogic.com/plugins/security/config" at "../config/config.xqy";
import module namespace application-cfg = "http://scholarsportal.info/xqmvc/config" at "/application/config/config.xqy";
declare namespace xdmphttp="xdmp:http";

declare function index()
{
    let $split := fn:tokenize( xdmp:get-request-url(), "\?")
    let $queryString := $split[2]
    return _authenticate($plugin-cfg:default-provider , $queryString)
    
};

declare function facebook()
{
    let $split := fn:tokenize( xdmp:get-request-url(), "\?")
    let $queryString := $split[2]
    return _authenticate("facebook", $queryString)
};
declare function github()
{
    let $split := fn:tokenize( xdmp:get-request-url(), "\?")
    let $queryString := $split[2]
    return _authenticate("github", $queryString)
};
declare function _authenticate($provider, $queryString){
    let $code           := xdmp:get-request-field("code")

    let $auth_provider  := fn:doc($plugin-cfg:configuration)/oauth_config/provider[@name eq $provider]
    let $client_id      := $auth_provider/id/text()
    let $client_secret  := $auth_provider/secret/text()
    (:let $redirect_url   := $auth_provider/redirect_url/text():)
    let $redirect_url := fn:concat("http://", $application-cfg:server-name, ":" , $application-cfg:server-http-port,  xqmvc:plugin-link('security', 'authentication', $provider)) 
    let $scope          := if($provider = "github") then "&amp;scope=user" else ""
    let $authorization_url := fn:concat($auth_provider/authorize_url/text(),
                                        "?client_id=", $client_id, 
                                        "&amp;redirect_uri=", xdmp:url-encode($redirect_url))
                                         
    let $access_token_url := fn:concat($auth_provider/access_token_url/text(),
                                       "?client_id=",$client_id, 
                                       "&amp;redirect_uri=", xdmp:url-encode($redirect_url),
                                       "&amp;code=", $code,
                                       "&amp;client_secret=", $client_secret,
                                       $scope)
                             
    return
        if(fn:not($code)) then
            xdmp:redirect-response($authorization_url)
        else 
            let $access_token_response := xdmp:http-get($access_token_url)
            return
                if($access_token_response[1]/xdmphttp:code/text() eq "200") then
                    
                    let $oauth_token_data := oauth2:parseAccessToken($access_token_response[2])
                    let $provider_user_data := oauth2:getUserProfileInfo($provider, $oauth_token_data)
                    return 
                        if($provider_user_data) then
                            let $user_id := $provider_user_data/id/text()  
                            let $markLogicUsername := oauth2:getOrCreateUserByProvider($provider, $user_id, $provider_user_data) 
                            let $authResult := oauth2:loginAsMarkLogicUser($markLogicUsername)
                            let $referer := xdmp:get-request-header("Referer")
                            return 
    
                                (: the referrer gets lost sometimes from the original site, namely when you need to login iwth your credential
                                   at facebook. If you're already logged in then it works fine. So if the referer is from facebook just
                                   redirected to the root :)
                                if($referer and fn:not(fn:starts-with($referer, "http://www.facebook.com"))) then
                                    xdmp:redirect-response($referer)
                                else
                                    xdmp:redirect-response("/")
                        else
                            (
                            let $log := xdmp:log("Could not get user information")
                            return ()
                            )
                else
                    (: if there's a problem just pass along the error :)
                    (
                    xdmp:set-response-code($access_token_response[1]/xdmphttp:code/text(),
                                           $access_token_response[1]/xdmphttp:message/text()),
                                           xdmp:log("an error"))
                                           
};
declare function logout(){
    let $_ := xdmp:logout()
    return xdmp:redirect-response("/")
};

