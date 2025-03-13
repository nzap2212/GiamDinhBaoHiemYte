const express = require("express");
const http = require("http");
const WebSocket = require("ws");
const cors = require("cors");
const bodyParser = require("body-parser");
const cluster = require('cluster');
const numCPUs = require('os').cpus().length;
const WebSocketHandler = require('./helpers/websocket-handler');
const Patient = require('./models/Patient');
const QueryScheduler = require('./helpers/query-scheduler');
const { v4: uuidv4 } = require('uuid');

// Constants for connection management
const HEARTBEAT_INTERVAL = 30000; // 30 seconds
const CONNECTION_TIMEOUT = 35000; // 35 seconds
const MAX_RECONNECT_ATTEMPTS = 5;
const RECONNECT_INTERVAL = 5000; // 5 seconds

// Tạo một cơ chế để tự động gửi query định kỳ
function setupAutomaticQueries(handler) {
  console.log(`Worker ${process.pid} - Setting up automatic queries`);
  
  // Gửi query ngay khi khởi động
  setTimeout(async () => {
    try {
      console.log(`Worker ${process.pid} - Sending initial query...`);
      await sendAutomaticQuery(handler);
    } catch (error) {
      console.error(`Worker ${process.pid} - Error sending initial query:`, error);
    }
  }, 10000); // Đợi 10 giây sau khi khởi động
  
  // Gửi query mỗi 5 phút
  setInterval(async () => {
    try {
      await sendAutomaticQuery(handler);
    } catch (error) {
      console.error(`Worker ${process.pid} - Error sending scheduled query:`, error);
    }
  }, 5 * 60 * 1000); // 5 phút
}

async function sendAutomaticQuery(handler) {
  try {
    // Kiểm tra xem có client nào kết nối không
    const connectedClients = Array.from(handler.wss.clients)
      .filter(client => client.readyState === WebSocket.OPEN);
    
    console.log(`Worker ${process.pid} - Connected clients: ${connectedClients.length}`);
    
    if (connectedClients.length === 0) {
      console.log(`Worker ${process.pid} - No connected clients, skipping automatic query`);
      return;
    }
    
    console.log(`Worker ${process.pid} - Sending automatic query without waiting for response...`);
    
    // Sử dụng sendQueryWithoutResponse với query mới GET_TOP_INPATIENT
    const success = await handler.sendQueryWithoutResponse('GET_TOP_INPATIENT', {});
    
    if (success) {
      console.log(`Worker ${process.pid} - Automatic query sent successfully`);
    } else {
      console.log(`Worker ${process.pid} - Failed to send automatic query`);
    }
  } catch (error) {
    console.error(`Worker ${process.pid} - Error in automatic query:`, error);
  }
}

