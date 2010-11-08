xquery version "1.0-ml";

module namespace nwn="http://norman.walsh.name/ns/modules/utils";

import module namespace search="http://marklogic.com/appservices/search"
       at "/MarkLogic/appservices/search/search.xqy";

declare namespace db="http://docbook.org/ns/docbook";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace foaf="http://xmlns.com/foaf/0.1/";
declare namespace geo="http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace itin="http://nwalsh.com/rdf/itinerary#";
declare namespace mldb="http://norman.walsh.name/ns/metadata";
declare namespace places="http://nwalsh.com/ns/places";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace skos="http://www.w3.org/2004/02/skos/core#";
declare namespace t="http://norman.walsh.name/ns/taxonomy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $MONTHS := ("January","Februar","March","April","May","June",
                             "July","August","September","October","November","December");

declare variable $ecoll := "http://norman.walsh.name/ns/collections/essay";
declare variable $scoll := "http://norman.walsh.name/ns/collections/staging";
declare variable $pcoll := "http://norman.walsh.name/ns/collections/production";
declare variable $rcoll := "http://norman.walsh.name/ns/collections/rejected";
declare variable $icoll := "http://norman.walsh.name/ns/collections/itinerary";
declare variable $vcoll := "http://norman.walsh.name/ns/collections/versions";
declare variable $ccoll := "http://norman.walsh.name/ns/collections/cached";

declare function nwn:show-staging() as xs:boolean {
  xdmp:has-privilege("http://norman.walsh.name/ns/priv/weblog-update", "execute")
};

declare function nwn:admin() as xs:boolean {
  xdmp:has-privilege("http://norman.walsh.name/ns/priv/weblog-update", "execute")
};

declare function nwn:httpuri($dburi as xs:string) as xs:string? {
  let $uri := if (ends-with($dburi, ".xml"))
              then substring-before($dburi, ".xml")
              else $dburi
  return
    if (nwn:show-staging() and starts-with($uri, "/staging/"))
    then
      substring-after($uri, "/staging")
    else
      if (starts-with($uri, "/production/"))
      then
        substring-after($uri, "/production")
      else
        ()
};

declare function nwn:docuri($uri as xs:string) as xs:string? {
  let $trimmed := if (starts-with($uri, "/production/"))
                  then substring-after($uri, "/production")
                  else if (starts-with($uri, "/staging/"))
                       then substring-after($uri, "/staging")
                       else $uri

  let $pfxs := (if (nwn:show-staging()) then "/staging" else (),
                "/production")

  let $uris := for $pfx in $pfxs
               return
                 if (doc-available(concat($pfx, $trimmed))
                    or doc-available(concat($pfx, $trimmed, ".xml")))
                 then concat($pfx, $trimmed)
                 else ()
  return
    if (doc-available($uri))
    then
      $uri
    else
      $uris[1]
};

declare function nwn:doc-exists($uri as xs:string, $condition as element()) as xs:boolean {
  not(empty(nwn:docuri($uri)))
};

declare function nwn:diruri($uri as xs:string) as xs:string? {
  let $pfxs := (if (nwn:show-staging()) then "/staging" else (),
                "/production")
  let $uris := for $pfx in $pfxs
               let $q := cts:directory-query(concat($pfx, $uri), "infinity")
               return
                 if (xdmp:estimate(cts:search(collection(), $q)) > 0)
                 then concat($pfx, $uri)
                 else ()
  return
    $uris[1]
};

declare function nwn:dir-exists($uri as xs:string, $condition as element()) as xs:boolean {
  not(empty(nwn:diruri($uri)))
};

declare function nwn:essay-collections() as xs:string+ {
  ($ecoll,
   if (nwn:show-staging()) then $scoll else (),
   $pcoll)
};

