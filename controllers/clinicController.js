const { sequelize } = require("../db/db");

exports.index = async (req, res) => {
  res.render("../views/index");
};

exports.navigateToCreateNewPatient = async (req, res) => {
  let insurerDetails = await sequelize.query(`Call getInsurerDetails();`);
  res.render("../views/clinic/create-new-patient.ejs", {
    insurerDetails,
  });
};

exports.createNewPatient = async (req, res, next) => {
  let patient = req.body;
  try {
    let result = await sequelize.query(`Call generateNextInsuranceNumber();`);
    let result1 = await sequelize.query(`Call getNextPatientDetailsNumber();`);
    let insurance_id = result[0].insurance_id;
    let patientID = result1[0].patient_id;
    let patients = await sequelize.query(
      `Call enterPatientDetails('${patientID}','${patient.firstName}','${patient.lastName}','${patient.patientAddress}','${patient.patientAge}','${insurance_id}','${patient.Insurance_Number}','${patient.insurerID}','${patient.insuranceType}');`
    );
    req.flash("success", "Patient added succesfully..!");
    res.redirect("/view-patient-details");
  } catch (error) {
    console.log(error);
    next(error);
  }
};

exports.getPatientDetails = async (req, res) => {
  let id = req.params.id;
  let patients = await sequelize.query(
    `Call getPatientsInformationUsingID(${id});`
  );
  if (patients.length) {
    let patient = patients[0];
    let insuranceCompanyDetails = await sequelize.query(
      `Call getInsurerDetails();`
    );
    res.render("../views/clinic/edit-patient.ejs", {
      patient,
      insuranceCompanyDetails,
    });
  } else {
    let err = new Error("No patient with id " + id + " found to update.");
    err.status = 404;
    next(err);
  }
};

exports.editPatientDetails = async (req, res, next) => {
  let id = req.params.id;
  let patient = req.body;
  try {
    let patients = await sequelize.query(
      `Call updatePatientDetails(${id},'${patient.first_name}','${patient.last_name}','${patient.address}','${patient.age}','${patient.insurance_id}','${patient.insurance_number}','${patient.insurer_id}','${patient.insurance_type}');`
    );
    req.flash("success", "Patient details updated successfully..!");
    res.redirect("/view-patient-details");
  } catch (error) {
    next(error);
  }
};

exports.viewPatientDetails = async (req, res) => {
  let patients = await sequelize.query("Call getPatientDetails();");
  patients.sort((a, b) => a.patient_id - b.patient_id);


  if (patients.length) {
    res.render("../views/clinic/patients", { patients });
  } else {
    patients = [];
    res.render("../views/clinic/patients", { patients });
  }
};

exports.viewAllPatientVisits = async (req, res) => {
  let patients = await sequelize.query("Call getListOfAllAppointments();");

  if (patients.length) {
    res.render("../views/clinic/all-visits", { patients });
  } else {
    patients = [];
    res.render("../views/clinic/patients", { patients });
  }
};
