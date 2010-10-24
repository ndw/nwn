xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "/nwn.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare function local:promote($uri as xs:string) as empty-sequence() {
  let $props := xdmp:document-properties($uri)/prop:properties
  let $coll := xdmp:document-get-collections($uri)

  let $newuri  := concat("/production/", substring-after($uri, "/staging/"))
  let $newcoll := ($coll[. != $nwn:scoll], $nwn:pcoll)
  let $newprop := $props/*[not(self::prop:*)]
  let $readperm := xdmp:permission("weblog-reader", "read")
  return
    if (starts-with($uri, "/staging/"))
    then
      (xdmp:document-insert($newuri, doc($uri), ($readperm), $newcoll),
       xdmp:document-set-properties($newuri, $newprop),
       xdmp:document-delete($uri))
    else
      xdmp:log(concat("Attempt to promote something not in staging? ", $uri))
};

declare function local:reject($uri as xs:string) as empty-sequence() {
  let $props := xdmp:document-properties($uri)/prop:properties
  let $coll := xdmp:document-get-collections($uri)

  let $newuri  := concat("/rejected/", substring-after($uri, "/staging/"))
  let $newcoll := ($coll[. != $nwn:scoll], $nwn:rcoll)
  let $newprop := $props/*[not(self::prop:*)]
  let $readperm := xdmp:permission("weblog-editor", "read")
  return
    if (starts-with($uri, "/staging/"))
    then
      (xdmp:document-insert($newuri, doc($uri), ($readperm), $newcoll),
       xdmp:document-set-properties($newuri, $newprop),
       xdmp:document-delete($uri))
    else
      xdmp:log(concat("Attempt to reject something not in staging? ", $uri))
};

let $action  := xdmp:get-request-field("action")
let $uri     := xdmp:get-request-field("uri")
let $docuri  := substring-before(substring-after($uri, "/comments"), ".")
return
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>Processed comment</title>
      { nwn:css-links() }
      <meta http-equiv='refresh' content="2;url={$docuri}"/>
    </head>
    <body>
      { nwn:banner((), "Processed comment", (), ()) }
      { if (doc-available($uri))
        then
          <div id="content">
            { if ($action = 'approve')
              then local:promote($uri)
              else if ($action = 'reject')
              then local:reject($uri)
              else <p>WTF? Action was neither approve nor reject?</p>
            }
            <p>Processed {$uri}: {$action};<br/>Returning to {$docuri}</p>
          </div>
        else
          <div id="content">
            <p>WTF? {$uri} doesn't exist!</p>
          </div>
      }
    </body>
  </html>
