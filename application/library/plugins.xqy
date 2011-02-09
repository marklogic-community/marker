xquery version "1.0-ml";

module namespace plugins = "http://marklogic.com/xqmvc/plugins";

import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
import module namespace xqmvc-conf = "http://scholarsportal.info/xqmvc/config" at "/application/config/config.xqy";

declare function plugins:getPlugins()
{
    let $base-dir :=
        let $config := admin:get-configuration()
        let $groupid := admin:group-get-id($config, "Default")
        return admin:appserver-get-root($config, admin:appserver-get-id($config, $groupid, admin:appserver-get-name($config, xdmp:server())))
    let $base-plugins-list := 
        for $plugin-dir in xdmp:filesystem-directory(fn:concat($base-dir, "/plugins"))/dir:entry/dir:filename/text()
            let $plugins :=
                if ($plugin-dir ne ".DS_Store" and $plugin-dir ne ".svn") 
                then 
                    (
                    $plugin-dir
                    )
                else ()
            return $plugins
    
    let $base-items :=
        for $item in $base-plugins-list
        let $item-xml :=    
            if(fn:doc(fn:concat("/plugins/", $item, "/config.xml")))
            then 
                (
                    <plugin name="{$item}" installed="true" installLocation="/{$item}/setup/index"/>
                )
            else
                (
                    <plugin name="{$item}" installed="false" installLocation="/{$item}/setup/index"/>
                )
        return $item-xml

    return  <plugins>
                {$base-items}
            </plugins>
};