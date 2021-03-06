var WebSocketServer = require("ws").Server;
var http = require("http");
var fs = require('fs');
var path = require("path");
var express = require("express");
var readline = require('readline');
var port = 8888;
var dataFolder = '../../Data/';
var nodeIdToLatLng = {};

var app = express();
//app.use(express.static(__dirname+ "/../"));
app.use('/abccccc', function(req, res, next) {
	console.log('come to here');
});
app.get('/', function(req, res, next) {
	console.log('receiving get request', req, res);
});
app.post('/somePostRequest', function(req, res, next) {
	console.log('receiving post request', req, res);
});
//app.listen(port); //port 80 need to run as root

console.log("app listening on %d ", port);

var server = http.createServer(app);
server.listen(port);

console.log("http server listening on %d", port);

var userId;
var wss = new WebSocketServer({server: server});
wss.on("connection", function (ws) {
	url = ws.upgradeReq.url;
	console.log("websocket connection open, url:" + url);
	
	strs = url.substring(1).split('/');
	page = strs[0];
	cmd = strs[1];
	params = strs.slice(2);
	console.log(page, cmd, params);


	if (page == 'collect') {
		var p = dataFolder + 'rawData/';
		if (cmd == 'ls') {
			// request on list the gps trajectories
			
			list = {items: []};
			fs.readdir(p, function (err, files) {
				if (err) {
					console.log(err);
					throw err;			
				}

				for (var i = 0; i < files.length; i++) {
					var file = files[i];
					if (file.substring(file.length - 7, file.length) == 'gps.csv')
						list.items.push(file.substring(0, file.length - 8));
				}
				console.log(list);
				ws.send(JSON.stringify(list));
				ws.close();
			});
		}
		else if (cmd == 'load') {
			// request on list the gps trajectories
			var filename = p + params[0] + '.gps.csv';
			console.log('begin', filename);
			list = {items: []};
			fs.exists(filename, function(exists) {
				  if (exists) {
					  var rd = readline.createInterface({
						  input: fs.createReadStream(filename),
						  output: process.stdout,
						  terminal: false
					  });
					  rd.on('line', function(line) {
						  list.items.push(line);
					  });
					  rd.on('close', function() {
						ws.send(JSON.stringify(list));
						ws.close();
					  });
				  }
			});
		}
	}
	else if (page == 'osm') {
		rPath = dataFolder + 'trajectorySets/'
		if (cmd == 'ls') {
			// request on list of osm dataset
			re = [];
			console.log('in osm ls');
			fs.readdir(rPath, function (err, files) {
				if (err) {
					console.log(err);
					console.log('ERROR: directory not existed?');
				}

				for (var i = 0; i < files.length; i++) {
					file = files[i];
					if (file.substring(file.length - 12, file.length) == '_summary.txt') {
						dataset = {name: file.substring(0, file.length - 12), trajectories: []};
						filename = rPath + file;
						lines = fs.readFileSync(filename, 'utf8').split('\n');
						//console.log(lines);
						for (j = 0; j + 1 < lines.length; j += 2) {
								//re.items.trajectories.push({id: tid, name: line});
							dataset.trajectories.push({id: lines[j], name: lines[j+1]});
						}
						re.push(dataset);
					}
				}
				ws.send(JSON.stringify(re));
				ws.close();
			});
		}
		else if (cmd == 'load') {
			// request on list the gps trajectories
			var filename = rPath + params[0] + '/' + params[1];
			console.log('begin', filename);
			re = [];
			fs.exists(filename, function(exists) {
				if (exists) {
					var rd = readline.createInterface({
						input: fs.createReadStream(filename),
						output: process.stdout,
						terminal: false
					});
					rd.on('line', function(line) {
						re.push(line);
					});
					rd.on('close', function() {
						console.log(re);
						ws.send(JSON.stringify(re));
						ws.close();
					});
				}
			});
		}
	}
	else if (page == 'fix') {
		rPath = dataFolder + 'trajectorySets/'
		if (cmd == 'ls') {
			// request on list of osm dataset
			re = [];
			fs.readdir(rPath, function (err, files) {
				if (err) {
					console.log(err);
					console.log('ERROR: directory not existed?');
				}

				for (var i = 0; i < files.length; i++) {
					file = files[i];
					if (file.substring(file.length - 5, file.length) == '.tfix')
						re.push(file);
				}
				ws.send(JSON.stringify(re));
				ws.close();
			});
		}
		else if (cmd == 'load') {
			// request on list the gps trajectories
			var filename = rPath + params[0];
			console.log('begin', filename);
			re = [];
			fs.exists(filename, function(exists) {
				if (exists) {
					var rd = readline.createInterface({
						input: fs.createReadStream(filename),
						output: process.stdout,
						terminal: false
					});
					rd.on('line', function(line) {
						console.log(line)
						re.push(line);
						updateNodeDictionary(line);
					});
					rd.on('close', function() {
						//console.log(re);
						ws.send(JSON.stringify(re));
						ws.close();
					});
				}
			});
		}
	}
	else if (page == 'res') {
		rPath = dataFolder + 'resultSets/'
		if (cmd == 'ls') {
			// load all result sets
			good_files = [];
			fs.readdir(rPath, function (err, files) {
				if (err) {
					console.log(err);
					console.log('ERROR: directory might not exist...');
				}

				for (var i = 0; i < files.length; i++) {
					file = files[i];
					if (file.substring(file.length - 5, file.length) == '.rset')
						good_files.push(file);
				}
				ws.send(JSON.stringify(good_files));
				console.log(good_files);
				ws.close();
			});
		}
		else if (cmd == 'load') {
			// request on list the gps trajectories
			var filename = rPath + params[0];
			console.log('loading file: ', filename);
			re = [];
			fs.exists(filename, function(exists) {
				if (exists) {
					var rd = readline.createInterface({
						input: fs.createReadStream(filename),
						output: process.stdout,
						terminal: false
					});
					rd.on('line', function(line) {
						line_str = "";
						// parse line into score + lat/lng pairs
						tokens = line.split(",");
						console.log(tokens)
						if( tokens.length <= 2){
							return;
						}
						var score = tokens[0];
						line_str += score + ","
						for( var i=1; i<tokens.length; i++){
							var nodeid = tokens[i];
							var latlng = nodeIdToLatLng[nodeid];
							line_str += latlng[0] + "," + latlng[1]
							if( i < tokens.length-1){
								line_str += ",";
							}
						}
						re.push(line_str);
						//console.log(line_str)
						// Add this segment to the dictionary
					});
					rd.on('close', function() {
						console.log(re);
						ws.send(JSON.stringify(re));
						ws.close();
					});
				}
			});
		}
	}
	else if (page == 'res2') {
		rPath = dataFolder + 'resultSets/'
		if (cmd == 'load') {
			// request on list the gps trajectories
			var filename = rPath + params[0];
			console.log('loading file: ', filename);
			lines = [];
			fs.exists(filename, function(exists) {
				if (exists) {
					var rd = readline.createInterface({
						input: fs.createReadStream(filename),
						output: process.stdout,
						terminal: false
					});
					rd.on('line', function(line) {
						lines.push(line);
					});
					rd.on('close', function() {
						re = {gndPath:[], estiPaths:[], attributes:[], attributeValues:[]}
						tokens = lines[0].split(",");
						for (var i = 0; i+2 <= tokens.length; i += 2) {
							re.gndPath.push( [ parseFloat(tokens[i]) , parseFloat(tokens[i+1]) ] );
							console.log(re.gndPath[ re.gndPath.length - 1]);
						}
						lines.shift();

						numAttributes = parseInt(lines[0]);
						lines.shift();
						for (var i = 0; i < numAttributes; i++) {
							re.attributes.push(lines[0].replace(/(\r\n|\n|\r)/gm,""));
							lines.shift();
						}

						numEstiPaths = parseInt(lines[0]);
						lines.shift();
						for (var i = 0; i < numEstiPaths; i++) {
							tokens = lines[0].split(",");
							tmpAttr = [];
							for (var j = 0; j < numAttributes; j++)
								tmpAttr.push( parseFloat(tokens[j]) );
							re.attributeValues.push(tmpAttr);
							tokens = tokens.splice(numAttributes);

							tmpPath = [];
							for (var j = 0; j+2 <= tokens.length; j+=2)
								tmpPath.push( [ parseFloat(tokens[j]), parseFloat(tokens[j+1]) ] );
							re.estiPaths.push(tmpPath);
							console.log(tmpPath);
							lines.shift();
						}
						//console.log(re);
						ws.send(JSON.stringify(re));
						ws.close();
					});
				}
			});
		}
	}
	
	ws.on("close", function () {
		console.log("websocket connection close");
	});
});
console.log("websocket server created");

function updateNodeDictionary(line){
	// parse tokens
	tokens = line.split(",");
	for (var i = 0; i+1<line.length; i += 3) {
		var id = tokens[i];
		var lat = tokens[i+1];
		var lng = tokens[i+2];
		nodeIdToLatLng[id] = [lat,lng];
	}

}
