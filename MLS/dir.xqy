xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

let $uri   := xdmp:get-request-field("uri")
let $parts := tokenize($uri, "/")
let $parent := string-join($parts[1 to count($parts)-2], "/")
let $dir   := nwn:diruri($uri)
let $files := for $uri in cts:uris()[starts-with(., $dir)]
              let $file  := substring-after($uri, $dir)
              let $bare  := if (ends-with($file, "/"))
                            then substring($file, 1, string-length($file) - 1)
                            else $file
              let $parts := tokenize($bare, "/")
              return
                if ($file = "" or count($parts) > 1)
                then
                  ()
                else
                  $file
return
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>Directory listing: {$uri}</title>
      { nwn:css-links() }
    </head>
    <body>
      { nwn:banner($uri, concat("Directory listing: ", $uri), (), nwn:most-recent-update()) }
      <div id="content">
        <div class="abstract"/>
        <dl>
          { if ($parent != "")
            then
              <dt><a href="{$parent}/">..</a></dt>
            else
              ()
          }
          { for $file in $files
            return
              if (ends-with($file, ".xml"))
              then
                let $base := substring($file, 1, string-length($file) - 4)
                return
                  (<dt><a href="{concat($uri,$base)}">{$base}</a></dt>,
                   <dt><a href="{concat($uri,$base,'.xml')}">{$base}.xml</a></dt>,
                   <dt><a href="{concat($uri,$base,'.rdf')}">{$base}.rdf</a></dt>)
              else
                <dt><a href="{concat($uri,$file)}">{$file}</a></dt>
          }
        </dl>
      </div>
      { nwn:footer() }
    </body>
  </html>


