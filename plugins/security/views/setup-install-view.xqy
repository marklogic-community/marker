xquery version "1.0-ml";
import module namespace xqmvc = "http://scholarsportal.info/xqmvc/core" at "/system/xqmvc.xqy";
import module namespace user = "http://marklogic.com/plugins/security/user" at "../models/user-model.xqy";
declare variable $data as map:map external;

<div id="main-content">
   <div>
    Setup was successful for the security plugin. Please login now to set your account as the administrator.
   </div>
</div>