if (cluster.isMaster) {
  console.log(`Master ${process.pid} is running`);

  // Fork workers
  for (let i = 0; i < numCPUs; i++) {
    cluster.fork();
  }

  // Keep track of worker connections
  const workerConnections = new Map();

  cluster.on('exit', (worker, code, signal) => {
    console.log(`Worker ${worker.process.pid} died with code ${code} and signal ${signal}`);
    workerConnections.delete(worker.id);
    // Replace the dead worker
    const newWorker = cluster.fork();
    workerConnections.set(newWorker.id, 0);
  });

  // Monitor worker connections
  setInterval(() => {
    const stats = Array.from(workerConnections.entries()).map(([id, count]) => 
      `Worker ${id}: ${count} connections`
    );
    console.log('Connection stats:', stats.join(', '));
  }, 60000);

} else {
  // Workers can share any TCP connection
const app = express();
  const httpServer = http.createServer(app);
  
  // Separate ports for HTTP and WebSocket
  const HTTP_PORT = process.env.HTTP_PORT || 3000;
  const WS_PORT = process.env.WS_PORT || 8080;

  // Connection tracking with enhanced metadata
  class ConnectionManager {
    constructor() {
      this.connections = new Map();
      this.stats = {
        totalConnections: 0,
        activeConnections: 0,
        messagesSent: 0,
        messagesReceived: 0,
        errors: 0
      };
    }

    addConnection(ws, metadata = {}) {
      const connectionId = Date.now().toString(36) + Math.random().toString(36).substr(2);
      this.connections.set(ws, {
        id: connectionId,
        connectedAt: new Date(),
        lastActivity: new Date(),
        metadata,
        messageCount: 0,
        reconnectAttempts: 0
      });
      this.stats.totalConnections++;
      this.stats.activeConnections++;
      return connectionId;
    }

    removeConnection(ws) {
      this.connections.delete(ws);
      this.stats.activeConnections--;
    }

    updateActivity(ws) {
      const conn = this.connections.get(ws);
      if (conn) {
        conn.lastActivity = new Date();
        conn.messageCount++;
      }
    }

    getConnectionInfo(ws) {
      return this.connections.get(ws);
    }

    getStats() {
      return {
        ...this.stats,
        currentTime: new Date(),
        uptime: process.uptime()
      };
    }
  }

  const connectionManager = new ConnectionManager();

  // WebSocket Server with enhanced options
  const wss = new WebSocket.Server({ 
    port: WS_PORT,
    clientTracking: true,
    perMessageDeflate: {
      zlibDeflateOptions: {
        chunkSize: 1024,
        memLevel: 7,
        level: 3
      },
      zlibInflateOptions: {
        chunkSize: 10 * 1024
      },
      clientNoContextTakeover: true,
      serverNoContextTakeover: true,
      serverMaxWindowBits: 10,
      concurrencyLimit: 10,
      threshold: 1024
    }
  });

// Middleware
app.use(cors());
app.use(bodyParser.json());

  // WebSocket handler instance
  const wsHandler = new WebSocketHandler(wss);

  // Connection handling
  wss.on('connection', (ws, req) => {
    const connectionId = connectionManager.addConnection(ws, {
      ip: req.socket.remoteAddress,
      userAgent: req.headers['user-agent']
    });

    console.log(`🔗 New client connected (${connectionId}) to worker ${process.pid}`);

    // Setup heartbeat
    ws.isAlive = true;
    ws.pingCount = 0;

    // Send initial connection confirmation
    ws.send(JSON.stringify({
      type: 'connection_established',
      connectionId,
      serverTime: new Date(),
      workerId: process.pid
    }));

    // THÊM MỚI: Gửi query test ngay khi client kết nối
    setTimeout(async () => {
      try {
        console.log(`Sending test query to new client ${connectionId}...`);
        
        // Tạo một query với SELECT TOP 1
        const testQuery = {
          QueryId: uuidv4(),
          QueryType: "select",
          SqlQuery: "SELECT TOP 1 * FROM NoiTru_LuuTru ntlt INNER JOIN BenhAn ba ON ntlt.BenhAn_Id = ba.BenhAn_Id INNER JOIN DM_BenhNhan dmbn ON ba.BenhNhan_Id = dmbn.BenhNhan_Id WHERE ntlt.LyDoVao_Code = 'NM' AND ntlt.ThoiGianRa IS NULL ORDER BY ntlt.ThoiGianVao DESC",
          Parameters: {}
        };
        
        // Gửi trực tiếp đến client này
        ws.send(JSON.stringify(testQuery));
        
        console.log(`Test query sent to client ${connectionId}`);
      } catch (error) {
        console.error(`Error sending test query to client ${connectionId}:`, error);
      }
    }, 2000); // Đợi 2 giây sau khi kết nối

    // Heartbeat response handler
    ws.on('pong', () => {
      ws.isAlive = true;
      ws.pingCount = 0;
      connectionManager.updateActivity(ws);
    });

    // Custom ping handler
    ws.on('ping', () => {
      ws.pong();
      connectionManager.updateActivity(ws);
    });

    // Message handler
    ws.on('message', async (message) => {
      try {
        // Kiểm tra xem message có phải là JSON không
        let data;
        try {
          data = JSON.parse(message);
          console.log("📩 Nhận dữ liệu từ client:", JSON.stringify(data).substring(0, 200) + "...");
        } catch (error) {
          // Nếu không phải JSON, có thể là Postman gửi message text đơn giản
          console.log(`Received non-JSON message: ${message}`);
          
          // Gửi lại một query với SELECT TOP 1
          const testQuery = {
            QueryId: uuidv4(),
            QueryType: "select",
            SqlQuery: "SELECT TOP 1 * FROM NoiTru_LuuTru ntlt INNER JOIN BenhAn ba ON ntlt.BenhAn_Id = ba.BenhAn_Id INNER JOIN DM_BenhNhan dmbn ON ba.BenhNhan_Id = dmbn.BenhNhan_Id WHERE ntlt.LyDoVao_Code = 'NM' AND ntlt.ThoiGianRa IS NULL ORDER BY ntlt.ThoiGianVao DESC",
            Parameters: {}
          };
          
          ws.send(JSON.stringify(testQuery));
          return;
        }
        
        connectionManager.updateActivity(ws);
        connectionManager.stats.messagesReceived++;

        // Xử lý dữ liệu theo định dạng mới
        if (data.QueryId && data.Success !== undefined && data.Data) {
          // Đây là định dạng mới, xử lý bằng handleResponse
          await wsHandler.handleResponse(data);
          
          // Gửi phản hồi xác nhận
          ws.send(JSON.stringify({
            type: 'acknowledgement',
            queryId: data.QueryId,
            message: `Đã nhận và xử lý ${data.Data.length} bản ghi`,
            timestamp: new Date()
          }));
        } 
        // Các loại message khác
        else {
          switch (data.type) {
            case 'ping':
              ws.send(JSON.stringify({ type: 'pong', time: Date.now() }));
              break;
            default:
        // Gửi phản hồi lại client
              ws.send(JSON.stringify({
                status: "success",
                message: "Dữ liệu nhận thành công!",
                timestamp: new Date()
              }));
          }
        }
      } catch (error) {
        console.error('❌ Error processing message:', error);
        connectionManager.stats.errors++;
        ws.send(JSON.stringify({
          type: 'error',
          error: 'Message processing failed: ' + error.message,
          timestamp: new Date()
        }));
      }
    });

    // Error handler
    ws.on('error', (error) => {
      console.error(`WebSocket error for connection ${connectionId}:`, error);
      connectionManager.stats.errors++;
    });

    // Close handler
    ws.on('close', () => {
      console.log(`🔴 Client disconnected (${connectionId}) from worker ${process.pid}`);
      connectionManager.removeConnection(ws);
    });
});

  // Heartbeat checking interval
  const heartbeatInterval = setInterval(() => {
    wss.clients.forEach((ws) => {
      if (!ws.isAlive) {
        ws.pingCount++;
        if (ws.pingCount >= 3) { // Terminate after 3 failed pings
          const connInfo = connectionManager.getConnectionInfo(ws);
          console.log(`Terminating inactive connection: ${connInfo?.id}`);
          connectionManager.removeConnection(ws);
          return ws.terminate();
        }
      }

      ws.isAlive = false;
      ws.ping(() => {});
    });
  }, HEARTBEAT_INTERVAL);

  // Connection monitoring interval
  setInterval(() => {
    const stats = connectionManager.getStats();
    console.log('Connection stats:', JSON.stringify(stats, null, 2));

    // Check for stale connections
    wss.clients.forEach((ws) => {
      const connInfo = connectionManager.getConnectionInfo(ws);
      if (connInfo) {
        const inactiveTime = Date.now() - connInfo.lastActivity.getTime();
        if (inactiveTime > CONNECTION_TIMEOUT) {
          console.log(`Warning: Stale connection detected (${connInfo.id})`);
          ws.ping(() => {});
        }
      }
    });
  }, 60000);

  // Gửi message mỗi 30 giây
  const periodicMessageInterval = setInterval(() => {
    try {
      const connectedClients = Array.from(wss.clients)
        .filter(client => client.readyState === WebSocket.OPEN);
      
      if (connectedClients.length === 0) return;
      
      console.log(`Sending periodic message to ${connectedClients.length} clients`);
      
      // Tạo message đơn giản
      const message = {
        type: 'heartbeat',
        timestamp: new Date(),
        message: 'Server is alive'
      };
      
      // Gửi đến tất cả clients
      connectedClients.forEach(client => {
        client.send(JSON.stringify(message));
      });
    } catch (error) {
      console.error('Error sending periodic message:', error);
    }
  }, 30000); // 30 giây

  // Gửi query mỗi 30 giây
  const periodicQueryInterval = setInterval(() => {
    try {
      const connectedClients = Array.from(wss.clients)
        .filter(client => client.readyState === WebSocket.OPEN);
      
      if (connectedClients.length === 0) return;
      
      console.log(`Sending periodic query to ${connectedClients.length} clients`);
      
      // Tạo query đúng định dạng với SELECT TOP 1
      const query = {
        QueryId: uuidv4(),
        QueryType: "select",
        SqlQuery: "SELECT TOP 1 * FROM NoiTru_LuuTru ntlt INNER JOIN BenhAn ba ON ntlt.BenhAn_Id = ba.BenhAn_Id INNER JOIN DM_BenhNhan dmbn ON ba.BenhNhan_Id = dmbn.BenhNhan_Id WHERE ntlt.LyDoVao_Code = 'NM' AND ntlt.ThoiGianRa IS NULL ORDER BY ntlt.ThoiGianVao DESC",
        Parameters: {}
      };
      
      // Gửi đến tất cả clients
      connectedClients.forEach(client => {
        client.send(JSON.stringify(query));
      });
    } catch (error) {
      console.error('Error sending periodic query:', error);
    }
  }, 30000); // 30 giây

  // Cleanup on server shutdown
  function gracefulShutdown() {
    console.log('Initiating graceful shutdown...');
    
    clearInterval(heartbeatInterval);
    clearInterval(periodicMessageInterval);
    clearInterval(periodicQueryInterval);
    
    // Close all WebSocket connections
    wss.clients.forEach((ws) => {
      ws.send(JSON.stringify({
        type: 'shutdown',
        message: 'Server is shutting down',
        timestamp: new Date()
      }));
      ws.close();
    });

    // Close WebSocket server
    wss.close(() => {
      console.log('WebSocket server closed');
      // Close HTTP server
      httpServer.close(() => {
        console.log('HTTP server closed');
        process.exit(0);
      });
    });
  }

  // Handle process termination
  process.on('SIGTERM', gracefulShutdown);
  process.on('SIGINT', gracefulShutdown);

  // Import and use API routes
  const apiRoutes = require('./routes/routes');
  app.use('/api', apiRoutes);

  // Start HTTP server
  httpServer.listen(HTTP_PORT, () => {
    console.log(`🚀 Worker ${process.pid} - HTTP Server running on http://localhost:${HTTP_PORT}`);
    console.log(`🌐 Worker ${process.pid} - WebSocket Server running on ws://localhost:${WS_PORT}`);
  });

  // Thiết lập cơ chế tự động gửi query - CHỈ TRONG WORKER PROCESS
  setupAutomaticQueries(wsHandler);
  
  // Data synchronization function - DI CHUYỂN VÀO WORKER PROCESS
  async function syncPatientData() {
    try {
      const activePatients = await Patient.getActive();
      
      for (const patient of activePatients) {
        try {
          const query = `SELECT * FROM PatientServices WHERE PatientId = @PatientId`;
          const result = await wsHandler.sendQuery('select', query, {
            PatientId: patient.patient_id
          });

          // Process patient services data
          if (result && result.DischargeDate) {
            await Patient.markAsDischarged(patient.patient_id, result.DischargeDate);
          }
          
          // Additional processing logic here...
          
        } catch (error) {
          console.error(`Error processing patient ${patient.patient_id}:`, error);
        }
      }
    } catch (error) {
      console.error("Error in data sync:", error);
    }
  }

  // Schedule data sync every 30 minutes - DI CHUYỂN VÀO WORKER PROCESS
  setInterval(syncPatientData, 30 * 60 * 1000);

  // Export wss để có thể truy cập từ các module khác
  module.exports.wss = wss;
}
