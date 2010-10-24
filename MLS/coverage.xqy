xquery version "1.0-ml";

import module namespace search="http://marklogic.com/appservices/search"
       at "/MarkLogic/appservices/search/search.xqy";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

import module namespace cache="http://norman.walsh.name/ns/modules/cache"
       at "cache.xqy";

declare namespace c="http://nwalsh.com/rdf/contacts#";
declare namespace db="http://docbook.org/ns/docbook";
declare namespace mldb="http://norman.walsh.name/ns/metadata";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

let $places := cts:element-values(xs:QName("mldb:coverage"),(),(),
                   cts:and-query((cts:collection-query($nwn:ecoll),
                                  cts:collection-query($nwn:pcoll))))
return
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>All coverage</title>
      <meta name="foaf:maker" content="foaf:mbox mailto:ndw@nwalsh.com" />
      <meta name="DC.title" content="Coverage"/>
      <link rel="icon" href="/graphics/nwn.png" type="image/png" />
      <link rel="home" href="/" title="NWN" />
      <link rel="contents" title="Contents" href="/dates.html" />
      <link rel="index" title="Index" href="/subjects.html" />
      { nwn:css-links() }
    </head>
    <body>
      { nwn:banner("/coverage", "All coverage", (), ()) }
      <div id="content">
        <div class="abstract">
          <p>All of the places I've written about.</p>
        </div>
        <dl>
          { for $place in $places
            let $q := cts:element-attribute-value-query(
                          xs:QName("rdf:Description"), xs:QName("rdf:about"),
                          concat("http://norman.walsh.name/knows/where/", $place))
            let $rdf := cts:search(/rdf:Description,
                            cts:and-query((cts:collection-query($nwn:pcoll), $q)))
            order by $rdf/c:associatedName
            return
              (<dt>
                 <a href="/knows/where/{$place}">
                   { if ($rdf/c:associatedTitle)
                     then string($rdf/c:associatedTitle)
                     else string($rdf/c:associatedName)
                   }
                 </a>
               </dt>,
               <dd>
                 <ul>
                   { let $q := cts:element-value-query(xs:QName("mldb:coverage"), $place)
                     let $essays := cts:search(/db:essay,
                                        cts:and-query((cts:collection-query($nwn:pcoll), $q)))
                     for $essay in $essays
                     order by $essay/db:info/mldb:pubdate descending
                     return
                       <li>
                         <a href="{nwn:httpuri(xdmp:node-uri($essay))}">
                           { string($essay/db:info/db:title) }
                         </a>, {
                             format-dateTime($essay/db:info/mldb:pubdate,
                                             "[D01]&#160;[MNn,*-3]&#160;[Y0001]")
                           }
                       </li>
                   }
                 </ul>
               </dd>)
          }
        </dl>
      </div>
      { nwn:footer() }
    </body>
  </html>
