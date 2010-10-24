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

function addpLinks() {
    $("p[id]").each(function(){
        $(this).append("<a class='plink' href='#" + $(this).attr("id") + "'> ¶</a>");
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
