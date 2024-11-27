const mongoose = require('mongoose')

const userSchema = new mongoose.Schema({
    // Thông tin cơ bản
    username: {
        type: String,
        required: true,
        unique: true,
        trim: true
    },
    email: {
        type: String,
        required: true,
        unique: true,
        lowercase: true
    },
    password: {
        type: String,
        required: true
    },

    // Thông tin cá nhân
    fullName: {
        type: String,
        default: ''
    },
    phoneNumber: {
        type: String,
        default: ''
    },
    avatarURL: {
        type: String,
        default: '' // URL ảnh đại diện
    },

    // Vai trò
    role: {
        type: String,
        enum: ['user', 'admin'], // Phân quyền: user hoặc admin
        default: 'user'
    },

    // Hoạt động
    favorites: [
        {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Store' // Danh sách nhà hàng yêu thích
        }
    ],
    reviews: [
        {
            store: {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'Store' // Nhà hàng được đánh giá
            },
            rating: {
                type: Number,
                min: 0,
                max: 5
            },
            comment: {
                type: String,
                default: ''
            },
            createdAt: {
                type: Date,
                default: Date.now
            }
        }
    ],

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

module.exports = mongoose.model('User', userSchema)