/* -*- JavaScript -*-
# The leading '#'s are just for consistency with other text formats
#
# rdf:
# dc:title Google mapping functions
# dc:date 2010-12-13
# dc:creator http://norman.walsh.name/knows/who/norman-walsh
# dc:description Utility routines for Google Map plots. Updated for Google Maps V3.
*/

var colors = ["red", "blue", "green", "orange", "cyan", "pink", "purple", "yellow"];

var ndwid = "24401095@N00";

var imageMarkers = new Object();
var photoColors = new Object();
var colorIdx = 1;
var localMarkers = new Array();
var markerDiv = "";
var photographerCount = 0;

var mapdata;
var map;
var lastUpdate = new Date();
var timerRunning = false;

function plotTracks(mparam, divid) {
    mapdata = mparam;

    var latlng = new google.maps.LatLng(mapdata.centerlat, mapdata.centerlng);
    var bounds = new google.maps.LatLngBounds(latlng, latlng);
    var mapopts = {
        zoom: mapdata.zoom,
        center: latlng,
    };

    if (mapdata.type == "terrain") {
        mapopts.mapTypeId = google.maps.MapTypeId.TERRAIN
    } else { // FIXME: deal with the other types...
        mapopts.mapTypeId = google.maps.MapTypeId.ROADMAP
    }

    map = new google.maps.Map(document.getElementById(divid), mapopts);

    for (var pos = 0; pos < mapdata.tracks.length; pos++) {
        var track = mapdata.tracks[pos];
        var points = new Array();
        for (var ppos = 0; ppos < track.length; ppos++) {
            var pt = track[ppos];
            latlng = new google.maps.LatLng(pt.lat,pt.lng);
            bounds.extend(latlng);
            points.push(trkPt(map,pt.lat,pt.lng,pt.ele,pt.time,pt.dist,pt.velocity,pt.count));
        }

        var lopts = {
            path: points,
            strokeColor: mapdata.trackColor,
            strokeWeight: mapdata.strokeWeight,
            strokeOpacity: mapdata.strokeOpacity
        }

        if (mapdata.lastTrackColor != null && pos+1 == mapdata.tracks.length) {
            lopts.strokeColor = mapdata.lastTrackColor;
        }

        var line = new google.maps.Polyline(lopts);
        line.setMap(map);
    }

    map.fitBounds(bounds);

    if (mapdata.showImageMarks) {
        lastUpdate.setDate(lastUpdate.getDate() - 1); // Make sure we do the first update
        google.maps.event.addListener(map, 'bounds_changed', addMapMarks);
    }
}

// Creates an extended GPoint
function trkPt(map, lat, lon, elev, time, dist, uph, count) {
    var pt = new google.maps.LatLng(lat,lon);
    pt.latitude = lat;
    pt.longitude = lon;
    pt.elevation = elev;
    pt.timestamp = time;
    pt.distance = dist;
    pt.unitsperhour = uph;
    pt.pointcount = count;

    if (mapdata.showTrackMarks) {
        var opts = {
            icon: "http://norman.walsh.name/googlemap/x.png",
            position: pt,
            title: "Point #" + count,
            map: map
        };

        var mark = new google.maps.Marker(opts);

        var html = "<div>Track point #" + count;
        html = html + " on<br />" + time + "<br />";
        html = html + "Lat: " + lat + "<br />";
        html = html + "Lon: " + lon + "<br />";
        html = html + "Ele: " + elev + "<br />";
        html = html + "Dis: " + dist + "mi<br />";
        if (uph != null) {
            html = html + "Spd: " + uph + "mi/hr<br />";
        }
        html = html + "</div>";

        var infowindow = new google.maps.InfoWindow({
            content: html
        });

        google.maps.event.addListener(mark, 'click', function() { infowindow.open(map,mark); });
    }

    return pt;
}

function addMapMarks() {
    lastUpdate = new Date();
    if (!timerRunning) {
        timerRunning = true;
        $("body").everyTime(250, "maptimer", checkMovement);
    }
}

function checkMovement() {
    var date = new Date();
    var diff = date - lastUpdate;

    if (diff > 250) {
        $("body").stopTime("maptimer");
        timerRunning = false;
    } else {
        return;
    }

    var clat = map.getCenter().lat();
    var clon = map.getCenter().lng();
    var bounds = map.getBounds();

    if (bounds == null) {
        return;
    }

    var southWest = bounds.getSouthWest();
    var northEast = bounds.getNorthEast();

    var minlat = southWest.lat();
    var minlng = southWest.lng();

    var maxlat = northEast.lat();
    var maxlng = northEast.lng();

    var id = $(map.getDiv()).attr("id");

    $("#" + id + "_messages").html("Loading photographs...");

    $.getJSON("/ajax/mapmarks.xqy",
              { "mapid": id,
                "lat": clat, "long": clon,
                "minlat": minlat, "minlong": minlng,
                "maxlat": maxlat, "maxlong": maxlng },
              placeMapMarks);
}

