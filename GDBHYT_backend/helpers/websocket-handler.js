const { v4: uuidv4 } = require('uuid');
const Patient = require('../models/Patient');
const { Worker } = require('worker_threads');
const path = require('path');
const QueryScheduler = require('./query-scheduler');
const WebSocket = require('ws');

class WebSocketHandler {
  constructor(wss) {
    this.wss = wss;
    this.pendingQueries = new Map();
    this.scheduler = new QueryScheduler(this);
    this.messageQueue = [];
    this.workers = new Map();
    this.isProcessing = false;
    this.maxWorkers = 4; // Số lượng workers tối đa
    this.connectedClients = new Map();
    this.lastQueryTime = 0; // Thời điểm gửi query gần nhất
    this.queryInterval = 30000; // 30 giây
    this.initializeWorkers();
  }

  initializeWorkers() {
    for (let i = 0; i < this.maxWorkers; i++) {
      const worker = new Worker(path.join(__dirname, 'message-worker.js'));
      
      worker.on('message', (result) => {
        this.handleWorkerResponse(result);
      });

      worker.on('error', (error) => {
        console.error('Worker error:', error);
      });

      this.workers.set(i, worker);
    }
  }

  async scheduleQuery(queryId, parameters, priority = 'normal') {
    return this.scheduler.enqueueQuery(queryId, parameters, priority);
  }

  async sendQuery(queryId, parameters) {
    try {
      // Tìm query trong query manager
      const queryManager = require('../queries');
      const patientQueries = require('../queries/patient-queries');
      
      // Tìm query dựa trên queryId
      let query;
      if (queryId === 'GET_INPATIENT_LIST') {
        query = patientQueries.getInpatientList;
      } else {
        // Fallback cho các query khác
        query = {
          id: queryId,
          type: 'select',
          sql: `SELECT * FROM Patients WHERE PatientId = @PatientId`,
          parameters: ['PatientId']
        };
      }
      
      // Chuẩn bị query
      let sql = query.sql;
      
      // Sử dụng hàm prepareQuery nếu có
      if (typeof query.prepareQuery === 'function') {
        sql = query.prepareQuery(sql, parameters);
      }
      
      const preparedQuery = {
        id: uuidv4(),
        type: query.type,
        sql: sql,
        parameters: parameters
      };
      
      return new Promise((resolve, reject) => {
        // Kiểm tra xem có client nào kết nối không
        const connectedClients = Array.from(this.wss.clients)
          .filter(client => client.readyState === WebSocket.OPEN);
        
        if (connectedClients.length === 0) {
          return reject(new Error('No connected clients available'));
        }

        // Store promise handlers
        this.pendingQueries.set(preparedQuery.id, { resolve, reject });

        // Gửi query đến tất cả clients
        const queryMessage = {
          QueryId: preparedQuery.id,
          QueryType: preparedQuery.type,
          SqlQuery: preparedQuery.sql,
          Parameters: preparedQuery.parameters
        };

        console.log(`Gửi query ${preparedQuery.id} đến ${connectedClients.length} clients`);
        
        // Cập nhật thời điểm gửi query gần nhất
        this.lastQueryTime = Date.now();
        
        connectedClients.forEach(client => {
          client.send(JSON.stringify(queryMessage));
        });

        // Timeout sau 30 giây
        setTimeout(() => {
          if (this.pendingQueries.has(preparedQuery.id)) {
            console.log(`Query ${preparedQuery.id} timeout`);
            this.pendingQueries.delete(preparedQuery.id);
            reject(new Error('Query timeout'));
          }
        }, 30000);
      });
    } catch (error) {
      console.error('Error preparing query:', error);
      throw error;
    }
  }

  async processMessageQueue() {
    if (this.isProcessing || this.messageQueue.length === 0) return;

    this.isProcessing = true;
    const availableWorkers = Array.from(this.workers.entries())
      .filter(([_, worker]) => !worker.busy);

    while (this.messageQueue.length > 0 && availableWorkers.length > 0) {
      const message = this.messageQueue.shift();
      const [workerId, worker] = availableWorkers.shift();
      
      worker.busy = true;
      worker.postMessage(message);
    }

    this.isProcessing = false;
  }