declare function nwn:most-recent-update() as xs:dateTime {
  let $search-options
    := <options xmlns="http://marklogic.com/appservices/search">
         <constraint name="collection">
           <collection prefix="http://norman.walsh.name/ns/collections/"/>
         </constraint>
         <constraint name="dt">
           <range type="xs:dateTime" facet="false">
             <element ns="http://norman.walsh.name/ns/metadata" name="updated"/>
             <bucket ge="1970-01-01T00:00:00Z" lt="{current-dateTime()}"
                     name="range">range</bucket>
           </range>
         </constraint>
         <search:operator name="sort">
           <search:state name="pubdate">
             <search:sort-order direction="descending" type="xs:dateTime" collation="">
               <search:element ns="http://norman.walsh.name/ns/metadata" name="updated"/>
             </search:sort-order>
             <search:sort-order>
               <search:score/>
             </search:sort-order>
           </search:state>
         </search:operator>
         <page-length>1</page-length>
       </options>

  let $incoll   := if (nwn:show-staging())
                   then "collection:production OR collection:staging"
                   else "collection:production"

  let $query    := concat("collection:essay dt:range (", $incoll, ") sort:pubdate")

  let $search   := search:search($query, $search-options)
  let $uri      := $search/search:result[1]/@uri/string()
  let $essay    := doc($uri)/db:essay
  return
    xs:dateTime($essay/db:info/mldb:updated)
};

declare function nwn:next-essay($pubdate as xs:dateTime) as element(db:essay)? {
  nwn:get-essays($pubdate, "ascending", 1)
};

declare function nwn:prev-essay($pubdate as xs:dateTime) as element(db:essay)? {
  nwn:get-essays($pubdate, "descending", 1)
};

declare function nwn:get-essays($cutoff as xs:dateTime,
                                $direction as xs:string,
                                $count as xs:decimal)
as element(db:essay)*
{
  let $incoll  := (if (nwn:show-staging()) then "staging" else (), "production")
  let $outcoll := "itinerary"
  return
    nwn:get-essays($incoll, $outcoll, $cutoff, $direction, $count)
};

declare function nwn:get-essays($incl as xs:string*,
                                $excl as xs:string*,
                                $cutoff as xs:dateTime,
                                $direction as xs:string,
                                $count as xs:decimal)
as element(db:essay)*
{
  let $search-options
    := <options xmlns="http://marklogic.com/appservices/search">
         <constraint name="collection">
           <collection prefix="http://norman.walsh.name/ns/collections/"/>
         </constraint>
         <constraint name="dt">
           <range type="xs:dateTime" facet="false">
             <element ns="http://norman.walsh.name/ns/metadata" name="pubdate"/>
             { if ($direction = "ascending")
               then
                 <bucket ge="{$cutoff + xs:dayTimeDuration('PT1S')}"
                         lt="{current-dateTime()}" name="range">range</bucket>
               else
                 <bucket ge="1970-01-01T00:00:00Z" lt="{$cutoff}" name="range">range</bucket>
             }
           </range>
         </constraint>
         <search:operator name="sort">
           <search:state name="relevance">
             <search:sort-order>
               <search:score/>
             </search:sort-order>
           </search:state>
           <search:state name="pubdate">
             <search:sort-order direction="{$direction}" type="xs:dateTime" collation="">
               <search:element ns="http://norman.walsh.name/ns/metadata" name="pubdate"/>
             </search:sort-order>
             <search:sort-order>
               <search:score/>
             </search:sort-order>
           </search:state>
         </search:operator>
         <page-length>{$count}</page-length>
       </options>

  let $incoll   := string-join(for $c in $incl
                              return concat("collection:", $c), " OR ")

  let $outcoll  := string-join(for $c in $excl
                               return concat("-collection:", $c), " ")

  let $query    := concat("collection:essay dt:range (", $incoll, ") ",
                          $outcoll, " sort:pubdate")

  let $search   := search:search($query, $search-options)

  let $uris     := $search/search:result/@uri/string()

  let $essays   := for $uri in $uris
                   return doc($uri)/db:essay
  return
    $essays
};

