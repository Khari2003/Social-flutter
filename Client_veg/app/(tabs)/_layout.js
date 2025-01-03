import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet } from 'react-native'; // Import Slider
import MapView, { Marker, Polyline, Circle } from 'react-native-maps'; // Import Circle
import useLocation from '../components/User/userLocation';
import Slider from '@react-native-community/slider'
import axios from 'axios';

const ip = '172.19.201.25';

const App = () => {
  const { location, errorMsg } = useLocation();
  const [radius, setRadius] = useState(5000); // Bán kính ban đầu 5km
  const [nodes, setNodes] = useState([]);
  const [path, setPath] = useState([]);
  const [stores, setStores] = useState([]);
  const [filteredStores, setFilteredStores] = useState([]);
  const [mapRegion, setMapRegion] = useState(null);

  useEffect(() => {
    fetchStoresData();
  }, []);

  useEffect(() => {
    if (location) {
      const latitudeDelta = 0.01;
      const longitudeDelta = 0.01;
      setMapRegion({
        latitude: location.coords.latitude,
        longitude: location.coords.longitude,
        latitudeDelta,
        longitudeDelta,
      });
    }
  }, [location]);

  useEffect(() => {
    if (stores.length > 0 && location) {
      filterStoresWithinRadius();
    }
  }, [stores, location, radius]);

  const fetchStoresData = async () => {
    try {
      const response = await axios.get(`http://${ip}:4000/api/getall`);
      setStores(response.data);
    } catch (error) {
      console.log(error);
    }
  };

  const filterStoresWithinRadius = () => {
    const userLocation = {
      lat: location.coords.latitude,
      lng: location.coords.longitude,
    };

    const filtered = stores.filter((store) => {
      const distance = getDistance(userLocation, {
        lat: store.coordinates.lat,
        lng: store.coordinates.lng,
      });
      return distance <= radius;
    });

    setFilteredStores(filtered);
  };

  const getDistance = (coord1, coord2) => {
    const R = 6371e3;
    const toRad = (x) => (x * Math.PI) / 180;

    const dLat = toRad(coord2.lat - coord1.lat);
    const dLng = toRad(coord2.lng - coord1.lng);

    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(toRad(coord1.lat)) *
        Math.cos(toRad(coord2.lat)) *
        Math.sin(dLng / 2) *
        Math.sin(dLng / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c;
  };

  return (
    <View style={styles.container}>
      {errorMsg ? (
        <Text style={styles.error}>{errorMsg}</Text>
      ) : location ? (
        <>
          <MapView style={styles.map} region={mapRegion}>
            {location && (
              <>
                <Marker
                  coordinate={{
                    latitude: location.coords.latitude,
                    longitude: location.coords.longitude,
                  }}
                  title="Vị trí của bạn"
                  pinColor="green"
                />
                <Circle
                  center={{
                    latitude: location.coords.latitude,
                    longitude: location.coords.longitude,
                  }}
                  radius={radius} // Bán kính
                  strokeColor="rgba(0, 0, 255, 0.5)"
                  fillColor="rgba(0, 0, 255, 0.2)"
                />
              </>
            )}
            {filteredStores.map((store, index) => (
              <Marker
                key={index}
                coordinate={{
                  latitude: store.coordinates.lat,
                  longitude: store.coordinates.lng,
                }}
                title={store.name}
              />
            ))}
          </MapView>
          <View style={styles.sliderContainer}>
            <Text>Bán kính: {radius / 1000} km</Text>
            <Slider
              minimumValue={1000} // Bán kính nhỏ nhất: 1km
              maximumValue={10000} // Bán kính lớn nhất: 10km
              step={500} // Tăng/giảm mỗi 500m
              value={radius}
              onValueChange={(value) => setRadius(value)}
            />
          </View>
        </>
      ) : (
        <View style={styles.loadingContainer}>
          <Text style={styles.loading}>Đang theo dõi tọa độ...</Text>
        </View>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  error: {
    color: 'red',
    textAlign: 'center',
    margin: 20,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#fff',
  },
  loading: {
    fontSize: 16,
    color: 'gray',
  },
  map: {
    flex: 1,
  },
  sliderContainer: {
    position: 'absolute',
    bottom: 20,
    width: '90%',
    alignSelf: 'center',
    backgroundColor: '#fff',
    padding: 10,
    borderRadius: 10,
    elevation: 5,
  },
});

export default App;