  async handleResponse(response) {
    try {
      // Kiểm tra xem có phải là định dạng mới không
      if (response.QueryId && response.Success !== undefined && response.Data) {
        console.log(`Nhận phản hồi cho query ${response.QueryId} với ${response.Data.length} bản ghi`);
        
        // Tìm pending query
        const pendingQuery = this.pendingQueries.get(response.QueryId);
        
        // Lưu dữ liệu vào database
        if (response.Success && Array.isArray(response.Data) && response.Data.length > 0) {
          console.log(`Lưu ${response.Data.length} bản ghi vào database`);
          await this.saveInpatientData(response.Data);
        }
        
        // Resolve promise nếu có
        if (pendingQuery) {
          this.pendingQueries.delete(response.QueryId);
          
          if (response.Success) {
            pendingQuery.resolve(response.Data);
          } else {
            pendingQuery.reject(new Error(response.Message || 'Unknown error'));
          }
        } else {
          console.log(`Không tìm thấy pending query cho ${response.QueryId}, có thể đã timeout`);
        }
        
        return;
      }
      
      // Xử lý các định dạng khác (nếu cần)
      console.log('Nhận được message không phải định dạng mới, bỏ qua');
    } catch (error) {
      console.error('Error handling response:', error);
    }
  }

  async saveInpatientData(inpatients) {
    console.log(`Bắt đầu lưu ${inpatients.length} bệnh nhân vào database`);
    
    // Lưu từng bệnh nhân vào database
    for (const inpatient of inpatients) {
      try {
        // Chuẩn hóa dữ liệu
        const patientData = {
          PatientId: inpatient.BenhAn_Id.toString(),
          Name: inpatient.TenBenhNhan,
          AdmissionDate: inpatient.ThoiGianVao,
          Department: inpatient.TenPhongBan,
          MedicalRecordNumber: inpatient.SoBenhAn,
          AdmissionNumber: inpatient.SoVaoVien,
          DiagnosisCode: inpatient.ICD_VaoKhoa
        };
        
        console.log(`Lưu bệnh nhân: ${patientData.PatientId} - ${patientData.Name}`);
        
        // Kiểm tra xem bệnh nhân đã tồn tại chưa
        const existingPatient = await Patient.findByPatientId(patientData.PatientId);
        
        if (existingPatient) {
          console.log(`Bệnh nhân ${patientData.PatientId} đã tồn tại, cập nhật thông tin`);
          await Patient.update(patientData);
        } else {
          console.log(`Bệnh nhân ${patientData.PatientId} chưa tồn tại, tạo mới`);
          await Patient.create(patientData);
        }
      } catch (error) {
        console.error(`Error saving inpatient ${inpatient.BenhAn_Id}:`, error);
      }
    }
    
    console.log(`Đã lưu xong ${inpatients.length} bệnh nhân vào database`);
  }

  handleWorkerResponse(result) {
    const { queryId, success, data, error } = result;
    const pendingQuery = this.pendingQueries.get(queryId);

    if (pendingQuery) {
      this.pendingQueries.delete(queryId);
      
      if (success) {
        pendingQuery.resolve(data);
        this.savePatientData(data);
      } else {
        pendingQuery.reject(new Error(error));
      }
    }

    // Mark worker as available
    const worker = Array.from(this.workers.entries())
      .find(([_, w]) => w.busy);
    if (worker) {
      worker[1].busy = false;
    }

    // Process next message if any
    this.processMessageQueue();
  }

  async savePatientData(data) {
    if (!Array.isArray(data)) return;
    
    const savePromises = data.map(async patientData => {
      try {
        await Patient.create(patientData);
      } catch (error) {
        console.error('Error saving patient data:', error);
      }
    });

    await Promise.allSettled(savePromises);
  }

  shutdown() {
    for (const [_, worker] of this.workers) {
      worker.terminate();
    }
  }

  getQueueInfo() {
    return this.scheduler.getQueueInfo();
  }

  // Gửi heartbeat để kiểm tra kết nối
  sendHeartbeat() {
    const connectedClients = Array.from(this.wss.clients)
      .filter(client => client.readyState === WebSocket.OPEN);
    
    connectedClients.forEach(client => {
      client.ping();
    });
  }

