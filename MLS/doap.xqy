xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

declare namespace db="http://docbook.org/ns/docbook";
declare namespace doap="http://usefulinc.com/ns/doap/#";
declare namespace foaf="http://xmlns.com/foaf/0.1/";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs="http://www.w3.org/2000/01/rdf-schema#";
declare namespace cc="http://web.resource.org/cc/";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace xlink="http://www.w3.org/1999/xlink";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $path as xs:string := xdmp:get-request-field("path");
declare variable $name as xs:string := xdmp:get-request-field("name");

declare function local:val($essay as element(), $str as xs:string) as xs:string? {
  let $elem := ($essay//*[contains(@role,$str)])[1]
  return
    if (empty($elem))
    then ()
    else string($elem)
};

declare function local:doap($essay as element(db:essay)) {
  let $revs := $essay//*[*[contains(@role,"doap.release.revision")]]
  return
    <doap:Project xmlns:doap="http://usefulinc.com/ns/doap/#"
                  xmlns:foaf="http://xmlns.com/foaf/0.1/"
                  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                  xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
                  xmlns:cc="http://web.resource.org/cc/"
                  xmlns:dc="http://purl.org/dc/elements/1.1/">
      <dc:date>{local:val($revs[1], "doap.release.created")}</dc:date>
      <doap:description>{local:val($essay, "doap.description")}</doap:description>
      { for $lic in $essay//doap:license
        return
          <doap:license rdf:resource="{$lic/@rdf:resource}"/>
      }
      <doap:shortdesc>{local:val($essay, "doap.description")}</doap:shortdesc>
      <doap:name>{local:val($essay, "doap.name")}</doap:name>
      <doap:release>
        <doap:Version>
          <doap:revision>{local:val($revs[1], "doap.release.revision")}</doap:revision>
          <doap:created>{local:val($revs[1], "doap.release.created")}</doap:created>
          <doap:branch>{local:val($revs[1], "doap.release.branch")}</doap:branch>
        </doap:Version>
      </doap:release>

      <doap:programming-language>{local:val($essay, "doap.programming-language")}</doap:programming-language>
      <doap:os>{local:val($essay, "doap.os")}</doap:os>
      <doap:shortname>{local:val($essay, "doap.shortname")}</doap:shortname>

{(:{local:val($essay, "doap.")}:)}

      <doap:download-page rdf:resource="{($essay//db:link[@role='doap.download-page'])[1]/@xlink:href}"/>
      <doap:homepage rdf:resource="{($essay//db:link[@role='doap.homepage'])[1]/@xlink:href}"/>

      <doap:maintainer>
        <foaf:Person>
          <foaf:name>Norman Walsh</foaf:name>
          <foaf:mbox_sha1sum>ef99fd659575b85b94575cc016043813ec1294dc</foaf:mbox_sha1sum>
          <rdfs:seeAlso rdf:resource="http://norman.walsh.name/foaf"/>
          <rdfs:seeAlso rdf:resource="http://norman.walsh.name/knows/who#norman-walsh"/>
        </foaf:Person>
      </doap:maintainer>

      <doap:bug-database rdf:resource="{($essay//db:link[@role='doap.bug-database'])[1]/@xlink:href}"/>
      <doap:repository>
        <doap:CVSRepository>
          <doap:browse rdf:resource="{($essay//db:link[@role='doap.CVSRepository.browse'])[1]/@xlink:href}"/>
          <doap:anon-root>{local:val($essay, "doap.CVSRepository.anon-root")}</doap:anon-root>
        </doap:CVSRepository>
      </doap:repository>

      <doap:created>{substring($essay/db:info/db:pubdate,1,10)}</doap:created>

      { for $rev in $revs[position() > 1]
        return
          <doap:release>
            <doap:Version>
              <doap:revision>{local:val($rev, "doap.release.revision")}</doap:revision>
              <doap:created>{local:val($rev, "doap.release.created")}</doap:created>
              <doap:branch>{local:val($rev, "doap.release.branch")}</doap:branch>
            </doap:Version>
          </doap:release>
      }


  </doap:Project>
};

let $uri := concat("/production", $path, "/", $name, ".xml")
let $doc := doc($uri)/db:essay
return
  if (empty($doc) or empty(local:val($doc, "doap.name")))
  then
    (xdmp:log(concat("404 on doap=", $uri)),
     xdmp:set-response-code(404, "Not Found."),
     concat("404 resource not found."))
  else
    local:doap($doc)

(:
   <doap:release>
      <doap:Version>
         <doap:revision>0.8.3</doap:revision>2008-10-26<doap:branch>alpha</doap:branch>
      </doap:Version>
   </doap:release>


:)