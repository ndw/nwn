xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

let $p := xdmp:get-request-field("p")
let $rm := xdmp:get-request-field("submit") = "REMOVE"
let $uris := if ($p) then cts:uris()[contains(., $p) and not(ends-with(., "/"))] else ()
return
  if ($rm)
  then
    let $rmuris := for $field in xdmp:get-request-field-names()
                   return
                     if (starts-with($field, "X"))
                     then xdmp:base64-decode(substring($field,2))
                     else ()
    return
      <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
          <title>Removed documents</title>
          { nwn:css-links() }
        </head>
        <body>
          { nwn:banner((), "Removed documents", (), ()) }
          <div id="content">
            <form method="POST" action="/rm.xqy">
              <p>Contains pattern: <input name="p" value="{$p}"/>{" "}
              <input type="submit" name="submit" value="search"/></p>
              { if ($rmuris) 
                then
                  <dl>
                    { for $name in $rmuris
                      return
                        <dt>{$name}{xdmp:document-delete($name)}</dt>
                    }
                  </dl>
                else
                  <p>No documents selected.</p>
              }
            </form>
          </div>
        </body>
      </html>
  else
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <title>Remove documents?</title>
        { nwn:css-links() }
      </head>
      <body>
        { nwn:banner((), "Remove documents?", (), ()) }
        <div id="content">
          <form method="POST" action="/rm.xqy">
            <p>Contains pattern: <input name="p" value="{$p}"/>{" "}
            <input type="submit" name="submit" value="search"/></p>
            <dl>
              { for $uri in $uris
                return
                  <dt><input type="checkbox" name="X{xdmp:base64-encode($uri)}"/>{$uri}</dt>
              }
            </dl>
            <input type="submit" name="submit" value="REMOVE"/>
          </form>
        </div>
      </body>
    </html>
