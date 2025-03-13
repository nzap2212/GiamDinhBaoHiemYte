const db = require('../config/database');

class Patient {
  static async create(patientData) {
    try {
      // Kiểm tra các trường bắt buộc
      if (!patientData.PatientId || !patientData.Name) {
        throw new Error('PatientId and Name are required');
      }
      
      // Chuẩn bị dữ liệu
      const data = [
        patientData.PatientId,
        patientData.Name,
        patientData.Age || null,
        patientData.AdmissionDate || null,
        patientData.Department || null,
        patientData.MedicalRecordNumber || null,
        patientData.AdmissionNumber || null,
        patientData.DiagnosisCode || null
      ];
      
      const [result] = await db.execute(
        `INSERT INTO patients 
         (patient_id, name, age, admission_date, department, medical_record_number, admission_number, diagnosis_code) 
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        data
      );
      
      console.log(`Created patient ${patientData.PatientId} with ID ${result.insertId}`);
      return result;
    } catch (error) {
      console.error('Error creating patient:', error);
      throw error;
    }
  }

  static async update(patientData) {
    try {
      // Kiểm tra PatientId
      if (!patientData.PatientId) {
        throw new Error('PatientId is required for update');
      }
      
      const [result] = await db.execute(
        `UPDATE patients 
         SET name = ?, 
             age = ?, 
             admission_date = ?, 
             department = ?, 
             medical_record_number = ?, 
             admission_number = ?, 
             diagnosis_code = ?,
             updated_at = CURRENT_TIMESTAMP
         WHERE patient_id = ?`,
        [
          patientData.Name,
          patientData.Age || null,
          patientData.AdmissionDate || null,
          patientData.Department || null,
          patientData.MedicalRecordNumber || null,
          patientData.AdmissionNumber || null,
          patientData.DiagnosisCode || null,
          patientData.PatientId
        ]
      );
      
      console.log(`Updated patient ${patientData.PatientId}, affected rows: ${result.affectedRows}`);
      return result;
    } catch (error) {
      console.error('Error updating patient:', error);
      throw error;
    }
  }

  static async findByPatientId(patientId) {
    try {
      const [rows] = await db.execute(
        'SELECT * FROM patients WHERE patient_id = ?',
        [patientId]
      );
      
      return rows.length > 0 ? rows[0] : null;
    } catch (error) {
      console.error('Error finding patient:', error);
      throw error;
    }
  }

  static async getActive() {
    try {
      const [rows] = await db.execute(
        'SELECT * FROM patients WHERE discharge_date IS NULL'
      );
      return rows;
    } catch (error) {
      console.error('Error getting active patients:', error);
      throw error;
    }
  }

  static async markAsDischarged(patientId, dischargeDate) {
    try {
      const [result] = await db.execute(
        'UPDATE patients SET discharge_date = ? WHERE patient_id = ?',
        [dischargeDate, patientId]
      );
      return result;
    } catch (error) {
      console.error('Error marking patient as discharged:', error);
      throw error;
    }
  }
}

module.exports = Patient; 