/* -*- JavaScript -*-
# The leading '#'s are just for consistency with other text formats
#
# rdf:
# dc:title Staging scripts
# dc:date 2010-10-24
# dc:creator http://norman.walsh.name/knows/who#norman-walsh
# dc:description JavaScript for staged essays.
*/

function checkUpToDate() {
    var docuri = $("meta[name='document.uri']").attr("content");
    $.getJSON("/ajax/lm.xqy", { "uri": docuri }, upToDateCallback);
}

function upToDateCallback(data) {
    var lmtime = $("meta[name='lastmodified.time']").attr("content");
    if (lmtime === data.lm) {
        // Ok, still up-to-date
    } else {
        $("body").stopTime();
        window.location.href = window.location.href;
    }
}

$(document).ready(function() {
    $("body").everyTime("1s", checkUpToDate)
});
