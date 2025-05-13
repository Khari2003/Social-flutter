require('dotenv').config();
const express = require('express');
const multer = require('multer');
const cloudinary = require('cloudinary').v2;
const cors = require('cors');
const fs = require('fs');

const app = express();
app.use(cors());
app.use(express.json());

// Cấu hình Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Cấu hình Multer (lưu file tạm)
const upload = multer({ dest: 'uploads/' });

// API upload file lên Cloudinary theo loại file
app.post('/upload', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No file uploaded' });

    const fileType = req.body.type || 'auto'; // image, video, audio
    let folder = 'uploads'; // Mặc định

    // Xác định thư mục lưu trên Cloudinary
    if (fileType === 'image') {
      folder = 'images';
    } else if (fileType === 'video') {
      folder = 'videos';
    } else if (fileType === 'audio') {
      folder = 'voices';
    }

    // Upload file lên Cloudinary
    const result = await cloudinary.uploader.upload(req.file.path, {
      resource_type: fileType,
      folder: folder, // Lưu vào thư mục tương ứng
    });

    // Xóa file tạm
    fs.unlinkSync(req.file.path);

    res.json({ message: 'Upload thành công!', url: result.secure_url });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Lỗi khi upload' });
  }
});

// Chạy server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server chạy tại http://192.168.170.200:${PORT}`);
});
