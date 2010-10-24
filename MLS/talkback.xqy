xquery version "1.0-ml";

import module namespace nwn="http://norman.walsh.name/ns/modules/utils"
       at "nwn.xqy";

declare namespace html="http://www.w3.org/1999/xhtml";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare function local:addp($nodes as node()*) as node()* {
  if ($nodes/self::p or $nodes/self::html:p)
  then
    $nodes
  else
    <p xmlns="http://www.w3.org/1999/xhtml">{$nodes}</p>
};

declare function local:trimws($nodes as node()*) as node()* {
  let $nfirst := $nodes[1]
  let $middle := if (count($nodes) > 2) then $nodes[2 to count($nodes)-1] else ()
  let $nlast  := if (count($nodes) > 1) then $nodes[last()] else ()
  return
    (if (not(empty($nfirst)) and xdmp:node-kind($nfirst) = "text")
     then
       if (normalize-space($nfirst) = "")
       then ()
       else text { replace($nfirst, "^\s+(.*)$", "$1", "s") }
     else
       $nfirst,
     $middle,
     if (not(empty($nlast)) and xdmp:node-kind($nlast) = "text")
     then
       if (normalize-space($nlast) = "")
       then ()
       else text { replace($nlast, "^(.*[^\s])\s+$", "$1", "s") }
     else
       $nlast)
};

declare function local:filter($nodes as node()*) as node()* {
  for $node in $nodes
  return
    if (xdmp:node-kind($node) = "element")
    then
      if ($node/self::html:a or $node/self::html:abbr or $node/self::html:b
          or $node/self::html:br or $node/self::html:code or $node/self::html:em
          or $node/self::html:i or $node/self::html:p or $node/self::html:pre
          or $node/self::html:strong or $node/self::html:var)
      then
        element { node-name($node) }
                { if ($node/self::html:a) then $node/@href else (),
                  local:filter($node/node()) }
      else
        local:filter($node/node())
  else
    $node
};

declare function local:get-value($name, $value, $default) {
  if (not(empty($value)))
  then
    $value
  else
    if (not(empty(local:cookie-value($name))))
    then
      local:cookie-value($name)
    else
      $default
};

declare variable $MATHANSWERS
  := ("one", "two", "three", "four", "five", "six", "seven",
      "eight", "nine", "ten", "eleven", "twelve", "thirteen",
      "fourteen", "fifteen", "sixteen", "seventeen", "eighteen",
      "nineteen", "twenty", "twenty-one", "twenty-two",
      "twenty-three", "twenty-four", "twenty-five", "twenty-six",
      "twenty-seven", "twenty-eight", "twenty-nine", "thirty",
      "thirty-one", "thirty-two", "thirty-three", "thirty-four",
      "thirty-five", "thirty-six", "thirty-seven", "thirty-eight",
      "thirty-nine", "forty", "forty-one", "forty-two", "forty-three",
      "forty-four", "forty-five", "forty-six", "forty-seven",
      "forty-eight", "forty-nine", "fifty", "fifty-one", "fifty-two",
      "fifty-three", "fifty-four", "fifty-five", "fifty-six",
      "fifty-seven", "fifty-eight", "fifty-nine", "sixty",
      "sixty-one", "sixty-two", "sixty-three", "sixty-four",
      "sixty-five", "sixty-six", "sixty-seven", "sixty-eight",
      "sixty-nine", "seventy", "seventy-one", "seventy-two",
      "seventy-three", "seventy-four", "seventy-five", "seventy-six",
      "seventy-seven", "seventy-eight", "seventy-nine", "eighty",
      "eighty-one", "eighty-two", "eighty-three", "eighty-four",
      "eighty-five", "eighty-six", "eighty-seven", "eighty-eight",
      "eighty-nine", "ninety", "ninety-one", "ninety-two",
      "ninety-three", "ninety-four", "ninety-five", "ninety-six",
      "ninety-seven", "ninety-eight", "ninety-nine");

declare variable $OPS := ("times", "plus", "minus");

declare variable $NUMBERS := ("one","two","three","four",
		              "five","six","seven","eight","nine","ten");

declare variable $submit    := xdmp:get-request-field("submit");
declare variable $remember  := local:get-value("remember", xdmp:get-request-field("remember"), "");
declare variable $sawform   := xdmp:get-request-field("sawform");
declare variable $page      := xdmp:get-request-field("page");
declare variable $okcomment := xdmp:get-request-field("okcomment");
declare variable $bingo     := if (xdmp:get-request-field("bingo") castable as xs:decimal)
                               then xs:decimal(xdmp:get-request-field("bingo"))
                               else 2;
declare variable $astr      := if (empty(xdmp:get-request-field("a")))
                               then xdmp:random(9)+1 else xdmp:get-request-field("a");
