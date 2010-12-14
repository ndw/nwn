/* -*- JavaScript -*-
# The leading '#'s are just for consistency with other text formats
#
# rdf:
# dc:title FlightMap.js
# dc:date 2006-01-12
# cvs:date $Date: 2004/06/10 13:32:07 $
# dc:creator Norman Walsh
# dc:description Flight maps with Google Maps API V3.
*/

// Globals.

var map;
var flights = [];
var markers = [];
var lines = [];

var lineWidth = 1;
var lineColor = '#ff0000';

function Setup() {
    try {
	// There's no point in doing this if there aren't any flights, so it might not work
        // correctly if the flights array is empty.

	// Calculate the optimal size and center for the map
	var bounds = new google.maps.LatLngBounds();
	for (var i = 0; i < flights.length; ++i ) {
	    var p = new google.maps.LatLng(flights[i].depart.lat, flights[i].depart.long);
	    bounds.extend(p);
	    p = new google.maps.LatLng(flights[i].arrive.lat, flights[i].arrive.long);
	    bounds.extend(p);
        }

        var latlng = new google.maps.LatLng(bounds.getCenter().lat(), bounds.getCenter().lng());
        var mapopts = {
            zoom: 4,
            center: latlng,
            mapTypeId: google.maps.MapTypeId.ROADMAP
        };

	map = new google.maps.Map(mapDiv, mapopts);
        map.fitBounds(bounds);

	// Finally, display the current state.
	Display(map);
    } catch ( e ) {
        // This used to use GLog, but I don't know where that went...
    }
}

function Airport(lat, long, iata, uri) {
    this.lat = lat;
    this.long = long;
    this.latlng = new google.maps.LatLng(lat, long);
    this.iata = iata;
    this.uri = uri;
}

function Flight(depart, arrive) {
    this.depart = depart;
    this.arrive = arrive;
}

function createPoint(map, lat, lng, title) {
    var latlng = new google.maps.LatLng(lat, lng);
    var marker = new google.maps.Marker({
        position: latlng,
        map: map,
        icon: "/googlemap/x.png",
        title: title
    });
}

function createLine(map, slatlng, elatlng, color, width) {
    var coords = [ slatlng, elatlng ];
    var line = new google.maps.Polyline({
        path: coords,
        strokeColor: color,
        strokeWidth: width,
        strokeWeight: 1,
        geodesic: true
    });
    line.setMap(map);
}

function Display(map) {
    // First remove any old markers and lines.
    for ( var i = 0; i < markers.length; ++i )
	map.removeOverlay( markers[i] );
    markers = [];
    for ( var i = 0; i < lines.length; ++i )
	map.removeOverlay( lines[i] );
    lines = [];

    // Now place the current markers and lines.
    for ( var i = 0; i < flights.length; ++i ) {
	var depart = flights[i].depart;
	var arrive = flights[i].arrive;

	createPoint(map, depart.lat, depart.long, depart.iata);
	createPoint(map, arrive.lat, arrive.long, arrive.iata);

        createLine(map, depart.latlng, arrive.latlng, lineColor, lineWidth);
    }
}
