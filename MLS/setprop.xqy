xquery version "1.0-ml";

declare namespace db="http://docbook.org/ns/docbook";
declare namespace dbng="http://docbook.org/docbook-ng";
declare namespace mldb="http://norman.walsh.name/ns/metadata";
declare namespace t="http://norman.walsh.name/ns/taxonomy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $uri := xdmp:get-request-field('uri');
declare variable $user-props := tokenize(xdmp:get-request-field('props'), ",");

let $tax := doc("/production/etc/taxonomy.xml")
let $props
  := for $prop in $user-props
     let $node := $tax//*[local-name(.) = $prop]
     return
       if (empty($node))
       then
         error(xs:QName("t:ERROR"), concat("Property not in taxonomy: ", $prop))
       else
         $prop
let $newprops
  := for $name in distinct-values($props)
     return
       <t:topic>{$name}</t:topic>
let $suri := concat("/staging", $uri, ".xml")
let $puri := concat("/production", $uri, ".xml")
let $docuri :=
  if (doc-available($suri))
  then
    $suri
  else
    if (doc-available($puri))
    then
      $puri
    else
      error(xs:QName("t:ERROR"), concat("No document for properties: ", $uri))
return
  (xdmp:document-remove-properties($docuri, xs:QName("t:topic")),
   xdmp:document-add-properties($docuri, $newprops),
   <updated>{$docuri}</updated>)


