xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

declare variable $method := xdmp:get-request-method();
declare variable $url as xs:string := xdmp:get-request-url();
declare variable $baseurl as xs:string
  := if (contains($url,"?")) then substring-before($url, "?") else $url;
declare variable $command as xs:string
  := if (contains($url,"?")) then substring-after($url, "?") else "";

declare variable $control
  := <control>
       <map method="POST">
         <pattern>^(/[^?]+)(\?(.*))?$</pattern>
         <replace>/post.xqy?uri=$1&amp;$3</replace>
       </map>
       <map>
         <pattern>^/(\?.*)?$</pattern>
         <replace>/default.xqy$1</replace>
       </map>
       <map>
         <pattern>^/local(/[^?]+)(\?(.*))?$</pattern>
         <replace>/local.xqy?uri=$1&amp;$3</replace>
       </map>
       <map>
         <pattern>^/setprop/([^?]+)(\?(.*))?$</pattern>
         <replace>/setprop.xqy?uri=$1&amp;$3</replace>
       </map>
       <map>
         <pattern>^((/.*)\.xqy(\?.*)?)$</pattern>
         <replace>$1</replace>
       </map>
       <map>
         <pattern>^(/.*).rdf$</pattern>
         <exists>$1.xml</exists>
         <replace>/rdf.xqy?uri=$1</replace>
       </map>
       <map>
         <pattern>^(.+)$</pattern>
         <exists>$1.xml</exists>
         <replace>/dispatch.xqy?uri=$1</replace>
       </map>
       <map>
         <pattern>^/near/(.*),(.*)$</pattern>
         <replace>/near.xqy?lat=$1&amp;long=$2</replace>
       </map>
     </control>;

declare function local:map($uri as xs:string) as xs:string? {
  local:map($uri, $control/map)
};

declare function local:map($uri as xs:string, $maps as element(map)*) as xs:string? {
  let $map := $maps[1]
  let $rest := $maps[position() > 1]
  return
    if (empty($map))
    then
      ()
    else
      if ((not($map/@method) or ($map/@method = $method)) and matches($uri, $map/pattern))
      then
        let $result := replace($uri, $map/pattern, $map/replace)
        let $exists := if ($map/exists)
                       then
                         nwn:docuri(replace($uri, $map/pattern, $map/exists))
                       else
                         ()
        return
          if (not($map/exists) or (not(empty($exists)) and doc-available($exists)))
          then
            $result
          else
            local:map($uri, $rest)
      else
        local:map($uri, $rest)
};

let $uri := "/2005/10/01/foo"
let $result := local:map($uri)
return
  if (empty($result))
  then
    (xdmp:set-response-code(404, "Not Found."),
     concat("404 resource not found: ", $uri))
  else
    concat($uri, " maps to ", $result)
