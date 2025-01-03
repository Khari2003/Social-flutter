const shortWay = require('./shortWay');
const OverpassData = require('./OverpassData'); // Module để lấy dữ liệu từ Overpass API

const calculateShortestPath = (elements, startCoord, endCoord) => {
    try {
        return shortWay(elements, startCoord, endCoord);
    } catch (error) {
        console.error('Error calculating shortest path:', error.message);
        throw new Error('Unable to calculate shortest path.');
    }
};

const wayIndex = async (req, res) => {
    const startCoord = req.body.startCoord || req.query.startCoord;
    const endCoord = req.body.endCoord || req.query.endCoord;
    const radius = req.body.radius || req.query.radius || 1000;

    // Ép kiểu và gán lại
    if (startCoord) {
        startCoord.lat = Number(startCoord.lat);
        startCoord.lng = Number(startCoord.lng);
    }
    if (endCoord) {
        endCoord.lat = Number(endCoord.lat);
        endCoord.lng = Number(endCoord.lng);
    }

    if (
        !startCoord || typeof startCoord.lat !== 'number' || isNaN(startCoord.lat) ||
        typeof startCoord.lng !== 'number' || isNaN(startCoord.lng)
    ) {
        console.error('Invalid start coordinates:', { startCoord });
        return res.status(400).json({
            error: 'Invalid input parameters. Please provide valid "startCoord".',
        });
    }

    if (
        endCoord &&
        (typeof endCoord.lat !== 'number' || isNaN(endCoord.lat) ||
        typeof endCoord.lng !== 'number' || isNaN(endCoord.lng))
    ) {
        console.error('Invalid end coordinates:', { endCoord });
        return res.status(400).json({
            error: 'Invalid "endCoord". If provided, it must contain valid coordinates.',
        });
    }

    try {
        const { lat, lng } = startCoord;
        const elements = await OverpassData(lat, lng, radius);

        if (!elements || elements.length === 0) {
            console.error('No data fetched from Overpass API.');
            return res.status(500).json({ error: 'Unable to fetch map data from Overpass API.' });
        }

        if (!endCoord) {
            return res.status(200).json({ elements });
        }

        const result = calculateShortestPath(elements, startCoord, endCoord);
        res.status(200).json({ result, elements });
    } catch (error) {
        console.error('Error in wayIndex:', error.message);
        res.status(500).json({ error: error.message });
    }
};

module.exports = wayIndex;
