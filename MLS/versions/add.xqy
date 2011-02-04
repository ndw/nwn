xquery version "1.0-ml";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $node as element() external;
declare variable $uri as xs:string external;

declare variable $perms := (xdmp:permission("weblog-reader", "read"),
                            xdmp:permission("weblog-reader", "update"),
                            xdmp:permission("weblog-editor", "read"),
                            xdmp:permission("weblog-editor", "update"));

let $Z      := xs:dayTimeDuration("PT0H")
let $nowz   := adjust-dateTime-to-timezone(current-dateTime(), $Z)
let $tstamp := format-dateTime($nowz, "[Y0001]-[M01]-[D01]/[H01]-[m01]-[s01]")
let $this   := concat("/versions/", $tstamp, $uri)
return
  xdmp:document-insert($this, $node, $perms, ())
