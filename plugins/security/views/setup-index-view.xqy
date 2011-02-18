xquery version "1.0-ml";
import module namespace xqmvc = "http://scholarsportal.info/xqmvc/core" at "/system/xqmvc.xqy";
import module namespace user = "http://marklogic.com/plugins/security/user" at "../models/user-model.xqy";
declare variable $data as map:map external;

<div id="main-content">
   <div>
   <h2>Security Setup</h2>
   <p>
    <a href="/security/setup/install">Security has not been installed on this application. To continue, please click here to install.</a>
    </p>
   </div>
</div>