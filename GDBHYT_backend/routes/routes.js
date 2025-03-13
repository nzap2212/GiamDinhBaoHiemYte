const router = require("express").Router();
const quanLyHoSo130Routes = require('./GiamDinh130_routes/QuanLyHoSo130');

router.get("/", (req, res) => {
  res.status(400).send("Forbidden");
});

// Sử dụng routes cho quản lý hồ sơ 130
router.use('/quanly-hoso130', quanLyHoSo130Routes);

module.exports = router;
