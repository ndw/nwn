import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

declare namespace mldb="http://norman.walsh.name/ns/metadata";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare function local:walk($nodes as node()*) as node()* {
  for $x in $nodes
  return
    typeswitch ($x)
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

xdmp:quote(local:xml("/production/2010/10/23/geo.xml"))
