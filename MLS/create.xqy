xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

declare namespace db="http://docbook.org/ns/docbook";
declare namespace etc="http://norman.walsh.name/ns/etc";

declare option xdmp:output "indent-untyped=yes";

let $uri   := xdmp:get-request-field("uri")
let $duri  := concat("/", format-dateTime(current-dateTime(), "[Y0001]/[M01]/[D01]/"),
                     replace($uri, "^.*/([^/]+)$", "$1"))

return
  if (nwn:show-staging())
  then
    (xdmp:set-response-code(201, "Created"),
     <essay xmlns="http://docbook.org/ns/docbook"
            xmlns:xlink="http://www.w3.org/1999/xlink"
            xmlns:dc="http://purl.org/dc/elements/1.1/"
            xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
            xml:lang="en"
            version='5.0'>
       <info>
         <title>{" "}</title>
         <biblioid class="uri">http://norman.walsh.name{replace($duri,"^(.*)\.xml$", "$1")}</biblioid>
         <volumenum>0</volumenum>
         <issuenum>0</issuenum>
         <pubdate>2038-01-19T03:14:07Z</pubdate>
         <author><personname>
           <firstname>Norman</firstname><surname>Walsh</surname>
         </personname></author>
         <copyright>
           <year>0</year>
           <holder>Norman Walsh</holder>
         </copyright>
{ comment { "
    <dc:coverage rdf:resource=""http://norman.walsh.name/knows/where/???""/>
    <dc:subject rdf:resource=""http://norman.walsh.name/knows/taxonomy#???""/>
    " } }
         <abstract>
           <para>???</para>
         </abstract>
       </info>
{ comment { "
  <epigraph>
     <attribution><personname>
       <firstname></firstname><surname></surname>
     </personname></attribution>
     <para></para>
  </epigraph>
  " } }
       <para xml:id='p1'>{" "}</para>
     </essay>)
  else
    (xdmp:log(concat("Insufficient permissions to create essay: ", $uri)),
     xdmp:set-response-code(404, "Not Found."),
     concat("404 resource not found: ", $uri, "&#10;"))
