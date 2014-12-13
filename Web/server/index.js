var WebSocketServer = require("ws").Server;
var http = require("http");
var fs = require('fs');
var path = require("path");
var express = require("express");
var readline = require('readline');
var port = 8888;
var dataFolder = '../../Data/';

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
		var p = dataFolder + 'forMat/';
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
		rPath = dataFolder + 'trajectorySetsFix/'
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
	
	ws.on("close", function () {
		console.log("websocket connection close");
	});
});
console.log("websocket server created");
