xquery version "1.0-ml";

import module namespace audit="http://norman.walsh.name/ns/modules/audit"
       at "/audit/audit.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare function local:errors($age as xs:dateTime) {
  let $agequery := cts:element-range-query(xs:QName("audit:datetime"), ">=", $age)
  let $codes    := cts:element-values(xs:QName("audit:code"), (), (), $agequery)
  return
    <dl>
      { for $code in $codes
        let $codequery := cts:element-value-query(xs:QName("audit:code"),string($code))
        let $query := cts:and-query(($codequery, $agequery))
        return
          (<dt>Code: {$code} ({xdmp:estimate(cts:search(/audit:http, $query))} reports)</dt>,
           if ($code = 200)
           then
             ()
           else
             <dd>
               <dl>
                 { let $uris := cts:element-values(xs:QName("audit:uri"), (), (), $query)
                   for $uri in $uris
                   let $uriquery := cts:element-value-query(xs:QName("audit:uri"),$uri)
                   let $matching := cts:search(/audit:http,
                                               cts:and-query(($query, $uriquery)))
                   return
                     (<dt>{ $uri }, ({count($matching)} reports)</dt>,
                      <dd>
                        <ul>
                          { for $report in $matching
                            order by $report/audit:datetime descending
                            return
                              <li>
                                <a href="{xdmp:node-uri($report)}">{xdmp:node-uri($report)}</a>
                              </li>
                          }
                        </ul>
                      </dd>)
                 }
               </dl>
             </dd>)
      }
    </dl>
};

let $now := current-dateTime()
return
  <div xmlns="http://www.w3.org/1999/xhtml">
    <h3>In the last hour...</h3>
    { local:errors($now - xs:dayTimeDuration("PT1H")) }
    <h3>In the last day...</h3>
    { local:errors($now - xs:dayTimeDuration("P1D")) }
{(:
    <h3>In the last week...</h3>
    { local:errors($now - xs:dayTimeDuration("P7D")) }
    <h3>In the last month...</h3>
    { local:errors($now - xs:dayTimeDuration("P31D")) }
:)}
  </div>
