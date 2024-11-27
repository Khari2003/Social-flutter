const mongoose = require('mongoose');
// mongoose.connect('mongodb://localhost:27017/NhaHangChay')

const storeSchema = new mongoose.Schema({
    name: { type: String, required: true },
    category: { type: String, required: true },
    description: { type: String, default: "" },
    address: { type: String, required: true },
    city: { type: String, default: "N/A" },
    coordinates: {
        lat: { type: Number, required: true },
        lng: { type: Number, required: true }
    },
    phoneNumber: { type: String, default: "Unknown" },
    email: { type: String, default: "" },
    website: { type: String, default: "" },
    rating: { type: Number, default: 0 },
    reviewsCount: { type: Number, default: 0 },
    priceLevel: { type: String, default: "$" },
    openingHours: { type: String, default: "Not specified" },
    closedDays: { type: [String], default: [] },
    imageURL: { type: String, default: "" },
    gallery: { type: [String], default: [] },
    facilities: { type: [String], default: [] },
    isDeliveryAvailable: { type: Boolean, default: false },
    menu: { type: [String], default: [] },
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now }
},{
    timestamps:true
});

// Tự động cập nhật `updatedAt` trước khi lưu
storeSchema.pre('save', function (next) {
    this.updatedAt = Date.now();
    next();
});

const StoreModel = mongoose.model('Store', storeSchema)
module.exports = StoreModel