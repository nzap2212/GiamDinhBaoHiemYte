const { QueryTypes } = require('./index');

const PatientQueries = {
  // Các query khác...

  // Query lấy danh sách bệnh nhân nội trú
  getInpatientList: {
    id: 'GET_INPATIENT_LIST',
    type: QueryTypes.SELECT,
    sql: `
      SELECT TOP 1 *
      FROM NoiTru_LuuTru ntlt
      INNER JOIN BenhAn ba ON ntlt.BenhAn_Id = ba.BenhAn_Id
      INNER JOIN DM_BenhNhan dmbn ON ba.BenhNhan_Id = dmbn.BenhNhan_Id
      INNER JOIN DM_PhongBan dmpb ON ntlt.PhongBan_Id = dmpb.PhongBan_Id
      WHERE ntlt.LyDoVao_Code = 'NM'
      AND ntlt.ThoiGianRa IS NULL
      ORDER BY ntlt.ThoiGianVao DESC
    `,
    description: 'Lấy 1 bệnh nhân nội trú đang điều trị mới nhất',
    parameters: []
  },

};

module.exports = PatientQueries; 