xquery version "1.0-ml";


(:


 Copyright 2010 MarkLogic Corporation 

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
 
module namespace xqmvc-controller = "http://scholarsportal.info/xqmvc/controller";
import module namespace xqmvc = "http://scholarsportal.info/xqmvc/core" at "/system/xqmvc.xqy";
import module namespace cfg = "http://marklogic.com/plugins/marker/config" at "../config/config.xqy";
import module namespace role = "http://marklogic.com/plugins/security/role" at "/plugins/security/models/role-model.xqy";
import module namespace authorization = "http://marklogic.com/plugins/security/authorization" at "/plugins/security/models/authorization-model.xqy";
import module namespace dls="http://marklogic.com/xdmp/dls" at "/MarkLogic/dls.xqy"; 
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
import module namespace library = "http://marklogic.com/marker/library" at "../library/library.xqy";
import module namespace mem = "http://xqdev.com/in-mem-update" at "../library/in-mem-update.xqy";
declare namespace xi="http://www.w3.org/2001/XInclude";
declare namespace dir="http://marklogic.com/xdmp/directory";
declare namespace ml="http://developer.marklogic.com/site/internal";
import module namespace xqmvc-conf = "http://scholarsportal.info/xqmvc/config" at "/application/config/config.xqy";
declare namespace marker="http://marklogic.com/marker";
declare variable $uuid := "8b1c60f4-f4b0-2b8a-8d5a-c37194b3e3d6";
declare variable $uuid2 := "8b1c60f4-f4b0-2b8a-8d5a-c37194b3e3d5";

declare function index()
{
    let $_ := role:createRole("marker-admin", "Admin user role for marker")
    return xqmvc:template('master-template', (
            'browsertitle', 'marker Setup',
            'body', xqmvc:plugin-view($cfg:plugin-name,'setup-index-view', ())
        ))
};
declare function install()
{
    
      
    
    let $_ := role:addRoleToRole("marker-admin","dls-admin")
    let $_ := role:addRoleToRole("marker-admin","dls-internal")
    let $_ := role:addUserToRole(xdmp:get-current-user(), "marker-admin")       
   
    let $addRoles := authorization:addPrivileges("marker-admin", 
        ("http://marklogic.com/xdmp/privileges/xdmp-invoke",
         "http://marklogic.com/xdmp/privileges/xdmp-eval",
         "http://marklogic.com/xdmp/privileges/xdmp-login",
         "http://marklogic.com/xdmp/privileges/xdmp-eval-in",
         "http://marklogic.com/xdmp/privileges/create-user",
         "http://marklogic.com/xdmp/privileges/any-uri",     
         "http://marklogic.com/xdmp/privileges/any-collection",
         "http://marklogic.com/xdmp/privileges/grant-all-roles",
         "http://marklogic.com/xdmp/privileges/get-user-names",
         "http://marklogic.com/xdmp/privileges/xdmp-value",
         "http://marklogic.com/xdmp/privileges/admin-module-read",
         "http://marklogic.com/xdmp/privileges/admin-module-write",
         "http://marklogic.com/xdmp/privileges/get-role-names",
         "http://marklogic.com/xdmp/privileges/xdmp-eval-in",
         "http://marklogic.com/xdmp/privileges/dls-user",
         "http://marklogic.com/xdmp/privileges/xdmp-filesystem-directory",
         "http://marklogic.com/xdmp/privileges/xdmp-document-get",
         "http://marklogic.com/xdmp/privileges/get-user-names"))         
    
    let $allVersionsRuleExists := fn:data(dls:retention-rules("All Versions Retention Rule")/dls:name)
    let $versionsRule := 
            if("All Versions Retention Rule" = $allVersionsRuleExists) then 
                "Rule 'All Versions Retention Rule' already exists."
            else
                let $a := (
                    dls:retention-rule-insert( 
                        dls:retention-rule(
                            "All Versions Retention Rule",
                            "Retain all versions of all documents",
                            (),
                            (),
                            "Locate all of the documents",
                            cts:and-query(())
                        )
                    )
                )    
                let $b := "Created All Versions Retention Rule." 
                return ($b)  
    let $_ := xdmp:eval("
        xquery version '1.0-ml'; 
        import module namespace sec='http://marklogic.com/xdmp/security' at '/MarkLogic/security.xqy';
        
            try{sec:protect-collection('http://marklogic.com/marker/drafts', 
                (xdmp:permission('marker-admin', 'execute'), xdmp:permission('marker-admin', 'update'))
            )}catch($e){},
             try{sec:protect-collection('http://marklogic.com/marker/published', 
                (xdmp:permission('marker-admin', 'execute'), xdmp:permission('security-anon', 'read'), xdmp:permission('marker-admin', 'update'))
             )}catch($e){}
     
        ",  
        (),
        <options xmlns="xdmp:eval"><database>{xdmp:database("Security")}</database> </options>
    )  
    let $_ := xdmp:document-insert("/plugins/marker/config.xml",
        <marker_config>
            <install-completed>true</install-completed>
            <default-page>/index.html</default-page>
        </marker_config>,
            (xdmp:permission("security-anon", "read"), xdmp:permission("marker-admin", "update"))
    )
    let $_ := xdmp:document-insert("/plugins/security/controller-mapping/marker-admin.xml",
        <role-mappings>
            <mapping mapped="1" plugin="marker" controller="ajax" action="index">marker/ajax/index</mapping>
            <mapping mapped="1" plugin="marker" controller="ajax" action="list-documents">marker/ajax/list-documents</mapping>
            <mapping mapped="1" plugin="marker" controller="ajax" action="unmanage-document">marker/ajax/unmanage-document</mapping>
            <mapping mapped="1" plugin="marker" controller="ajax" action="manage-document">marker/ajax/manage-document</mapping>
            <mapping mapped="1" plugin="marker" controller="ajax" action="update-uri-content">marker/ajax/update-uri-content</mapping>
            <mapping mapped="1" plugin="marker" controller="ajax" action="checkout-status">marker/ajax/checkout-status</mapping>
            <mapping mapped="1" plugin="marker" controller="ajax" action="checkout">marker/ajax/checkout</mapping>
            <mapping mapped="1" plugin="marker" controller="ajax" action="checkin">marker/ajax/checkin</mapping>
            <mapping mapped="1" plugin="marker" controller="ajax" action="publish">marker/ajax/publish</mapping>
            <mapping mapped="1" plugin="marker" controller="ajax" action="unpublish">marker/ajax/unpublish</mapping>
            <mapping mapped="1" plugin="marker" controller="ajax" action="get-version-content">marker/ajax/get-version-content</mapping>
            <mapping mapped="1" plugin="marker" controller="ajax" action="get-uri-information">marker/ajax/get-uri-information</mapping>
            <mapping mapped="1" plugin="marker" controller="ajax" action="change-view-mode">marker/ajax/change-view-mode</mapping>
            <mapping mapped="1" plugin="marker" controller="library" action="list">marker/library/list</mapping>
            <mapping mapped="1" plugin="marker" controller="setup" action="index">marker/setup/index</mapping>
            <mapping mapped="1" plugin="marker" controller="setup" action="install">marker/setup/install</mapping>
            <mapping mapped="1" plugin="marker" controller="setup" action="install-data">marker/setup/install-data</mapping>
            <mapping mapped="1" plugin="marker" controller="setup" action="install-data-properties">marker/setup/install-data-properties</mapping>
            <mapping mapped="1" plugin="marker" controller="setup" action="install-data-publish">marker/setup/install-data-publish</mapping>
            <mapping mapped="1" plugin="marker" controller="render" action="index">marker/render/index</mapping>
        </role-mappings>,
            (xdmp:permission("security-anon", "read"), xdmp:permission("security-admin", "update"))
    )

   let $_ := xdmp:document-insert("/application/mapping.xml",
        <mappings>
            <mapping regex="^/(about|services|offices|links|insurance)*$" template="/template.xhtml">
                <params name="name" match="1"/>
            </mapping>
        </mappings>,
            (xdmp:permission("security-anon", "read"), xdmp:permission("security-admin", "update"), xdmp:permission("marker-admin", "update"))
    )

    let $config := admin:get-configuration()
    let $config := admin:database-set-uri-lexicon($config, 
            xdmp:database(), fn:true())
    let $_ := admin:save-configuration($config)
    (:reset cached roles:)
    let $_ := xdmp:set-session-field("roles",())
    let $_ := xdmp:set-session-field("init-redirect",())
    let $_ := xdmp:set-server-field("authorization:marker-admin", '')
    let $config := admin:get-configuration()
    let $config := admin:database-set-trailing-wildcard-searches($config, 
        xdmp:database(), fn:true())
    let $_ := admin:save-configuration($config)
    let $config := admin:get-configuration()
    let $config := admin:database-set-collection-lexicon($config, 
        xdmp:database(), fn:true())
    let $_ := admin:save-configuration($config)

    let $config := admin:get-configuration()  
    let $config  := admin:database-add-range-element-index($config, xdmp:database(),  admin:database-range-element-index("string", "http://marklogic.com/marker", "author", "http://marklogic.com/collation/", fn:false() ))
    let $config  := admin:database-add-range-element-index($config, xdmp:database(),  admin:database-range-element-index("string", "http://marklogic.com/marker", "type", "http://marklogic.com/collation/", fn:false() ))
    let $config  := admin:database-add-range-element-index($config, xdmp:database(),  admin:database-range-element-index("string", "http://marklogic.com/marker", "category", "http://marklogic.com/collation/", fn:false() ))
    let $config  := admin:database-add-range-element-index($config, xdmp:database(),  admin:database-range-element-index("string", "", "person", "http://marklogic.com/collation/", fn:false() ))
    let $config  := admin:database-add-range-element-index($config, xdmp:database(),  admin:database-range-element-index("string", "", "place", "http://marklogic.com/collation/", fn:false() ))
    let $config  := admin:database-add-range-element-index($config, xdmp:database(),  admin:database-range-element-index("string", "", "thing", "http://marklogic.com/collation/", fn:false() ))
    (:let $config  := admin:database-add-range-element-index($config, xdmp:database(),  admin:database-range-element-index("dateTime", "http://marklogic.com/marker", "create-date", "", fn:false() ))
    let $config  := admin:database-add-range-element-index($config, xdmp:database(),  admin:database-range-element-index("dateTime", "http://marklogic.com/marker", "update-date", "", fn:false() ))
    let $config  := admin:database-add-range-element-index($config, xdmp:database(),  admin:database-range-element-index("dateTime", "http://marklogic.com/marker", "publish-date", "", fn:false() )):)
    (:let $config  := admin:database-add-range-element-index($config, xdmp:database(),  admin:database-range-element-index("string", "http://marklogic.com/marker", "tag", "http://marklogic.com/collation/", fn:false() )):)
    let $config  := admin:database-add-range-element-index($config, xdmp:database(),  admin:database-range-element-index("string", "", "tag", "http://marklogic.com/collation/", fn:false() ))
    let $config  := admin:database-add-range-element-index($config, xdmp:database(),  admin:database-range-element-index("date", "", "date", "", fn:false() ))
    let $_ := admin:save-configuration($config)   
    return xqmvc:template('master-template', (
                'browsertitle', 'marker Setup Complete',
                'body', xqmvc:plugin-view($cfg:plugin-name,'setup-install-view', ())
            ))
    
};
declare function install-data()
{
    let $collection := "http://marklogic.com/marker/drafts"
    let $note := "insert from setup install"
    let $permissions := (xdmp:permission('marker-admin', 'update'), xdmp:permission('marker-admin', 'read')) 
    let $content-insert := 
        dls:document-insert-and-manage(
         "/content-root/containers/site-wide/fallback.container",
         fn:true(),
            (  
            <div>Sorry. This content could not be served
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Fallback Container</marker:title>
                    <marker:name>fallback</marker:name>
                    <marker:abstract>Container for missing container</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
            </div>
            ),
         $note,
         $permissions, 
         $collection)
    let $content-insert := 
        dls:document-insert-and-manage(
         "/content-root/containers/site-wide/login-logout.container",
         fn:true(),
            (  
            <div runtime="dynamic" style="position:absolute;top:61px;right:86px;width:150px;text-align:right;"> 
                <exec>
                xquery version "1.0-ml";
                import module namespace taglib-security = "http://marklogic.com/plugin/security/taglib" at "/plugins/security/taglibs/taglib-auth.xqy";
                taglib-security:login-logout()
                </exec>
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Login/Logout Container</marker:title>
                    <marker:name>login-logout</marker:name>
                    <marker:abstract>Container for authentication - dependent upon the security plugin</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
            </div>
            ),
         $note,
         $permissions, 
         $collection) 
    (: document is not under mgmt in transaction yet :)     
    (:let $publish := library:publishLatest("/content-root/containers/site-wide/fallback.container"):)
    let $content-insert := 
        dls:document-insert-and-manage(
        "/content-root/containers/site-wide/main-navigation.container",
         fn:true(),
         (  
         <div>
            <xi:include href="/content-root/containers/site-wide/search.container">
                <xi:fallback>
                      <xi:include href="/content-root/containers/site-wide/fallback.container">
                         <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                      </xi:include>
                  </xi:fallback> 
            </xi:include> 
            <ul id="nav" class="sf-menu sf-js-enabled sf-shadow">
                <!-- XXX Generate from the database and apply a css class based on selected one? -->
                <li id="m-about">    <a href="/">About Dr. Beddow</a></li>
                <li id="m-services"> <a href="/services">Services</a></li>
                <li id="m-offices">  <a href="/offices">Offices</a></li>
                <li id="m-links">    <a href="/links">Helpful Patient Links</a></li>
                <li id="m-insurance"><a href="/insurance">Insurance Information</a></li>
            </ul>
            <xi:include href="/content-root/containers/site-wide/login-logout.container">
              <xi:fallback>
                  <xi:include href="/content-root/containers/site-wide/fallback.container">
                     <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                  </xi:include>
              </xi:fallback> 
            </xi:include> 
            <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>Miscellaneous</marker:type> 
                <marker:title>Main Navigation Container</marker:title>
                <marker:name>main-navigation</marker:name>
                <marker:abstract>Main navigation container</marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:published-date></marker:published-date>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:authors>
                </marker:authors>
                <marker:categories>
                </marker:categories>
                <marker:tags>
                </marker:tags>
            </marker:content>
        </div>
         ),  
         $note,
         $permissions, 
         $collection)

    let $content-insert := 
        dls:document-insert-and-manage(
        "/content-root/containers/site-wide/pages.container",
         fn:true(),
         (  
         <div>
            <ul class="xoxo">
                <li id="pages-3" class="widget widget_panes">
                <h2 class="widgettitle">Pages</h2>
                <ul>
                <!-- XXX Generate from the database and apply a css class based on selected one? -->
                <li class="page_item" id="m-about">    <a href="/">About Dr. Beddow</a></li>
                <li class="page_item" id="m-services"> <a href="/services">Services</a></li>
                <li class="page_item" id="m-offices">  <a href="/offices">Offices</a></li>
                <li class="page_item" id="m-links">    <a href="/links">Helpful Patient Links</a></li>
                <li class="page_item" id="m-insurance"><a href="/insurance">Insurance Information</a></li>
                </ul></li>
            </ul>
            <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>Miscellaneous</marker:type> 
                <marker:title>Page Navigation Container</marker:title>
                <marker:name>page-navigation</marker:name>
                <marker:abstract>Page navigation container</marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:published-date></marker:published-date>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:authors>
                </marker:authors>
                <marker:categories>
                </marker:categories>
                <marker:tags>
                </marker:tags>
            </marker:content>
        </div>
         ),  
         $note,
         $permissions, 
         $collection)

     let $content-insert := 
        dls:document-insert-and-manage(
        "/content-root/containers/content.container",
         fn:true(),
         (  <div runtime="dynamic">
                <exec>
                import module namespace library = "http://marklogic.com/marker/library" at "/plugins/marker/library/library.xqy";
                declare namespace marker="http://marklogic.com/marker";
                declare variable $name external;
                let $name := if ($name) then $name else "about" (: home page is /about :)
                let $doc := library:stripMeta( library:doc(fn:concat("/content-root/containers/", $name, ".container"))/*)
                let $meta := library:marker-properties-bag(fn:concat("/content-root/containers/", $name, ".container"))
                return 
                    <div id="content">
                        <h2 class="page-title">{{$meta/marker:title/string()}}</h2>
                        <div class="page-content">{{$doc}}</div>
                        <script>document.title = 'Dr. Isabell Beddow - {{$meta/marker:title/string()}}'</script>
                        <script>$(document).ready(function() {{{{ $('#m-{{$name}}').addClass('current_page_item') }}}} )</script>
                    </div>
                </exec>
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Site Content</marker:title>
                    <marker:name>content</marker:name>
                    <marker:abstract></marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
            </div>
            ),  
         $note,
         $permissions, 
         $collection)
 let $content-insert := 
        dls:document-insert-and-manage(
        "/content-root/containers/about.container",
         fn:true(),
         (
         <div>
Dr. Beddow is a Board Certified Obstetrician/Gynecologist who has been practicing in the Bay Area for over a decade.    She was on faculty at Stanford until returning to private practice.  Born in Iowa City, Iowa, Dr. Beddow attended Bryn Mawr College in Pennsylvania where she studied mathematics.  She then returned to the University of Iowa College of Medicine and completed an intensive residency training at the University of Wisconsin in Madison. <img style="border-width: 0px; padding-left: 10px; float: right;" src="http://drbeddow.com/images/beddow-twins.jpg" alt="Dr Beddow" />

<div><br/></div>

Dr. Beddow is a mother to three young children and has a special bond with twin mothers as she is one herself. She enjoys taking care of women at all ages of life, from first pap smears to menopausal issues.  She is especially fond of helping women along with the new joy of motherhood. As a mother, she will provide you with a personal perspective on pregnancy, labor and delivery.  As an experienced physician she will help you to navigate through pregnancy and delivery with an understanding of the choices that you make along the way.

<div><br/></div>

In addition to caring  for pregnant women and their families, Dr. Beddow also treats women for generalized primary care and gynecologic issues, infertility, irregular bleeding, post-menopausal issues and annual pap smears.   She is trained in laparoscopy, hysteroscopy and micro-invasive surgery, and looks forward to helping you with all of your ob/gyn needs.
         <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>Page</marker:type> 
                <marker:title>About Dr. Beddow</marker:title>
                <marker:name>about</marker:name>
                <marker:abstract>About Dr. Beddow</marker:abstract>
                <marker:searchable>true</marker:searchable>
                <marker:published-date></marker:published-date>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:authors>
                </marker:authors>
                <marker:categories>
                </marker:categories>
                <marker:tags>
                </marker:tags>
            </marker:content>
            </div>
         ),  
         $note,
         $permissions, 
         $collection)

 let $content-insert := 
        dls:document-insert-and-manage(
        "/content-root/containers/offices.container",
         fn:true(),
         (
         <div>
<h3>San Mateo</h3>
1 Baywood Avenue, Suite 5
San Mateo, CA 94402
(650) 558 0611
Fax (650) 558 0613
<div style="float: left;">
<a style="float: right;" href="http://maps.google.com/maps?f=q&amp;source=s_q&amp;hl=en&amp;geocode=&amp;view=map&amp;q=1+Baywood+Avenue+Suite+5,+San+Mateo,+Ca+94402&amp;sll=37.56494,-122.328258&amp;sspn=0.009797,0.025406&amp;ie=UTF8&amp;hq=&amp;hnear=1+Baywood+Ave+Suite+5,+San+Mateo,+California+94402&amp;ll=37.5671,-122.327142&amp;spn=0.005953,0.00912&amp;z=16" target="_blank">Larger map</a>
</div>
         <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>Page</marker:type> 
                <marker:title>Offices</marker:title>
                <marker:name>offices</marker:name>
                <marker:abstract>Offices</marker:abstract>
                <marker:searchable>true</marker:searchable>
                <marker:published-date></marker:published-date>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:authors>
                </marker:authors>
                <marker:categories>
                </marker:categories>
                <marker:tags>
                </marker:tags>
            </marker:content>
            </div>
         ),  
         $note,
         $permissions, 
         $collection)
 let $content-insert := 
        dls:document-insert-and-manage(
        "/content-root/containers/services.container",
         fn:true(),
         (
         <div>
<h3>Obstetrics</h3>
<ul>
    <li>Early testing and ultrasound for every pregnancy.</li>
    <li>Experienced, compassionate care</li>
    <li>Friendly nurse and office staff</li>
    <li>High and low-risk pregnancy management</li>
    <li><em>Natural</em> or un-medicated childbirth support</li>
    <li>Elective cesarean section available</li>
    <li>Lactation support after delivery</li>
</ul>
<h3>Gynecology</h3>
<ul>
    <li>Annual well women exams</li>
    <li>Pre-conceptual counseling</li>
    <li>Contraceptive counseling</li>
    <li>Abnormal periods (bleeding)</li>
    <li>Pelvic pain</li>
    <li>Infertility evaluation and treatment</li>
    <li>Vaginal discharge</li>
    <li>Pap smear screening and abnormal pap smear treatment</li>
    <li>HPV and STD testing</li>
    <li>Fibroids</li>
    <li>Menopause and hormone evaluation</li>
    <li>Ovarian cysts and treatment</li>
    <li>Endometriosis</li>
    <li>Vaginal restructuring after childbirth</li>
</ul>
         <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>Page</marker:type> 
                <marker:title>Services</marker:title>
                <marker:name>services</marker:name>
                <marker:abstract>Services</marker:abstract>
                <marker:searchable>true</marker:searchable>
                <marker:published-date></marker:published-date>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:authors>
                </marker:authors>
                <marker:categories>
                </marker:categories>
                <marker:tags>
                </marker:tags>
            </marker:content>
            </div>
         ),  
         $note,
         $permissions, 
         $collection)
 let $content-insert := 
        dls:document-insert-and-manage(
        "/content-root/containers/links.container",
         fn:true(),
         (
         <div>
<ul>
    <li><strong>Up To Date for patients</strong>: UpToDate is an online medical information resource where patients can go to learn about a medical condition, better understand management and treatment options, and find information to have a better dialogue with their health care providers. UpToDate provides in-depth, authoritative medical information, including recommendations based on the latest published evidence. Patients can view hundreds of free patient-level topics or subscribe to gain access to thousands of physician-level topics.UpToDate is the trusted resource of physicians around the world and is used by the majority of academic medical centers in the US. Visit them at <a href="http://www.uptodate.com/patients">http://www.uptodate.com/patients</a></li>
    <li><strong>FORE </strong>is the Foundation for Osteoporosis Research and Education, A national non-profit voluntary health organization dedicated to preventing osteoporosis through research and education of the public and medical community to increase osteoporosis awareness of risk, detection, prevention and treatment.  <a href="http://www.fore.org">http://www.fore.org</a></li>
    <li><strong>The March of Dimes </strong>provides pregnancy information, pre-conception suggestions, and an interactive game designed to learn about pregnancy.    See <a href="http://www.marchofdimes.com">http://www.marchofdimes.com</a></li>
    <li><strong>Le Leche League</strong> is an international organization that supports mothering through breastfeeding,by promoting breastfeeding awareness and information.  See <a href="http://www.lll.org">http://www.lll.org</a></li>
    <li><strong>American College of Obstetricians and Gynecologists </strong>official web site provides a physician directory, health columns, courses and more.   See <a href="http://www.acog.org/publications/patient_education/">http://www.acog.org/publications/patient_education/</a></li>
    <li><strong>Women’s Cancer Network</strong> developed by the Gynecologic Cancer Foundation for women and their families.  See <a href="http://www.wcn.org">http://www.wcn.org</a></li>
    <li>The <strong>American Cancer Society</strong>’s official webpage at <a href="http://www.cancer.org">http://www.cancer.org</a></li>
    <li><strong>American Heart Association </strong>gives women of all ages the facts on women's heart disease and stroke See <a href="http://women.americanheart.org/" target="_blank">http://women.americanheart.org</a></li>
    <li><strong>National Osteoporosis Foundation is the </strong>leading resource for up-to-date, medically sound information on the causes, prevention, detection and treatment of osteoporosis. See <a href="http://www.nof.org/" target="_blank">http://www.nof.org</a></li>
    <li><strong>The North American Menopause Society.  "</strong>NAMS” is a nonprofit organization that provides a forum for a multitude of scientific disciplines with an interest in the human female menopause. See <a href="http://www.menopause.org/" target="_blank">http://www.menopause.org</a></li>
    <li> <strong>Menopause and therapy for menopausal symptoms </strong>presented by Wyeth, women and physicians talking about menopause.  See <a href="http://www.knowmenopause.com/" target="_blank">http://www.knowmenopause.com</a></li>
    <li> <strong>Nutrition information </strong>from U.S. Department of Agriculture.  Design your food pyramid at <a href="http://mypyramid.com/" target="_blank">http://www.mypyramid.com</a></li>
    <li>Learn about <strong>sexually transmitted disease,</strong> from the American Social Health Association at  <a href="http://www.ashastd.org/" target="_blank">http://ww.ashastd.org</a></li>
    <li><strong>Emergency contraception -</strong> what to do if you have unprotected intercourse and do not want to become pregnant.  See <a href="http://www.go2planb.com/" target="_blank">http://www.go2planb.com</a></li>
    <li> <strong>Prevent pregnancy after sex</strong>, from the Office of Population Research at Princeton University &amp; Association of Reproductive Health Professionals.  See <a href="http://ec.princeton.edu/" target="_blank">http://ec.princeton.edu</a></li>
    <li>Other helpful links:
<ul>
    <li><a href="http://www.cdc.gov/">http://www.cdc.gov/</a></li>
    <li><a href="http://www.cdc.gov/"></a><a href="http://www.healthywomen.org/">http://www.healthywomen.org/</a></li>
    <li><a href="http://www.twshf.org/">http://www.twshf.org/</a></li>
    <li><a href="http://www.aasect.org/">http://www.aasect.org/</a></li>
</ul>
</li>
</ul>
         <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>Page</marker:type> 
                <marker:title>Helpful Patient Links</marker:title>
                <marker:name>links</marker:name>
                <marker:abstract>Helpful Patient Links</marker:abstract>
                <marker:searchable>true</marker:searchable>
                <marker:published-date></marker:published-date>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:authors>
                </marker:authors>
                <marker:categories>
                </marker:categories>
                <marker:tags>
                </marker:tags>
            </marker:content>
            </div>
         ),  
         $note,
         $permissions, 
         $collection)
 let $content-insert := 
        dls:document-insert-and-manage(
        "/content-root/containers/insurance.container",
         fn:true(),
         (
         <div>
Dr Beddow accepts the following PPO insurance plans
<ul>
    <li>Aetna</li>
    <li>Blue Cross/Anthem</li>
    <li>Blue Shield</li>
    <li>Cigna</li>
    <li>Coventry</li>
    <li>Great West</li>
    <li>Health Net</li>
    <li>Humana</li>
    <li>Integrated</li>
    <li>PHCS</li>
    <li>United Healthcare</li>
</ul>

Dr Beddow does not currently accept any HMO plans.
         <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>Page</marker:type> 
                <marker:title>Insurance Information</marker:title>
                <marker:name>insurance</marker:name>
                <marker:abstract>Insurance Information</marker:abstract>
                <marker:searchable>true</marker:searchable>
                <marker:published-date></marker:published-date>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:authors>
                </marker:authors>
                <marker:categories>
                </marker:categories>
                <marker:tags>
                </marker:tags>
            </marker:content>
            </div>
         ),  
         $note,
         $permissions, 
         $collection)

    let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/containers/site-wide/search.container",
         fn:true(),
         (<div style="position: absolute; top: 3px; left: 10px;" >   
                <form action="/search" method="get">
                    <fieldset style="border: 0" >
                        <legend><label style="position: static" for="q">Search</label></legend>
                    <input type="hidden" id="start" name="start" value="1"/>
                    <input type="text" value=" Search the site" id="q" name="q" class="default" onblur="if (this.value == '')this.value = ' Search the site';" onfocus="if (this.value == ' Search the site')this.value = '';"/>
                    </fieldset>
                </form>
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Search Form Container</marker:title>
                    <marker:name>search</marker:name>
                    <marker:abstract>Input form for search</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
            </div>
            
            ),
         $note,
         $permissions, 
         $collection)   
    let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/containers/site-wide/search-results.container",
         fn:true(),
         (  
         <div runtime="dynamic">
                <exec>
                xquery version "1.0-ml";
                import module namespace library = "http://marklogic.com/marker/library" at "/plugins/marker/library/library.xqy";
                import module namespace dls="http://marklogic.com/xdmp/dls" at "/MarkLogic/dls.xqy";  
                import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
                declare namespace xi="http://www.w3.org/2001/XInclude";
                declare namespace marker="http://marklogic.com/marker";
                
                declare variable $options :=
                <options xmlns="http://marklogic.com/appservices/search">
                    <additional-query>
                        {
                        cts:and-query
                        (
                            (
                            cts:collection-query
                            (
                                ("http://marklogic.com/marker/published")
                            ),
                            cts:collection-query
                            (
                                ("http://marklogic.com/marker/searchable")
                            )
                            )
                        )
                        }
                  </additional-query>
                  <constraint name="Category">
                    <range type="xs:string" collation="http://marklogic.com/collation/">
                     <element ns="http://marklogic.com/marker" name="type"/>
                     
                    </range>
                  </constraint> 
                  <constraint name="Author">
                    <range type="xs:string" collation="http://marklogic.com/collation/">
                     <element ns="http://marklogic.com/marker" name="author"/>
                     
                    </range>
                  </constraint>
                  <constraint name="Tags">
                    <range type="xs:string" collation="http://marklogic.com/collation/">
                     <element ns="" name="tag"/>
                     
                    </range>
                  </constraint> 
                  <constraint name="Person">
                    <range type="xs:string" collation="http://marklogic.com/collation/">
                     <element ns="" name="person"/>
                     
                    </range>
                  </constraint> 
                  <constraint name="Place">
                    <range type="xs:string" collation="http://marklogic.com/collation/">
                     <element ns="" name="place"/>
                     
                    </range>
                  </constraint> 
                  <constraint name="Things">
                    <range type="xs:string" collation="http://marklogic.com/collation/">
                     <element ns="" name="thing"/>
                     
                    </range>
                  </constraint> 
                </options>;
                declare function local:pagination($results)
                {{
                    let $start := xs:unsignedLong($results/@start)
                    let $length := xs:unsignedLong($results/@page-length)
                    let $total := xs:unsignedLong($results/@total)
                    let $last := xs:unsignedLong($start + $length -1)
                    let $end := if ($total gt $last) then $last else $total
                    let $qtext := $results/search:qtext[1]/text()
                    let $next := if ($total gt $last) then $last + 1 else ()
                    let $previous := if (($start gt 1) and ($start - $length gt 0)) then fn:max((($start - $length),1)) else ()
                    let $next-href := 
                         if ($next) 
                         then fn:concat("/search?q=",if ($qtext) then fn:encode-for-uri($qtext) else (),"&amp;start=",$next)
                         else ()
                    let $previous-href := 
                         if ($previous)
                         then fn:concat("/search?q=",if ($qtext) then fn:encode-for-uri($qtext) else (),"&amp;start=",$previous)
                         else ()
                    let $total-pages := fn:ceiling($total div $length)
                    let $currpage := fn:ceiling($start div $length)
                    let $pagemin := 
                        fn:min(for $i in (1 to 4)
                        where ($currpage - $i) gt 0
                        return $currpage - $i)
                    let $rangestart := fn:max(($pagemin, 1))
                    let $rangeend := fn:min(($total-pages,$rangestart + 4))
                    
                    return (
                        <div class="page-status"><b>{{$start}}</b> to <b>{{$end}}</b> of {{$total}}</div>,
                        if($rangestart eq $rangeend)
                        then ()
                        else
                            <ul class="pagination"> 
                               {{ if ($previous) then <li class="previous"><a href="{{$previous-href}}" >Previous</a></li> else () }}
                               {{
                                 for $i in ($rangestart to $rangeend)
                                 let $page-start := (($length * $i) + 1) - $length
                                 let $page-href := concat("/search?q=",if ($qtext) then encode-for-uri($qtext) else (),"&amp;start=",$page-start)
                                 return 
                                    if ($i eq $currpage) 
                                    then <li class="active">{{$i}}</li>
                                    else <li><a href="{{$page-href}}">{{$i}}</a></li>
                                }}
                               {{ if ($next) then <li class="next"><a href="{{$next-href}}">Next</a></li> else ()}}
                            </ul>
                    )
                }};
                declare variable $q external;
                declare variable $start external;
                
                let $results := search:search($q, $options, xs:unsignedLong($start))
                let $total := data($results/@total)
                let $items :=
                    for $result in $results//search:result
                    let $base-uri := doc(data($result/@uri))/property::dls:version/dls:document-uri/text()
                    let $base-doc := doc(data($result/@uri))/*/marker:content
                    let $title := 
                        if($base-doc/marker:title/text())
                        then ($base-doc/marker:title/text())
                        else (fn:concat("&amp;","nbsp;"))
                    let $type := $base-doc/marker:type/text()
                    let $item := 
                        if($type eq 'Page')
                        then 
                            (
                            <div class="result">
                                <a href="{{fn:concat($base-doc/*/marker:realized-path/text(),fn:replace($base-doc/marker:name/text(), ' ' , '_'))}}">{{$title}}</a>
                                <p>
                                    {{
                                      for $snip in $result//search:match/node()
                                                 return
                                                        if (fn:node-name($snip) eq xs:QName("search:highlight"))
                                                        then <b>{{$snip/text()}}</b>
                                                        else $snip   
                                    }}
                                </p>
                            </div>
                            )
                        else if($type eq 'Miscellaneous')
                        then 
                            (
                            let $link-search := cts:search
                                                    (
                                                        fn:doc(), 
                                                        cts:and-query
                                                        (
                                                            (
                                                            cts:collection-query(("http://marklogic.com/marker/published")),
                                                            cts:element-attribute-value-query
                                                                (
                                                                xs:QName("xi:include"), 
                                                                xs:QName("href"), 
                                                                $base-uri
                                                                )
                                                            )
                                                        )
                                                    )/property::dls:version/dls:document-uri/text()
                            let $links :=
                                
                                for $found-item in $link-search
                                let $properties := library:doc($found-item)/*/marker:content
                                return
                                    <div class="result">
                                        <a href="/{{fn:replace(fn:replace(fn:replace($found-item, '/content-root/site/', ''), '/template.xhtml', ''), 'template.xhtml', '')}}">{{$properties/marker:title/text()}}</a>
                                        <p>
                                            {{
                                                 for $snip in $result//search:match/node()
                                                 return
                                                        if (fn:node-name($snip) eq xs:QName("search:highlight"))
                                                        then <b>{{$snip/text()}}</b>
                                                        else $snip                                                                                                                                                                               
                                       
                                            }}
                                        </p>
                                    </div>
                                    
                            return $links
                                
                            )
                        else () 
                    return $item
                let $facets :=  
                    for $facet in $results/search:facet
                    let $facet-count := fn:count($facet/search:facet-value)
                    let $facet-name := fn:data($facet/@name)
                    return
                        if($facet-count gt 0)
                        then 
                                <ul>
                                {{
                                    let $facet-items :=
                                        for $val in $facet/search:facet-value
                                        let $print := if($val/text()) then $val/text() else "Unknown"
                                        let $qtext := ($results/search:qtext)
                                        let $this :=
                                            if (fn:matches($val/@name/string(),"\W"))
                                            then fn:concat('"',$val/@name/string(),'"')
                                            else if ($val/@name eq "") then '""'
                                            else $val/@name/string()
                                        let $this := fn:concat($facet/@name,':',$this)
                                        let $selected := fn:matches($qtext,$this,"i")
                                        let $icon := 
                                            if($selected)
                                            then <img src="/application/resources/img/checkmark.gif"/>
                                            else <img src="/application/resources/img/checkblank.gif"/>
                                        let $link := 
                                            if($selected)
                                            then search:remove-constraint($qtext,$this,$options)
                                            else if(fn:string-length($qtext) gt 0)
                                            then fn:concat("(",$qtext,")"," AND ",$this)
                                            else $this
                                        
                                        let $link := fn:concat(fn:encode-for-uri($link), "&amp;start=1")
                                        return
                                            <li>{{$icon}}<a href="search?q={{$link}}">{{fn:lower-case($print)}}</a> [{{fn:data($val/@count)}}]</li>
                                    return (
                                                <li>
                                                    <span>{{$facet-name}}</span>
                                                    <ul>{{$facet-items[1 to 10]}}</ul>
                                                </li>  
                                            )
                                }}          
                                </ul> 
                         else ()

                return
                    <div>
                        <div id="content">
                            <h2 class="page-title">Search Results</h2>
                        
                            <div class="page-content results">
                            {{if($items) then ($items) else (fn:concat("Sorry, nothing found for your search on '", $q, "'."))}}
                            </div>
                            <div class="pagination-container">
                                 {{local:pagination($results)}}
                            </div>
                        </div>
                        <div id="sidebar">
                            <div class="sidebar-top">&#160; </div>
                            <ul class="xoxo"> 
                                <li> <h2 class="widgettitle">Filters</h2>
                                {{$facets}}
                                </li> 
                            </ul>
                            <div class="sidebar-bottom">&#160; </div>
                        </div>
                    </div>
                </exec>
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Search Results Container</marker:title>
                    <marker:name>search-results</marker:name>
                    <marker:abstract>Search results - includes results, paging and facets</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
            </div>
            ),
         $note,
         $permissions, 
         $collection)   
    let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/containers/site-wide/footer-navigation.container",
         fn:true(),
         (  <div>
                <p>Copyright © 2010 Dr. Isabell Beddow.  All Right Reserved.</p>
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Footer Container</marker:title>
                    <marker:name>footer-navigation</marker:name>
                    <marker:abstract>Footer navigation container</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
            </div>
            ),
         $note,
         $permissions, 
         $collection)

    let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/site/template.xhtml",
         fn:true(),
         (  
         <html>
            <head>
                <link rel="shortcut icon" type="image/vnd.microsoft.icon" href="http://drbeddow.com/wp-content/themes/thistle/favicon.ico" />
                <link rel="stylesheet" type="text/css" media="screen" href="/application/resources/css/style.css"/>
            </head>
            <body>
                <div id="wrap">
                    <div id="container">
                        <div id="header" style="position:relative;">
                            <h1 id="blog-title"><a href="/" rel="home">Dr. Isabell Beddow</a></h1>
                            <p id="blog-desc"><span>Obstetrics &amp; Gynecology</span></p>
                            <div id="navigation">
                              <xi:include href="/content-root/containers/site-wide/main-navigation.container">
                               <xi:fallback>
                                <xi:include href="/content-root/containers/site-wide/fallback.container">
                                    <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                </xi:include>
                               </xi:fallback> 
                              </xi:include>  
                           </div>
                       </div>
                    </div>
                    <div id="col-wrap">
                        <xi:include href="/content-root/containers/content.container">
                            <xi:fallback>
                                <xi:include href="/content-root/containers/site-wide/fallback.container">
                                    <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                </xi:include>
                            </xi:fallback> 
                        </xi:include> 

                        <div id="sidebar">
                            <div class="sidebar-top">&#160; </div>
                            <xi:include href="/content-root/containers/site-wide/pages.container">
                                <xi:fallback>
                                    <xi:include href="/content-root/containers/site-wide/fallback.container">
                                        <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                    </xi:include>
                                </xi:fallback> 
                            </xi:include> 
                            <div class="sidebar-bottom">&#160; </div>
                        </div>
                    </div>
                    <div id="footer">
                        <xi:include href="/content-root/containers/site-wide/footer-navigation.container">
                            <xi:fallback>
                                <xi:include href="/content-root/containers/site-wide/fallback.container">
                                    <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                </xi:include>
                            </xi:fallback> 
                        </xi:include> 
                    </div>
                </div>
            </body>
            <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>template</marker:type> 
                <marker:title>Home</marker:title>
                <marker:name>template</marker:name>
                <marker:abstract>Home template</marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:base-id>{$uuid}</marker:base-id>
                <marker:derived>true</marker:derived>
            </marker:content>
        </html>  
            ),
         $note,
         $permissions, 
         $collection)     

 let $content-insert :=
        dls:document-insert-and-manage(
         "/content-root/site/search/template.xhtml",
         fn:true(),
         (  
         <html>
            <head>
                <link rel="shortcut icon" type="image/vnd.microsoft.icon" href="http://drbeddow.com/wp-content/themes/thistle/favicon.ico" />
                <link rel="stylesheet" type="text/css" media="screen" href="/application/resources/css/style.css"/>
            </head>
            <body>
                <div id="wrap">
                    <div id="container">
                        <div id="header" style="position:relative;">
                            <h1 id="blog-title"><a href="/" rel="home">Dr. Isabell Beddow</a></h1>
                            <p id="blog-desc"><span>Obstetrics &amp; Gynecology</span></p>
                            <div id="navigation">
                              <xi:include href="/content-root/containers/site-wide/main-navigation.container">
                               <xi:fallback>
                                <xi:include href="/content-root/containers/site-wide/fallback.container">
                                    <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                </xi:include>
                               </xi:fallback> 
                              </xi:include>  
                           </div>
                       </div>
                    </div>
                    <div id="col-wrap">
                        <xi:include href="/content-root/containers/site-wide/search-results.container">
                            <xi:fallback>
                                <xi:include href="/content-root/containers/site-wide/fallback.container">
                                    <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                </xi:include>
                            </xi:fallback> 
                        </xi:include> 
                    </div>
                    <div id="footer">
                        <xi:include href="/content-root/containers/site-wide/footer-navigation.container">
                            <xi:fallback>
                                <xi:include href="/content-root/containers/site-wide/fallback.container">
                                    <xi:fallback><p>NOT FOUND</p></xi:fallback> 
                                </xi:include>
                            </xi:fallback> 
                        </xi:include> 
                    </div>
                </div>
            </body>
             <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>template</marker:type> 
                <marker:title>Search</marker:title>
                <marker:name>template</marker:name>
                <marker:abstract>Derived Search template </marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:base-id>{$uuid2}</marker:base-id>
                <marker:derived>true</marker:derived>
            </marker:content>
        </html>  
            ),
         $note,
         $permissions, 
         $collection) 
let $log := if ($xqmvc-conf:debug) then xdmp:log("Completed base data insert") else ()

    return xdmp:redirect-response("/marker/setup/install-data-properties")                                                          
     
};

declare function install-data-properties()
{
    let $log := if ($xqmvc-conf:debug) then xdmp:log("Starting properties update") else ()
    let $base-dir :=
        let $config := admin:get-configuration()
        let $groupid := admin:group-get-id($config, "Default")
        return admin:appserver-get-root($config, admin:appserver-get-id($config, $groupid, admin:appserver-get-name($config, xdmp:server())))
    
     let $default-container :=<marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>Miscellaneous</marker:type> 
                <marker:title>Content</marker:title>
                <marker:name>content</marker:name>
                <marker:abstract>Content</marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:published-date></marker:published-date>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:authors>
                </marker:authors>
                <marker:categories>
                </marker:categories>
                <marker:tags>
                </marker:tags>
            </marker:content>
    let $_ := dls:document-set-properties('/content-root/containers/content.container', ($default-container))

     let $default-container :=<marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>Miscellaneous</marker:type> 
                <marker:title>About Dr. Beddow</marker:title>
                <marker:name>about</marker:name>
                <marker:abstract>About Dr. Beddow</marker:abstract>
                <marker:searchable>true</marker:searchable>
                <marker:published-date></marker:published-date>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:authors>
                </marker:authors>
                <marker:categories>
                </marker:categories>
                <marker:tags>
                </marker:tags>
            </marker:content>
    let $_ := dls:document-set-properties('/content-root/containers/about.container', ($default-container))

     let $default-container :=<marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>Miscellaneous</marker:type> 
                <marker:title>Services</marker:title>
                <marker:name>services</marker:name>
                <marker:abstract>Services</marker:abstract>
                <marker:searchable>true</marker:searchable>
                <marker:published-date></marker:published-date>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:authors>
                </marker:authors>
                <marker:categories>
                </marker:categories>
                <marker:tags>
                </marker:tags>
            </marker:content>
    let $_ := dls:document-set-properties('/content-root/containers/services.container', ($default-container))

     let $default-container :=<marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>Miscellaneous</marker:type> 
                <marker:title>Offices</marker:title>
                <marker:name>offices</marker:name>
                <marker:abstract>Offices</marker:abstract>
                <marker:searchable>true</marker:searchable>
                <marker:published-date></marker:published-date>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:authors>
                </marker:authors>
                <marker:categories>
                </marker:categories>
                <marker:tags>
                </marker:tags>
            </marker:content>
    let $_ := dls:document-set-properties('/content-root/containers/offices.container', ($default-container))

     let $default-container :=<marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>Miscellaneous</marker:type> 
                <marker:title>Helpful Patient Links</marker:title>
                <marker:name>links</marker:name>
                <marker:abstract>Helpful Patient Links</marker:abstract>
                <marker:searchable>true</marker:searchable>
                <marker:published-date></marker:published-date>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:authors>
                </marker:authors>
                <marker:categories>
                </marker:categories>
                <marker:tags>
                </marker:tags>
            </marker:content>
    let $_ := dls:document-set-properties('/content-root/containers/links.container', ($default-container))

     let $default-container :=<marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>Page</marker:type> 
                <marker:title>Insurance Information</marker:title>
                <marker:name>insurance</marker:name>
                <marker:abstract>Insurance Information</marker:abstract>
                <marker:searchable>true</marker:searchable>
                <marker:published-date></marker:published-date>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:authors>
                </marker:authors>
                <marker:categories>
                </marker:categories>
                <marker:tags>
                </marker:tags>
            </marker:content>
    let $_ := dls:document-set-properties('/content-root/containers/insurance.container', ($default-container))

    let $log := if ($xqmvc-conf:debug) then xdmp:log("Setting general content properties") else ()
    let $default-container :=
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Content</marker:type> 
                    <marker:title>Fallback Container</marker:title>
                    <marker:name>fallback</marker:name>
                    <marker:abstract>Container for missing container</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
    let $_ := dls:document-set-properties('/content-root/containers/site-wide/fallback.container', ($default-container))
    let $default-container :=
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Login/Logout Container</marker:title>
                    <marker:name>login-logout</marker:name>
                    <marker:abstract>Container for authentication - dependent upon the security plugin</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
    let $_ := dls:document-set-properties('/content-root/containers/site-wide/login-logout.container', ($default-container))
    let $default-container :=
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Footer Container</marker:title>
                    <marker:name>footer-navigation</marker:name>
                    <marker:abstract>Footer navigation container</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
    let $_ := dls:document-set-properties("/content-root/containers/site-wide/footer-navigation.container",($default-container))
    let $default-container :=
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Search Form Container</marker:title>
                    <marker:name>search</marker:name>
                    <marker:abstract>Input form for search</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
    let $_ := dls:document-set-properties("/content-root/containers/site-wide/search.container",($default-container))
    let $default-container :=
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Search Results Container</marker:title>
                    <marker:name>search-results</marker:name>
                    <marker:abstract>Search results - includes results, paging and facets</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
    let $_ := dls:document-set-properties("/content-root/containers/site-wide/search-results.container",($default-container))
    let $default-container :=
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Main Navigation Container</marker:title>
                    <marker:name>main-navigation</marker:name>
                    <marker:abstract>Main navigation container</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
    let $_ := dls:document-set-properties("/content-root/containers/site-wide/main-navigation.container", ($default-container))
    let $default-container :=
                <marker:content xmlns:marker="http://marklogic.com/marker">
                    <marker:type>Miscellaneous</marker:type> 
                    <marker:title>Page Navigation Container</marker:title>
                    <marker:name>page-navigation</marker:name>
                    <marker:abstract>Page navigation container</marker:abstract>
                    <marker:searchable>false</marker:searchable>
                    <marker:published-date></marker:published-date>
                    <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                    <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                    <marker:authors>
                    </marker:authors>
                    <marker:categories>
                    </marker:categories>
                    <marker:tags>
                    </marker:tags>
                </marker:content>
    let $_ := dls:document-set-properties("/content-root/containers/site-wide/pages.container", ($default-container))
    let $default-template :=
                 <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>template</marker:type> 
                <marker:title>Home</marker:title>
                <marker:name>template</marker:name>
                <marker:abstract>Site template </marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:base-id>{$uuid}</marker:base-id>
                <marker:derived>true</marker:derived>
            </marker:content>
    let $_ := dls:document-set-properties("/content-root/site/template.xhtml", ($default-template))
    let $default-template :=
                 <marker:content xmlns:marker="http://marklogic.com/marker">
                <marker:type>template</marker:type> 
                <marker:title>Search</marker:title>
                <marker:name>template</marker:name>
                <marker:abstract>Derived Search template </marker:abstract>
                <marker:searchable>false</marker:searchable>
                <marker:create-date>{fn:current-dateTime()}</marker:create-date>
                <marker:update-date>{fn:current-dateTime()}</marker:update-date>
                <marker:base-id>{$uuid}</marker:base-id>
                <marker:derived>true</marker:derived>
            </marker:content>
    let $_ := dls:document-set-properties("/content-root/site/search/template.xhtml", ($default-template))
    
    let $log := if ($xqmvc-conf:debug) then xdmp:log("Completed base properties insert") else ()
    return xdmp:redirect-response("/marker/setup/install-data-publish")  
};
declare function install-data-publish()
{
    let $log := if ($xqmvc-conf:debug) then xdmp:log("Publishing latest version of main content") else ()
    let $publish := library:publishLatest("/content-root/containers/site-wide/fallback.container")
    let $publish := library:publishLatest("/content-root/containers/site-wide/footer-navigation.container")
    let $publish := library:publishLatest("/content-root/containers/site-wide/search.container")
    let $publish := library:publishLatest("/content-root/containers/site-wide/search-results.container")
    let $publish := library:publishLatest("/content-root/containers/site-wide/main-navigation.container")
    let $publish := library:publishLatest("/content-root/containers/site-wide/pages.container")
    let $publish := library:publishLatest("/content-root/containers/site-wide/login-logout.container")

    let $publish := library:publishLatest("/content-root/site/template.xhtml")
    let $publish := library:publishLatest("/content-root/site/search/template.xhtml")

    let $publish := library:publishLatest("/content-root/containers/content.container")

    let $publish := library:publishLatest("/content-root/containers/about.container")
    let $publish := library:publishLatest("/content-root/containers/offices.container")
    let $publish := library:publishLatest("/content-root/containers/services.container")
    let $publish := library:publishLatest("/content-root/containers/links.container")
    let $publish := library:publishLatest("/content-root/containers/insurance.container")

    let $log := if ($xqmvc-conf:debug) then xdmp:log("Publishing complete") else ()
    return xqmvc:template('master-template', (
                'browsertitle', 'marker Data Install Complete',
                'body', xqmvc:plugin-view($cfg:plugin-name,'setup-install-data-view', ())
            )) 
};
