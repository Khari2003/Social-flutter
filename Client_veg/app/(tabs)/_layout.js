import React, { useState, useEffect, useMemo } from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import MapView, { Marker, Circle, Polyline } from 'react-native-maps';
import { AntDesign } from '@expo/vector-icons';
import useLocation from '../components/User/userLocation';
import axios from 'axios';

const ip = '192.168.209.1'; // Địa chỉ IP của API backend

const App = () => {
  // Sử dụng hook để lưu trữ trạng thái
  const { location, errorMsg } = useLocation(); // Lấy vị trí hiện tại của người dùng
  const [nodes, setNodes] = useState([]); // Danh sách các node trong tuyến đường
  const [path, setPath] = useState([]); // Đường dẫn ngắn nhất
  const [stores, setStores] = useState([]); // Danh sách các cửa hàng
  const [filteredStores, setFilteredStores] = useState([]); // Cửa hàng trong bán kính
  const [radius, setRadius] = useState(5000); // Bán kính tìm kiếm (mặc định 5km)
  const [mapRegion, setMapRegion] = useState(null); // Khu vực hiển thị trên bản đồ
  const [selectedStore, setSelectedStore] = useState(null); // Cửa hàng được chọn
  const [fetchedPath, setFetchedPath] = useState(false); // Kiểm tra xem đã lấy đường dẫn chưa

  // Thiết lập khu vực bản đồ khi vị trí của người dùng thay đổi
  useEffect(() => {
    if (location && !selectedStore) {
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

  // Lấy danh sách cửa hàng từ API khi ứng dụng được tải
  useEffect(() => {
    fetchStoresData();
  }, []);

  // Lấy dữ liệu tuyến đường nếu chưa có
  useEffect(() => {
    if (location && !fetchedPath) {
      fetchNodeWayData();
    }
  }, [location, fetchedPath]);

  // Lọc các cửa hàng trong bán kính khi vị trí hoặc danh sách cửa hàng thay đổi
  useEffect(() => {
    if (stores.length > 0 && location) {
      filterStoresWithinRadius();
    }
  }, [stores, location]);

  // Hàm lấy tuyến đường giữa vị trí người dùng và cửa hàng
  const fetchNodeWayData = async (storeCoordinates) => {
    try {
      const response = await axios.get(`http://${ip}:4000/api/v1/way`, {
        params: {
          startCoord: { lat: location.coords.latitude, lng: location.coords.longitude },
          endCoord: storeCoordinates,
        },
      });

      if (response && response.data) {
        if (response.data.result) {
          const { result, elements } = response.data;

          const nodeData = elements.filter((el) => el.type === 'node');

          setNodes(nodeData);
          setPath(result.shortWay.path);

          // Tự động điều chỉnh khu vực bản đồ hiển thị dựa trên đường dẫn
          const start = nodeData.find((n) => n.id === Number(result.shortWay.path[0]));
          const end = nodeData.find((n) => n.id === Number(result.shortWay.path[result.shortWay.path.length - 1]));

          if (start && end) {
            const latitudeDelta = Math.abs(start.lat - end.lat) + 0.01;
            const longitudeDelta = Math.abs(start.lon - end.lon) + 0.01;
            setMapRegion({
              latitude: (start.lat + end.lat) / 2,
              longitude: (start.lon + end.lon) / 2,
              latitudeDelta,
              longitudeDelta,
            });
          }
        }
      } else {
        console.warn('Invalid data structure received from API');
      }
    } catch (error) {
      console.error('Failed to fetch data:', error.message || error);
    }
  };

  // Hàm lấy danh sách cửa hàng từ API
  const fetchStoresData = async () => {
    try {
      const response = await axios.get(`http://${ip}:4000/api/getall`);
      setStores(response.data);
    } catch (error) {
      console.log(error);
    }
  };

  // Lọc các cửa hàng trong bán kính đã định
  const filterStoresWithinRadius = () => {
    if (!location) return;

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

  // Hàm tính khoảng cách giữa 2 điểm tọa độ (Haversine Formula)
  const getDistance = (coord1, coord2) => {
    const R = 6371e3; // Bán kính Trái Đất (m)
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

  // Lấy tọa độ của node dựa vào ID
  const getNodeCoordinates = (nodeId) => {
    const node = nodes.find((n) => n.id === Number(nodeId));
    return node ? { latitude: node.lat, longitude: node.lon } : null;
  };

  // Chuyển đổi đường dẫn thành danh sách tọa độ
  const getPathCoordinates = () => {
    return path
      .map((nodeId) => getNodeCoordinates(nodeId))
      .filter((coord) => coord !== null);
  };

  // Vòng tròn hiển thị phạm vi bán kính
  const memoizedCircle = useMemo(() => {
    if (!location) return null;
    return (
      <Circle
        center={{
          latitude: location.coords.latitude,
          longitude: location.coords.longitude,
        }}
        radius={radius}
        strokeColor="rgba(0, 0, 255, 0.5)"
        fillColor="rgba(0, 0, 255, 0.2)"
      />
    );
  }, [radius, location]);

  // Điều chỉnh bán kính tìm kiếm
  const adjustRadius = (adjustment) => {
    setRadius((prevRadius) => {
      const newRadius = prevRadius + adjustment;
      return Math.max(0, Math.min(5000, newRadius)); // Đảm bảo giá trị trong khoảng 0-5000
    });
  };

  return (
    <View style={styles.container}>
      {errorMsg ? (
        <Text style={styles.error}>{errorMsg}</Text>
      ) : location ? (
        <>
          <MapView style={styles.map} region={mapRegion}>
            {location && (
              <Marker
                coordinate={{
                  latitude: location.coords.latitude,
                  longitude: location.coords.longitude,
                }}
                title="Vị trí của bạn"
                pinColor='green'
              />
            )}
            {filteredStores.map((store, index) => (
              <Marker
                key={index}
                coordinate={{
                  latitude: store.coordinates.lat,
                  longitude: store.coordinates.lng,
                }}
                title={store.name}
                onPress={() => {
                  setSelectedStore(store);
                  fetchNodeWayData(store.coordinates);
                }}
              />
            ))}
            {path.length > 0 && (
              <Polyline
                coordinates={getPathCoordinates()}
                strokeColor="blue"
                strokeWidth={3}
              />
            )}
            {memoizedCircle}
          </MapView>
          <View style={styles.sliderContainer}>
            <View style={styles.radiusContainer}>
              <TouchableOpacity
                onPress={() => setRadius((prev) => Math.max(prev - 100, 0))}
              >
                <AntDesign name="minuscircle" size={24} color="black" />
              </TouchableOpacity>
              <Text style={styles.radiusText}>Bán kính: {radius} m</Text>
              <TouchableOpacity
                onPress={() => setRadius((prev) => Math.min(prev + 100, 5000))}
              >
                <AntDesign name="pluscircle" size={24} color="black" />
              </TouchableOpacity>
            </View>
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
    alignItems: 'center',
  },
  radiusContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    width: '100%',
  },
  radiusText: {
    fontSize: 16,
    textAlign: 'center',
    marginHorizontal: 10,
  },
  buttonContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    width: 100,
    marginTop: 10,
  },
});

export default App;
