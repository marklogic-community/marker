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
module namespace taglib-security = "http://marklogic.com/plugin/security/taglib";
declare namespace html = "http://www.w3.org/1999/xhtml";
import module namespace xqmvc = "http://scholarsportal.info/xqmvc/core" at "/system/xqmvc.xqy";

declare function taglib-security:login-logout()
{
    let $username := xdmp:get-current-user()
    let $isLoggedIn := $username != "security-anon"
    let $userDetails := /user[@name = $username]/provider-data
    let $picture :=$userDetails/picture/text()
    return
    <div>
        <div id="login-action"> 
        {
            if( $isLoggedIn ) then 
                <a href="{ xqmvc:plugin-link('security', 'authentication', 'logout')}" onmouseover="$('#profile').show(300);" onmouseout="$('#profile').hide(500);">Logout</a> 
            else 
                <div id="login" style="cursor:hand;cursor:pointer;">Login</div>
                
        }
        </div>
        <div id="login-modal" title="Login">
            <p style="text-align:center;">Log in using one of the following:<br/><br/>
            <a href="{ xqmvc:plugin-link('security', 'authentication', 'facebook') }"><img src="/plugins/security/resources/img/facebook.png" border="0" /></a>
            <a href="{ xqmvc:plugin-link('security', 'authentication', 'github') }"><img src="/plugins/security/resources/img/github.png" border="0" /></a>
               
            </p>
        </div>
        <script>
            $(function() {{
                $("#login").click(function(){{$('#login-modal').dialog('open');}});
                $( "#login-modal" ).dialog({{
                    autoOpen: false,
                    width: 300,
                    height: 140,
                    modal: true
                }});
            }});
        </script>

        {
            if($isLoggedIn) then
                <div id="profile" style="padding:5px;display:none;">
                    <div style="float:right;">
                        <a href="{$userDetails/link/text()}">{$userDetails/name/text()}&nbsp;</a><br/>
                        <span>via {xs:string( $userDetails/@name )}</span>
                    </div>
                    <img style="width:30px;margin-right:5px;" src="{$picture}" />
                </div>
            else ()
        }
   </div> 
        
};
declare function taglib-security:current-user()
{
    let $username := xdmp:get-current-user()
    let $isLoggedIn := $username != "security-anon"
    let $userDetails := /user[@name = $username]/provider-data
    let $picture :=$userDetails/picture/text()
    return 
            if($isLoggedIn) then
                <div id="profile" style="padding:5px;height:40px;">
                <div style="float:right;text-align:right;">
                        <a href="{$userDetails/link/text()}">{$userDetails/name/text()}&nbsp;</a><br/>
                        <span>via {xs:string( $userDetails/@name )}</span>
                    </div>
                    <img style="width:30px;margin-right:5px;" src="{$picture}" />
                    
                </div>
            else (<div>&nbsp;</div>)
        
};
