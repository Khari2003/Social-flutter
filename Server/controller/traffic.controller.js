const axios = require('axios');
const Traffic = require('../models/traffic.model')
const {updateTrafficDataVietnam} = require('./trafficFlow')

// Hàm xem tất cả thông tin giao thông
const getAllTrafficData = async () => {
    try {
        const trafficData = await Traffic.find();
        return trafficData;
    } catch (error) {
        console.error('Lỗi khi lấy thông tin giao thông:', error);
        return [];
    }
};

const getTrafficDataByCoordinates = async (latitude, longitude, provinces) => {
    try {
        const radiusInKm = 5; // Bán kính 5km
        const EARTH_RADIUS = 6371; // Bán kính Trái đất tính theo km

        const haversineDistance = (lat1, lon1, lat2, lon2) => {
            const toRadians = (degree) => (degree * Math.PI) / 180;
            const dLat = toRadians(lat2 - lat1);
            const dLon = toRadians(lon2 - lon1);

            const a =
                Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                Math.cos(toRadians(lat1)) *
                    Math.cos(toRadians(lat2)) *
                    Math.sin(dLon / 2) *
                    Math.sin(dLon / 2);

            const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
            return EARTH_RADIUS * c;
        };

        const nearbyProvinces = provinces.filter((province) => {
            const [provLat, provLon] = province.point.split(',').map(Number);
            const distance = haversineDistance(latitude, longitude, provLat, provLon);
            return distance <= radiusInKm;
        });

        if (nearbyProvinces.length === 0) {
            return null;
        }

        const trafficData = await Traffic.find({
            province: { $in: nearbyProvinces.map((p) => p.name) },
        });

        return trafficData;
    } catch (error) {
        console.error('Lỗi khi lấy thông tin giao thông theo tọa độ:', error);
        return null;
    }
};

// Lên lịch cập nhật dữ liệu giao thông mỗi giờ
setInterval(updateTrafficDataVietnam, 3600000);

// Chạy hàm cập nhật ngay khi script bắt đầu
updateTrafficDataVietnam();

module.exports = { updateTrafficDataVietnam, getAllTrafficData, getTrafficDataByCoordinates };