declare function nwn:similar($essay as element(db:essay)) as element(db:essay)* {
  let $docterms := ($essay//db:link, $essay//db:wikipedia,
                    $essay//db:code, $essay//db:command)
  let $terms    := if (count($docterms) > 2) then $docterms else $essay
  let $posq     := cts:similar-query($terms)
  let $negq     := cts:collection-query($nwn:vcoll)
  let $q        := cts:and-not-query($posq, $negq)
  let $essays   := (cts:search(collection($ecoll), $q)[1 to 6])/db:essay
  return
    $essays except $essay
};

declare function nwn:get-essays-near($lat as xs:decimal,
                                     $long as xs:decimal,
                                     $count as xs:decimal)
{
  nwn:get-essays-near($lat, $long, $count, (1, 2, 5, 10, 15, 25, 50, 100, 250, 500))
};

declare function nwn:get-essays-near($lat as xs:decimal,
                                     $long as xs:decimal,
                                     $count as xs:decimal,
                                     $search as xs:decimal+)
{
  let $essays := nwn:get-essays-within($lat, $long, $search[1])
  return
    if (count($essays) >= $count or count($search) = 1)
    then
      ($search[1], $essays)
    else
      nwn:get-essays-near($lat, $long, $count, $search[position() > 1])
};

declare function nwn:get-essays-within($lat as xs:decimal,
                                       $long as xs:decimal,
                                       $dist as xs:decimal)
as element(db:essay)*
{
  let $circ  := cts:circle($dist, cts:point($lat, $long))
  let $query := cts:element-pair-geospatial-query(xs:QName("mldb:geoloc"),
                                                  xs:QName("geo:lat"), xs:QName("geo:long"),
                                                  $circ)
  let $anq   := cts:and-not-query($query, cts:collection-query($nwn:vcoll))
  return
    cts:search(collection($nwn:ecoll), $anq)/db:essay
};

declare function nwn:fix-namespace($nodes as node()*,
                                   $fromns as xs:string*,
                                   $tons as xs:string)
as node()*
{
  for $node in $nodes
  return
    if (xdmp:node-kind($node) = "element")
    then
      if (namespace-uri($node) = $fromns)
      then
        element { QName($tons, local-name($node)) }
                { $node/namespace::*[. != $fromns],
                  $node/@*,
                  nwn:fix-namespace($node/node(), $fromns, $tons) }
    else
      element { node-name($node) }
              { $node/namespace::*,
                $node/@*,
                nwn:fix-namespace($node/node(), $fromns, $tons) }
  else
    $node
};

declare function nwn:flight-map($trip as element(itin:trip)) as element(html:script) {
  let $legs   := $trip//itin:leg[(@class='flight' or @class='train')
                                 and itin:arrive and itin:depart]
  let $points := distinct-values(for $p in ($legs/itin:arrive, $legs/itin:depart)
                                 return substring-after($p,"#"))
  let $script :=
    <lines xmlns="http://www.w3.org/1999/xhtml">
      <line>var mapDiv = document.getElementById('flightmap');</line>
      <line>function Plot() {{</line>
      { for $point in $points
        let $var := translate($point, ".", "")
        let $uri := concat("http://norman.walsh.name/knows/where/", $point)
        let $pq  := cts:element-attribute-value-query(xs:QName("rdf:Description"),
                                                      xs:QName("rdf:about"), $uri)
        let $place := cts:search(collection($nwn:pcoll), $pq)[1]/rdf:Description
        let $trace := if (empty($place))
                      then xdmp:log(concat("No RDF for ", $uri))
                      else ()
        return
          <line>{"    "}{$var} = new Airport({string($place/geo:lat)}, {string($place/geo:long)}, "{$point}", {if ($place/foaf:homepage) then concat("""", $place/foaf:homepage/@rdf:resource, """") else """"""});</line>
      }
      { for $leg in $legs
        let $dep := substring-after($leg/itin:depart, '#')
        let $depvar := translate($dep, ".", "")
        let $arr := substring-after($leg/itin:arrive, '#')
        let $arrvar := translate($arr, ".", "")
        return
          <line>    flights.push(new Flight({$depvar},{$arrvar}));</line>
      }
      <line>    Setup();</line>
      <line>}}</line>
      <line>$(document).ready(function() {{</line>
      <line>    Plot();</line>
      <line>}});</line>
    </lines>
  return
    <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript">
      { string-join($script/line, "&#10;") }
    </script>
};

declare function nwn:extract-topics($essay as element(db:essay)) as element(mldb:topic)* {
  let $tax := doc("/production/etc/taxonomy.xml")
  return
    for $subject in $essay/db:info/dc:subject
    let $topic := substring-after($subject/@rdf:resource, '#')
    let $tt := $tax//t:*[local-name(.) = string($topic)]
    return
      if ($topic = '' or count($tt) != 1)
      then
         error(xs:QName("nwn:BADSUBJECT"),concat("Can't parse ", $subject/@rdf:resource))
      else
        <mldb:topic>{string($topic)}</mldb:topic>
};

declare function nwn:extract-subjects($essay as element(db:essay)) as element(mldb:subject)* {
  let $tax := doc("/production/etc/taxonomy.xml")
  let $subjects as xs:string*
    := (for $wiki in $essay//db:wikipedia
        return
          normalize-space($wiki),
        for $person in $essay//db:personname
        return
          if ($person/db:surname)
          then
            concat(normalize-space($person/db:surname), " ", 
                   normalize-space(($person/db:givenname,$person/db:firstname)[1]))
          else
            normalize-space($person),
          for $index in $essay//db:indexterm
          return
            normalize-space(string-join(($index/db:primary,
                                         $index/db:secondary,$index/db:tertiary), ", ")),
          for $app in $essay//db:application
          return
            normalize-space($app),
          for $subject in $essay/db:info/dc:subject
          let $topic := substring-after($subject/@rdf:resource, '#')
          let $tt := $tax//t:*[local-name(.) = string($topic)]
          return
            if ($topic = '' or count($tt) != 1)
            then
              error(xs:QName("nwn:BADSUBJECT"),concat("Can't parse ", $subject/@rdf:resource))
            else
              if ($tt/skos:prefLabel)
              then normalize-space($tt/skos:prefLabel)
              else normalize-space($topic))
  return
    for $s in distinct-values($subjects)
    order by $s
    return
      <mldb:subject>{$s}</mldb:subject>
};

declare function nwn:extract-geo($essay as element(db:essay)) as element(mldb:geoloc)* {
  for $cov in $essay/db:info/dc:coverage
  let $about := string($cov/@rdf:resource)
  let $rdf := /rdf:Description[@rdf:about=$about]
  return
    if ($rdf/geo:lat and $rdf/geo:long)
    then
      <mldb:geoloc>
        <geo:lat>{string(($rdf/geo:lat)[1])}</geo:lat>
        <geo:long>{string(($rdf/geo:long)[1])}</geo:long>
      </mldb:geoloc>
    else
      if (empty($rdf))
      then
        error(xs:QName("nwn:BADCOVERAGE"),concat("No data for ", $about))
      else
        ()
};

declare function nwn:patch-metadata($essay as element(db:essay)) as element(db:essay) {
  let $lmdate := current-dateTime()
  let $pubdate := string($essay/db:info/db:pubdate)
  let $pubdt
    := if (string-length($pubdate) = 7)
       then concat($pubdate, "-01T12:00:00Z")
       else if ($pubdate castable as xs:dateTime)
            then $pubdate
            else concat($pubdate,"T12:00:00Z")
  let $info
    := <info xmlns="http://docbook.org/ns/docbook">
         <mldb:id>
           { if ($essay/db:info/db:volumenum)
             then
               concat($essay/db:info/db:volumenum,",",$essay/db:info/db:issuenum)
             else
               string($essay/db:info/db:biblioid[not(@class='uri')])
           }
         </mldb:id>
         { if ($pubdt castable as xs:dateTime)
           then
             <mldb:pubdate>
               { $pubdt }
             </mldb:pubdate>
           else
             xdmp:log(concat("Cannot cast ", $pubdt, " as a dateTime"))
         }
         <mldb:updated>
           { $lmdate }
         </mldb:updated>
         { nwn:extract-topics($essay) }
         { nwn:extract-subjects($essay) }
         { nwn:extract-geo($essay) }
         { $essay/db:info/node()[not(namespace-uri(.) = "http://norman.walsh.name/ns/metadata")] }
       </info>
  return
    <essay xmlns="http://docbook.org/ns/docbook">
      { $essay/namespace::* }
      { $essay/@* }
      { for $node in $essay/node()
        return
          if ($node/self::db:info)
          then $info
          else $node
      }
    </essay>
};

declare function nwn:css-meta() {
  (<meta xmlns="http://www.w3.org/1999/xhtml"
         name="foaf:maker" content="foaf:mbox mailto:ndw@nwalsh.com" />,
   <meta xmlns="http://www.w3.org/1999/xhtml"
         name="viewport"
         content="width=device-width,target-densityDpi=device-dpi,user-scalable=yes"/>)
};

declare function nwn:css-links() {
  (<link xmlns="http://www.w3.org/1999/xhtml"
         rel="stylesheet" type="text/css" href="/css/docbook.css" />,
   <link xmlns="http://www.w3.org/1999/xhtml"
         rel="stylesheet" type="text/css" href="/css/base.css" />,
  <link xmlns="http://www.w3.org/1999/xhtml"
         rel="stylesheet" media="screen and (max-device-width: 800px)" type="text/css"
         href="/css/mobile.css" />,
   <link xmlns="http://www.w3.org/1999/xhtml"
         rel="stylesheet" media="screen and (max-device-width: 800px)" type="text/css"
         href="/css/sidebar-narrow.css"/>,
   <link xmlns="http://www.w3.org/1999/xhtml"
         rel="stylesheet" media="screen and (min-device-width: 801px)"
         href="/css/sidebar-wide.css"/>,
   <link xmlns="http://www.w3.org/1999/xhtml"
         rel="stylesheet" type="text/css" media="print"
         href="/css/print.css" />)
};

declare function nwn:banner($essay as element(db:essay)) as element(html:div) {
  let $title   := string($essay/db:info/db:title)
  let $issue   := if ($essay/db:info/db:volumenum)
                  then
                    concat("Volume ", $essay/db:info/db:volumenum,
                           ", Issue ", $essay/db:info/db:issuenum)
                  else
                    ()
  let $pubdate := xs:dateTime($essay/db:info/mldb:pubdate)
  let $moddate := xs:dateTime($essay/db:info/mldb:updated)
  return
    nwn:banner(nwn:httpuri(xdmp:node-uri($essay)), $title, $issue, $pubdate, $moddate)
};

declare function nwn:banner($uri as xs:string?,
                            $title as xs:string,
                            $issue as xs:string?,
                            $pubdate as xs:dateTime?)
as element(html:div)
{
  nwn:banner($uri, $title, $issue, $pubdate, ())
};

declare function nwn:banner($uri as xs:string?,
                            $title as xs:string,
                            $issue as xs:string?,
                            $pubdate as xs:dateTime?,
                            $moddate as xs:dateTime?)
as element(html:div)
{
  <div id="banner" xmlns="http://www.w3.org/1999/xhtml">
    <div id="hnav">
      <div class="title">
        <a href="/">Norman<span class="punct">.</span>Walsh<span class="punct">.name</span></a>
      </div>
    </div>
    { if (empty($uri))
      then
        ()
      else
        let $base := "http://chart.apis.google.com/chart?chs=125x125&amp;cht=qr"
        let $text := concat("http://norman.walsh.name", $uri)
        return
          <div id="qrcode">
            { (: alt="" is intentional, if there's no code, there's no point :) }
            <img alt="" src="{$base}&amp;chl={$text}"/>
          </div>
    }
    <h1>{$title}</h1>

    <div id="dateline">
      { if (empty($issue))
        then
          ()
        else
          <span class="issue">
            { concat($issue, if (empty($pubdate)) then "" else "; ") }
          </span>
      }
      { if (empty($pubdate))
        then
          ()
        else
          (<span class="date">
             { format-dateTime($pubdate, "[D01] [MNn,*-3] [Y0001]") }
           </span>,
           if (empty($moddate) or nwn:same-date($moddate,$pubdate))
           then
             ()
           else
             <span class="small">
               { concat(" (modified ", format-dateTime($moddate, "[D01] [MNn,*-3] [Y0001]"), ")") }
             </span>)
      }
    </div>
  </div>
};

declare function nwn:same-date($d1 as xs:dateTime, $d2 as xs:dateTime) as xs:boolean {
  (year-from-dateTime($d1) = year-from-dateTime($d2)
   and month-from-dateTime($d1) = month-from-dateTime($d2)
   and day-from-dateTime($d1) = month-from-dateTime($d2))
};

declare function nwn:footer() as element(html:div) {
  <div id="footer" xmlns="http://www.w3.org/1999/xhtml">
    <div class="rights">
      <p>Copyright &#169; 1998–{year-from-dateTime(nwn:most-recent-update())} Norman Walsh.
      { comment { "Creative Commons License" } }
      This work is licensed under a <a rel="license"
      href="http://creativecommons.org/licenses/by-nc/2.0/">Creative Commons License</a>.
      { comment { "/Creative Commons License" } }
      </p>
    </div>
  </div>
};

declare function nwn:format-essay($uri as xs:string) as document-node()? {
  let $source := concat($uri, ".xml")
  let $cached := concat("/cached", $uri, ".html")
  let $sourcedt := xdmp:document-properties($source)/prop:properties/prop:last-modified
  let $cacheddt := xdmp:document-properties($cached)/prop:properties/prop:last-modified
  return
    if (doc-available($source))
    then
      if (xs:dateTime($cacheddt) > xs:dateTime($sourcedt))
      then
        let $trace := xdmp:log(concat("Cached ", $uri))
        return
          doc($cached)
      else
        let $html := nwn:do-format($source)
        let $readperm := xdmp:permission("weblog-reader", "read")
        let $updateperm := xdmp:permission("weblog-reader", "update")
        return
          (xdmp:document-insert($cached, $html, ($readperm, $updateperm), ($nwn:ccoll)), $html)
    else
      xdmp:log(concat("Source not available? ", $source))
};

declare function nwn:do-format($uri as xs:string) as document-node() {
  let $trace := xdmp:log(concat("Formatting ", $uri))
  let $xslt := "/style/essay2html.xsl"
  let $doc := doc($uri)
  let $map := map:map()
  return
    (xdmp:set-response-content-type("text/html"),
     xdmp:xslt-invoke($xslt, $doc, $map))
};

declare function nwn:foaf-name($name as xs:string) as element(rdf:Description)? {
  nwn:rdf(xs:QName("foaf:name"), $name)
};

declare function nwn:foaf-nick($nick as xs:string) as element(rdf:Description)? {
  nwn:rdf(xs:QName("foaf:nick"), $nick)
};

declare function nwn:rdf($prop as xs:QName, $value as xs:string)
as element(rdf:Description)?
{
  nwn:rdf($prop, $value, ())
};

declare function nwn:rdf($prop as xs:QName, $value as xs:string, $type as xs:string?)
as element(rdf:Description)?
{
  (: FIXME: /production/ is a nasty hack here. :)
  let $allrdf := /rdf:Description[starts-with(xdmp:node-uri(.), "/production/")
                                  and *[node-name(.) = $prop and . = $value]]
  let $rdf := if (empty($type))
              then $allrdf
              else $allrdf[rdf:type/@rdf:resource = $type]
  return
    if (empty($rdf))
    then
      xdmp:log(concat("nwn:rdf(", $prop, ",",$value,",",$type,") returned no matches"))
    else
      if (count($rdf) > 1)
      then
        (xdmp:log(concat("nwn:rdf(", $prop, ",",$value,",",$type,") returned multiple")),$rdf[1])
      else
        $rdf[1]
};

declare function nwn:subject-mentions($page as xs:string) as xs:decimal {
  let $q := cts:element-value-query(xs:QName("mldb:subject"), $page)
  return
    xdmp:estimate(cts:search(/db:essay, cts:and-query((cts:collection-query($nwn:pcoll), $q))))
};
