const Traffic = require('../models/traffic.model');
const axios = require('axios');

const API_URL = 'https://api.tomtom.com/traffic/services/4/flowSegmentData/relative0/10/json';

const bboxVietnam = {
    "Hà Nội": [
        { lat: 20.5270, lon: 105.3347 },
        { lat: 21.3760, lon: 106.0514 }
    ],
    // Thêm các tỉnh khác nếu cần
};

const generateGridPoints = (bbox, step) => {
    const [min, max] = bbox;
    const points = [];
    for (let lat = min.lat; lat <= max.lat; lat += step) {
        for (let lon = min.lon; lon <= max.lon; lon += step) {
            points.push({ lat: parseFloat(lat.toFixed(6)), lon: parseFloat(lon.toFixed(6)) });
        }
    }
    return points;
};

const updateTrafficDataVietnam = async () => {
    try {
        const now = new Date();
        const minutes = now.getMinutes();
        const seconds = now.getSeconds();

        // Chỉ cập nhật khi đúng giờ tròn
        if (minutes !== 0 || seconds !== 0) {
            console.log(`Chưa đến giờ tròn. Hiện tại là ${now.toISOString()}`);
            return;
        }

        console.log(`Bắt đầu cập nhật dữ liệu giao thông lúc ${now.toISOString()}`);

        for (const [province, bbox] of Object.entries(bboxVietnam)) {
            const gridPoints = generateGridPoints(bbox, 0.05);

            for (const point of gridPoints) {
                try {
                    const response = await axios.get(API_URL, {
                        params: {
                            point: `${point.lat},${point.lon}`,
                            unit: 'KMPH',
                            openLr: false,
                            key: 'GZlosH8AfBsnPMcIdy288MSHUitdsEsW'
                        }
                    });

                    const flowData = response.data.flowSegmentData;

                    if (!flowData || !flowData.coordinates) {
                        console.warn(`Không có dữ liệu giao thông hợp lệ cho tọa độ: ${point.lat},${point.lon}`);
                        continue;
                    }

                    const trafficData = {
                        frc: flowData.frc,
                        currentSpeed: flowData.currentSpeed,
                        freeFlowSpeed: flowData.freeFlowSpeed,
                        currentTravelTime: flowData.currentTravelTime,
                        freeFlowTravelTime: flowData.freeFlowTravelTime,
                        confidence: flowData.confidence,
                        roadClosure: flowData.roadClosure,
                        coordinates: flowData.coordinates.coordinate,
                        lastUpdated: new Date(),
                        province: province
                    };

                    await Traffic.findOneAndUpdate(
                        { 'coordinates.0.latitude': trafficData.coordinates[0].latitude },
                        trafficData,
                        { upsert: true, new: true, strict: false }
                    );
                } catch (error) {
                    if (error.response?.data?.error === 'Point too far from nearest existing segment.') {
                        console.warn(`Bỏ qua điểm (${point.lat},${point.lon}) do lỗi: ${error.response.data.detailedError.message}`);
                    } else {
                        console.error(`Lỗi khác khi lấy dữ liệu cho điểm (${point.lat},${point.lon}):`, error.message);
                    }
                    continue;
                }
            }
        }
        console.log('Cập nhật dữ liệu giao thông hoàn tất');
    } catch (error) {
        console.error('Lỗi khi cập nhật dữ liệu giao thông:', error);
    }
};

module.exports = { updateTrafficDataVietnam };