function moreMapMarks() {
    var id = $(markerDiv).attr("id")
    id = id.substring(0, id.length - "_messages".length)
    data = { mapid: id, localMarkers: localMarkers };
    placeMapMarks(data);
}

function clearMapMarks() {
    // Remove the markers from the map...
    for (var id in imageMarkers) {
        imageMarkers[id].setMap(null);
    }

    imageMarkers = new Object();
    photoColors = new Object();
    colorIdx = 1;

    var text = "Showing none. ";
    text = text + " <a href='javascript:moreMapMarks()'>More</a>?";
    markerDiv.innerHTML = text;
}

function placeMapMarks(data) {
    var mapid = data.mapid
    var markers = data.localMarkers;

    localMarkers = markers;
    markerDiv = $("#" + mapid + "_messages").get(0);

    var total = 0;
    var showing = 0;
    var limit = 24;
    var pos = 0;

    while (pos < markers.length) {
	var m = markers[pos];
        var markobj = m;
	total += m.more + 1;

	if (imageMarkers[markobj.id]) {
	    // This one's already on the map
	    pos += m.more + 1; // Skip the others at this coord
	    showing += m.more + 1;
	    continue;
        }

	if (limit > 0) {
	    showing += m.more + 1;

	    if (photoColors[m.nsid] == undefined) {
		if (m.nsid == ndwid) {
		    photoColors[m.nsid] = "red";
		} else {
		    photoColors[m.nsid] = colors[colorIdx];
		    colorIdx++;
		    if (colorIdx >= colors.length) {
			colorIdx = 1;
		    }
		}
	    }

	    // Are they all by the same person, on the same date?
	    var samedate = true
	    var samephotog = true
	    for (next = 1; next <= m.more && (samedate || samephotog); next++) {
		if (m.date.substr(15) != markers[pos+next].date.substr(15)) {
		    samephotog = false;
		}
		if (m.date.substr(0,11) != markers[pos+next].date.substr(0,11)) {
		    samedate = false
		}
	    }

            var wtitle = "";

	    if (samedate && samephotog) {
		if (m.more > 0) {
		    wtitle = (m.more+1) + " photos by " + m.date.substr(15)
		} else {
		    wtitle = '"' + m.title + '" taken ' + m.date
		}
	    } else if (samephotog) {
		wtitle = (m.more+1) + " photos by " + m.date.substr(15)
	    } else {
		wtitle = (m.more+1) + " photographs"
	    }

	    var maxthumb = 9;
	    var count = m.more;
	    var rcount = 0;

	    var morep = "";
	    if (m.more >= maxthumb) {
		morep = "<p>And " + (m.more-maxthumb+1) + " additional photo";
		morep += (m.more > maxthumb ? "s" : "");
		morep += " at this location";
	    }

	    var html = "<b><a href='" + m.url + "'>" + m.title + "</a></b>";

	    if (m.more > 0) {
		html += " and more"
	    }

	    html += "<p align='center'>Taken "
	    if (samedate && samephotog) {
		html += m.date
	    } else if (samedate) {
		html += m.date.substr(0,11)
		html += " by various people"
	    } else if (samephotog) {
		html += "on various days by "
		html += m.date.substr(15)
	    } else {
		html += "on various days by various people"
	    }
	    html += "</p>"

	    while (count >= 0) {
		if (maxthumb > 0) {
		    html += "<a href='" + m.url + "'>";
		    html += "<img width='75' height='75' border='0' ";
		    html += "style='margin: 1px;' ";
		    html += "src='" + m.thumb + "' alt='Thumbnail' /></a>";
		    rcount++;
		    if (rcount >= 3) {
			html += "<br />";
			rcount = 0;
		    }
		    maxthumb--;
		}
		if (count > 0) {
		    m = markers[++pos];
		}
		count--;
	    }

	    html += "</p>" + morep;

	    var markopts = {
                icon: "http://norman.walsh.name/graphics/pins/" + photoColors[m.nsid] + ".png",
                position: new google.maps.LatLng(markobj.lat,markobj.lon),
                title: wtitle,
                map: map
	    };

            var infoopts = {
                content: html
            };

            addMarker(markopts, infoopts, markobj.id);

	    limit--;
	    pos++
	} else {
	    pos += m.more + 1;
	}
    }

    if (total > 0) {
	var text = "";
	if (total == showing) {
	    text = "Showing " + total + " image" + (total>1 ? "s" : "");
            text += ".";
	} else {
	    text = "Showing " + showing + " of " + total + " images";
            text += ".";
	    text += "<a href='javascript:moreMapMarks()'>More</a>? ";
	}
	text += "<a href='javascript:clearMapMarks()'>Clear</a>? ";
        $("#" + mapid + "_messages").html(text);
    } else {
        $("#" + mapid + "_messages").html("There are no images on this map.");
    }
}

function addMarker(markopts, infoopts, id) {
    var mark = new google.maps.Marker(markopts);
    var info = new google.maps.InfoWindow(infoopts);
    google.maps.event.addListener(mark, 'click', function() {
        info.open(map,mark);
    });
    imageMarkers[id] = mark;
}
