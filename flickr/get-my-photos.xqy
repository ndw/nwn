xquery version "1.0-ml";

import module namespace flickr="http://www.flickr.com/services/api/"
       at "/flickr.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $me as xs:string external;
declare variable $photos as element() external;

declare variable $perms := (xdmp:permission("weblog-reader", "read"),
                            xdmp:permission("weblog-editor", "read"),
                            xdmp:permission("weblog-editor", "update"));

declare function local:get-photo-list($userid as xs:string) as element(flickr:photos) {
  let $perpage := 500
  let $photos  := flickr:people.getPublicPhotos($userid, (), $perpage, 1)
  let $divpage := xs:integer($photos/@total) idiv $perpage
  let $pages   := if (xs:integer($photos/@total) mod $perpage = 0) then $divpage else $divpage + 1
  return
    <flickr:photos>
      { local:new-photo-list($photos/flickr:photo) }
      { for $page in (2 to $pages)
        return
          local:new-photo-list(flickr:people.getPublicPhotos($userid, (), $perpage, $page)/flickr:photo)
      }
    </flickr:photos>
};

declare function local:new-photo-list($photos as element(flickr:photo)*) as element(flickr:photo)* {
  for $photo in $photos
  let $uri := concat("/photos/", $photo/@owner, "/", $photo/@secret, "/", $photo/@id, ".xml")
  return
    if (doc-available($uri))
    then
      ()
    else
      $photo
};

declare function local:get-user-photos($photos as element(flickr:photo)*) as empty-sequence() {
  let $updates
    := for $photo in $photos
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
               let $photo := flickr:photos.getInfo($photo/@id, $photo/@secret)
               return
                 (xdmp:node-replace($xphoto, $photo), <updated>{$uri}</updated>)
         else
           let $photo := flickr:photos.getInfo($photo/@id, $photo/@secret)
           return
             if ($photo/self::flickr:photo)
             then
               (xdmp:document-insert($uri, $photo, $perms), <inserted>{$uri}</inserted>)
             else
               (xdmp:log("get-user-photos error:"), xdmp:log($photo))
  let $message
    := concat(count($updates), " photos; ",
              count($updates/self::inserted), " new, ",
              count($updates/self::updated), " updated, ",
              count($updates/self::up-to-date), " up-to-date.")
  return
    xdmp:log($message)
};

declare function local:get-photo-data($photo as element(flickr:photo)) {
  let $metadata := flickr:photos.getInfo($photo/@id, $photo/@secret)
  let $sizes    := flickr:photos.getSizes($photo/@id)
  return
    <photo xmlns="http://www.flickr.com/services/api/">
      { $metadata/@* }
      { $metadata/node() }
      { $sizes }
    </photo>
};

if ($photos/self::empty)
then
  let $photos := local:get-photo-list($me)
  return
    (concat("Spawned request to download ", count($photos/*), " of my photos."),
     xdmp:log(concat("Spawned request to download ", count($photos/*), " of my photos.")),
     xdmp:spawn("/get-my-photos.xqy", (fn:QName("","me"), $me, fn:QName("","photos"), $photos)))
  else
    local:get-user-photos($photos/*)

