const express = require("express");
const ekeyRoutes = require("./src/ekey/routes");
const studentRoutes = require("./src/student/routes")
const ausleihRoutes= require("./src/ausleihe/routes")
var cors = require('cors')
const checkauth = require("./auth");

const app = express();
const port = 3000;



const admin = require('firebase-admin');

const serviceAccount = require('./serviceAccountKey.json');



admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});



app.use(cors());
app.use(checkauth)

app.use(express.json());
app.get("/", (req, res) => {
  res.send("Hello World!");
})

app.use('/api/v1/ekeys', ekeyRoutes);
app.use('/api/v1/studenten', studentRoutes);
app.use('/api/v1/ausleihen', ausleihRoutes);
app.listen(port, () => console.log(`App listening on Port ${port}`));
