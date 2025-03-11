// 

const WebSocket = require('ws');

const server = new WebSocket.Server({ port: 3000 });

server.on('connection', (ws) => {
    console.log("✅ Client đã kết nối!");

    // Gửi yêu cầu truy vấn SQL
    ws.send(JSON.stringify({ query: "SELECT * FROM Users" }));

    ws.on('message', (message) => {
        console.log("📩 Nhận phản hồi từ Windows Service:", message);
    });
});

console.log("🔵 WebSocket Server chạy trên ws://localhost:3000");
