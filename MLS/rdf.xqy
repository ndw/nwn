xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

declare namespace db="http://docbook.org/ns/docbook";
declare namespace mldb="http://norman.walsh.name/ns/metadata";
declare namespace owl="http://www.w3.org/2002/07/owl#";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace a="http://nwalsh.com/rdf/accounts#";
declare namespace c="http://nwalsh.com/rdf/contacts#";
declare namespace foaf="http://xmlns.com/foaf/0.1/";

let $uri := xdmp:get-request-field("uri")
let $docuri := concat(nwn:docuri($uri), ".xml")
let $base := nwn:httpuri($docuri)
return
  (xdmp:log(concat("RDF for: ", $uri, " => ", $docuri)),
   if (contains($uri, "/examples/"))
   then
     (xdmp:log(concat("RDF for: ", $uri, " => 404!")),
      xdmp:set-response-code(404, "Not Found."),
      concat("404 resource not found: ", $uri))
   else
     let $doc := doc($docuri)/db:essay
     return
       <rdf:RDF xmlns:doap="http://usefulinc.com/ns/doap/#"
                xmlns:foaf="http://xmlns.com/foaf/0.1/"
                xmlns:gal="http://norman.walsh.name/rdf/gallery#"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
                xmlns:cc="http://web.resource.org/cc/"
                xmlns:t="http://norman.walsh.name/knows/taxonomy#"
                xmlns:cvs="http://nwalsh.com/rdf/cvs#"
                xmlns:dc="http://purl.org/dc/elements/1.1/"
                xmlns:dcterms="http://purl.org/dc/terms/">
         <rdf:Description rdf:about="http://norman.walsh.name{$base}">
           <rdf:type rdf:resource="http://norman.walsh.name/knows/taxonomy#Article"/>
           <dc:type rdf:resource="http://purl.org/dc/dcmitype/Text"/>
           <dc:format>text/html</dc:format>
           <dc:isFormatOf rdf:resource="http://norman.walsh.name{$base}.xml"/>
           <dcterms:created>{string($doc/db:info/mldb:pubdate)}</dcterms:created>
           <dcterms:issued>{string($doc/db:info/mldb:updated)}</dcterms:issued>
           <dc:identifier>{string($doc/db:info/mldb:id)}</dc:identifier>
           <dc:title>{string($doc/db:info/db:title)}</dc:title>
           <dc:date>{string($doc/db:info/mldb:pubdate)}</dc:date>
           <dc:creator rdf:resource="http://norman.walsh.name/knows/who#norman-walsh"/>
           <dc:rights>Copyright © {substring($doc/db:info/mldb:pubdate,1,4)} Norman Walsh.
           This work is licensed under the Creative Commons Attribution-NonCommercial License.
           </dc:rights>
           <cc:license rdf:resource="http://creativecommons.org/licenses/by-nc/2.0/"/>
           <rdf:type rdf:resource="http://web.resource.org/cc/Work"/>
           <dc:description>{string($doc/db:info/db:abstract)}</dc:description>
           { $doc/db:info/dc:* }
         </rdf:Description>
         <rdf:Description rdf:about="http://norman.walsh.name{$base}.xml">
           <dc:format>application/docbook+xml</dc:format>
           <dc:hasFormat rdf:resource="http://norman.walsh.name/2010/09/26/nymug"/>
           <dcterms:created>{string($doc/db:info/mldb:pubdate)}</dcterms:created>
           <dcterms:issued>{string($doc/db:info/mldb:updated)}</dcterms:issued>
           <dc:identifier>{string($doc/db:info/mldb:id)}</dc:identifier>
           <dc:title>{string($doc/db:info/db:title)}</dc:title>
           <dc:date>{string($doc/db:info/mldb:pubdate)}</dc:date>
           <dc:creator rdf:resource="http://norman.walsh.name/knows/who#norman-walsh"/>
           <dc:rights>Copyright © {substring($doc/db:info/mldb:pubdate,1,4)} Norman Walsh.
           This work is licensed under the Creative Commons Attribution-NonCommercial License.
           </dc:rights>
           <cc:license rdf:resource="http://creativecommons.org/licenses/by-nc/2.0/"/>
           <rdf:type rdf:resource="http://web.resource.org/cc/Work"/>
           <dc:description>{string($doc/db:info/db:abstract)}</dc:description>
           { $doc/db:info/dc:* }
         </rdf:Description>
       </rdf:RDF>)
