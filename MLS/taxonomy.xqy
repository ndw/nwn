xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace db="http://docbook.org/ns/docbook";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace etc="http://norman.walsh.name/ns/etc";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace mldb="http://norman.walsh.name/ns/metadata";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace skos="http://www.w3.org/2004/02/skos/core#";
declare namespace tax="http://norman.walsh.name/ns/taxonomy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $taxonomy := doc("/production/etc/taxonomy.xml");
declare variable $uri := xdmp:get-request-field("uri");
declare variable $duri := if (empty($uri)) then () else nwn:docuri($uri);
declare variable $doc := if (empty($duri)) then () else doc(concat($duri, ".xml"));

declare function local:dump($nodes as element()+) as element()+ {
  for $node in $nodes
  let $topic := local-name($node)
  let $rdfuri := concat("http://norman.walsh.name/knows/taxonomy#", local-name($node))
  let $checked := $doc/db:essay/db:info/dc:subject[@rdf:resource = $rdfuri]
  return
    (<dt xmlns="http://www.w3.org/1999/xhtml" id="{local-name($node)}">
       <input type="checkbox" name="{local-name($node)}">
       { if ($checked)
         then attribute { QName("", "checked") } { "checked" }
         else ()
       }
       </input>
       { if ($node/skos:prefLabel)
         then string($node/skos:prefLabel)
         else local-name($node)
       }
     </dt>,
     <dd xmlns="http://www.w3.org/1999/xhtml">
       { if ($node/tax:*[not(self::tax:Omit) and not(self::tax:Sticky)])
         then
           <dl>
             { local:dump($node/tax:*[not(self::tax:Omit) and not(self::tax:Sticky)]) }
           </dl>
         else
           ()
       }
     </dd>)
};

let $x := 1
return
  if (empty($doc))
  then
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <title>Taxonomy</title>
      </head>
      <body>
        <h1>Taxonomy</h1>
        <p>Can't find {$uri}.</p>
      </body>
    </html>
  else
    if (xdmp:get-request-field("update") = "update")
    then
      let $names := xdmp:get-request-field-names()[. != "uri" and . != "update"]
      let $newsubj := for $name in $names
                      return
                        <dc:subject
                            rdf:resource="http://norman.walsh.name/knows/taxonomy#{$name}"/>
      let $updinfo := <info xmlns="http://docbook.org/ns/docbook">
                        {$doc/db:essay/db:info/node()
                           [not(self::dc:subject)
                            and not(namespace-uri(.)="http://norman.walsh.name/ns/metadata")]}
                        {$newsubj}
                      </info>
      let $updessay := nwn:patch-metadata(
                           <essay xmlns="http://docbook.org/ns/docbook">
                             { $doc/db:essay/namespace::* }
                             { $updinfo }
                             { $doc/db:essay/node()[not(self::db:info)]}
                           </essay>
                        )


      let $tcoll  := "http://norman.walsh.name/ns/collections/versions"
      let $extrac := "http://norman.walsh.name/ns/collections/essay"
      let $Z      := xs:dayTimeDuration("PT0H")
      let $nowz   := adjust-dateTime-to-timezone(current-dateTime(), $Z)
      let $tstamp := format-dateTime($nowz, "[Y0001]-[M01]-[D01]/[H01]-[m01]-[s01]")
      let $this   := concat("/versions/", $tstamp, $uri, ".xml")
      return
        (xdmp:document-insert($this, $updessay, (), ($tcoll, $extrac)),
         xdmp:node-replace($doc/db:essay/db:info, $updessay/db:info),
         concat("Updated subjects for ", $uri, ".xml"))
    else
      <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
          <title>Taxonomy</title>
        </head>
        <body>
          <h1>Taxonomy</h1>
          <form action="/taxonomy.xqy" method="get">
            <input type="hidden" name="uri" value="{$uri}"/>
            <input type="hidden" name="update" value="update"/>
            <dl>
              { local:dump($taxonomy/tax:Everything) }
            </dl>
            <input type="submit" value="Update"/>
          </form>
        </body>
      </html>
