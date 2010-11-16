xquery version "1.0-ml";

import module namespace flickr="http://www.flickr.com/services/api/"
       at "/flickr.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare variable $me
  := <flickr:contact nsid="24401095@N00" username="ndw"
                     realname="Norm Walsh" path_alias="ndw"
                     location="Belchertown, United States"/>;

declare option xdmp:mapping "false";

let $contacts := ($me, flickr:contacts.getList((), 1000, ())/flickr:contact)
return
  (for $contact in $contacts
   return
     (xdmp:document-insert(concat("/flickr/contacts/", $contact/@nsid, ".xml"), $contact),
      xdmp:document-insert(concat("/tasks/update-user-photos-", $contact/@nsid, ".xml"),
                           <flickr:update-user-photos userid="{$contact/@nsid}"/>)),
   concat("Read ", count($contacts), " users."),
   xdmp:log(concat("Read ", count($contacts), " users.")))

