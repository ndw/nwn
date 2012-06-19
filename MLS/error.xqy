xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "/nwn.xqy";

import module namespace audit="http://norman.walsh.name/ns/modules/audit"
       at "/audit/audit.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $error:errors as node()* external;
declare variable $code := xdmp:get-response-code()[1];
declare variable $uri := xdmp:get-request-url();
declare variable $verb := xdmp:get-request-method();

let $audit := audit:http($verb, $uri, $code, $error:errors)
return
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>
        { if ($code = 404)
          then "Resource not found"
          else "Well that went all pear shaped"
        }
      </title>
      { nwn:css-links() }
    </head>
    <body>
      { nwn:banner((),
                   if ($code = 404)
                   then concat("Resource not found: ", $uri)
                   else concat("Well that went all pear shaped (", $code, ")"),
                   (), ())
      }
      <div id="content">
        <div class="abstract">
          <p>We apologize for the inconvenience...</p>
        </div>

        { if ($code = 404)
          then
            <p>There's nothing here with that name. I've reported the problem, perhaps
            Norm will be able to get it online.</p>
          else
            <p>Sorry, that's a bug. My bad. I've reported the problem, Norm will get
            on it as soon as possible.</p>
        }

        { if (nwn:show-staging())
          then
            <div class="errors">
              { for $err in $error:errors
                return
                  xdmp:xslt-invoke("format-error.xsl", $err)/*
              }
            </div>
          else
            ()
        }
      </div>
      { nwn:footer() }
    </body>
  </html>
