const db = require('../config/database');

class PatientService {
  static async create(serviceData) {
    try {
      const [result] = await db.execute(
        'INSERT INTO patient_services (patient_id, service_code, service_name, service_date, quantity, amount) VALUES (?, ?, ?, ?, ?, ?)',
        [
          serviceData.patient_id,
          serviceData.service_code,
          serviceData.service_name,
          serviceData.service_date,
          serviceData.quantity,
          serviceData.amount
        ]
      );
      return result;
    } catch (error) {
      console.error('Error creating patient service:', error);
      throw error;
    }
  }

  static async getByPatientId(patientId) {
    try {
      const [rows] = await db.execute(
        'SELECT * FROM patient_services WHERE patient_id = ?',
        [patientId]
      );
      return rows;
    } catch (error) {
      console.error('Error getting patient services:', error);
      throw error;
    }
  }
}

module.exports = PatientService; 