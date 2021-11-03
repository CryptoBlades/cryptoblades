const express = require("express");
const app = express();
var axios = require('axios');
var cors = require('cors');

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.listen(2400, () => {
	console.log("Server started at port 2400");
});

app.get("/products", async (req, res) => {
	try {
		const response = await axios({
      method: 'get',
      url: 'https://api.printful.com/store/products',
      headers: { 
        'Authorization': 'Basic cWQ0M2k2dWEtcnJmMS0wcmptOm1vcmEtOXE4ODk2amtrZGEz', 
      }
		});

		res.status(200).json(response.data);
	} catch (err) {
		res.status(500).json({ message: err });
	}
});

app.get("/countries", async (req, res) => {
	try {
		const response = await axios({
      method: 'get',
      url: 'https://api.printful.com/countries',
      headers: { 
        'Authorization': 'Basic cWQ0M2k2dWEtcnJmMS0wcmptOm1vcmEtOXE4ODk2amtrZGEz', 
      }
		});

		res.status(200).json(response.data);
	} catch (err) {
		res.status(500).json({ message: err });
	}
});

app.post("/create_order", async (req, res) => {
	try {
    // TODO Validate that blockchain transaction was successful.
		const response = await axios({
      method: 'post',
      url: 'https://api.printful.com/orders',
      headers: { 
        'Authorization': 'Basic cWQ0M2k2dWEtcnJmMS0wcmptOm1vcmEtOXE4ODk2amtrZGEz', 
      }
		}, req.body);

		res.status(200).json(response.data);
	} catch (err) {
    console.log(err)
		res.status(500).json({ message: err.response.data.result });
	}
});
