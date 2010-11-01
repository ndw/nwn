/* -*- JavaScript -*-
# The leading '#'s are just for consistency with other text formats
#
# rdf:
# dc:title Google mapping functions
# dc:date 2010-10-31
# dc:creator http://norman.walsh.name/knows/who/norman-walsh
# dc:description Utility routines for Google Map plots.
*/

var icon = new GIcon();
icon.image = "http://norman.walsh.name/googlemap/x.png";
icon.shadow = "http://norman.walsh.name/googlemap/xshadow.png";
icon.iconSize = new GSize(3, 3);
icon.shadowSize = new GSize(3, 3);
icon.iconAnchor = new GPoint(1, 1);
icon.infoWindowAnchor = new GPoint(2, 0);

var colors = ["red", "blue", "green", "orange", "cyan", "pink", "purple", "yellow"];
var photoIcons = new Object();
for (idx in colors) {
    var micon = new GIcon();
    micon.image = "http://norman.walsh.name/graphics/pins/" + colors[idx] + ".png";
    micon.shadow = "http://norman.walsh.name/graphics/pins/shadow.png";
    micon.iconSize = new GSize(32, 32);
    micon.shadowSize = new GSize(56, 32);
    micon.iconAnchor = new GPoint(16, 32);
    micon.infoWindowAnchor = new GPoint(16, 0);
    photoIcons[colors[idx]] = micon;
}

var ndwid = "24401095@N00";

var imageMarkers = new Object();
var photoColors = new Object();
var colorIdx = 1;
var localMarkers = new Array();
var markerDiv = "";
var photographerCount = 0;

function configureMap(map,lat,lon,mag) {
    map.addMapType(G_PHYSICAL_MAP);
    map.addControl(new GLargeMapControl());
    map.addControl(new GMapTypeControl());
    map.setCenter(new GLatLng(lat,lon),mag)

    //GEvent.addListener(map,"dragend",mapDragged);
    //GEvent.addListener(map,"zoomend",mapZoomed);
    // moveend seems to subsume dragend and zoomend, and I don't want multiple calls...
    GEvent.addListener(map,"moveend",mapDragged);

    return map;
}

// Creates one of our tracking points
function createPoint(point) {
    var opts = {
        icon: icon,
        clickable: true,
        title: "Point #" + point.pointcount
    }
    var marker = new GMarker(point, opts);
    GEvent.addListener(marker, "click", function() {
        var html = "<div>Track point #" + point.pointcount;
        if (point.timestamp != '') {
            html = html + " on<br />" + point.timestamp + "<br />";
        } else {
            html = html + "<br />";
        }
        html = html + "Lat: " + point.latitude + "<br />";
        html = html + "Lon: " + point.longitude + "<br />";
        html = html + "Ele: " + point.elevation + "<br />";
        html = html + "Dis: " + point.distance + "mi<br />";
        if (point.unitsperhour != 'unk') {
            html = html + "Spd: " + point.unitsperhour + "mi/hr<br />";
        }
        html = html + "</div>";
        marker.openInfoWindowHtml(html);
    });
    map.addOverlay(marker);
}

// Creates a popup marker
function createMarker(point,name) {
    var marker = new GMarker(point);
    var html = "<b>" + name + "</b>";
    GEvent.addListener(marker, "click", function() {
        marker.openInfoWindowHtml(html);
    });

    return marker;
}

// Creates a popup image marker
function createImageMarker(lat,lon,opts,html) {
    var marker = new GMarker(new GPoint(lon,lat), opts);
    GEvent.addListener(marker, "click", function() {
        marker.openInfoWindowHtml(html);
    });
    return marker;
}

// Creates an extended GPoint
function trkPt(lat, lon, elev, time, dist, uph, count) {
    var pt = new GPoint(lon, lat);
    pt.latitude = lat;
    pt.longitude = lon;
    pt.elevation = elev;
    pt.timestamp = time;
    pt.distance = dist;
    pt.unitsperhour = uph;
    pt.pointcount = count;
    return pt;
}

function mapDragged() {
    addMapMarks();
}

function mapZoomed(oldLevel,newLevel) {
    addMapMarks();
}

function addMapMarks() {
    var clat = map.getCenter().lat();
    var clon = map.getCenter().lng();

    var bounds = map.getBounds();
    var southWest = bounds.getSouthWest();
    var northEast = bounds.getNorthEast();

    var minlat = southWest.lat();
    var minlng = southWest.lng();

    var maxlat = northEast.lat();
    var maxlng = northEast.lng();

    var id = $(map.getContainer()).attr("id");

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

/*
function moveMapTo(lat,lon) {
    var center = new GLatLng(lat,lon);
    map.setCenter(center);
}
*/

function clearMapMarks() {
    map.clearOverlays();
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
	total += m.more + 1;

	if (imageMarkers[m.id] == 1) {
	    // This one's already on the map
	    pos += m.more + 1; // Skip the others at this coord
	    showing += m.more + 1;
	    continue;
	}

	if (limit > 0) {
	    imageMarkers[m.id] = 1;
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

	    var opts = {
		icon: photoIcons[photoColors[m.nsid]],
		clickable: true
	    }

	    if (samedate && samephotog) {
		if (m.more > 0) {
		    opts.title = (m.more+1) + " photos by " + m.date.substr(15)
		} else {
		    opts.title = '"' + m.title + '" taken ' + m.date
		}
	    } else if (samephotog) {
		opts.title = (m.more+1) + " photos by " + m.date.substr(15)
	    } else {
		opts.title = (m.more+1) + " photographs"
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

	    // It's ok to use m.lat/m.lon because they're all the same
	    map.addOverlay(createImageMarker(m.lat,m.lon,opts,html));

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
