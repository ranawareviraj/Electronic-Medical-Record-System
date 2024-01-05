# Electronic-Medical-Record-System
Electronic Medical Record System

## DB Setup:
1. Execute Clinic_DB  Creation.sql script in MYSQL DB
2. Execute Clinic_DB Functions.sql in MYSQL DB

## Dental Clinic System
PreRequisite: Latest NodeJS installed.

Steps Run Project :
1. Install NodeJS 14.0.0^
2. Naviagate to emr-dental-clinic directory.
3. Run `npm install`
4. Update user and password in db.js file in emr-dental-clinic/db directory.
  line to be updated: new Sequelize('clinic_db', '<user>', '<Password>'
5. Run command  "node app.js"

## Development server
Open `http://localhost:4200/` in the browser to access application home page
