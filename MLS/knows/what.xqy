xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "/nwn.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace a="http://nwalsh.com/rdf/accounts#";
declare namespace c="http://nwalsh.com/rdf/contacts#";
declare namespace db="http://docbook.org/ns/docbook";
declare namespace etc="http://norman.walsh.name/ns/etc";
declare namespace foaf="http://xmlns.com/foaf/0.1/";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace mldb="http://norman.walsh.name/ns/metadata";
declare namespace owl="http://www.w3.org/2002/07/owl#";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs="http://www.w3.org/2000/01/rdf-schema#";
declare namespace t="http://norman.walsh.name/knows/taxonomy#";

declare option xdmp:mapping "false";

declare function local:redirect($what as xs:string) {
  let $newuri := concat("http://", /etc:host-config/etc:reader/etc:host,
                        if (/etc:host-config/etc:reader/etc:port)
                        then concat(":", /etc:host-config/etc:reader/etc:port)
                        else "",
                        "/knows/what/", $what, ".html")
  return
    (xdmp:set-response-code(303, "See Other"),
     xdmp:add-response-header("Location", $newuri),
     concat("303 See other: ", $newuri))
};

declare function local:rdf($rdf as element(rdf:Description)?) as element(rdf:RDF) {
  <rdf:RDF>
    {$rdf}
  </rdf:RDF>
};

declare function local:html($rdf as element(rdf:Description)?) as element(html:html) {
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>{string($rdf/c:associatedName)}</title>
      <meta name="foaf:maker" content="foaf:mbox mailto:ndw@nwalsh.com" />
      <meta name="DC.title" content="{string($rdf/c:associatedName)}"/>
      <link rel="alternate" type="application/rdf+xml" title="Essay metadata"
            href="{substring-after(xdmp:node-uri($rdf), '/knows/what/')}" />
      <link rel="icon" href="/graphics/nwn.png" type="image/png" />
      <link rel="home" href="/" title="NWN" />
      <link rel="contents" title="Contents" href="/dates.html" />
      <link rel="index" title="Index" href="/subjects.html" />
      { nwn:css-links() }
    </head>
    <body>
      { nwn:banner(nwn:httpuri(xdmp:node-uri($rdf)),
                   $rdf/c:associatedName, (), nwn:most-recent-update()) }
      <div id="content">
        <dl>
          <dt>URI</dt>
          <dd>
            <ul>
              <li>
                <a href="{string($rdf/@rdf:about)}">{string($rdf/@rdf:about)}</a>
              </li>
            </ul>
          </dd>

          { if ($rdf/foaf:homepage)
            then
              (<dt>Homepage</dt>,
               <dd>
                 <ul>
                   { for $page in $rdf/foaf:homepage
                     return
                       <li>
                         <a href="{$page/@rdf:resource}">{string($page/@rdf:resource)}</a>
                       </li>
                   }
                 </ul>
               </dd>)
            else
              ()
          }

          { if ($rdf/t:wikipedia)
            then
              (<dt>Wikipedia</dt>,
               <dd>
                 <ul>
                   <li>
                     <a href="http://en.wikipedia.org/wiki/{$rdf/t:wikipedia}">
                       { string($rdf/t:wikipedia) }
                     </a>
                   </li>
                 </ul>
               </dd>)
            else
              ()
          }

          { if ($rdf/t:specification)
            then
              (<dt>Specification</dt>,
               <dd>
                 <ul>
                   { for $spec in $rdf/t:specification
                     return
                       <li>
                         <a href="{$spec/@rdf:resource}">{string($spec/@rdf:resource)}</a>
                       </li>
                   }
                 </ul>
               </dd>)
            else
              ()
          }

          { if ($rdf/foaf:depiction)
            then
              (<dt>Depictions</dt>,
               <dd>
                 <ul>
                   { for $dep in $rdf/foaf:depiction
                     return
                       <li>
                         <a href="$dep/@rdf:resource">{string($dep/@rdf:resource)}</a>
                       </li>
                   }
                 </ul>
               </dd>)
            else
              ()
          }

          { let $evq := cts:or-query(for $label in $rdf/rdfs:label
                                     return
                                       cts:element-value-query(xs:QName("mldb:subject"), $label))
            let $aq  := cts:and-query((cts:collection-query($nwn:pcoll),$evq))
            let $anq := cts:and-not-query($aq, cts:collection-query($nwn:vcoll))
            let $essays := cts:search(/db:essay, $anq)
            return
              if ($essays)
              then
                (<dt>Essays</dt>,
                 <dd>
                   <ul>
                     { for $essay in $essays
                       order by $essay/db:info/mldb:pubdate descending
                       return
                         <li>
                           <a href="{nwn:httpuri(xdmp:node-uri($essay))}">
                             { string($essay/db:info/db:title) }
                             </a>, {
                               format-dateTime($essay/db:info/mldb:pubdate,
                                               "[D01]&#160;[MNn,*-3]&#160;[Y0001]")
                             }
                             <div class="listabstract">
                               { string($essay/db:info/db:abstract) }
                             </div>
                         </li>
                     }
                   </ul>
                 </dd>)
              else
                ()
          }

          { let $seealso := for $type in ($rdf/rdf:type/@rdf:resource,
                                          $rdf/rdfs:seeAlso/@rdf:resource)
                            return
                              if (starts-with($type, "http://nwalsh.com/rdf/contacts#"))
                              then ()
                              else string($type)
             return
               if ($seealso)
               then
                (<dt>See also</dt>,
                 <dd>
                   <ul>
                     { for $uri in $seealso
                       return
                         <li>
                           <a href="{$uri}">{$uri}</a>
                         </li>
                     }
                   </ul>
                 </dd>)
              else
                ()
          }
        </dl>
      </div>
      { nwn:footer() }
    </body>
  </html>
};

