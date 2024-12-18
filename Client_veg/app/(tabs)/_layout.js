import axios from 'axios';
import React, { useEffect, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import MapView, { Polyline, Marker } from 'react-native-maps';
import * as Location from 'expo-location'

const App = () => {
  const [nodes, setNodes] = useState([]); // Danh sách node
  const [path, setPath] = useState([]);   // Danh sách đường đi (path)
  const [startNode, setStartNode] = useState(null); // Node bắt đầu
  const [endNode, setEndNode] = useState(null);     // Node kết thúc
  const [userLocation, setUserLocation] = useState(null);

  useEffect(() => {
    fetchNodeWayData();
  }, []);

  useEffect(() => {
    getUserLocation();
  })

  const getUserLocation = async () => {
    try {
      // Yêu cầu quyền truy cập vị trí
      let { status } = await Location.requestForegroundPermissionsAsync();
      if (status !== 'granted') {
        Alert.alert('Permission Denied', 'Quyền truy cập vị trí bị từ chối.');
        return;
      }

      // Lấy vị trí hiện tại
      let location = await Location.getCurrentPositionAsync({
        accuracy: Location.Accuracy.High,
      });
      const { latitude, longitude } = location.coords;
      setUserLocation({ latitude, longitude });
    } catch (error) {
      console.error('Error getting location:', error.message);
    }
  };

  // console.log(userLocation)

  const fetchNodeWayData = async () => {
    try {
      // Thay đổi URL API nếu cần thiết
      const response = await axios.get('http://192.168.1.4:4000/api/v1/way', {
        params: {
          startCoord: { lat: 20.964924, lon: 105.827779 },
          endCoord: { lat: 20.973178, lon: 105.828666 },
        },
      });

      if (response && response.data) {
        const { result, elements } = response.data;

        // Lưu danh sách node từ elements
        const nodeData = elements.filter((el) => el.type === 'node');
        setNodes(nodeData);

        // Lưu danh sách path từ result.path
        setPath(result.path);

        // Xác định node bắt đầu và kết thúc
        const start = nodeData.find((n) => n.id === Number(result.path[0]));
        const end = nodeData.find((n) => n.id === Number(result.path[result.path.length - 1]));

        setStartNode(start);
        setEndNode(end);
      } else {
        console.warn('Invalid data structure received from API');
      }
    } catch (error) {
      console.error('Failed to fetch data:', error.message || error);
      console.log(error);
    }
  };

  // Hàm lấy tọa độ node từ ID
  const getNodeCoordinates = (nodeId) => {
    const node = nodes.find((n) => n.id === Number(nodeId));
    return node ? { latitude: node.lat, longitude: node.lon } : null;
  };

  // Tạo mảng tọa độ cho đường Polyline
  const getPathCoordinates = () => {
    return path
      .map((nodeId) => getNodeCoordinates(nodeId))
      .filter((coord) => coord !== null); // Bỏ qua các node không tìm thấy
  };

  return (
    <View style={styles.container}>
      <MapView
        style={styles.map}
        initialRegion={{
          latitude: 20.964924,
          longitude: 105.827779,
          latitudeDelta: 0.05,
          longitudeDelta: 0.05,
        }}
      >
        {/* Marker cho node bắt đầu */}
        {startNode && (
          <Marker
            coordinate={{ latitude: startNode.lat, longitude: startNode.lon }}
            title="Start Node"
            pinColor="green"
          />
        )}

        {/* Marker cho node kết thúc */}
        {endNode && (
          <Marker
            coordinate={{ latitude: endNode.lat, longitude: endNode.lon }}
            title="End Node"
            pinColor="red"
          />
        )}

        {/* Hiển thị đường đi từ path */}
        {path.length > 0 && (
          <Polyline
            coordinates={getPathCoordinates()}
            strokeColor="#FF0000" // Màu của đường
            strokeWidth={3} // Độ rộng của đường
          />
        )}
      </MapView>
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
});

export default App;
