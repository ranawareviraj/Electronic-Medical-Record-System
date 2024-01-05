
/*
This file contains below details:

I. Functions:
	isSlotAvailable :- This function for checking availability of the slot. It return whether requested slot is available of not.

II. Triggers:
	a. createInvoiceForappointmentInfo: This trigger adds new bill into invoice table
	b. updateInvoiceForUpdateInAppointmentInfo: This Trigger updates the  Invoice on appointment update.
    c. updateBillForDeleteInAppointmentInfo: This Trigger updates the  Invoice on appointment update

III. Procedures
	1. getPatientDetails: Stored Procedure for fetching Patient details
	2. getInsurerDetails: Stored Procedure for fetching Insurer Details
	3. getPatientsInformationUsingID: Stored Procedure to retrieve Patient details using patient_id
	4. enterPatientDetails: Stored Procedure for adding patient information
	5. updatePatientDetails: Update Patient Details into clinic database
	6. generateNextInsuranceNumber: Stored Procedure to find last insurance id and generate incremented insurance_id
	7. getNextPatientDetailsNumber: Stored Procedure to find last patient id and generate incremented patient_id
	8. getListOfAllAppointments: Stored Procedure for Printing out a list of all visits to the clinic ordered by visit date, visit time, patient name, their diagnoses, and physician name
	9. deleteInvoice: Stored Procedure for deleting specific invoice
	10. insertData: Initialize DB with some preloaded data
    
IV. Views
	1. patientInvoice: Create view to see Patient_Invoice along with appointment and treatment information.     

*/

use clinic_db;

-- ********* SECTION I : Functions *********
-- 1. This function for checking availability of the slot
DELIMITER //
CREATE FUNCTION isSlotAvailable(
    dentist_id            INT,
    slotStartDateTime   DATETIME,
    slotEndDateTime     DATETIME
) RETURNS BOOLEAN DETERMINISTIC
BEGIN
    RETURN CASE WHEN EXISTS (
        -- contain records iff the slot clashes with an existing appointment
        SELECT TRUE
        FROM appointment AS a
        WHERE
                CONVERT(slotStartDateTime, TIME) < a.appt_end_time   
            AND CONVERT(slotEndDateTime,   TIME) > a.appt_start_time
            AND a.dentist_id = dentist_id
            AND a.appointment_date = CONVERT(slotStartDateTime, DATE)
    ) THEN FALSE ELSE TRUE
    END;
END; //
DELIMITER ;


-- ********* SECTION II : TRIGGERS *********
-- 1. This Trigger ensure that appointments do not conflict
DELIMITER //
CREATE TRIGGER checkForNewAppointmentsDoNotClash
    BEFORE INSERT ON appointment
    FOR EACH ROW