declare function local:index() as element(html:html) {
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>What</title>
      <link rel="icon" href="/graphics/nwn.png" type="image/png" />
      <link rel="home" href="/" title="NWN" />
      <link rel="contents" title="Contents" href="/dates.html" />
      <link rel="index" title="Index" href="/subjects.html" />
      { nwn:css-links() }
    </head>
    <body>
      { nwn:banner("/what", "What", (), nwn:most-recent-update()) }
      <div id="content">
        <div class="abstract">
          <p>What norm knows...</p>
        </div>
        <p>I've assigned URIs to the things listed below. This list
        may grow in the future, but in recent months, I've started to
        use <a href="http://en.wikipedia.org/">Wikipedia</a> URIs for
        things instead of defining my own. </p>
        <dl>
          { for $rdf in /rdf:Description[rdf:type/@rdf:resource
                                         ="http://nwalsh.com/rdf/contacts#Thing"
                                         and starts-with(xdmp:node-uri(.), "/production/")]
            order by string($rdf/c:associatedName)
            return
              <dt id="{substring-after($rdf/@rdf:about, 'knows/what/')}">
                <a href="/knows/what/{substring-after($rdf/@rdf:about, 'knows/what/')}">
                  { string($rdf/c:associatedName) }
                </a>
              </dt>
          }
        </dl>
      </div>
      { nwn:footer() }
    </body>
  </html>
};

let $what := xdmp:get-request-field("what")
let $type := xdmp:get-request-field("type")
let $rdf  := doc(concat("/production/etc/knows/what/", $what, ".rdf"))/rdf:Description
return
  if (empty($what) or $what = "")
  then
    local:index()
  else
    if (empty($rdf))
    then
      (xdmp:set-response-code(404, "Not Found."),
       concat("404 resource not found: /knows/what/", $what))
    else
      if ($type eq "html")
      then
        local:html($rdf)
      else
        if ($type eq "rdf")
        then
          local:rdf($rdf)
        else
          local:redirect($what)

