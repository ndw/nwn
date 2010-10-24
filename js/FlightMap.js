/* -*- JavaScript -*-
# The leading '#'s are just for consistency with other text formats
#
# rdf:
# dc:title FlightMap.js
# dc:date 2006-01-12
# cvs:date $Date: 2004/06/10 13:32:07 $
# dc:creator Norman Walsh
# dc:description Derived from http://www.acme.com/planimeter/ (C) 2005 Jef Poskanzer
*/

// Copyright © 2005, 2006 by Jef Poskanzer <jef@mail.acme.com>.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
// OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
// LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
// OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
// SUCH DAMAGE.
//
// For commentary on this license please see http://www.acme.com/license.html

// Globals.

var map;
var flights = [];
var markers = [];
var lines = [];

var lineWidth = 2;
var lineColor = '#ff0000';

var redIcon = new GIcon();
redIcon.image = 'http://norman.walsh.name/googlemap/x.png';
redIcon.shadow = 'http://norman.walsh.name/googlemap/xshadow.png';
redIcon.iconSize = new GSize( 3, 3 );
redIcon.shadowSize = new GSize( 3, 3 );
redIcon.iconAnchor = new GPoint( 1,  1 );
redIcon.infoWindowAnchor = new GPoint( 2, 0 );

function Setup() {
    try {
        // Check browser compatibility.
        if ( ! GBrowserIsCompatible() ) {
            mapDiv.innerHTML = 'Sorry, your browser is not compatible with Google Maps.';
            return;
        }

	// Create the map.
	map = new GMap2( mapDiv );
	map.addControl( new GSmallMapControl() );
	map.addControl( new GMapTypeControl() );
	map.addControl( new GScaleControl() );

	// Default over the central US
	var midlat = 38;
	var midlong = -97;
	map.setCenter(new GLatLng(midlat, midlong), 3);
	map.setMapType( G_NORMAL_MAP );

	// Calculate the optimal size and center for the map
	var bounds = new GLatLngBounds();
	for (var i = 0; i < flights.length; ++i ) {
	    var p = new GLatLng(flights[i].depart.lat, flights[i].depart.long);
	    bounds.extend(p);
	    p = new GLatLng(flights[i].arrive.lat, flights[i].arrive.long);
	    bounds.extend(p);
	}
	
	map.setZoom(map.getBoundsZoomLevel(bounds));
	map.setCenter(bounds.getCenter());

	// Finally, display the current state.
	Display();
    } catch ( e ) {
        GLog.write( 'Flightmap Setup:\n' + Props( e ) );
    }
}

function Airport(lat, long, iata, uri) {
    this.lat = lat;
    this.long = long;
    this.latlng = new GLatLng(lat, long);
    this.iata = iata;
    this.uri = uri;
}

function Flight(depart, arrive) {
    this.depart = depart;
    this.arrive = arrive;
}

function createPoint(lat, long, iata, uri) {
    var marker = new GMarker(new GPoint(long,lat), { icon: redIcon } );
    GEvent.addListener(marker, "click", function() {
	var html = "<div>Airport: <a href=\"" + uri + "\">";
	html = html + iata + "</a></div>";
	marker.openInfoWindowHtml(html);
    });
    markers.push( marker );
    map.addOverlay( marker );
}

function Display() {
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

	createPoint(depart.lat, depart.long, depart.iata, depart.uri);
	createPoint(arrive.lat, arrive.long, arrive.iata, arrive.uri);

	AddPolylinesSkippingDateline( lines, AllSameHemisphere( GreatCirclePoints( depart.latlng, arrive.latlng ) ), lineColor, lineWidth );
    }
}

function AllSameHemisphere( ps )
    {
    for ( var i = 1; i < ps.length; ++i )
	{
	if ( ps[i].lng() - ps[i-1].lng() > 180.0 )
	    ps[i] = new GLatLng( ps[i].lat(), ps[i].lng() - 360.0 );
	else if ( ps[i].lng() - ps[i-1].lng() < -180.0 )
	    ps[i] = new GLatLng( ps[i].lat(), ps[i].lng() + 360.0 );
	}
    return ps;
    }