declare variable $bstr      := if (empty(xdmp:get-request-field("b")))
                               then xdmp:random(9)+1 else xdmp:get-request-field("b");
declare variable $opstr     := if (empty(xdmp:get-request-field("op")))
                               then xdmp:random(2)+1 else xdmp:get-request-field("op");
declare variable $anum      := if ($astr castable as xs:decimal)
                               then xs:decimal($astr) else xdmp:random(9)+1;
declare variable $bnum      := if ($bstr castable as xs:decimal)
                               then xs:decimal($bstr) else xdmp:random(9)+1;
declare variable $opnum     := if ($opstr castable as xs:decimal)
                               then xs:decimal($opstr) else xdmp:random(2)+1;
declare variable $a         := if ($anum > $bnum) then $anum else $bnum;
declare variable $b         := if ($anum > $bnum) then $bnum else $anum;
declare variable $op        := if ($opnum >= 1 and $opnum <= 3) then $opnum else xdmp:random(2)+1;
declare variable $inline    := xdmp:get-request-field("inline");
declare variable $name      := local:get-value("name", xdmp:get-request-field("name"), "");
declare variable $email     := xdmp:get-request-field("email");
declare variable $captcha   := xdmp:get-request-field("captcha");
declare variable $homepage  := xdmp:get-request-field("homepage");
declare variable $usercomment
  := if (xdmp:get-request-field("comment"))
     then xdmp:tidy(xdmp:get-request-field("comment"))[2]/html:html/html:body/node()
     else text { "" };
declare variable $comment   := local:addp(local:filter(local:trimws($usercomment)));

declare variable $correctMath := (normalize-space($captcha) = "")
                                 or (if (matches($captcha, "^\d+$"))
                                     then xs:decimal($captcha)*2 = $bingo
                                     else $MATHANSWERS[$bingo div 2] = $captcha);

declare variable $rawcomment := nwn:fix-namespace($comment, "http://www.w3.org/1999/xhtml", "");
declare variable $txtcomment := string-join(for $node in $rawcomment return xdmp:quote($node), "");
declare variable $enccomment := xdmp:crypt($txtcomment, "sodium chloride");
declare variable $okpage     := doc-available(concat("/production", $page, ".xml"));
declare variable $oksubmit   := $enccomment = $okcomment;

declare variable $errors
  := if ($sawform != "1")
     then ()
     else
       (if (normalize-space($name) = "")
        then <span ref="name"> You must provide your name. </span>
        else (),
        if (normalize-space($email) = "")
        then <span ref="email"> You must provide your email address. </span>
        else (),
        if (not(matches($email, "^[^@]+@[^@]+\.[a-z]+$")))
        then <span ref="email"> That email address looks bogus to me. </span>
        else (),
        if (normalize-space($txtcomment) = "")
        then <span ref="comment">What's the point if you've nothing to say?.</span>
        else (),
        if (not($correctMath))
        then <span ref="captcha"> Ok, let's try a different math question. </span>
        else ());

declare function local:error($ref as xs:string) as element(html:span)? {
  if ($errors[@ref=$ref])
  then
    <span class="error" xmlns="http://www.w3.org/1999/xhtml">
      { ($errors[@ref=$ref])[1]/node() }
    </span>
  else
    ()
};

declare function local:errorattr($ref as xs:string) as attribute()? {
  if ($errors[@ref=$ref])
  then
    attribute { QName("", "class") } { "error" }
  else
    ()
};

declare function local:format-cookie() as xs:string {
  let $params := (<name>{$name}</name>, <email>{$email}</email>,
                  <homepage>{$homepage}</homepage>, <remember>{$remember}</remember>)
  let $params := for $p in $params
                 return
                   xdmp:base64-encode(concat(local-name($p), "=", string($p)))
  return
    concat("remember-me=", string-join($params, ","), ";path=/")
};

declare function local:cookie-value($param as xs:string) as xs:string? {
  let $cookie := string-join(xdmp:get-request-header("Cookie"), ";")
  let $value  := substring-after($cookie, "remember-me=")
  let $cookie := if (contains($value, ";")) then substring-before($value,";") else $value
  let $params := for $p in tokenize($cookie, ",")
                 return
                   try {
                     xdmp:base64-decode($p)
                   } catch ($e) {
                     ""
                   }
  let $value  := for $p in $params
                 return
                   if (starts-with($p, concat($param,"=")))
                   then
                     substring-after($p, "=")
                   else
                     ()
  return
    $value[1]
};

