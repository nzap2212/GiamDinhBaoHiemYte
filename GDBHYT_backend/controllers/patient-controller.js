const wsHandler = require('../helpers/websocket-handler');

class PatientController {
  // Lấy danh sách bệnh nhân nội trú
  async getInpatientList(req, res) {
    try {
      // Lấy tham số từ request (nếu có)
      const { limit, offset } = req.query;
      
      // Chuẩn bị tham số (nếu có)
      const parameters = {};
      if (limit) parameters.Limit = parseInt(limit);
      if (offset) parameters.Offset = parseInt(offset);
      
      // Thêm query vào hàng đợi và đợi kết quả
      const result = await wsHandler.scheduleQuery('GET_INPATIENT_LIST', parameters);
      
      // Trả về kết quả cho client API
      res.json({
        success: true,
        data: result,
        count: result.length,
        timestamp: new Date()
      });
    } catch (error) {
      console.error('Error fetching inpatient list:', error);
      res.status(500).json({
        success: false,
        error: error.message,
        timestamp: new Date()
      });
    }
  }

  // API để kiểm tra trạng thái hàng đợi
  async getQueueStatus(req, res) {
    try {
      const queueInfo = wsHandler.getQueueInfo();
      res.json({
        success: true,
        data: queueInfo,
        timestamp: new Date()
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message,
        timestamp: new Date()
      });
    }
  }
}

module.exports = new PatientController(); 