const StoreModel = require('../models/store.model');

const getAllStores = async (req, res) => {
    try {
        // Lấy tất cả dữ liệu từ bảng
        const stores = await StoreModel.find({});
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

module.exports = {getAllStores, postCreateStore};