declare function local:drawForm() as element(html:html) {
  let $anum   := if ($correctMath) then $a else xdmp:random(9)+1
  let $bnum   := if ($correctMath) then $b else xdmp:random(9)+1
  let $a      := if ($anum > $bnum) then $anum else $bnum
  let $b      := if ($anum > $bnum) then $bnum else $anum
  let $op     := if ($correctMath) then $op else xdmp:random(2)+1
  let $answer := if ($OPS[$op] = "times") then $a * $b
                 else if ($OPS[$op] = "plus") then $a + $b
                 else $a - $b
  return
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>Your comment</title>
      { nwn:css-links() }
      <link rel='stylesheet' type='text/css' href='/css/readercomment.css' />
    </head>
    <body>
      { nwn:banner((), "Your comment", (), ()) }
      <div id='readercomment'>
        <h2>Preview</h2>
        <div id='comments'>
          <h2>Comment:</h2>
          <div class='comment'>
            { $comment }
            <div class='name'>Posted by {$name}</div>
          </div>
        </div>

        <form action='/cgi-bin/talkback' method='POST'>
          { if ($correctMath and $captcha != "" and empty($errors))
            then
              (<input type="submit" value="Submit comment" name="submit" />,
               " (Submit will post the comment as it appears above.)",
               if (not($oksubmit))
               then
                 <p>You changed the comment, please proof it again and resubmit.</p>
               else
                 ())
            else
              ()
          }
          <input type='hidden' name='sawform' value='1' />
          <input type='hidden' name='page' value='{$page}' />
          <input type='hidden' name='okcomment' value='{$enccomment}'/>
          <input type='hidden' name='bingo' value='{$answer*2}' />
          <input type='hidden' name='a' value='{$a}' />
          <input type='hidden' name='b' value='{$b}' />
          <input type='hidden' name='op' value='{$op}' />
          <h1>Comment</h1>
          { if ($inline = "1")
            then
              <p>Almost done; please proofread your comment,
                 complete the math question below, and press 'Update comment'
                 to continue.</p>
            else
              ()
          }
          <table border='0' summary='Form design' cellspacing="0" cellpadding="3">
            <tr>
              { local:errorattr('name') }
              <td valign='top'>Name:</td>
              <td><input type='text' name='name' size='40' maxlength='80' value='{$name}'/>
              { local:error('name') } </td>
            </tr>
            <tr>
              { local:errorattr('name') }
              <td valign='top'>Email<sup>*</sup>:</td>
              <td><input type='text' name='email' size='40' maxlength='80' value='{$email}'/>
              { local:error('email') } </td>
            </tr>
            <tr>
              <td>&#160;</td>
              <td><sup>*</sup>Please provide your real email address;
              it will not be displayed as part of the comment.</td>
            </tr>
            <tr>
              <td valign='top'>Homepage:</td>
              <td><input type='text' name='homepage' size='72' maxlength='128' value='{$homepage}'/></td>
            </tr>
            <tr>
              { local:errorattr('name') }
              <td valign='top'>Comment<sup>**</sup>:</td>
              <td>
                <textarea name='comment' rows='12' cols='72'>
                { string-join(for $node in $rawcomment return xdmp:quote($node), "") }
                </textarea>
                { if ($errors[@ref='comment'])
                  then
                    (<br/>,local:error('comment'))
                  else
                    ()
                }
              </td>
            </tr>
            <tr>
              <td>&#160;</td>
              <td><sup>**</sup>The following markup may be used in the body of the
              comment: a, abbr, b, br, code, em, i, p, pre, strong,  and var. You can
              also use character entities. Any other markup
              will be discarded, including all attributes
              (except <code>href</code> on <code>a</code>).
              Your tag soup will be sanitized...
              </td>
            </tr>
            <tr>
              { local:errorattr('captcha') }
              <td colspan='2'>What is {concat($NUMBERS[$a], " ", $OPS[$op], " ", $NUMBERS[$b])}?
              <input type='text' name='captcha' size='16' maxlength='16' value='{$captcha}'/>
              { local:error('captcha') }
              </td>
            </tr>
            <tr><td>&#160;</td><td>In an effort to reduce the amount of comment spam
            submitted by bots, I'm trying out a simple
            <a href='http://en.wikipedia.org/wiki/Captcha'>CAPTCHA</a>
            system. In order to submit your comment, you must answer the
            simple math question above. For example, if asked "What is the
            two plus five?", you would enter 7.
            </td>
            </tr>
            <tr>
              <td colspan='2'>
                <input type='checkbox' name='remember' value="1">
                { if ($remember = "1")
                  then
                    attribute { QName("","checked") } { "checked" }
                  else
                    ()
                }
                </input> Remember me?
              (Want a cookie?)</td>
            </tr>
          </table>
          <p><input name='submit' type='submit' value='Update comment'/>
          &#160;(There must be no errors before you submit.)</p>
        </form>
        {(:
        <ul>
          { for $name in xdmp:get-request-field-names()
            return
              <li>{$name}: {xdmp:get-request-field($name)}</li>
          }
          <li>enc: {$enccomment}</li>
          <li>oksubmit: {$oksubmit}</li>
          { for $f in $errors return <li>{$f}</li> }
        </ul>
        :)}
      </div>
      <div>
        <p class="body-content">The body of the essay you are commenting on appears below.
        Certain features, such as the navigation, are not
        supported in this preview. I might someday fix that. Or not.
        </p>
        <hr/>
        { doc(concat("/cached/production", $page, ".html")) }
      </div>
    </body>
  </html>
};

