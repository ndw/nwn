xquery version "1.0-ml";

let $uri := xdmp:get-request-field("uri")
return
  if (doc-available($uri))
  then
    doc($uri)
  else
    error(xs:QName("error:NOURI"), "There's no document with that uri.")
