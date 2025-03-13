// Định nghĩa các loại query
const QueryTypes = {
  SELECT: 'select',
  INSERT: 'insert',
  UPDATE: 'update',
  DELETE: 'delete'
};

// Định nghĩa các nhóm query
const QueryGroups = {
  PATIENT: 'patient',
  SERVICE: 'service',
  BILLING: 'billing',
  REPORT: 'report'
};

module.exports = {
  QueryTypes,
  QueryGroups
}; 