declare function local:errorPage() as element(html:html) {
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>Your comment</title>
      { nwn:css-links() }
      <link rel='stylesheet' type='text/css' href='/css/readercomment.css' />
    </head>
    <body>
      { nwn:banner((), "Your comment", (), ()) }
      <div id='readercomment'>
        <h1>Preview</h1>
        <div id='comments'>
          <h2>Comment:</h2>
          <div class='comment'>
            { $comment }
            <div class='name'>Posted by {$name}</div>
          </div>
        </div>
        <p>You can't comment on that page, it doesn't exist.</p>
      </div>
    </body>
  </html>
};

declare function local:postComment() as element(html:html) {
  let $uri    := concat("/comments", $page, ".xml")

  let $count  := count(cts:uri-match(concat("/production/comments", $page, ".*")))
                  + count(cts:uri-match(concat("/staging/comments", $page, ".*")))
                  + count(cts:uri-match(concat("/rejected/comments", $page, ".*")))
  let $num    := format-number($count+1, "0000")

  let $Z      := xs:dayTimeDuration("PT0H")
  let $nowz   := adjust-dateTime-to-timezone(current-dateTime(), $Z)
  let $tstamp := format-dateTime($nowz, "[Y0001]-[M01]-[D01]/[H01]-[m01]-[s01]")
  let $this   := concat("/versions/comments/", $tstamp, $page, ".", $num, ".xml")
  let $stage  := concat("/staging/comments", $page, ".", $num, ".xml")

  let $now    := adjust-dateTime-to-timezone(current-dateTime(), xs:dayTimeDuration("PT0H"))
  let $nowstr := format-dateTime($now, "[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]Z")
  let $alturi := concat("http://norman.walsh.name", $page, "#comment", $num)
  let $cookie := if ($remember = "1")
                 then
                   local:format-cookie()
                 else
                   ()
  let $entry
    := <entry xml:lang="en" xmlns="http://purl.org/atom/ns#">
         <title>Comment {$num} on {$page}</title>
         <link rel="alternate" type="text/html" href="{$alturi}"/>
         <id>{$alturi}</id>
         <issued>{$nowstr}</issued>
         <modified>{$nowstr}</modified>
         <author>
           <name>{$name}</name>
           <email>{$email}</email>
           { if (normalize-space($homepage) = "")
             then ()
             else <uri>{normalize-space($homepage)}</uri>
           }
         </author>
         <atom:content type="text/html" mode="xml" xmlns:atom="http://purl.org/atom/ns#" xmlns="">
           { $rawcomment }
         </atom:content>
       </entry>

  let $extrac := "http://norman.walsh.name/ns/collections/comment"
  let $tcoll  := "http://norman.walsh.name/ns/collections/versions"
  let $coll   := "http://norman.walsh.name/ns/collections/staging"

  let $rperm  := xdmp:permission("weblog-reader", "read")
  let $uperm  := xdmp:permission("weblog-editor", "update")

  return
    (xdmp:document-insert($this, $entry, ($rperm, $uperm), ($tcoll, $extrac)),
     xdmp:document-insert($stage, $entry, ($rperm, $uperm), ($coll, $extrac)),
     if (empty($cookie))
     then ()
     else xdmp:add-response-header("Set-Cookie", $cookie),
     <html xmlns="http://www.w3.org/1999/xhtml">
       <head>
         <title>Thank you for your comment</title>
         { nwn:css-links() }
         <meta http-equiv='refresh' content="2;url={$page}"/>
         <link rel='stylesheet' type='text/css' href='/css/readercomment.css' />
       </head>
       <body>
         { nwn:banner((), "Thank you for your comment", (), ()) }
         <div id="content">
           <p>Thank you for your comment on
           <a href="{$page}">{$page}</a>. We'll take you back there in
           just a moment.</p>
         </div>
       </body>
     </html>)
};

if ($okpage)
then
  if ($submit = "Submit comment" and $oksubmit)
  then
    local:postComment()
  else
    local:drawForm()
else
  local:errorPage()
