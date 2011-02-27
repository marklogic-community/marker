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
    <h1>Welcome to Marker from MarkLogic</h1>
    <p>
        This is a sample site provided by MarkLogic to demonstrate a CMS on top of MarkLogic. The sample is based off of a derived xqmvc architecture that has been modified
        to support multiple url structures and security schemes.
    </p>
    <p>
        Out of the box you get the new security plugin that allows role based authorization to the mvc model. If you are seeing this screen, you have successfully
        installed the security plugin.
    </p>
    <p>
        Please check out the side bar to the right for additional plugins that may need to be installed.
    </p>
    <p>
        <a href="http://github.com/marklogic/marker">
            Website / Documentation
        </a>
    </p>
    <table>
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
        <tr>
            <td># of Documents in Library:</td><td>{fn:count(cts:search(fn:doc(), 
        cts:and-query((
            cts:directory-query("/", "infinity"), fn:concat('', "*")))))}</td>
        </tr>
        <tr>
            <td>Documents:</td><td>{for $doc in cts:search(fn:doc(), 
        cts:and-query((
            cts:directory-query("/", "infinity"), fn:concat('', "*"))))
            return <div>{fn:base-uri($doc)}</div>}</td>
        </tr>
    </table>
</div>
