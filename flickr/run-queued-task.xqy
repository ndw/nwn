xquery version "1.0-ml";

import module namespace flickr="http://www.flickr.com/services/api/"
       at "/flickr.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $perms := (xdmp:permission("weblog-reader", "read"),
                            xdmp:permission("weblog-editor", "read"),
                            xdmp:permission("weblog-editor", "update"));

declare variable $maxtasks := 1; (: Only doing one now, while debugging the task server problems :)
declare variable $tasklist := cts:search(collection(), cts:directory-query("/tasks/", "1"));
declare variable $tasks    := $tasklist[1 to $maxtasks];

declare function local:run-task($index as xs:int, $task as element()) {
  let $trace := xdmp:log(concat("Running queued task (", $index, " of ", $maxtasks, "; ", count($tasklist), " remain): ", xdmp:node-uri($task)))
  return
  typeswitch ($task)
    case element(flickr:update-user-photos)
         return local:update-user-photos($task)
    case element(flickr:get-user-photos)
         return local:get-user-photos($task)
    default
         return $task
};


declare function local:update-user-photos($task as element(flickr:update-user-photos)) {
  let $userid  := string($task/@userid)
  let $perpage := 500
  let $photos  := flickr:people.getPublicPhotos($userid, (), $perpage, 1)
  let $divpage := xs:integer($photos/@total) idiv $perpage
  let $pages   := if (xs:integer($photos/@total) mod $perpage = 0) then $divpage else $divpage + 1
  return
    (for $page in (1 to $pages)
     return
       xdmp:document-insert(concat("/tasks/get-user-photos-", $userid, "-", $page, ".xml"),
                            <flickr:get-user-photos page="{$page}" perpage="{$perpage}"
                                                    userid="{$userid}"/>,
                            $perms),
     xdmp:document-delete(xdmp:node-uri($task)),
     concat("Queued ", $pages, " pages for ", $userid),
     xdmp:log(concat("Queued ", $pages, " pages for ", $userid)))
};

declare function local:get-user-photos($task as element(flickr:get-user-photos)) {
  let $userid  := string($task/@userid)
  let $perpage := xs:integer($task/@perpage)
  let $page    := xs:integer($task/@page)
  let $photos  := flickr:people.getPublicPhotos($userid, "last_update", $perpage, $page)
  let $updates
    := for $photo in $photos/flickr:photo
       let $uri := concat("/photos/", $photo/@owner, "/", $photo/@secret, "/", $photo/@id, ".xml")
       return
         if (doc-available($uri))
         then
           let $xphoto := doc($uri)/flickr:photo
           let $updated := $xphoto/flickr:dates/@lastupdate
           return
             if ($updated = $photo/@lastupdate)
             then
               <up-to-date>{$uri}</up-to-date>
             else
               let $data := local:get-photo-data($photo)
               return
                 (xdmp:node-replace($xphoto, $data), <updated>{$uri}</updated>)
         else
           let $data := local:get-photo-data($photo)
           return
             if ($data/self::flickr:photo)
             then
               (xdmp:document-insert($uri, $data, $perms), <inserted>{$uri}</inserted>)
             else
               (xdmp:log("get-user-photos error:"), xdmp:log($photo))
  let $message
    := concat($userid, "/", $perpage, "/", $page, ": ",
              count($updates), " photos; ",
              count($updates/self::inserted), " new, ",
              count($updates/self::updated), " updated, ",
              count($updates/self::up-to-date), " up-to-date.")
  return
    (xdmp:document-delete(xdmp:node-uri($task)), xdmp:log($message), $message)
};

declare function local:get-photo-data($photo as element(flickr:photo)) as element(flickr:photo) {
  let $metadata := flickr:photos.getInfo($photo/@id, $photo/@secret)
  let $sizes    := flickr:photos.getSizes($photo/@id)
  return
    <photo xmlns="http://www.flickr.com/services/api/">
      { $metadata/@* }
      { $metadata/node() }
      { $sizes }
    </photo>
};

if (empty($tasks))
then
  ()
else
   for $task at $index in $tasks
   return
     local:run-task($index, $task/*)
