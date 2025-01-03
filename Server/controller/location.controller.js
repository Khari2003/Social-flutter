const StoreModel = require('../models/store.model');
const overpassData = require('./OverpassData')
const calculateDistance = require('./calDistance')

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

const getAllStoresInArena = async (req, res) => {
    const userCoord = req.body.userCoord || req.query.userCoord; // { lat, lng }
    const radius = req.body.radius || req.query.radius || 500; // Bán kính mặc định là 500m

    try {
        // Kiểm tra dữ liệu vị trí của người dùng
        if (!userCoord || !userCoord.lat || !userCoord.lng) {
            return res.status(400).json({ error: 'Vui lòng cung cấp tọa độ lat và lng.' });
        }

        const { lat, lng } = userCoord;

        // Lấy toàn bộ danh sách cửa hàng từ cơ sở dữ liệu
        const allStores = await StoreModel.find({}, 'name coordinates address category');

        // Lọc các cửa hàng trong phạm vi bán kính
        const filteredStores = allStores.filter(store => {
            const distance = calculateDistance(
                lat, lng,
                store.coordinates.lat, store.coordinates.lng
            );
            return distance <= radius;
        });

        // Gọi Overpass API để lấy thêm dữ liệu (đường xá, POI, v.v.)
        const elements = await overpassData(lat, lng, radius);
        // console.log(elements)
        // Trả kết quả
        res.status(200).json({
            stores: filteredStores,
            arenaData: elements
        });
    } catch (error) {
        console.error('Lỗi khi lấy dữ liệu:', error.message);
        res.status(500).json({ error: 'Đã xảy ra lỗi máy chủ.' });
    }
};

module.exports = {getAllStores, postCreateStore, getAllStoresInArena};
