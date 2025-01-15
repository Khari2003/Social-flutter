const mongoose = require('mongoose');

const TrafficSchema = new mongoose.Schema({
    province: {
        type: String,
        required: true
    },
    frc: String,
    currentSpeed: Number,
    freeFlowSpeed: Number,
    currentTravelTime: Number,
    freeFlowTravelTime: Number,
    confidence: Number,
    roadClosure: Boolean,
    coordinates: [
        {
            latitude: Number,
            longitude: Number
        }
    ],
    lastUpdated: {
        type: Date,
        default: Date.now
    }
});

// Create the model for traffic data
const Traffic = mongoose.model('Traffic', TrafficSchema);

// Export the model
module.exports = Traffic;
