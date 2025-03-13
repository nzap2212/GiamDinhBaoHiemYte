const mysql = require('mysql2/promise');

let pool;

async function initializeDatabase() {
  try {
    pool = mysql.createPool({
      host: 'localhost',
      user: 'root',
      password: 'Giap221202@',
      database: 'hospital_db',
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0
    });

    // Kiểm tra kết nối
    const connection = await pool.getConnection();
    console.log('✅ Database connected successfully');
    connection.release();
    
    // Tạo bảng nếu chưa tồn tại
    await createTablesIfNotExist();
    
    return pool;
  } catch (err) {
    console.error('❌ Database connection error:', err);
    // Thử kết nối lại sau 5 giây
    console.log('Retrying connection in 5 seconds...');
    setTimeout(initializeDatabase, 5000);
    return null;
  }
}

async function createTablesIfNotExist() {
  try {
    // Tạo bảng patients nếu chưa tồn tại
    await pool.execute(`
      CREATE TABLE IF NOT EXISTS patients (
        id INT AUTO_INCREMENT PRIMARY KEY,
        patient_id VARCHAR(50) UNIQUE NOT NULL,
        name VARCHAR(100) NOT NULL,
        age INT,
        admission_date DATETIME,
        discharge_date DATETIME,
        department VARCHAR(100),
        medical_record_number VARCHAR(50),
        admission_number VARCHAR(50),
        diagnosis_code VARCHAR(20),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `);
    
    // Tạo bảng patient_services nếu chưa tồn tại
    await pool.execute(`
      CREATE TABLE IF NOT EXISTS patient_services (
        id INT AUTO_INCREMENT PRIMARY KEY,
        patient_id VARCHAR(50),
        service_code VARCHAR(50),
        service_name VARCHAR(100),
        service_date DATETIME,
        quantity INT,
        amount DECIMAL(10,2),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
      )
    `);
    
    console.log('✅ Database tables checked/created successfully');
  } catch (error) {
    console.error('❌ Error creating tables:', error);
  }
}

// Khởi tạo database khi import module
initializeDatabase();

module.exports = {
  getPool: () => pool,
  execute: async (sql, params) => {
    if (!pool) {
      await initializeDatabase();
    }
    return pool.execute(sql, params);
  }
}; 