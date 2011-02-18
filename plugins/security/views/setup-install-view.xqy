xquery version "1.0-ml";
import module namespace xqmvc = "http://scholarsportal.info/xqmvc/core" at "/system/xqmvc.xqy";
declare variable $data as map:map external;
(
        <div>
      <h2>Security Setup Successful</h2>
           <div>
            Setup was successful for the security plugin. Please click logout (upper right top corner) and then click login to set your account as the administrator.
           </div>
              <script>
            $(function() {{
               $('#login-modal').dialog('open');
            }});
        </script>
        </div>
)