const mongoose = require('mongoose')

const userSchema = new mongoose.Schema({
    username: {
        type: String,
        required: true,
        min: 3,
        max: 15,
        unique: true,
    },
    email: {
        type: String,
        required: true,
        min: 4,
        max: 50,
        unique: true,
    },
    password: {
        type: String,
        require: true,
        min: 6,
    },
    description: {
        type: String,
        max: 50,
        default: "",
    },
    profilePicture: {
        type: String,
        default: "",
    },
    followers: {
        type: Array,
        default: [],
    },
    followings: {
        type: Array,
        default: [],
    },
    role: {
        type: String,
        enum: ["admin", "user"],
        required: true,
        default: "user",
    },
    gender: {
        type: String,
        enum: ["male", "female"],
    },
    jwtToken: {
        type: String,
    },
    coordinates: {
        lat: { type: Number },
        lng: { type: Number }
    },

    // Thời gian
    createdAt: {
        type: Date,
        default: Date.now
    },
    updatedAt: {
        type: Date,
        default: Date.now
    }
},{
    timestamps:true
});

// Tự động cập nhật `updatedAt` trước khi lưu
userSchema.pre('save', function (next) {
    this.updatedAt = Date.now();
    next();
});

const UserModel = mongoose.model('User', userSchema)
module.exports = UserModel