const pool = require("../../db");
const queries = require('./queries');
const getEkeysdata = (req, res)=> {
  const besitzer =req.query.besitzer? req.query.besitzer: "%"
  const zustand =req.query.zustand? req.query.zustand: "%"
  const berechtigung =req.query.berechtigung? req.query.berechtigung: "%"

  pool.query(queries.getUebersicht, [besitzer,zustand,berechtigung], (error, results) => {
    if(error) {
      res.status(400).send("FEHLER: "+ error.message);
      console.log(error);
    }else {
      res.status(200).json(results.rows);
    }

  })
};

const getEkeyscount = (req, res)=> {
  const besitzer =req.query.besitzer? req.query.besitzer: "%"
  const zustand =req.query.zustand? req.query.zustand: "%"
  const berechtigung =req.query.berechtigung? req.query.berechtigung: "%"

  pool.query(queries.getUebersicht, [besitzer,zustand,berechtigung], (error, results) => {
    if(error) {
      res.status(400).send("FEHLER: "+ error.message);
      console.log(error);
    }else {
      res.status(200).json(results.rowCount);
    }

  })
};

const getEkeyById = (req, res) => {
  const ekeyID = req.params.ekeyID;
  pool.query(queries.getEkeyById, [ekeyID], (error, results) => {
    if(error){
      res.status(400).send("FEHLER: "+ error.message);
      console.log(error);
    }else {
      res.status(200).json(results.rows);
    }
  })
}

const addEkey = (req, res) =>  {
  const { ekeyid, besitzer, zustand, berechtigung, notiz} = req.body;

  // Existiert Ekey schon?
  pool.query(queries.getEkeyById, [ekeyid], (error, results) => {
    if(results.rows.length) {
      res.status(409).send("FEHLER: E-Key existiert bereits.");
      return;
    }else {
      pool.query(queries.addEkey, [ ekeyid, besitzer, zustand, berechtigung, notiz], (error, results) => {
        // Fehlgeschlagen?
        if(error) {
          res.status(400).send("FEHLER:" + error.message);
          console.log(error);
        }else {
          res.status(201).send("Ekey wurde erfolgreich erstellt.");
        }
      })
    }
  })

  // Hinzufügen

}

const deleteEkeyById = (req, res) => {
  const ekeyID = req.params.ekeyID;
  pool.query(queries.getEkeyById, [ekeyID], (error, results) => {
    const noEkeyFound = !results.rows.length;
    if(error) {
      res.status(400).send("FEHLER: "+ error.message);
      console.log(error);
    }
    if(noEkeyFound)  {
      res.status(400).send("Ekey konnte nicht gefunden werden");
    }else {
      pool.query(queries.deleteEkeyById, [ekeyID], (error, results) => {
        if(error) {
          res.status(400).send("FEHLER: "+ error.message);
          console.log(error);
        }else {
          res.status(200).send("Ekey wurde erfolgreich gelöscht.");
        }
      })
    }

  })
}

const updateEkey = (req, res) => {
  const { ekeyid, berechtigung, notiz} = req.body;
  pool.query(queries.getEkeyById, [ekeyid], (error, results) => {
    const noEkeyFound = !results.rows.length;
    if(error) {
      res.status(400).send("FEHLER: "+ error.message);
      console.log(error);
    }
    if (noEkeyFound) {
      res.status(400).send("FEHLER: Ekey konnte nicht gefunden werden.")
    } else {
      pool.query(queries.updateEkey, [ekeyid, berechtigung, notiz], (error, results) => {
        if(error) {
          res.status(400).send("FEHLER: "+ error.message);
          console.log(error);
        }else {
          res.status(200).send("Ekey wurde erfolgreich aktualisiert.");
        }
      })
    }
  });
}

const sperreEkey = (req, res) => {
  const {ekeyid} = req.body;
  console.log(req.body)
  pool.query(queries.sperreEkey, [ekeyid],(error,results)=>{
    if(error) {
      res.status(400).send("FEHLER: "+ error.message);
      console.log(error);
    }else {
      res.status(200).send("Key erfolgreich gesperrt.");
    }
  })
}

const entsperreEkey = (req, res) => {
  const {ekeyid,notiz} = req.body;
  console.log(req.body)
  pool.query(queries.entsperreEkey, [ekeyid,notiz],(error,results)=>{
    if(error) {
      res.status(400).send("FEHLER: "+ error.message);
      console.log(error);
    }else {
      res.status(200).send("Entsperrung war erfolgreich!");
    }
  })
}


const zurueckEkey = (req, res) => {
  const {ekeyid} = req.body;
  console.log(req.body)
  pool.query(queries.zuruecknehmen, [ekeyid],(error,results)=>{
    if(error) {
      res.status(400).send("FEHLER: "+ error.message);
    }else {
      res.status(200).send("Zurücknehmen war erfolgreich.");
    }
    console.log(results);
  })
}

module.exports = {
  getEkeysdata,
  getEkeyById,
  addEkey,
  deleteEkeyById,
  updateEkey,
  sperreEkey,
  getEkeyscount,
  zurueckEkey,
  entsperreEkey
};