function AddPolylinesSkippingDateline( lines, ps, lineColor, lineWidth )
    {
    var line;
    for ( var i = 1; i < ps.length; ++i )
	{
	if ( ps[i-1].lng() < -180.0 && ps[i].lng() >= -180.0 ||
	     ps[i-1].lng() > 180.0 && ps[i].lng() <= 180.0 )
	    {
	    // Oosp, we crossed the dateline.  Add two separate polylines.
	    line = new GPolyline( ps.slice( 0, i - 1 ), lineColor, lineWidth );
	    lines.push( line );
	    map.addOverlay( line );
	    line = new GPolyline( ps.slice( i ), lineColor, lineWidth );
	    lines.push( line );
	    map.addOverlay( line );
	    return;
	    }
	}

    // We didn't cross the dateline, so just add one polyline.
    line = new GPolyline( ps, lineColor, lineWidth );
    lines.push( line );
    map.addOverlay( line );
    }

//var metersPerKm = 1000.0;
//var meters2PerHectare = 10000.0;
//var feetPerMeter = 3.2808399;
//var feetPerMile = 5280.0;
//var acresPerMile2 = 640;
//
//function Areas( areaMeters2 )
//    {
//    var areaHectares = areaMeters2 / meters2PerHectare;
//    var areaKm2 = areaMeters2 / metersPerKm / metersPerKm;
//    var areaFeet2 = areaMeters2 * feetPerMeter * feetPerMeter;
//    var areaMiles2 = areaFeet2 / feetPerMile / feetPerMile;
//    var areaAcres = areaMiles2 * acresPerMile2;
//    return areaMeters2.toPrecision(4) + ' m&sup2; / ' + areaHectares.toPrecision(4) + ' hectares / ' + areaKm2.toPrecision(4) + ' km&sup2; / ' + areaFeet2.toPrecision(4) + ' ft&sup2; / ' + areaAcres.toPrecision(4) + ' acres / ' + areaMiles2.toPrecision(4) + ' mile&sup2;';
//    }

var earthRadiusMeters = 6367460.0;	// average of polar and equatorial radii
var metersPerDegree = 2.0 * Math.PI * earthRadiusMeters / 360.0;	// of latitude

function GreatCirclePoints( p1, p2 )
    {
    var maxDistanceMeters = 200000.0;		// 200 km
    var ps = [];
    if ( p1.distanceFrom( p2 ) <= maxDistanceMeters )
	{
	// For short distances we just use a rhumb line.
	ps.push( p1 );
	ps.push( p2 );
	}
    else
	{
	// Recursive decomposition.  Figure out the midpoint and
	// draw the two resulting segments.
	//
	// To compute the midpoint we convert from spherical
	// coordinates to x,y,z Cartesian coordinates, find the
	// midpoint there (which is trivial), and then convert
	// back to spherical coordinates.
	var theta1 = p1.lng() * radiansPerDegree;
	var phi1 = ( 90.0 - p1.lat() ) * radiansPerDegree;
	var x1 = earthRadiusMeters * Math.cos( theta1 ) * Math.sin( phi1 );
	var y1 = earthRadiusMeters * Math.sin( theta1 ) * Math.sin( phi1 );
	var z1 = earthRadiusMeters * Math.cos( phi1 );

	var theta2 = p2.lng() * radiansPerDegree;
	var phi2 = ( 90.0 - p2.lat() ) * radiansPerDegree;
	var x2 = earthRadiusMeters * Math.cos( theta2 ) * Math.sin( phi2 );
	var y2 = earthRadiusMeters * Math.sin( theta2 ) * Math.sin( phi2 );
	var z2 = earthRadiusMeters * Math.cos( phi2 );

	var x3 = ( x1 + x2 ) / 2.0;
	var y3 = ( y1 + y2 ) / 2.0;
	var z3 = ( z1 + z2 ) / 2.0;

	var r3 = Math.sqrt( x3 * x3 + y3 * y3 + z3 * z3 );
	var theta3 = Math.atan2( y3, x3 );
	var phi3 = Math.acos( z3 / r3 );
	var p3 = new GLatLng( 90.0 - phi3 * degreesPerRadian , theta3 * degreesPerRadian );

	var s1 = GreatCirclePoints( p1, p3 );
	var s2 = GreatCirclePoints( p3, p2 );
	for ( var i = 0; i < s1.length; ++i )
	    ps.push( s1[i] );
	for ( var i = 1; i < s2.length; ++i )
	    ps.push( s2[i] );
	}
    return ps;
    }

//function PlanarPolygonAreaMeters2( points )
//    {
//    // Formula from http://mathworld.wolfram.com/PolygonArea.html
//
//    var a = 0.0;
//    for ( var i = 0; i < points.length; ++i )
//	{
//	var j = ( i + 1 ) % points.length;
//	var xi = points[i].lng() * metersPerDegree * Math.cos( points[i].lat() * radiansPerDegree );
//	var yi = points[i].lat() * metersPerDegree;
//	var xj = points[j].lng() * metersPerDegree * Math.cos( points[j].lat() * radiansPerDegree );
//	var yj = points[j].lat() * metersPerDegree;
//	a += xi * yj - xj * yi;
//	}
//    return Math.abs( a / 2.0 );
//    }


