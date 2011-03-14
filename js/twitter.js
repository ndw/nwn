var profilepics = new Object();
var tweets = new Object();

$(document).ready(function() {
    findTweets();
});

function findTweets() {
    $("div.tweet span.attribution a").each(function() {
        addImage(this);
    });
}

function addImage(anchor) {
    var id = $(anchor).text();
    var asktwitter = false;

    if (id in profilepics) {
        updateHtml(anchor, id);
        return;
    }

    if (! (id in tweets)) {
        asktwitter = true;
        tweets[id] = new Array();
    }
    tweets[id].push(anchor)

    if (asktwitter) {
        $.getJSON("http://api.twitter.com/1/users/show.json?id=" + id + "&callback=?", null, gotProfile);
        /*
        var x = new Object();
        x.screen_name = id;
        x.profile_image_url = "http://a1.twimg.com/profile_images/1265029326/Avatar-13_normal.png";
        gotProfile(x);
        */
    }
}

function gotProfile(data) {
    id = data.screen_name;
    image = data.profile_image_url;
    profilepics[id] = image;
    for (var pos in tweets[id]) {
        updateHtml(tweets[id][pos], id);
    }
}

function updateHtml(anchor, id) {
    var div = $(anchor).parent().parent();
    div.prepend("<img height='48' align='right' src='" + profilepics[id] + "' alt='profile pic' />");
}
