xquery version "1.0-ml";

declare namespace audit="http://norman.walsh.name/ns/modules/audit";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $now as xs:dateTime := current-dateTime();
declare variable $cutoff as xs:dayTimeDuration := xs:dayTimeDuration("P33D");
declare variable $max-delete as xs:unsignedLong := 25000;

declare function local:purge-uris() as xs:string* {
  for $uri in cts:uris()[matches(., "^/audit/\d\d\d\d-\d\d-\d\d/\d\d.*\.xml$")]
  let $dt := xs:dateTime(replace($uri, "^/audit/(\d\d\d\d-\d\d-\d\d)/(\d\d).*$", "$1T$2:00:00"))
  return
    if ($now - $dt > $cutoff)
    then
      $uri
    else
      ()
};

let $alluris := local:purge-uris()
let $uris := $alluris[1 to $max-delete]
return
  (for $uri in $uris return xdmp:document-delete($uri),
   concat("Removed ", count($uris), " of ", count($alluris), " out-of-date audit log entries.&#10;"))

