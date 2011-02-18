xquery version "1.0-ml";
import module namespace xqmvc = "http://scholarsportal.info/xqmvc/core" at "/system/xqmvc.xqy";
declare variable $data as map:map external;
(

        <div>
            <h2>Marker Data Setup Successful</h2>
           <div>
            Data install was successful for the marker plugin. To begin browsing click <a href="/">here</a>. This will take you into the admin screen for content. 
            In order to see content while not logged in, you need to go in and publish the content via the inline editor control.
           </div>
        </div>
)