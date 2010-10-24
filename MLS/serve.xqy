xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

declare namespace db="http://docbook.org/ns/docbook";
declare namespace mldb="http://norman.walsh.name/ns/metadata";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare function local:walk($nodes as node()*) as node()* {
  for $x in $nodes
  return
    typeswitch ($x)
      case element(db:title)
        return
          if ($x/../../self::db:essay and not($x/../db:biblioid[@class="uri"]))
          then
            (element { node-name($x) }
                    { $x/@*, local:walk($x/node()) },
             element { QName("http://docbook.org/ns/docbook", "biblioid") }
                     { attribute { QName("", "class") } { "uri" },
                       concat("http://norman.walsh.name", nwn:httpuri(xdmp:node-uri($x))) })
          else
            element { node-name($x) }
                    { $x/@*, local:walk($x/node()) }
      case element()
        return
          if ($x/self::mldb:*)
          then
            ()
          else
            element { node-name($x) }
                    { $x/@*, local:walk($x/node()) }
      default
        return $x
};

declare function local:xml($uri as xs:string) as document-node() {
  let $doc := doc($uri)
  return
    document { local:walk($doc/node()) }
};

let $uri := xdmp:get-request-field("uri")
let $docuri := nwn:docuri($uri)
return
  ( (:xdmp:log(concat("Serve: ", $uri, " => ", $docuri)),:)
   if (xdmp:has-privilege("http://norman.walsh.name/ns/priv/weblog-update", "execute")
       and doc-available($uri))
   then
     doc($uri)
   else
     if (contains($uri, "/examples/"))
     then
       doc($docuri)
     else
       if (ends-with($uri, ".xml"))
       then
         local:xml($docuri)
       else
         doc($docuri))
