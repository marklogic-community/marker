xquery version "1.0-ml";
import module namespace xqmvc = "http://scholarsportal.info/xqmvc/core" at "/system/xqmvc.xqy";
import module namespace taglib-library = "http://marklogic.com/marker/taglib/library" at "../taglibs/taglib-library.xqy";
declare namespace html = "http://www.w3.org/1999/xhtml";
declare variable $data as map:map external;
<div style="">
<!-- inject taglib here  e-->
<div style="width:250px;float:left;margin-right:5px;height:300px;">{taglib-library:directory-tree()}</div>
<div style="width:390px;float:left;">{taglib-library:directory-management()}</div>
</div>