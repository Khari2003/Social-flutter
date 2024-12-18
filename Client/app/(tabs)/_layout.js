import React, { useState, useEffect } from 'react';
import { View, StyleSheet, PermissionsAndroid, Platform } from 'react-native';
import MapboxGL from '@rnmapbox/maps';

MapboxGL.setAccessToken('sk.eyJ1Ijoibmd1eWVua2hhaTIwMDMiLCJhIjoiY20zenVxZW9kMjFmdTJsc2NkMGJkNnRtOCJ9.G3pYpUwGwgtpVjLe1y2grw');

const MapboxRoute = () => {
  const [routeCoordinates, setRouteCoordinates] = useState([]);
  const [location, setLocation] = useState(null);

  useEffect(() => {
    requestLocationPermission();
  }, []);

  // Yêu cầu quyền truy cập vị trí
  const requestLocationPermission = async () => {
    if (Platform.OS === 'android') {
      const granted = await PermissionsAndroid.request(
        PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION,
        {
          title: "Permission to Access Location",
          message: "This app needs access to your location to show your current position.",
          buttonNeutral: "Ask Me Later",
          buttonNegative: "Cancel",
          buttonPositive: "OK",
        }
      );
      if (granted === PermissionsAndroid.RESULTS.GRANTED) {
        console.log('Location permission granted');
      } else {
        console.log("Location permission denied");
      }
    } else {
      console.log('Location permission granted');
    }
  };

  // Tọa độ Hồ Gươm (đích)
  const destination = [105.933834, 20.957407]; // Tọa độ Hồ Gươm

  useEffect(() => {
    if (location) {
      fetchRoute(location);  // Fetch route when location is available
    }
  }, [location]);

  const fetchRoute = async (userLocation) => {
    const { latitude, longitude } = userLocation.coords;

    // Kiểm tra nếu có tọa độ người dùng
    if (!latitude || !longitude) {
      return;
    }

    const url = `https://api.mapbox.com/directions/v5/mapbox/driving/${longitude},${latitude};${destination[0]},${destination[1]}?geometries=geojson&access_token=sk.eyJ1Ijoibmd1eWVua2hhaTIwMDMiLCJhIjoiY20zenVxZW9kMjFmdTJsc2NkMGJkNnRtOCJ9.G3pYpUwGwgtpVjLe1y2grw`;

    try {
      const response = await fetch(url);
      const data = await response.json();

      if (data.routes && data.routes.length > 0) {
        const route = data.routes[0].geometry.coordinates;
        setRouteCoordinates(route);
      } else {
        console.error("No route found");
      }
    } catch (error) {
      console.error('Error fetching route:', error);
    }
  };

  // Cập nhật vị trí người dùng
  const onUserLocationUpdate = (location) => {
    setLocation(location);
  };

  return (
    <View style={styles.container}>
      <MapboxGL.MapView style={styles.map}>
        {/* Theo dõi vị trí người dùng */}
        <MapboxGL.Camera
          followUserLocation={true}
          zoomLevel={14}
        />

        {/* Hiển thị tuyến đường */}
        {routeCoordinates.length > 0 && (
          <MapboxGL.ShapeSource
            id="routeSource"
            shape={{
              type: 'Feature',
              geometry: {
                type: 'LineString',
                coordinates: routeCoordinates,
              },
            }}
          >
            <MapboxGL.LineLayer
              id="routeLayer"
              style={{
                lineWidth: 5,
                lineColor: 'blue',
              }}
            />
          </MapboxGL.ShapeSource>
        )}

        {/* Hiển thị điểm kết thúc (Hồ Gươm) */}
        <MapboxGL.PointAnnotation
          id="destination"
          coordinate={destination}
        >
          <View style={[styles.marker, { backgroundColor: 'red' }]} />
        </MapboxGL.PointAnnotation>

        {/* Hiển thị vị trí người dùng */}
        <MapboxGL.UserLocation
          visible={true}
          onUpdate={onUserLocationUpdate}
        />
      </MapboxGL.MapView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  map: {
    flex: 1,
  },
  marker: {
    width: 10,
    height: 10,
    backgroundColor: 'blue',
    borderRadius: 5,
  },
});

export default MapboxRoute;
