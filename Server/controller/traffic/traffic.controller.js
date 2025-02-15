const cron = require('node-cron');
const Traffic = require('../../models/traffic.model');
const { updateTrafficDataVietnam, generateGridPoints } = require('./components/trafficFlow');
const bboxVietnam = require('./components/trafficFlow').bboxVietnam;

// Hàm xem tất cả thông tin giao thông
const getAllTrafficData = async () => {
    try {
        const trafficData = await Traffic.find({});
        return trafficData;
    } catch (error) {
        console.error('Lỗi khi lấy thông tin giao thông:', error);
        return [];
    }
};

// Lấy dữ liệu giao thông theo tọa độ
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

// Lấy dữ liệu giao thông theo từng khu vực với phân trang
const getTrafficDataByGrid = async (province, page = 1, limit = 20) => {
    try {
        const bbox = bboxVietnam[province];
        if (!bbox) {
            throw new Error(`Không tìm thấy bbox cho tỉnh ${province}`);
        }

        const gridPoints = generateGridPoints(bbox, 0.1);
        const start = (page - 1) * limit;
        const end = start + limit;

        // Chỉ lấy các điểm trong phạm vi phân trang
        const pagedPoints = gridPoints.slice(start, end);
        const trafficData = [];

        for (const point of pagedPoints) {
            const data = await Traffic.find({
                'coordinates.0.latitude': point.lat,
                'coordinates.0.longitude': point.lon,
            });
            trafficData.push(...data);
        }

        return trafficData;
    } catch (error) {
        console.error('Lỗi khi lấy dữ liệu giao thông theo lưới:', error);
        return [];
    }
};

// Hàm cập nhật dữ liệu giao thông cũ
const updateOldTrafficData = async () => {
    try {
        const cutoffTime = new Date();
        cutoffTime.setHours(cutoffTime.getHours() - 1);

        const result = await Traffic.updateMany(
            { lastUpdated: { $lt: cutoffTime } },
            { $set: { status: 'outdated', lastChecked: new Date() } }
        );
        console.log(`Đã cập nhật trạng thái cho ${result.modifiedCount} bản ghi cũ.`);
    } catch (error) {
        console.error('Lỗi khi cập nhật dữ liệu cũ:', error);
    }
};

// Thiết lập cron job chạy mỗi giờ
cron.schedule('0 * * * *', () => {
    console.log('Đang cập nhật trạng thái dữ liệu giao thông cũ...');
    updateOldTrafficData();
});

// Lên lịch cập nhật dữ liệu giao thông mỗi giờ
setInterval(updateTrafficDataVietnam, 3600000);

// Chạy hàm cập nhật ngay khi script bắt đầu
updateTrafficDataVietnam();

module.exports = {
    updateTrafficDataVietnam,
    getAllTrafficData,
    getTrafficDataByCoordinates,
    getTrafficDataByGrid,
};