//function SphericalPolygonAreaMeters2( points )
//    {
//    // Formula from http://mathworld.wolfram.com/SphericalPolygon.html
//    // !!! Doesn't work for self-intersecting polygons.
//
//    // Sum up all the angles.
//    var totalAngle = 0.0;
//    for ( i = 0; i < points.length; ++i )
//	{
//	var j = ( i + 1 ) % points.length;
//	var k = ( i + 2 ) % points.length;
//	totalAngle += Angle( points[i], points[j], points[k] );
//	}
//
//    // In planar geometry, the sum of the angles inside an n-vertex polygon
//    // is ( n - 2 ) * 180.  We subtract that from the actual sum to get
//    // what's called the spherical excess - the extra angle we have due
//    // to being on a sphere.
//    var planarTotalAngle = ( points.length - 2 ) * 180.0;
//    var sphericalExcess = totalAngle - planarTotalAngle;
//
//    if ( sphericalExcess > 420.0 )
//	{
//	// The spherical excess should be a small positive number for small
//	// polygons.  For polygons that cover most of a hemisphere, the
//	// excess might be as high as 360 degrees.  If the value we got is
//	// higher than that, then what happened is the points of the polygon
//	// were entered in counter-clockwise order instead of clockwise.
//	// This is simple to deal with, just convert all the angles
//	// to the other side (which we can do all at once, to the sum),
//	// and recalculate the spherical excess.
//	totalAngle = points.length * 360.0 - totalAngle;
//	sphericalExcess = totalAngle - planarTotalAngle;
//	}
//    else if ( sphericalExcess > 300.0 && sphericalExcess < 420.0 )
//	{
//	// This case tries to detect and correct for self-intersecting
//	// polygons.  Very large self-intersecting polygons may still
//	// be handled incorrectly.
//	sphericalExcess = Math.abs( 360.0 - sphericalExcess );
//	}
//
//    return sphericalExcess * radiansPerDegree * earthRadiusMeters * earthRadiusMeters;
//    }


//// Returns the angle of the vertex p1-p2-p3, on the right side.  For the angle
//// on the left side, subtract from 360.
//function Angle( p1, p2, p3 )
//    {
//    var bearing21 = Bearing( p2, p1 );
//    var bearing23 = Bearing( p2, p3 );
//    var angle = bearing21 - bearing23;
//    if ( angle < 0.0 )
//	angle += 360.0;
//    return angle;
//    }

//var clicked = false, doubleClicked;

//function MapClick( overlay, point )
//    {
//    try
//        {
//	if ( overlay == null && point != null )
//	    {
//	    // We want to avoid placing a marker on double-clicks.
//	    if ( clicked )
//		// We were already doing a click; set the double-click flag.
//		doubleClicked = true;
//	    else
//		{
//		// A fresh click; set the click flag and then wait 1/4 second.
//		clicked = true;
//		doubleClicked = false;
//		setTimeout( MakeCaller( MapClickLater, point ), 250 ); 
//		}
//	    }
//	}
//    catch( e )
//        {
//        GLog.write( 'MapClick:\n' + Props( e ) );
//        }
//    }


//function MapClickLater( point )
//    {
//    try
//        {
//	// If the delay has passed with no second click, do it.
//	if ( ! doubleClicked )
//	    {
//	    points.push( point );
//	    Display();
//	    }
//	// And reset the flag for the next click.
//	clicked = false;
//	}
//    catch( e )
//        {
//        GLog.write( 'MapClickLater:\n' + Props( e ) );
//        }
//    }


//function MarkerClick( pointIndex )
//    {
//    try
//        {
//	RotatePoints( pointIndex + 1 );
//	Display();
//	}
//    catch( e )
//        {
//        GLog.write( 'MarkerClick:\n' + Props( e ) );
//        }
//    }


//function RotatePoints( n )
//    {
//    var t = [];
//    for ( var i = 0; i < points.length; ++i )
//	t.push( points[( i + n ) % points.length] );
//    points = t;
//    }


//function DeleteLastPoint()
//    {
//    if ( points.length > 0 )
//	points.length--;
//    Display();
//    }


//function ClearAllPoints()
//    {
//    points = [];
//    Display();
//    }

function Props( o )
    {
    var s = '';
    for ( p in o )
	{
	if ( s.length != 0 )
	    s += '\n';
	s += p + ': ' + o[p];
	}
    return s;
    }
