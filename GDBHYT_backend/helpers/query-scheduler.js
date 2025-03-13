const { v4: uuidv4 } = require('uuid');

class QueryScheduler {
  constructor(wsHandler) {
    this.wsHandler = wsHandler;
    this.queryQueue = [];
    this.isProcessing = false;
    this.processingInterval = 30000; // 30 giây
    this.timer = null;
    this.failedQueries = new Map(); // Lưu trữ các query thất bại
    this.maxRetries = 3; // Số lần thử lại tối đa
  }

  // Thêm query vào hàng đợi
  enqueueQuery(queryId, parameters, priority = 'normal', retryCount = 0) {
    return new Promise((resolve, reject) => {
      const queryRequest = {
        id: uuidv4(),
        queryId,
        parameters,
        priority,
        resolve,
        reject,
        timestamp: Date.now(),
        retryCount
      };

      // Thêm vào hàng đợi
      this.queryQueue.push(queryRequest);
      
      // Sắp xếp hàng đợi theo priority và retry count
      this.queryQueue.sort((a, b) => {
        // Ưu tiên theo priority
        if (a.priority === 'high' && b.priority !== 'high') return -1;
        if (a.priority !== 'high' && b.priority === 'high') return 1;
        
        // Sau đó ưu tiên theo retry count (ưu tiên thấp hơn cho các retry)
        if (a.retryCount !== b.retryCount) return a.retryCount - b.retryCount;
        
        // Cuối cùng ưu tiên theo thời gian
        return a.timestamp - b.timestamp;
      });

      // Bắt đầu xử lý nếu chưa chạy
      if (!this.timer) {
        this.startProcessing();
      }
    });
  }

  // Bắt đầu xử lý hàng đợi
  startProcessing() {
    console.log('Bắt đầu xử lý hàng đợi query, gửi mỗi 30 giây');
    this.timer = setInterval(() => {
      this.processNextBatch();
    }, this.processingInterval);
  }

  // Xử lý batch tiếp theo
  async processNextBatch() {
    // Luôn tiếp tục xử lý, ngay cả khi batch trước đó chưa hoàn thành
    if (this.queryQueue.length === 0) {
      return;
    }

    console.log(`Đang xử lý batch với ${this.queryQueue.length} queries`);

    // Lấy query tiếp theo từ hàng đợi
    const queryRequest = this.queryQueue.shift();
    
    try {
      // Gửi query và đợi kết quả
      const result = await this.wsHandler.sendQuery(
        queryRequest.queryId, 
        queryRequest.parameters
      ).catch(error => {
        // Nếu lỗi và chưa vượt quá số lần retry
        if (queryRequest.retryCount < this.maxRetries) {
          console.log(`Query ${queryRequest.id} thất bại, thử lại lần ${queryRequest.retryCount + 1}`);
          
          // Thêm lại vào queue với retry count tăng lên
          this.enqueueQuery(
            queryRequest.queryId,
            queryRequest.parameters,
            queryRequest.priority,
            queryRequest.retryCount + 1
          ).then(queryRequest.resolve).catch(queryRequest.reject);
        } else {
          // Đã vượt quá số lần retry, reject promise
          console.error(`Query ${queryRequest.id} thất bại sau ${this.maxRetries} lần thử lại`);
          queryRequest.reject(error);
        }
        
        // Throw lỗi để nhảy vào catch block
        throw error;
      });
      
      // Nếu thành công, resolve promise
      queryRequest.resolve(result);
      
    } catch (error) {
      console.error('Lỗi khi xử lý query:', error);
      // Lỗi đã được xử lý trong catch block của sendQuery
    }

    // Dừng timer nếu không còn query nào
    if (this.queryQueue.length === 0) {
      this.stopProcessing();
    }
  }

  // Dừng xử lý
  stopProcessing() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
      console.log('Đã dừng xử lý hàng đợi query');
    }
  }

  // Lấy thông tin hàng đợi
  getQueueInfo() {
    return {
      queueLength: this.queryQueue.length,
      isProcessing: this.isProcessing,
      nextProcessingTime: this.timer ? new Date(Date.now() + this.processingInterval) : null,
      failedQueriesCount: this.failedQueries.size
    };
  }
}

module.exports = QueryScheduler; 