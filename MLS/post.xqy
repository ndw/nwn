xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

import module namespace versions="http://norman.walsh.name/ns/modules/versions"
       at "/versions/versions.xqy";

declare namespace c="http://www.w3.org/ns/xproc-step";
declare namespace db="http://docbook.org/ns/docbook";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace etc="http://norman.walsh.name/ns/etc";
declare namespace mldb="http://norman.walsh.name/ns/metadata";
declare namespace patom="http://purl.org/atom/ns#";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace tax="http://norman.walsh.name/ns/taxonomy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $taxonomy := doc("/production/etc/taxonomy.xml");

declare variable $posturi  := xdmp:get-request-field('uri');
declare variable $type   := xdmp:get-request-header('Content-Type');
declare variable $format
  := if ($type = 'application/xml' or ends-with($type, '+xml') or ends-with($posturi, ".xml"))
     then "xml"
     else if (contains($type, "text/") or ends-with($posturi, ".txt"))
          then "text"
          else "binary";
declare variable $body := xdmp:get-request-body($format);

declare variable $apocalypse := xs:dateTime("2038-01-19T03:14:07Z");

declare variable $paraid := 0;

(: ============================================================ :)

declare function local:walkinfo($nodes as node()*) as node()* {
  let $year := year-from-dateTime(current-dateTime())
  let $vol  := $year - 1997
  return

  for $x in $nodes
  return
    typeswitch ($x)
      case element(db:volumenum)
        return
          if (string($x) = "0")
          then
            element { node-name($x) }
                    { $x/@*, $vol }
          else
            element { node-name($x) }
                    { $x/@*, local:walkinfo($x/node()) }
      case element(db:issuenum)
        return
          if (string($x) = "0")
          then
            let $posq  := cts:and-query((cts:collection-query($nwn:pcoll),
                              cts:element-value-query(xs:QName("db:volumenum"), string($vol))))
            let $negq  := cts:collection-query($nwn:vcoll)
            let $thisyear := cts:search(collection($nwn:ecoll), cts:and-not-query($posq, $negq))
            let $issue := count($thisyear) + 1
            return
              element { node-name($x) }
                      { $x/@*, $issue }
          else
            element { node-name($x) }
                    { $x/@*, local:walkinfo($x/node()) }
      case element(db:pubdate)
        return
          if ($x castable as xs:dateTime and xs:dateTime($x) = $apocalypse)
          then
            let $dt := format-dateTime(current-dateTime(), "[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]")
            let $dtz := replace(format-dateTime(current-dateTime(), "[Z]"), "^(...?)(..)$", "$1:$2")
            return
              element { node-name($x) }
                      { $x/@*, concat($dt,$dtz) }
          else
            element { node-name($x) }
                    { $x/@*, local:walkinfo($x/node()) }
      case element(db:year)
        return
          if (string($x) = "0")
          then
            element { node-name($x) }
                    { $x/@*, year-from-dateTime(current-dateTime()) }
          else
            element { node-name($x) }
                    { $x/@*, local:walkinfo($x/node()) }
      case element()
        return
          element { node-name($x) }
                  { $x/@*, local:walkinfo($x/node()) }
      default
        return $x
};

declare function local:walk($nodes as node()*) as node()* {
  for $x in $nodes
  return
    typeswitch ($x)
      case element(db:essay)
        return
          element { node-name($x) }
                  { $x/@*, $x/namespace::*, local:walk($x/node()) }
      case element(db:info)
        return
          if ($x/../self::db:essay)
          then
            local:walkinfo($x)
          else
            element { node-name($x) }
                    { $x/@*, local:walk($x/node()) }
      case element(db:para)
        return
          if ($x/@xml:id)
          then
            element { node-name($x) }
                    { $x/@*, local:walk($x/node()) }
          else
            let $id := concat("p", $paraid)
            let $set := xdmp:set($paraid, $paraid + 1)
            return
              element { node-name($x) }
                      { $x/@*,
                        attribute { xs:QName("xml:id") } { $id },
                        local:walk($x/node()) }
      case element()
        return
          element { node-name($x) }
                  { $x/@*, local:walk($x/node()) }
      default
        return $x
};

declare function local:patch($doc as document-node()) as document-node() {
  let $pnums := for $p in $doc//db:para[matches(@xml:id, "^p\d+$")]
                return
                  xs:integer(substring($p/@xml:id, 2))
  let $set := xdmp:set($paraid, if (empty($pnums)) then 1 else max($pnums)+1)
  return
    document { local:walk($doc/node()) }
};

(: ============================================================ :)

