const axios = require('axios');
const shortWay = require('./shortWay');
const {getOverpassData} = require('./location.controller')

// Hàm tính đường đi giữa hai điểm
const calculateShortestPath = (elements, startCoord, endCoord) => {
    try {
        const result = shortWay(elements, startCoord, endCoord);
        return result;
    } catch (error) {
        console.error('Error calculating shortest path:', error.message);
        throw new Error('Unable to calculate shortest path.');
    }
};

// Endpoint xử lý yêu cầu
const wayIndex = async (req, res) => {
    const startCoord = req.body.startCoord || req.query.startCoord;
    const endCoord = req.body.endCoord || req.query.endCoord;
    
    if (!startCoord || !endCoord || !userLocation) {
        return res.status(400).json({ error: 'Invalid input parameters.' });
    }

    try {
        const { latitude, longitude } = userLocation;

        // Lấy dữ liệu từ Overpass API
        const elements = await getOverpassData(latitude, longitude, radius);

        // Tính đường đi ngắn nhất
        const result = calculateShortestPath(elements, startCoord, endCoord);

        res.status(200).json({
            result: result,
            elements: elements,
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

module.exports = wayIndex;