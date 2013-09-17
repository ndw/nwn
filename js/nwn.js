/* -*- JavaScript -*-
# The leading '#'s are just for consistency with other text formats
#
# rdf:
# dc:title General scripting support for norman.walsh.name
# dc:date 2004-03-19
# cvs:date $Date$
# dc:creator http://norman.walsh.name/knows/who#norman-walsh
# dc:description JavaScript for stylesheet switching. Stolen from ongoing. Reworked to use JQuery
*/

function addpLink(elem, id) {
    var last = $(elem).contents().last();
    if ($(last).get(0).nodeType == 1) {
        //console.log("recurse: ", last)
        addpLink(last, id)
    } else {
        //console.log("add link: ", last)
        //console.log("TEXT [", last.text(), "] ", last.text().length)
        var trimmed = last.text().replace(/\s+$/, "")
        trimmed = trimmed.replace(/&/g, "&amp;")
        trimmed = trimmed.replace(/</g, "&lt;")
        //console.log("TRIM [", trimmed, "] ", trimmed.length)
        last.replaceWith(trimmed)
        $(elem).append("<a class='plink' href='#" + id + "'>&#160;¶</a>");
    }
}

function addpLinks() {
    $("p[id]").each(function(){
        addpLink(this, $(this).attr("id"))
    });
}

function inlineComment() {
    $("#newcomment").css("display", "block");
    $("#addcommentlink").before("Add");
    $("#addcommentlink").remove();
}

$(document).ready(function() {
    addpLinks();
});
