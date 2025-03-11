const express = require("express");
const http = require("http");
const WebSocket = require("ws");
const cors = require("cors");
const bodyParser = require("body-parser");

const app = express();
const server = http.createServer(app); // HTTP Server
const wss = new WebSocket.Server({ server }); // WebSocket Server

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Import API routes
const apiRoutes = require("./routes/api");
app.use("/api", apiRoutes);

// WebSocket logic
const clients = new Set(); // Lưu danh sách client đang kết nối

wss.on("connection", (ws) => {
    console.log("🔗 Client WebSocket kết nối!");
    clients.add(ws);

    ws.on("message", (message) => {
        console.log("📩 Nhận dữ liệu từ client:", message);

        // Gửi phản hồi lại client
        ws.send(JSON.stringify({ status: "success", message: "Dữ liệu nhận thành công!" }));
    });

    ws.on("close", () => {
        console.log("🔴 Client WebSocket đã ngắt kết nối.");
        clients.delete(ws);
    });
});

// Chạy server trên cổng 3000
const PORT = 3000;
server.listen(PORT, () => {
    console.log(`🚀 Server đang chạy trên http://localhost:${PORT}`);
});
