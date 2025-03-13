const express = require('express');
const router = express.Router();
const PatientController = require('../../controllers/patient-controller');

// Route lấy danh sách bệnh nhân nội trú
router.get('/inpatients', PatientController.getInpatientList);

// Route kiểm tra trạng thái hàng đợi
router.get('/queue-status', PatientController.getQueueStatus);

// Thêm route để gửi message thủ công
router.get('/send-test-message', async (req, res) => {
  try {
    const wsHandler = require('../../helpers/websocket-handler');
    const wss = require('../../server').wss;
    
    const connectedClients = Array.from(wss.clients)
      .filter(client => client.readyState === WebSocket.OPEN);
    
    if (connectedClients.length === 0) {
      return res.json({
        success: false,
        message: 'No connected clients available'
      });
    }
    
    // Gửi message đến tất cả clients
    const message = {
      type: 'test',
      timestamp: new Date(),
      message: 'This is a test message'
    };
    
    connectedClients.forEach(client => {
      client.send(JSON.stringify(message));
    });
    
    res.json({
      success: true,
      message: `Test message sent to ${connectedClients.length} clients`
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Thêm route để gửi query thủ công
router.get('/send-test-query', (req, res) => {
  try {
    // Lưu wss vào global để có thể truy cập từ các module khác
    if (!global.wss) {
      global.wss = require('../../server').wss;
    }
    
    const WebSocket = require('ws');
    const { v4: uuidv4 } = require('uuid');
    
    const connectedClients = Array.from(global.wss.clients)
      .filter(client => client.readyState === WebSocket.OPEN);
    
    if (connectedClients.length === 0) {
      return res.json({
        success: false,
        message: 'No connected clients available'
      });
    }
    
    // Tạo query đúng định dạng
    const query = {
      QueryId: uuidv4(),
      QueryType: "select",
      SqlQuery: "SELECT ba.TiepNhan_Id, ba.BenhAn_Id, ba.SoBenhAn, dmbn.SoVaoVien, dmbn.TenBenhNhan FROM NoiTru_LuuTru ntlt INNER JOIN BenhAn ba ON ntlt.BenhAn_Id = ba.BenhAn_Id INNER JOIN DM_BenhNhan dmbn ON ba.BenhNhan_Id = dmbn.BenhNhan_Id LIMIT 10",
      Parameters: {}
    };
    
    // Gửi đến tất cả clients
    connectedClients.forEach(client => {
      client.send(JSON.stringify(query));
    });
    
    res.json({
      success: true,
      message: `Test query sent to ${connectedClients.length} clients`,
      query: query
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;
