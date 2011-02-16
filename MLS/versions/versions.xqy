xquery version "1.0-ml";

module namespace versions="http://norman.walsh.name/ns/modules/versions";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare function versions:store(
  $node as node(),
  $baseuri as xs:string)
as empty-sequence()
{
  xdmp:invoke("/versions/add.xqy",
              (xs:QName("node"), $node, xs:QName("uri"), $baseuri),
              <options xmlns="xdmp:eval">
                <database>{xdmp:database("nwn-versions")}</database>
              </options>)
};
