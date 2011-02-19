xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "/nwn.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace db="http://docbook.org/ns/docbook";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace geo="http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace mldb="http://norman.walsh.name/ns/metadata";
declare namespace tax="http://norman.walsh.name/ns/taxonomy";

declare option xdmp:mapping "false";

declare variable $taxonomy := doc("/production/etc/taxonomy.xml");

declare variable $lmdate as xs:dateTime
  := if (xdmp:get-request-field("lmdate"))
     then xs:dateTime(xdmp:get-request-field("lmdate"))
     else current-dateTime();

declare function local:patch($doc as document-node()) as document-node()? {
  let $subjok  := local:valid-subjects($doc/db:essay/db:info/dc:subject)
  let $coverok := local:valid-coverage($doc/db:essay/db:info/dc:coverage)
  return
    if ($subjok and $coverok)
    then
      document { nwn:patch-metadata($doc/db:essay) }
    else
      (if ($subjok) then () else (xdmp:log("Invalid subject"), xdmp:log($doc/db:essay/db:info/dc:subject)),
       if ($coverok) then () else (xdmp:log("Invalid coverage"), xdmp:log($doc/db:essay/db:info/dc:coverage)))
};

declare function local:valid-subjects($subjects as element(dc:subject)*) as xs:boolean {
  if (empty($subjects))
  then
    false()
  else
    let $invalid :=
      for $subj in $subjects
      let $name := substring-after($subj/@rdf:resource, "#")
      return
        if ($taxonomy//tax:*[local-name(.) = $name]) then () else $name
    return
      empty($invalid)
};

declare function local:valid-coverage($covers as element(dc:coverage)*) as xs:boolean {
  if (empty($covers))
  then
    true()
  else
    let $invalid :=
      for $cover in $covers
      let $rdf := /rdf:Description[@rdf:about=$cover/@rdf:resource
                       and (xdmp:document-get-collections(xdmp:node-uri(.)) = $nwn:pcoll)]
      return
        if ($rdf/geo:lat and $rdf/geo:long) then () else string($cover/@rdf:resource)
    return
      empty($invalid)
};

(: ============================================================ :)

declare function local:show-page() {
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>Promote pages</title>
      {nwn:css-meta()}
      {nwn:css-links()}
      <script type="text/javascript" src="/js/jquery-1.4.2.min.js">
      </script>
      <script type="text/javascript" src="/js/nwn.js">
      </script>
      <script type="text/javascript">
function checkall() {{
  $("input:checkbox").each(function(){{this.checked = true;}});
}}
function checknone() {{
  $("input:checkbox").each(function(){{this.checked = false;}});
}}
      </script>
    </head>
    <body>
      <div id="banner" xmlns="http://www.w3.org/1999/xhtml">
        <div id="hnav">
          <div class="title">
            <a href="/">Norman<span class="punct">.</span>Walsh<span class="punct">.name</span></a>
          </div>
        </div>
      </div>
      <h1>Promote pages</h1>
      <div>
        <a href="/admin/promote">Reload</a>, Check
        <a href="javascript:checkall()">all</a>,
        <a href="javascript:checknone()">none</a>.
      </div>
      <form action="/admin/promote" method="POST">
        <input type="hidden" name="post" value="1"/>
        <dl>
          { for $page in collection($nwn:scoll)
            let $uri := xdmp:node-uri($page)
            let $href := if (starts-with($uri, "/staging/comments/"))
                         then substring-after(substring-before($uri, "."), "/staging/comments")
                         else nwn:httpuri($uri)
            order by $uri
            return
              <dt>
                <input type="checkbox" name="{$uri}"/>
                { "&#160;" }
                <a href="{$href}">{ $uri }</a>
              </dt>
          }
        </dl>
        <input type="submit"/>
      </form>
    </body>
  </html>
};

declare function local:do-promote() {
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>Promote pages</title>
      {nwn:css-meta()}
      {nwn:css-links()}
      <script type="text/javascript" src="/js/jquery-1.4.2.min.js">
      </script>
      <script type="text/javascript" src="/js/nwn.js">
      </script>
    </head>
    <body>
      <div id="banner" xmlns="http://www.w3.org/1999/xhtml">
        <div id="hnav">
          <div class="title">
            <a href="/">Norman<span class="punct">.</span>Walsh<span class="punct">.name</span></a>
          </div>
        </div>
      </div>
      <h1>Promoted pages</h1>
      <div>
        <a href="/admin/promote">Reload</a>
      </div>
      <dl>
        { for $uri in xdmp:get-request-field-names()
          return
            if ($uri = "post")
            then
              ()
            else
              <dt>
                { local:promote($uri) }
                <a href="{nwn:httpuri($uri)}">{ $uri }</a>
              </dt>
        }
      </dl>
    </body>
  </html>
};

declare function local:promote($uri as xs:string) as xs:string? {
  let $props := xdmp:document-properties($uri)/prop:properties
  let $coll := xdmp:document-get-collections($uri)

  let $newuri  := concat("/production/", substring-after($uri, "/staging/"))
  let $newcoll := ($coll[. != $nwn:scoll], $nwn:pcoll)
  let $newprop := $props/*[not(self::prop:*)]
  let $readperm := xdmp:permission("weblog-reader", "read")

  let $doc := doc($uri)
  let $patched := if ($doc/db:essay) then local:patch($doc) else $doc

  return
    if (starts-with($uri, "/staging/"))
    then
      if (empty($patched))
      then
        "FAIL: "
      else
        ("PASS: ",
         xdmp:document-insert($newuri, $patched, ($readperm), $newcoll),
         xdmp:document-set-properties($newuri, $newprop),
         xdmp:document-delete($uri))
    else
      xdmp:log(concat("Attempt to promote something not in staging? ", $uri))
};

if (nwn:show-staging())
then
  if (xdmp:get-request-field("post"))
  then
    local:do-promote()
  else
    local:show-page()
else
  "You can't do that."