  // Thêm phương thức mới để gửi query mà không cần đợi phản hồi
  async sendQueryWithoutResponse(queryId, parameters) {
    try {
      console.log(`Attempting to send query without response: ${queryId}`);
      
      // Tìm query trong query manager
      const queryManager = require('../queries');
      const patientQueries = require('../queries/patient-queries');
      
      // Tìm query dựa trên queryId
      let query;
      if (queryId === 'GET_INPATIENT_LIST') {
        query = patientQueries.getInpatientList;
      } else {
        // Fallback cho các query khác
        query = {
          id: queryId,
          type: 'select',
          sql: `SELECT * FROM Patients WHERE PatientId = @PatientId`,
          parameters: ['PatientId']
        };
      }
      
      // Chuẩn bị query
      let sql = query.sql;
      
      // Sử dụng hàm prepareQuery nếu có
      if (typeof query.prepareQuery === 'function') {
        sql = query.prepareQuery(sql, parameters);
      }
      
      const preparedQuery = {
        id: uuidv4(),
        type: query.type,
        sql: sql,
        parameters: parameters
      };
      
      // Kiểm tra xem có client nào kết nối không
      const connectedClients = Array.from(this.wss.clients)
        .filter(client => client.readyState === WebSocket.OPEN);
      
      console.log(`Found ${connectedClients.length} connected clients`);
      
      if (connectedClients.length === 0) {
        console.log('No connected clients available');
        return false;
      }

      // Gửi query đến tất cả clients
      const queryMessage = {
        QueryId: preparedQuery.id,
        QueryType: preparedQuery.type,
        SqlQuery: preparedQuery.sql,
        Parameters: preparedQuery.parameters
      };

      console.log(`Gửi query ${preparedQuery.id} đến ${connectedClients.length} clients (không đợi phản hồi)`);
      
      connectedClients.forEach(client => {
        client.send(JSON.stringify(queryMessage));
      });
      
      console.log(`Query ${preparedQuery.id} sent to ${connectedClients.length} clients`);
      return true;
    } catch (error) {
      console.error('Error sending query without response:', error);
      return false;
    }
  }

  // Thêm phương thức mới để xử lý dữ liệu từ response
  async savePatientDataFromResponse(data) {
    try {
      // Chuẩn hóa dữ liệu
      const patientData = {
        PatientId: data.BenhAn_Id || data.PatientId,
        Name: data.TenBenhNhan || data.Name,
        Age: data.Tuoi || data.Age,
        AdmissionDate: data.ThoiGianVao || data.AdmissionDate,
        Department: data.TenPhongBan || data.Department,
        MedicalRecordNumber: data.SoBenhAn || data.MedicalRecordNumber,
        AdmissionNumber: data.SoVaoVien || data.AdmissionNumber,
        DiagnosisCode: data.ICD_VaoKhoa || data.DiagnosisCode
      };
      
      // Kiểm tra xem có PatientId không
      if (!patientData.PatientId) {
        console.error('Cannot save patient data: Missing PatientId');
        return;
      }
      
      // Lưu vào database
      console.log(`Saving patient data for ${patientData.PatientId}`);
      await Patient.create(patientData);
      console.log(`Successfully saved patient data for ${patientData.PatientId}`);
      
      // Nếu có dữ liệu dịch vụ, lưu thêm
      if (data.Services && Array.isArray(data.Services)) {
        await this.savePatientServices(patientData.PatientId, data.Services);
      }
    } catch (error) {
      console.error('Error saving patient data from response:', error);
    }
  }

  // Thêm phương thức để lưu dịch vụ của bệnh nhân
  async savePatientServices(patientId, services) {
    try {
      const PatientService = require('../models/PatientService');
      
      for (const service of services) {
        await PatientService.create({
          patient_id: patientId,
          service_code: service.ServiceCode || service.MaDichVu,
          service_name: service.ServiceName || service.TenDichVu,
          service_date: service.ServiceDate || service.NgayDichVu,
          quantity: service.Quantity || service.SoLuong || 1,
          amount: service.Amount || service.ThanhTien || 0
        });
      }
      
      console.log(`Saved ${services.length} services for patient ${patientId}`);
    } catch (error) {
      console.error(`Error saving services for patient ${patientId}:`, error);
    }
  }
}

module.exports = WebSocketHandler; 