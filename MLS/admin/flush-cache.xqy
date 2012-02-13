xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "/nwn.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare function local:remove-doc(
  $uri as xs:string
) {
  let $flush := for $prefix in ("/cached/production", "/cached/staging")
                let $docuri := concat($prefix, $uri, ".html")
                return
                  if (doc-available($docuri))
                  then xdmp:document-delete($docuri)
                  else ()
  return
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <title>Flushed</title>
        { nwn:css-links() }
        <meta http-equiv='refresh' content="0;url={$uri}"/>
      </head>
      <body>
        { nwn:banner((), "Flushed", (), ()) }
        <div id="content">
          <p>The cache has been cleared for {$uri}.</p>
        </div>
      </body>
    </html>
};

declare function local:flush-all() {
  let $uris := cts:uris()[contains(.,"/cached/") and ends-with(.,".html")]
  return
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <title>Flushed</title>
        { nwn:css-links() }
      </head>
      <body>
        { nwn:banner((), "Flushed", (), ()) }
        <div id="content">
          <p>The cache has been cleared of {count($uris)} documents:</p>
          <ul>
            { for $uri in $uris
              return
                (xdmp:document-delete($uri),
                 <li>{$uri}</li>)
            }
          </ul>
        </div>
      </body>
    </html>
};

let $uri := xdmp:get-request-field("uri")
return
  if (empty($uri))
  then local:flush-all()
  else local:remove-doc($uri)