BEGIN
    IF NOT isSlotAvailable(
        NEW.dentist_id,
        CAST( CONCAT(NEW.appointment_date, ' ', NEW.appt_start_time)  AS DATETIME ),
        CAST( CONCAT(NEW.appointment_date, ' ', NEW.appt_end_time)    AS DATETIME )
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Appointment Slot is not available. Please select another time slot.';
    END IF;
END; //
DELIMITER ;

-- 2. Trigger to adds new bill into invoice table
DELIMITER //
CREATE TRIGGER createInvoiceForappointmentInfo
    after INSERT ON appointment_info
    FOR EACH ROW
BEGIN
	DECLARE Previous_Bill DECIMAL(9,2);
    DECLARE Current_Bill DECIMAL(9,2);
	if exists (select * from invoice b where b.appointment_id = NEW.appointment_id)
    then 
		 SET Previous_Bill = (SELECT bill1.invoice_amount from invoice bill1 where bill1.appointment_id = NEW.appointment_id);
         SET Current_Bill = (Select P_Details.treatment_fee 
				from treatment P_Details 
                join appointment_info af 
					on af.appointment_id = P_Details.treatment_id 
				where P_Details.treatment_id = NEW.treatment_id
                and af.appointment_id = NEW.appointment_id);
         UPDATE invoice bill2 
			SET bill2.invoice_amount = Previous_Bill + Current_Bill
			where bill2.appointment_id = NEW.appointment_id;
         SET Previous_Bill = 0;
         SET Current_Bill = 0;
	else
		INSERT INTO invoice (appointment_id, invoice_amount, patient_id, insurance_id)
		select a.appointment_id, P_Details.treatment_fee, pd.patient_id, pd.insurance_id from 
		appointment_info as af
		join treatment P_Details
			ON af.appointment_id = P_Details.treatment_id
		JOIN appointment a
			on a.appointment_id = af.appointment_id
		join patient pd
			on pd.patient_id = a.patient_id
        where af.appointment_id = NEW.appointment_id
			and af.appointment_id = NEW.appointment_id;
	end if;
END; //
DELIMITER ;


-- 3. This Trigger updates the  Invoice on appointment update
DELIMITER //
CREATE TRIGGER updateInvoiceForUpdateInAppointmentInfo
    after UPDATE ON appointment_info
    FOR EACH ROW
BEGIN
	DECLARE Previous_Bill DECIMAL(9,2);
    DECLARE Current_Value DECIMAL(9,2);
    DECLARE Previous_Value DECIMAL(9,2);
	SET Previous_Bill = (SELECT bill1.invoice_amount from invoice bill1 where bill1.appointment_id = NEW.appointment_id);
	SET Current_Value = (Select P_Details.treatment_fee from treatment P_Details where P_Details.treatment_id = NEW.treatment_id);
	SET Previous_Value = (Select P_Details.treatment_fee from treatment P_Details where P_Details.treatment_id = OLD.treatment_id);
	UPDATE invoice bill2 
			SET bill2.invoice_amount = Previous_Bill + Current_Value - Previous_Value
			where bill2.appointment_id = NEW.appointment_id;
         SET Previous_Bill = 0;
         SET Current_Value = 0;
         SET Previous_Value = 0;
END; //
DELIMITER ;



-- 4. This Trigger updates Invoice if on appointment deletion/cancellation
DELIMITER //
CREATE TRIGGER updateBillForDeleteInAppointmentInfo
    after DELETE ON appointment_info
    FOR EACH ROW
BEGIN
	DECLARE Previous_Bill DECIMAL(9,2);
    DECLARE Previous_Value DECIMAL(9,2);
	SET Previous_Bill = (SELECT bill1.invoice_amount from invoice bill1 where bill1.appointment_id = OLD.appointment_id);
	SET Previous_Value = (Select P_Details.Fee from treatment P_Details where P_Details.treatment_id = OLD.treatment_id);
    IF (Previous_Bill - Previous_Value) = 0
    then delete from invoice bill2 where bill2.appointment_id = OLD.appointment_id;
	else
	 UPDATE invoice bill2 
			SET bill2.invoice_amount = Previous_Bill - Previous_Value
			where bill2.appointment_id = OLD.appointment_id;
         SET Previous_Bill = 0;
         SET Previous_Value = 0;
	end if;
END; //
DELIMITER ;

-- ********* SECTION III : Views *********				  
-- 1. Create view to see Patient_Invoice along with appointment and treatment information.     
CREATE VIEW patientInfo AS
SELECT 
	invoice.invoice_id as Invoice_Number,
    patient.patient_id as Patient_ID,
    patient.first_name as First_Name ,
    patient.last_name as Last_Name,
	invoice.insurance_id,
    appointment.appointment_date as Appointment_Date,
    appointment.appt_start_time as Start_Time,
    treatment.treatment_details as Treatment_Details,
	treatment.treatment_fee as Treatment_Fee,
    dentist.dentist_name as Dentist_Name,
    invoice.invoice_amount as Total_Bill
FROM
    patient
        INNER JOIN
    appointment ON patient.patient_id = appointment.patient_id
        INNER JOIN
    appointment_info ON appointment.appointment_id = appointment_info.appointment_id
        INNER JOIN
    treatment ON appointment_info.treatment_id = treatment.treatment_id
        INNER JOIN
    dentist ON appointment.dentist_id = dentist.dentist_id
     INNER JOIN
    invoice ON invoice.appointment_id = appointment.appointment_id
ORDER BY 
	appointment.appointment_date, 
    appointment.appt_start_time,
    treatment.treatment_details, 
    patient.first_name, 
    patient.last_name;

-- ********* SECTION IV : STORED PROCEDURES *********
 -- 1. Stored Procedure for fetching Patient details  --
DELIMITER //
CREATE PROCEDURE getPatientDetails()
BEGIN
	SELECT 
		*
	FROM
		patient
			INNER JOIN
		insurance ON patient.insurance_id = insurance.insurance_id
			JOIN
		insurer ON insurance.insurer_id = insurer.insurer_id;
END //
DELIMITER ;

-- Uncomment below line to test stored procedure getPatientDetails() 
-- call getPatientDetails();


-- 2. Stored Procedure for fetching Insurer Details  --
DELIMITER //
CREATE PROCEDURE getInsurerDetails()
BEGIN
 SELECT * FROM insurer;
 END //
DELIMITER ;

-- Uncomment below line to test stored procedure getInsurerDetails() 
-- call getInsurerDetails();


 -- 3. Stored Procedure to retrieve Patient details using patient_id  --
DELIMITER //
CREATE PROCEDURE getPatientsInformationUsingID(
  	IN ID INT
)
BEGIN
	SELECT 
		*
	FROM
		patient
			INNER JOIN
		insurance ON patient.insurance_id = insurance.insurance_id
			INNER JOIN
		insurer ON insurance.insurer_id = insurer.insurer_id
	WHERE
		patient_id = ID;
END //
DELIMITER ;

-- Uncomment below line to teststored procedure getPatientsInformationUsingID();
-- call getPatientsInformationUsingID(111);


 -- 4. Stored Procedure for adding patient information  --
DELIMITER //
CREATE PROCEDURE enterPatientDetails(
	IN patient_id INT,
	IN first_name VARCHAR(45),
	IN last_name VARCHAR(45),
	IN address VARCHAR(100) ,
	IN age INT,
	IN insurance_id INT,
    IN insurance_number INT,
	IN insurer_id INT,
	IN insurance_type VARCHAR(45)
  )
BEGIN
	-- Insert Insurance Details
	INSERT INTO insurance values (insurance_id, insurance_number, insurer_id, insurance_type);
    
    -- Insert Patient Details
	INSERT INTO patient  VALUES (patient_id, first_name, last_name, address, age, insurance_id);
END //
DELIMITER ;

-- 5. Update Patient Details into clinic database
DELIMITER //
CREATE PROCEDURE updatePatientDetails(
  IN patientId INT,
	IN firstName VARCHAR(45),
	IN lastName VARCHAR(45),
	IN patientAddress VARCHAR(100) ,
	IN patientAge INT,
	IN insuranceId INT,
    IN insuranceNumber INT,
	IN insurerId INT,
	IN insuranceType VARCHAR(45)
  )
BEGIN
UPDATE patient
	SET
		first_name = firstName,
		last_name  = lastName ,
		address =  patientAddress,
		age = patientAge,
		insurance_id  = insuranceId
	WHERE 
		patient_id  = patientId;

UPDATE insurance
	SET
		insurer_id = insurerId,
		insurance_number = insuranceNumber,
		insurance_type = insuranceType
	WHERE
		insurance_id = insuranceId;
END //
DELIMITER ;
-- This will be called from UI to modify patient details


-- 6. Stored Procedure to find last insurance id and generate incremented insurance_id
DELIMITER //
CREATE PROCEDURE generateNextInsuranceNumber()
BEGIN
	SELECT MAX(insurance_id) + 1 as insurance_id from insurance;
END //
DELIMITER ;

-- 7. Stored Procedure to find last patient id and generate incremented patient_id
DELIMITER //
CREATE PROCEDURE getNextPatientDetailsNumber()
BEGIN
	SELECT MAX(patient_id) + 1 as patient_id from patient;
END //
DELIMITER ;



-- 8. Stored Procedure for Printing out a list of all visits to the clinic ordered by visit date, visit time, patient
-- name, their diagnoses, and physician name
DELIMITER //
CREATE PROCEDURE getListOfAllAppointments()
BEGIN
	SELECT
		patient.patient_id, 
        patient.first_name, 
        patient.last_name, 
        appointment.appointment_date,
        appointment.appt_start_time,
		treatment.treatment_details, 
        dentist.dentist_name
	FROM
		patient
			INNER JOIN
		appointment ON patient.patient_id = appointment.patient_id
			INNER JOIN
		appointment_info ON appointment.appointment_id = appointment_info.appointment_id
			INNER JOIN
		treatment ON appointment_info.treatment_id = treatment.treatment_id
			INNER JOIN
		dentist ON appointment.dentist_id = dentist.dentist_id
	ORDER BY 
		appointment.appointment_date, 
        appointment.appt_start_time, 
        treatment.treatment_details,
        dentist.dentist_name;
END //
DELIMITER ;   

-- 9. Stored Procedure for deleting specific invoice
DELIMITER //
CREATE PROCEDURE deleteInvoice(
  IN invoiceId INT)
BEGIN  
	DELETE FROM invoice 
WHERE
    invoice_id = invoiceId;  
END //
DELIMITER ;


DELIMITER //
CREATE PROCEDURE insertData()
BEGIN
INSERT INTO insurer(insurer_name) VALUES ('ICICI'),('HDFC'),('Pegram'),('Soby'),('Byrd'),('Martin');
INSERT INTO insurance values 
(111,313123, 4, 'Gold'),
(112,323123, 3, 'Gold'),
(113,333123, 3, 'Gold'),
(114,343123,1, 'Gold'),
(115,353123, 1, 'Gold'),
(116,363123, 2, 'Gold'),
(117,373123, 2, 'Gold'),
(118,383123,2, 'Gold'),
(119,3831223,1, 'Gold'),
(120,393123, 2, 'Gold'),
(121,303123, 3, 'Gold'),
(122,312123, 2, 'Silver'),
(123,31312342, 4, 'Silver'),
(124,3134123, 2, 'Silver'),
(125,313523, 1, 'Silver'),
(126,313623, 2, 'Silver'),
(127,313723, 1, 'Platinum'),
(128,313873, 3, 'Platinum'),
(129,313923, 2, 'Platinum'),
(130,313023, 1, 'Platinum'),
(131,313753, 4, 'Platinum'),
(132,313893, 2, 'Gold'),
(133,3138353, 1, 'Gold'),
(134,3139235, 3, 'Gold'),
(135,3132235, 2, 'Gold'),
(136,3133234, 1, 'Gold'),
(137,3132232, 3, 'Gold'),
(138,31352343, 1, 'Gold'),
(139,31332334, 2, 'Gold'),
(140,31383355, 1, 'Silver'),
(141,31382354, 4, 'Gold'),
(142,31312335, 1, 'Gold'),
(143,3131523, 3, 'Gold'),
(144,31312533, 1, 'Gold'),
(145,3134353, 1, 'Gold'),
(146,3131533, 2, 'Gold'),
(147,3131623, 2, 'Gold'),
(148,3131463, 2, 'Gold'),
(149,31312753, 1, 'Gold'),
(150,31312563, 2, 'Gold'),
(151,313126573, 3, 'Gold'),
(152,31317623, 2, 'Silver'),
(153,313126573, 4, 'Silver'),
(154,31315723, 2, 'Silver'),
(155,31312763, 1, 'Silver'),
(156,31312773, 2, 'Silver'),
(157,313127563, 1, 'Platinum'),
(158,31312653, 3, 'Platinum'),
(159,313126753, 2, 'Platinum'),
(160,31312763, 1, 'Platinum'),
(161,31312763, 4, 'Platinum'),
(162,31312673, 2, 'Gold'),
(163,31312673, 1, 'Gold'),
(164,313126433, 3, 'Gold'),
(165,31312433, 2, 'Gold'),
(166,313124323, 1, 'Gold'),
(167,332413123, 3, 'Gold'),
(168,3134223, 1, 'Gold'),
(169,313123, 2, 'Gold'),
(170,3143523, 1, 'Silver'),
(171,313123, 2, 'Silver'),
(172,31314523, 1, 'Silver'),
(173,3131223, 1, 'Gold'),
(174,31312533, 3, 'Gold'),
(175,313125433, 2, 'Gold'),
(176,3131253, 1, 'Gold')
;

INSERT INTO patient  VALUES 
(1,'Zoe','Abraham',' Wrangler Street Hope Mills, NC 28348',43,111),
(2,'Yvonne','Allan','8775 High Ridge Drive Tabor City, NC 28463',44,112),
(3,'Wendy','Alsop','9449 Hill Street Raleigh, NC 27617',41,113),
(4,'Wanda','Anderson','90 Fletcher St. Raleigh, NC 27605',35,114),
(5,'Virginia','Arnold','9621 Fox Avenue Greensboro, NC 27412',43,115),
(6,'Victoria','Avery','98 Hill Ave. Spencer, NC 28159',29,116),
(7,'Vanessa','Bailey','23 Plymouth St. Roxboro, NC 27574',20,117),
(8,'Una','Baker','7248 Estate Street Cove City, NC 28523',22,118),
(9,'Tracey','Ball','64 S. Miles St. Reidsville, NC 27321',20,119),
(10,'Theresa','Bell','44 East Mandarin St. Hickory, NC 28601',45,120),
(11,'Sue','Berry','303 Birch Hill Drive Camden, NC 27921',28,121),
(12,'Stephanie','Black','7043 Pebble St. Bellarthur, NC 27811',34,122),
(13,'Sophie','Blake','7745 Second Dr. Teachey, NC 28464',24,123),
(14,'Sonia','Bond','714 Rosewood Street Gastonia, NC 28055',45,124),
(15,'Sarah','Bower','21 Wentworth Dr. Cramerton, NC 28032',20,125),
(16,'Samantha','Brown','27 Kirkland Ave. Pendleton, NC 27862',48,126),
(17,'Sally','Buckland','458 Stonybrook Circle Halifax, NC 27839',29,127),
(18,'Ruth','Burgess','888 Crystal Street Aydlett, NC 27916',20,128),
(19,'Rose','Butler','578 North Moonlight Dr. Ellenboro, NC 28040',22,129),
(20,'Rebecca','Cameron','8319 Revolution Drive Raleigh, NC 27612',37,130),
(21,'Rachel','Campbell','7923 South Wild Rose St. Moyock, NC 27958',38,131),
(22,'Pippa','Carr','50 Westport Avenue Manteo, NC 27954',47,132),
(23,'Penelope','Chapman','860 East Cedar Swamp St. Charlotte, NC 28260',38,133),
(24,'Olivia','Churchill','91 Walt Whitman Ave. Wagram, NC 28396',24,134),
(25,'Nicola','Clark','8513 Miller Ave. Wrightsville Beach, NC 28480',44,135),
(26,'Natalie','Clarkson','7383 Primrose Rd. Raleigh, NC 27614',22,136),
(27,'Molly','Coleman','9247 Colonel Ave. New Bern, NC 28563',40,137),
(28,'Michelle','Cornish','8775 High Ridge Drive Tabor City, NC 28463',20,138),
(29,'Melanie','Davidson','9449 Hill Street Raleigh, NC 27617',31,139),
(30,'Megan','Davies','90 Fletcher St. Raleigh, NC 27605',21,140),
(31,'Mary','Dickens','9621 Fox Avenue Greensboro, NC 27412',41,141),
(32,'Maria','Dowd','98 Hill Ave. Spencer, NC 28159',23,142),
(33,'Madeleine','Duncan','23 Plymouth St. Roxboro, NC 27574',31,143),
(34,'Lisa','Dyer','7248 Estate Street Cove City, NC 28523',42,144),
(35,'Lily','Edmunds','64 S. Miles St. Reidsville, NC 27321',43,145),
(36,'Lillian','Ellison','44 East Mandarin St. Hickory, NC 28601',37,146),
(37,'Leah','Ferguson','303 Birch Hill Drive Camden, NC 27921',23,147),
(38,'Lauren','Fisher','7043 Pebble St. Bellarthur, NC 27811',49,148),
(39,'Kylie','Forsyth','7745 Second Dr. Teachey, NC 28464',41,149),
(40,'Kimberly','Fraser','714 Rosewood Street Gastonia, NC 28055',43,150),
(41,'Katherine','Gibson','888 Crystal Street Aydlett, NC 27916',46,151),
(42,'Karen','Gill','578 North Moonlight Dr. Ellenboro, NC 28040',29,152),
(43,'Julia','Glover','8319 Revolution Drive Raleigh, NC 27612',33,153),
(44,'Joanne','Graham','7923 South Wild Rose St. Moyock, NC 27958',49,154),
(45,'Joan','Grant','50 Westport Avenue Manteo, NC 27954',26,155),
(46,'Jessica','Gray','860 East Cedar Swamp St. Charlotte, NC 28260',45,156),
(47,'Jennifer','Greene','91 Walt Whitman Ave. Wagram, NC 28396',40,157),
(48,'Jasmine','Hamilton','8513 Miller Ave. Wrightsville Beach, NC 28480',44,158),
(49,'Jane','Hardacre','7383 Primrose Rd. Raleigh, NC 27614',33,159),
(50,'Jan','Harris','9247 Colonel Ave. New Bern, NC 28563',47,160),
(51,'Irene','Hart','8775 High Ridge Drive Tabor City, NC 28463',35,161),
(52,'Heather','Hemmings','9449 Hill Street Raleigh, NC 27617',39,162),
(53,'Hannah','Henderson','888 Crystal Street Aydlett, NC 27916',40,163),
(54,'Grace','Hill','578 North Moonlight Dr. Ellenboro, NC 28040',43,164),
(55,'Gabrielle','Hodges','8319 Revolution Drive Raleigh, NC 27612',47,165),
(56,'Fiona','Howard','7923 South Wild Rose St. Moyock, NC 27958',23,166),
(57,'Felicity','Hudson','50 Westport Avenue Manteo, NC 27954',38,167),
(58,'Faith','Hughes','860 East Cedar Swamp St. Charlotte, NC 28260',24,168),
(59,'Emma','Hunter','91 Walt Whitman Ave. Wagram, NC 28396',30,169),
(60,'Emily','Ince','8513 Miller Ave. Wrightsville Beach, NC 28480',22,170),
(61,'Ella','Jackson','7383 Primrose Rd. Raleigh, NC 27614',29,171),
(62,'Elizabeth','James','9247 Colonel Ave. New Bern, NC 28563',33,172),
(63,'Dorothy','Johnston','8775 High Ridge Drive Tabor City, NC 28463',23,173),
(64,'Donna','Jones','9449 Hill Street Raleigh, NC 27617',25,174),
(65,'Diane','Kelly','90 Fletcher St. Raleigh, NC 27605',21,175),
(66,'Diana','Kerr','9621 Fox Avenue Greensboro, NC 27412',32,176);

INSERT INTO  dentist VALUES (1,'Zoe Abraham',1),
(2,'Yvonne Allan',7),
(3,'Wendy Alsop',4),
(4,'Wanda Anderson',8),
(5,'Virginia Arnold',4),
(6,'Victoria Avery',1),
(7,'Vanessa Bailey',5),
(8,'Una Baker',7),
(9,'Tracey Ball',2),
(10,'Theresa Bell',4),
(11,'Sue Berry',7),
(12,'Stephanie Black',9),
(13,'Sophie Blake',5),
(14,'Sonia Bond',1),
(15,'Sarah Bower',3),
(16,'Samantha Brown',9),
(17,'Sally Buckland',6),
(18,'Ruth Burgess',3),
(19,'Rose Butler',1),
(20,'Rebecca Cameron',7),
(21,'Rachel Campbell',5),
(22,'Pippa Carr',8),
(23,'Penelope Chapman',5),
(24,'Olivia Churchill',4),
(25,'Nicola Clark',8),
(26,'Natalie Clarkson',1),
(27,'Molly Coleman',7),
(28,'Michelle Cornish',4),
(29,'Melanie Davidson',6),
(30,'Megan Davies',4),
(31,'Mary Dickens',8)
;

INSERT INTO appointment VALUES (1, '2022-11-01', '09:00:00', '10:00:00', 1, 11),
(2, '2022-11-01',  '10:00:00', '11:00:00',1, 12),
(3, '2022-11-01',  '11:00:00', '12:00:00',1, 13),
(4, '2022-11-01',  '12:00:00', '13:00:00',1, 14),
(5, '2022-11-01',  '13:00:00', '14:00:00',1, 15),
(6, '2022-11-01',  '14:00:00', '15:00:00',2, 16),
(7, '2022-11-01',  '15:00:00', '16:00:00',2, 17),
(8, '2022-11-01',  '16:00:00', '17:00:00',2, 18),
(9, '2022-11-01',  '18:00:00', '19:00:00',2, 19),
(10, '2022-11-01',  '19:00:00', '20:00:00',3, 20),
(11, '2022-11-02', '09:00:00', '10:00:00', 3, 21),
(12, '2022-11-02',  '10:00:00', '11:00:00',3, 22),
(13, '2022-11-02',  '11:00:00', '12:00:00',3, 23),
(14, '2022-11-02',  '12:00:00', '13:00:00',4, 24),
(15, '2022-11-02',  '13:00:00', '14:00:00',4, 25),
(16, '2022-11-02',  '14:00:00', '15:00:00',4, 26),
(17, '2022-11-02',  '15:00:00', '16:00:00',4, 27),
(18, '2022-11-02',  '16:00:00', '17:00:00',6, 28),
(19, '2022-11-02',  '18:00:00', '19:00:00',6, 29),
(20, '2022-11-02',  '19:00:00', '20:00:00',7, 30),
(21, '2022-11-03', '09:00:00', '10:00:00', 8, 31),
(22, '2022-11-03',  '10:00:00', '11:00:00',8, 32),
(23, '2022-11-03',  '11:00:00', '12:00:00',9, 33),
(24, '2022-11-03',  '12:00:00', '13:00:00',12, 34),
(25, '2022-11-03',  '13:00:00', '14:00:00',3, 35),
(26, '2022-11-03',  '14:00:00', '15:00:00',5, 36),
(27, '2022-11-03',  '15:00:00', '16:00:00',6, 37),
(28, '2022-11-03',  '16:00:00', '17:00:00',7, 38),
(29, '2022-11-03',  '18:00:00', '19:00:00',7, 39),
(30, '2022-11-03',  '19:00:00', '20:00:00',8, 40),
(31, '2022-11-04', '09:00:00', '10:00:00', 12, 41),
(32, '2022-11-04',  '10:00:00', '11:00:00',12, 42),
(33, '2022-11-04',  '11:00:00', '12:00:00',13, 43),
(34, '2022-11-04',  '12:00:00', '13:00:00',14, 44),
(35, '2022-11-04',  '13:00:00', '14:00:00',15, 45),
(36, '2022-11-04',  '14:00:00', '15:00:00',6, 46),
(37, '2022-11-04',  '15:00:00', '16:00:00',12, 47),
(38, '2022-11-04',  '16:00:00', '17:00:00',12, 48),
(39, '2022-11-04',  '18:00:00', '19:00:00',12, 49),
(40, '2022-11-04',  '19:00:00', '20:00:00',11, 50),
(41, '2022-11-05', '09:00:00', '10:00:00', 13, 51),
(42, '2022-11-05',  '10:00:00', '11:00:00',14, 52),
(43, '2022-11-05',  '11:00:00', '12:00:00',15, 53),
(44, '2022-11-05',  '12:00:00', '13:00:00',17, 54),
(45, '2022-11-05',  '13:00:00', '14:00:00',18, 55),
(46, '2022-11-05',  '14:00:00', '15:00:00',22, 56),
(47, '2022-11-05',  '15:00:00', '16:00:00',22, 57),
(48, '2022-11-05',  '16:00:00', '17:00:00',21, 58),
(49, '2022-11-05',  '18:00:00', '19:00:00',12, 59),
(50, '2022-11-05',  '19:00:00', '20:00:00',11, 60);

INSERT INTO treatment (treatment_details, treatment_fee) VALUES ('Root Canal', '500'),
('Cleaning Tooth', '300'),
('Cavities', '150'),
('Cosmetic', '1000'),
('Electroconvulsive therapy (ECT)', '500'),
('Transcranial magnetic stimulation (TMS)', '300'),
('Ambulatory monitoring', '150'),
('Echocardiogram', '1000'),
('Electroconvulsive therapy (ECT)', '500'),
('COVID', '5000'),
('ECG', '500'),
('Eye Treatment', '5900');



INSERT INTO appointment_info VALUES (1, 2),
(2,1),
(3,2),
(4,1),
(5,3),
(6,5),
(7,6),
(8,8),
(9,7),
(10,4),
(11,2),
(12,4),
(13,2),
(14,8),
(15,3),
(16,7),
(17,2),
(18,1),
(19,7),
(20,1),
(21, 2),
(22,7),
(23,2),
(24,7),
(25,3),
(26,1),
(27,2),
(28,10),
(29,2),
(30,6),
(31, 6),
(32,1),
(33,6),
(34,1),
(35,3),
(36,1),
(37,2),
(38,6),
(39,2),
(40,6),
(41,2),
(42,3),
(43,2),
(44,1),
(45,3),
(46,3),
(47,5),
(48,5),
(49,1),
(50,9);
   END //
DELIMITER ;

CALL insertData();

Call updatePatientDetails(4,'Wanda','Anderson','90 Fletcher St. Raleigh, NC 27605','35','114','343123','1','Medium');
