const express = require("express");
const morgan = require("morgan");
const methodOverride = require("method-override");
const db = require("./db/db");
const session = require("express-session");
const flash = require("connect-flash");
const clinicRouter = require("./routes/clinicRouter");
const app = express();

let PORT = 4200;
let host = "localhost";
app.set("view engine", "ejs");
app.use(
  session({
    secret: "asdasdgfdgdfg545678769ghdfhfdadad",
    resave: false,
    saveUninitialized: false,
    cookie: { maxAge: 60 * 60 * 1000 },
  })
);
app.use(flash());
app.use((req, res, next) => {
  res.locals.errorMessages = req.flash("error");
  res.locals.successMessages = req.flash("success");
  next();
});

app.use(express.static("public"));
app.use(express.urlencoded({ extended: true }));
app.use(morgan("tiny"));
app.use(methodOverride("_method"));

app.use("/", clinicRouter);

app.use((req, res, next) => {
  let err = new Error("Unable to locate" + req.url);
  err.status = 404;
  next(err);
});

app.use((err, req, res, next) => {
  console.log(err.stack);
  if (!err.status) {
    err.status = 500;
    err.message = "Server encountered problem..!";
  }
  res.status(err.status);
  res.render("error", { error: err });
});

db.db
  .then(() => {
    console.log("DB Connection successful");
    app.listen(PORT, host, () => {
      console.log("The App is up and running at port", PORT);
    });
  })
  .catch((err) => {
    console.error("DB Connection Failed:", err);
  });
