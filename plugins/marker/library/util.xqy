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
module namespace util = "http://marklogic.com/marker/util";

(:~
 : Retrieves a named cookie from the request headers.
 :
 : @param $name the name of the cookie
 :
 : @return a sequence containing the values for the given cookie name.
 : If no cookies of that name were found, the empty sequence is returned.
 :
 :)
declare function util:getCookie($name as xs:string) as xs:string* {
 let $urlname := xdmp:url-encode($name)
 let $header := fn:string-join(xdmp:get-request-header("Cookie"), ";")
 let $cookies := fn:tokenize($header, "; ?")[fn:starts-with(., fn:concat($urlname, "="))]
 for $c in $cookies
 return xdmp:url-decode(fn:substring-after($c, "="))
};


(:~
 : Utility function for making a deep copy
 : TODO - move to some util type place
 :)
declare function util:copy($element as element()) as element() {
   element {fn:node-name($element)}
      {$element/@*,
          for $child in $element/node()
              return
               if ($child instance of element())
                 then util:copy($child)
                 else $child
      }
};



declare function util:replaceUriParameter($uri, $name, $value) {
    let $param := fn:concat($name, "=")
    let $regex := fn:concat("^(.*)", $param, "(\d*)(.*)$")
    let $a := fn:replace($uri, $regex, "$1")
    let $c := fn:replace($uri, $regex, "$3")

    return
    if(fn:contains($uri, $param)) then
        fn:concat($a, $param, $value, $c)
    else
        if(fn:contains($uri, "?"))
        then
            fn:concat($uri, "&amp;", $param, $value)
        else 
            fn:concat($uri, "?", $param, $value)        
};

declare function util:formatShortDateTime($dt as xs:dateTime) as xs:string {
    (: MM/DD/YY HH:MM  Z :)
    let $month := fn:month-from-dateTime($dt)
    let $day := fn:day-from-dateTime($dt)
    let $year := fn:year-from-dateTime($dt)
    let $hour := fn:hours-from-dateTime($dt)
    let $min := fn:minutes-from-dateTime($dt)
    let $tz := fn:timezone-from-dateTime($dt)    
    (: return fn:concat($month, "/", $day, "/", $year, " ", util:format-number($hour, "00"), ":", util:format-number($min, "00"), " ", $tz)  :)
    let $time := fn:adjust-time-to-timezone(xs:time($dt), $tz)

    return fn:concat($month, "/", $day, "/", $year, " ", $time )   
};

declare function util:formatShortDate($dt as xs:dateTime) as xs:string {
    (: MM/DD/YY HH:MM  Z :)
    let $month := fn:month-from-dateTime($dt)
    let $day := fn:day-from-dateTime($dt)
    let $year := fn:year-from-dateTime($dt)

    return fn:concat($month, "/", $day, "/", $year )   
};


declare function util:timeAgo($dt as xs:dateTime) as xs:string {
    let $duration := fn:current-dateTime() - $dt
    let $days := fn:days-from-duration($duration)
    let $hours := fn:hours-from-duration($duration)
    let $minutes := fn:minutes-from-duration($duration)
    let $seconds := fn:seconds-from-duration($duration)
    let $totalSeconds := $seconds + $minutes * 60 + $hours * 3600 + $days * 86400
    let $totalMinutes := $minutes + $hours * 60 + $days * 720    
    let $totalHours := $hours + $days * 24
    return
        if($totalSeconds < 60) then
            "a moment ago"
        else if($totalMinutes < 60) then
            fn:concat($totalMinutes, " minute", util:_plural($totalMinutes), " ago")
        else if($totalHours < 24) then
            fn:concat($totalHours, " hour", util:_plural($totalHours), " ago")
        else
            fn:concat($days, " day", util:_plural($days), " ago")

};

(: http://blogs.datadirect.com/format-number.xquery :)
declare function util:format-number($number as xs:decimal, $format as xs:string) as xs:string
{
    let $strNumber := 
        fn:string(
            if (fn:ends-with($format, "%")) then $number*100 else $number
        )
    let $decimalPart := 
        fn:codepoints-to-string(
            util:format-number-decimal(
                fn:string-to-codepoints( fn:substring-after($strNumber, ".") ),
                fn:string-to-codepoints( fn:substring-after($format, ".") )
            )
        )
    let $integerPart := fn:codepoints-to-string(
        util:format-number-integer(
            fn:reverse(
                fn:string-to-codepoints(
                    if(fn:starts-with($strNumber, "0.")) then
                        ""
                    else
                        if( fn:contains($strNumber, ".") ) then fn:substring-before($strNumber, ".") else $strNumber
                )
            ),
            fn:reverse(
                fn:string-to-codepoints(
                    if( fn:contains($format, ".") ) then fn:substring-before($format, ".") else $format
                )
            ),
            0, -1
        )
    )
    return
        if (fn:string-length($decimalPart) > 0) then
            fn:concat($integerPart, ".", $decimalPart) 
        else
            $integerPart
};

(: http://blogs.datadirect.com/format-number.xquery :)
declare function util:format-number-decimal($number as xs:integer*, $format as xs:integer*) as xs:integer*
{
    if ($format[1] = 35 or $format[1] = 48) then
        if (fn:count($number) > 0) then
            ($number[1], util:format-number-decimal(fn:subsequence($number, 2), fn:subsequence($format, 2)))
        else
            if ($format[1] = 35) then () else ($format[1], util:format-number-decimal((), fn:subsequence($format, 2)))
    else
        if (fn:count($format) > 0) then
            ($format[1], util:format-number-decimal($number, fn:subsequence($format, 2)))
        else
            ()
};

(: http://blogs.datadirect.com/format-number.xquery :)
declare function util:format-number-integer($number as xs:integer*, $format as xs:integer*, $thousandsCur as xs:integer, $thousandsPos as xs:integer) as xs:integer*
{
    if( $thousandsPos > 0 and $thousandsPos = $thousandsCur and fn:count($number) > 0) then
        (util:format-number-integer($number, $format, 0, $thousandsCur), 44)
    else
        if ($format[1] = 35 or $format[1] = 48) then
            if (fn:count($number) > 0) then
                (util:format-number-integer(fn:subsequence($number, 2), fn:subsequence($format, 2), $thousandsCur+1, $thousandsPos), $number[1])
            else
                if ($format[1] = 35) then () else (util:format-number-integer((), fn:subsequence($format, 2), $thousandsCur+1, $thousandsPos), $format[1])
        else
            if (fn:count($format) > 0) then
                if ($format[1] = 44) then
                    (util:format-number-integer($number, fn:subsequence($format, 2), 0, $thousandsCur), $format[1])
                else
                    (util:format-number-integer($number, fn:subsequence($format, 2), $thousandsCur+1, $thousandsPos), $format[1])
            else
                if (fn:count($number) > 0) then
                    (util:format-number-integer(fn:subsequence($number, 2), $format, $thousandsCur+1, $thousandsPos), $number[1])
                else
                    ()
};

declare function util:_plural($num) {
    if($num = 1) then "" else "s"
};

declare function util:random-hex($length as xs:integer) as xs:string{
    fn:string-join(
        for $n in 1 to $length
        return
            xdmp:integer-to-hex(xdmp:random(15)),""
    )
};
     
declare function util:generate-uuid-v4() as xs:string{
    fn:string-join(
        (
            util:random-hex(8),
            util:random-hex(4),   
            util:random-hex(4),
            util:random-hex(4),
            util:random-hex(12)
        ),
        "-"
    )
};
