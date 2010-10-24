import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

declare namespace db="http://docbook.org/ns/docbook";
declare namespace mldb="http://norman.walsh.name/ns/metadata";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare function local:patch($essay as element(db:essay)) {
  let $uri := xdmp:node-uri($essay)
  let $cover
    := for $c in $essay/db:info/dc:coverage/@rdf:resource
       return
         <mldb:coverage>{substring-after($c,"where/")}</mldb:coverage>
  let $geoloc := $essay/db:info/mldb:geoloc[1]
  return
    for $c in $cover
    return
      xdmp:node-insert-before($geoloc, $c)
};

<doc>
{
for $f in /db:essay[db:info/dc:coverage
                    and starts-with(xdmp:node-uri(.), "/production/")]
return
  local:patch($f)
}
</doc>

