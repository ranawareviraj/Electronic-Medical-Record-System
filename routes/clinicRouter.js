const express = require("express");
const controller = require("../controllers/clinicController");

const router = express.Router();

router.get("/", controller.index);
router.get("/create-new-patient", controller.navigateToCreateNewPatient);
router.post("/create-new-patient", controller.createNewPatient);
router.get("/view-patient-details", controller.viewPatientDetails);
router.get("/view-patient-visits", controller.viewAllPatientVisits);
router.get("/edit-patient-details/:id", controller.getPatientDetails);
router.put("/edit-patient-details/:id", controller.editPatientDetails);

module.exports = router;
