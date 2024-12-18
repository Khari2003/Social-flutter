const StoreModel = require('../models/store.model');
const axios = require('axios');

const getAllStores = async (req, res) => {
    try {
        // Lấy tất cả dữ liệu từ bảng
        const stores = await StoreModel.find({}, 'coordinates');
        // Trả về toàn bộ dữ liệu dưới dạng JSON
        res.json(stores);
    } catch (error) {
        console.error('Error fetching store data:', error);
        res.status(500).send('Internal Server Error');
    }
}

const postCreateStore = async (req, res) => {
    try {
        const {
            name,
            category,
            description = "",
            address,
            city = "N/A", // Giá trị mặc định nếu không có
            coordinates,
            phoneNumber = "Unknown", // Giá trị mặc định nếu không có
            email = "",
            website = "",
            rating = 0,
            reviewsCount = 0,
            priceLevel = "$",
            openingHours = "Not specified",
            closedDays = [],
            imageURL = "",
            gallery = [],
            facilities = [],
            isDeliveryAvailable = false,
            menu = [],
            createdAt = new Date(),
            updatedAt = new Date()
        } = req.body;

        // Kiểm tra dữ liệu bắt buộc
        if (!name || !category || !address || !coordinates || !coordinates.lat || !coordinates.lng) {
            return res.status(400).json({
                error: 'Các trường bắt buộc: name, category, address, coordinates.lat, coordinates.lng.'
            });
        }

        // Tạo một instance mới của StoreModel
        const newStore = new StoreModel({
            name,
            category,
            description,
            address,
            city,
            coordinates,
            phoneNumber,
            email,
            website,
            rating,
            reviewsCount,
            priceLevel,
            openingHours,
            closedDays,
            imageURL,
            gallery,
            facilities,
            isDeliveryAvailable,
            menu,
            createdAt,
            updatedAt
        });

        // Lưu vào cơ sở dữ liệu
        const savedStore = await newStore.save();

        // Trả về kết quả
        res.status(201).json({
            message: 'Nhà hàng đã được thêm thành công.',
            store: savedStore
        });
    } catch (error) {
        console.error('Error adding store:', error);
        res.status(500).json({
            error: 'Đã xảy ra lỗi khi thêm nhà hàng.'
        });
    }
}

// Hàm lấy dữ liệu từ Overpass API theo phạm vi
const getOverpassData = async (latitude, longitude, radius) => {
    // Tính toán phạm vi bbox từ bán kính (theo đơn vị mét)
    const earthRadius = 6371000; // Bán kính Trái Đất tính theo mét
    const latDiff = (radius / earthRadius) * (180 / Math.PI);
    const lonDiff = (radius / earthRadius) * (180 / Math.PI) / Math.cos(latitude * Math.PI / 180);

    const minLat = latitude - latDiff;
    const maxLat = latitude + latDiff;
    const minLon = longitude - lonDiff;
    const maxLon = longitude + lonDiff;

    const overpassQuery = `
        [out:json];
        (
            way["highway"~"primary|secondary|tertiary|residential"](${minLat},${minLon},${maxLat},${maxLon});
            node(w);
        );
        out body;
    `;

    try {
        const response = await axios.post('https://overpass-api.de/api/interpreter', overpassQuery, {
            headers: {
                'Content-Type': 'text/plain',
            },
        });
        return response.data.elements;
    } catch (error) {
        console.error('Error fetching data from Overpass API:', error.message);
        throw new Error('Unable to fetch Overpass data.');
    }
};

const getArena = async (req, res) => {
    const userLocation = req.body.userLocation || req.query.userLocation; // { latitude, longitude }
    const radius = req.body.radius || req.query.radius || 500; // Bán kính mặc định là 500m

    try {
        const { latitude, longitude } = userLocation;

        const elements = await getOverpassData(latitude, longitude, radius);

        res.status(200).json({
            elements: elements
        })
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
}

// Hàm tính khoảng cách giữa hai điểm (Công thức Haversine)
const calculateDistance = (lat1, lon1, lat2, lon2) => {
    const toRadians = (degrees) => degrees * (Math.PI / 180);

    const earthRadius = 6371; // Bán kính Trái Đất tính theo km
    const dLat = toRadians(lat2 - lat1);
    const dLon = toRadians(lon2 - lon1);

    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(toRadians(lat1)) *
            Math.cos(toRadians(lat2)) *
            Math.sin(dLon / 2) *
            Math.sin(dLon / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return earthRadius * c * 1000; // Chuyển đổi sang mét
};

const getAllStoresInArena = async (req, res) => {
    const userLocation = req.body.userLocation || req.query.userLocation; // { latitude, longitude }
    const radius = req.body.radius || req.query.radius || 500; // Bán kính mặc định là 500m

    try {
        // Kiểm tra dữ liệu vị trí của người dùng
        if (!userLocation || !userLocation.latitude || !userLocation.longitude) {
            return res.status(400).json({ error: 'Vui lòng cung cấp tọa độ latitude và longitude.' });
        }

        const { latitude, longitude } = userLocation;

        // Lấy toàn bộ danh sách cửa hàng từ cơ sở dữ liệu
        const allStores = await StoreModel.find({}, 'name coordinates address category');
        
        // Lọc các cửa hàng trong phạm vi bán kính
        const filteredStores = allStores.filter(store => {
            const distance = calculateDistance(
                latitude, longitude,
                store.coordinates.lat, store.coordinates.lng
            );
            return distance <= radius;
        });

        // Gọi Overpass API để lấy thêm dữ liệu (đường xá, POI, v.v.)
        const elements = await getOverpassData(latitude, longitude, radius);

        // Trả kết quả
        res.status(200).json({
            stores: filteredStores,
            arenaData: elements
        });
    } catch (error) {
        console.error('Lỗi khi lấy dữ liệu:', error.message);
        res.status(500).json({ error: 'Đã xảy ra lỗi máy chủ.' });
    }
};

module.exports = {getAllStores, postCreateStore, getArena, getOverpassData, getAllStoresInArena};
