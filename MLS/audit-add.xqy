xquery version "1.0-ml";

declare namespace audit="http://norman.walsh.name/ns/modules/audit";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $node external;
declare variable $uri external;

declare variable $perms := (xdmp:permission("weblog-reader", "read"),
                            xdmp:permission("weblog-editor", "read"),
                            xdmp:permission("weblog-editor", "update"));

let $tstamp := format-dateTime(current-dateTime(), "/audit/[Y0001]-[M01]-[D01]/[H01]/")
let $docuri := if ($uri = "")
               then concat($tstamp, xdmp:integer-to-hex(xdmp:random()), ".xml")
               else $uri
return
  if (starts-with($node/audit:uri, "/ajax/lm.xqy?"))
  then
    ( (: Nevermind tracking this editing ajax call :) )
  else
    xdmp:document-insert($docuri, $node, $perms,
                         "http://norman.walsh.name/ns/collections/audit")
