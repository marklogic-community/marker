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
import module namespace xqmvc = "http://scholarsportal.info/xqmvc/core" at "../../system/xqmvc.xqy";
declare variable $data as map:map external;

<div>
    <p>
        <a href="http://code.google.com/p/xqmvc">
            Website / Documentation
        </a>
    </p>
    <table>
        <tr>
        <td>doc count:</td><td>{fn:count(xdmp:directory("/wiki/"))}</td>
        </tr>
        <tr>
            <td>Time:</td><td>{ xdmp:strftime("%a %d %b %Y %I:%M %p", xs:dateTime(map:get($data, 'time'))) }</td>
        </tr>
        <tr>
            <td>Architecture:</td><td>{ map:get($data, 'arch') }</td>
        </tr>
        <tr>
            <td>Platform:</td><td>{ map:get($data, 'plat') }</td>
        </tr>
        <tr>
            <td>MarkLogic:</td><td>{ map:get($data, 'vers') }</td>
        </tr>
    </table>
    <p><a href="{ xqmvc:link('welcome', 'restricted') }">Restricted &raquo;</a></p>
</div>