declare function local:invalid($doc as element(db:essay)) as xs:string? {
  let $uri     := string(/etc:host-config/etc:essay-validator)
  let $opts    := <options xmlns="xdmp:http">
                    <data>{xdmp:quote($doc)}</data>
                  </options>
  let $results := xdmp:http-post($uri, $opts)
  let $code    := string($results[1]/*:code)
  let $xml     := if ($code = "200") then xdmp:unquote($results[2]) else <c:errors/>
  let $trace   := if ($code = "200" and $xml/c:success)
                  then ()
                  else (xdmp:log($uri),xdmp:log($results))
  let $xmlok   := not(empty($xml/c:success))
  let $titleok := not(string($doc/db:info/db:title) eq "???")
  let $absok   := not(string($doc/db:info/db:abstract) eq "???")

  let $bibid   := $body/db:essay/db:info/db:biblioid
                        [@class='uri'and starts-with(.,'http://norman.walsh.name/')][1]
  let $uri     := if (empty($bibid))
                  then
                    $posturi
                  else
                    concat(substring-after($bibid, 'norman.walsh.name'), ".xml")
  let $uri     := concat("/production", $uri)

  let $dateok  := not(doc-available($uri))
                  or ($body/db:essay/db:info/db:pubdate != $apocalypse)

  let $volok   := empty($doc/db:info/db:volumenum)
                  or $doc/db:info/db:volumenum castable as xs:positiveInteger
  let $issok   := empty($doc/db:info/db:issuenum)
                  or $doc/db:info/db:issuenum castable as xs:positiveInteger
  let $dupid   := for $p in $doc//db:para[not(ancestor::db:info)]
                  let $id := $p/@xml:id
                  return
                    if ($p/@xml:id and count($doc//db:para[@xml:id = $id]) != 1)
                    then $id else ()
  let $paraok  := not($doc//db:para[not(@xml:id) and not(ancestor::db:info)]) and empty($dupid)
  let $mldbok  := empty($doc/db:info/mldb:*)
  let $valid   := $xmlok and $titleok and $absok and $volok and $issok and $paraok and $dateok
  let $message := if (not($xmlok)) then "Not an XML-valid essay"
                  else if (not($titleok)) then "Title is not valid"
                  else if (not($absok)) then "Abstract is not valid"
                  else if (not($volok)) then "Volume number is not valid"
                  else if (not($issok)) then "Issue number is not valid"
                  else if (not($paraok)) then "There's a para without an xml:id or a dup xml:id"
                  else if (not($mldbok)) then "db:info contains mldb:*"
                  else if (not($dateok)) then "db:pubdate is still $apocolypse"
                  else ""
  return
    if (not($valid))
    then
      (xdmp:log(concat("Not valid: ", $message)), $message)
    else
      ()
};

let $bibid  := $body/db:essay/db:info/db:biblioid
                     [@class='uri'and starts-with(.,'http://norman.walsh.name/')][1]
let $pub    := true() or starts-with($posturi,"/pub/")
let $uri    := if (not(empty($bibid)) and $pub)
               then
                 concat(substring-after($bibid, 'norman.walsh.name'), ".xml")
               else
                 $posturi

let $prod   := xdmp:get-request-field("approve") = "true"
let $stage  := if ($prod)
               then concat("/production", $uri)
               else concat("/staging", $uri)

let $coll   := if ($prod)
               then "http://norman.walsh.name/ns/collections/production"
               else "http://norman.walsh.name/ns/collections/staging"

let $essay   as xs:boolean := $format = "xml" and ($body/db:essay)
let $comment as xs:boolean := $format = "xml" and $body/patom:entry
let $wfxml   as xs:boolean := $format ne "xml" or $body/*

let $pbody  := if ($essay and $pub) then local:patch($body) else $body

let $extrac := (if ($essay)
                then "http://norman.walsh.name/ns/collections/essay"
                else (),
                if ($essay and contains($uri, "/itinerary/"))
                then "http://norman.walsh.name/ns/collections/itinerary"
                else (),
                if ($comment)
                then
                  ("http://norman.walsh.name/ns/collections/comment",
                   if (ends-with($uri, ".rej"))
                   then "http://norman.walsh.name/ns/collections/comment/rejected"
                   else "http://norman.walsh.name/ns/collections/comment/accepted")
                else ())

let $notvalid := if ($essay) then local:invalid($pbody/db:essay) else ()
let $doc    := if ($essay)
               then
                 nwn:patch-metadata($pbody/db:essay)
               else $pbody

let $perms := (xdmp:permission("weblog-reader", "read"),
               xdmp:permission("weblog-editor", "read"),
               xdmp:permission("weblog-editor", "update"))

return
  if ($wfxml and empty($notvalid))
  then
    (versions:store($doc, $uri),
     xdmp:document-insert($stage, $doc, ($perms), ($coll, $extrac)),
     <success>
       <uri>{$stage}</uri>
       <type>{$type}</type>
       <format>{$format}</format>
       <this>{$uri}</this>
     </success>)
  else
    (xdmp:set-response-code(400, concat("Invalid essay: ", $notvalid)),
     <fail>
       <uri>{$stage}</uri>
       <type>{$type}</type>
       <format>{$format}</format>
       <this>{$uri}</this>
       <message>{$notvalid}</message>
     </fail>)
