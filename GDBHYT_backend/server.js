const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const routes = require('./routes/routes');
const app = express()

// Middleware
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

// Cấu hình CORS
app.use(cors());

// Hoặc cấu hình cụ thể cho từng origin
app.use(cors({
    origin: ['http://tracking.zigisoft.com', 'http://localhost:3000'], // Thay bằng địa chỉ frontend
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));


//sử dụng routes
app.use('/', routes)

const PORT = 3001;
app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});