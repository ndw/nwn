xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace audit="http://norman.walsh.name/ns/modules/audit";
declare namespace db="http://docbook.org/ns/docbook";
declare namespace html="http://www.w3.org/1999/xhtml";

declare option xdmp:mapping "false";

declare variable $r200       := cts:element-value-query(xs:QName("audit:code"), "200");
declare variable $irrdir     := cts:or-query(for $dir in ("css", "local", "js", "graphics",
                                                          "popular.xqy", "favicon.ico",
                                                          "atom", "rss", "cgi-bin", "knows")
                                             return
                                               cts:element-value-query(xs:QName("audit:dir"),
                                                                       $dir));
declare variable $irrext     := cts:or-query(for $ext in ("atom")
                                             return
                                               cts:element-value-query(xs:QName("audit:ext"),
                                                                       $ext));

declare variable $irrelevant := cts:or-query(($irrdir, $irrext));


declare function local:urilist($startTime as xs:dateTime) as element()* {
  let $agequery := cts:element-range-query(xs:QName("audit:datetime"), ">=", $startTime)
  let $posquery := cts:and-query(($agequery, $r200))
  let $uris     := cts:element-values(xs:QName("audit:uri"), (),
                       ("descending", "frequency-order", "limit=10"),
                       cts:and-not-query($posquery, $irrelevant))
  for $uri in $uris
  let $count := xdmp:estimate(
                  cts:search(/audit:http,
                             cts:and-not-query(
                               cts:and-query(
                                 (cts:element-value-query(xs:QName("audit:uri"), $uri),
                                 $posquery)),
                               $irrelevant)))
  let $doc := doc(nwn:docuri($uri))

  let $refs := cts:element-values(xs:QName("audit:referrer"), (),
                       ("descending", "frequency-order", "limit=5"),
                       cts:and-query(($r200, cts:element-value-query(xs:QName("audit:uri"),$uri))))

  return
    (<dt xmlns="http://www.w3.org/1999/xhtml"><a href="{$uri}">{$uri}</a> ({$count})</dt>,
     if ($refs)
     then
       <dd xmlns="http://www.w3.org/1999/xhtml">
         <dl>
           { for $ref in $refs
             return
               <dt>{local:link($ref)}</dt>
           }
         </dl>
       </dd>
     else
       ())
};

declare function local:link($ref as xs:string) as element()* {
  let $host := substring-before(substring-after($ref, "//"), "/")
  let $base := concat("http://", $host, "/")
  let $s    := if ($host = "images.search.yahoo.com")
               then local:param($ref, "p")
               else if ($host = "www.bing.com" or contains($host, "www.google."))
               then local:param($ref, "q")
               else ()
  return
    if ($ref = "")
    then
      <span xmlns="http://www.w3.org/1999/xhtml">(no referrer)</span>
    else
      (<a xmlns="http://www.w3.org/1999/xhtml" href="{$ref}" title="{$ref}">
         { concat($base, if ($base != $ref) then "..." else "") }
       </a>,
       <span xmlns="http://www.w3.org/1999/xhtml">&#160;{$s}</span>)
};

declare function local:param($ref as xs:string, $name as xs:string) as xs:string? {
  let $qparam := substring-after($ref, "?")
  let $params := tokenize($qparam, "&amp;")
  let $stwith := concat($name, "=")
  let $param :=
    for $p in $params
    return
      if (starts-with($p, $stwith))
      then
        substring-after($p, $stwith)
      else
        ()
  return
    $param[1]
};

<div xmlns="http://www.w3.org/1999/xhtml">
  <h2>Popular today</h2>
  <dl>
    { local:urilist(xs:dateTime(format-dateTime(current-dateTime(),
                                                "[Y0001]-[M01]-[D01]T00:00:00"))) }
  </dl>
  <h2>Popular this week</h2>
  <dl>
    { local:urilist(current-dateTime() - xs:dayTimeDuration("P7D")) }
  </dl>
</div>


