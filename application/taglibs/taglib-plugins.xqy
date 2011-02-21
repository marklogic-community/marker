xquery version "1.0-ml";
module namespace taglib-plugins = "http://marklogic.com/xqmvc/taglib/plugins";
import module namespace plugins = "http://marklogic.com/xqmvc/plugins" at "/application/library/plugins.xqy";
declare namespace html = "http://www.w3.org/1999/xhtml";

declare function taglib-plugins:plugins-list()
{
   
   
        <li><span>Plugins</span>
            <ul>
            {
                for $plugin in plugins:getPlugins()//plugin
                let $plugin-info :=
                    if(fn:data($plugin/@installed) eq "true")
                    then
                        (
                            <li><img style="width:20px;" src="/application/resources/img/ready.png"/>{fn:data($plugin/@name)}</li>
                        )
                    else
                        (
                            <li><a href="{fn:data($plugin/@installLocation)}"><img style="width:20px;" src="/application/resources/img/install.png"/>{fn:data($plugin/@name)} (NOT INSTALLED)</a></li>
                        )
                return $plugin-info
            }
            </ul>
        </li>

};