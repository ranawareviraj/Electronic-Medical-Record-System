# Electronic-Medical-Record-System
Electronic Medical Record System

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#introduction">Introduction</a></li>
    <li><a href="#database-design">Database Design</a></li>
    <li><a href="#setup">Setup</a></li>
  </ol>
</details>

### Introduction:
Below are the requirements of the EMR(Electronic Medical Record) Application.
- The dental clinic database should help manage the entire process in the clinic digitally.
- It should allow user to manage below data:
- Patient information: This should include unique identifier for patient, patients address, name, age, etc
- Dentist information: Name of the dentist who treated the patient along with how experienced the practitioner is should be captured.
- Appointment details: When patient visits a clinic, its appointment details should be available. This should include appointment time.
- Treatment information: The procedure carried out on patient should be available in the database. It should include fees charged for treatment.
- Insurance details: For patients & treatments insurance details along with insurer should be captured in database.
- Billing: Patients bill information should be available.
- Database should allow user to rectify records.
- It should allow searching of specific info, such as previous appointment and treatment details. 
- It should provide listing patients/appointments based on input criteria.

### Database Design:

<img width="703" alt="image" src="https://github.com/ranawareviraj/Electronic-Medical-Record-System/assets/112779376/b401c2d4-4a74-42ff-a6e0-4b5a5735da5a">

### Application:
- Home Page:
<img width="680" alt="image" src="https://github.com/ranawareviraj/Electronic-Medical-Record-System/assets/112779376/5f072229-9b72-4245-a70e-aa009f5603c3">

- Patient Details:
<img width="680" alt="image" src="https://github.com/ranawareviraj/Electronic-Medical-Record-System/assets/112779376/b8a17600-6ffb-4199-96fb-5a6b16395fec">

- Edit Patient Details:
<img width="680" alt="image" src="https://github.com/ranawareviraj/Electronic-Medical-Record-System/assets/112779376/7dd22e5b-4cba-4d37-ad07-20a6fcc64765">

- View All Appointments:
<img width="680" alt="image" src="https://github.com/ranawareviraj/Electronic-Medical-Record-System/assets/112779376/16809d1d-a5df-4a45-9731-c54eac05ac89">


### Setup:
#### DB Setup:
1. Execute Clinic_DB  Creation.sql script in MYSQL DB
2. Execute Clinic_DB Functions.sql in MYSQL DB

#### Dental Clinic System
PreRequisite: Latest NodeJS installed.

Steps Run Project :
1. Install NodeJS 14.0.0^
2. Naviagate to emr-dental-clinic directory.
3. Run `npm install`
4. Update user and password in db.js file in emr-dental-clinic/db directory.
  line to be updated: new Sequelize('clinic_db', '<user>', '<Password>'
5. Run command  "node app.js"

#### Development server
Open `http://localhost:4200/` in the browser to access application home page
