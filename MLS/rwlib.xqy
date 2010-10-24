xquery version "1.0-ml";

module namespace rwlib="http://norman.walsh.name/ns/modules/rwlib";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare function rwlib:rewrite($uri as xs:string, $opts as element(rwlib:options))
as xs:string?
{
  rwlib:rewrite(xdmp:get-request-method(), $uri, $opts)
};

declare function rwlib:rewrite($method as xs:string,
                               $uri as xs:string,
                               $opts as element(rwlib:options))
as xs:string?
{
  rwlib:do_rewrite($method, $uri, $opts/rwlib:map)
};

declare function rwlib:do_rewrite($method as xs:string,
                                  $uri as xs:string,
                                  $maps as element(rwlib:map)*)
as xs:string?
{
  let $map := $maps[1]
  let $rest := $maps[position() > 1]
  return
    if (empty($map))
    then
      ()
    else
      if ((not($map/@method) or ($map/@method = $method)) and matches($uri, $map/rwlib:pattern))
      then
        let $match := rwlib:and($uri, $map/rwlib:pattern,
                                $map/*[not(self::rwlib:pattern) and not(self::rwlib:replace)])
        return
          if ($match)
          then
            replace($uri, $map/rwlib:pattern, $map/rwlib:replace)
          else
            rwlib:do_rewrite($method, $uri, $rest)
      else
        rwlib:do_rewrite($method, $uri, $rest)
};

declare function rwlib:apply($uri as xs:string,
                             $pattern as xs:string,
                             $conditions as element()*)
as xs:boolean*
{
  for $cond in $conditions
  return
    typeswitch($cond)
    case element(rwlib:or) return rwlib:or($uri, $pattern, $cond/*)
    case element(rwlib:and) return rwlib:and($uri, $pattern, $cond/*)
    case element(rwlib:exists) return rwlib:exists(replace($uri, $pattern, $cond))
    case element(rwlib:dir-exists) return rwlib:dir-exists(replace($uri, $pattern, $cond))
    case element(rwlib:function) return rwlib:function(replace($uri, $pattern, $cond), $cond)
    case element(rwlib:privilege) return rwlib:privilege($cond)
    default return error(xs:QName("rwlib:ERROR"),
                         concat("Unexpected conditional: ", node-name($cond)))
};

declare function rwlib:and($uri as xs:string,
                           $pattern as xs:string,
                           $conditions as element()*)
as xs:boolean
{
  let $fail := for $result in rwlib:apply($uri, $pattern, $conditions)
               return
                 if (not($result))
                 then false()
                 else ()
  return
    empty($fail)
};

declare function rwlib:or($uri as xs:string,
                          $pattern as xs:string,
                          $conditions as element()*)
as xs:boolean
{
  let $pass := for $result in rwlib:apply($uri, $pattern, $conditions)
               return
                 if ($result)
                 then true()
                 else ()
  return
    not(empty($pass))
};

declare function rwlib:exists($uri as xs:string) as xs:boolean
{
  doc-available($uri)
};

declare function rwlib:dir-exists($uri as xs:string) as xs:boolean
{
  not(empty(xdmp:directory-properties($uri)))
};

declare function rwlib:function($uri as xs:string,
                                $condition as element())
as xs:boolean
{
  let $f := xdmp:function(QName($condition/@ns, $condition/@apply), $condition/@at)
  return
    xdmp:apply($f, $uri, $condition) cast as xs:boolean
};

declare function rwlib:privilege($condition as element()) as xs:boolean
{
  xdmp:has-privilege($condition/@uri, $condition)
};
