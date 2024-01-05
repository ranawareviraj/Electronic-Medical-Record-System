const { Sequelize, Model } = require("sequelize");

const sequelize = new Sequelize("clinic_db", "root", "Uncc@2022", {
  host: "localhost",
  logging: (...msg) => console.log(msg),
  dialect: "mysql", //| 'postgres' | 'sqlite' | 'mariadb' | 'mssql' | 'db2' | 'snowflake' | 'oracle' */
});

const connect = sequelize.authenticate();
module.exports.db = connect;
module.exports.sequelize = sequelize;
