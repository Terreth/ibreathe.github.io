var MongoClient = require('mongodb').MongoClient
 , assert = require('assert');

// Connection URL
var url = 'mongodb://localhost:27017/myproject';
// Use connect method to connect to the Server
MongoClient.connect(url, function(err, db) {
  assert.equal(null, err);
  console.log("Connected correctly to server");

  var col = db.collection('contacts');
  // Insert a single document
 // col.insertMany([{a:1}, {a:2}, {a:2}], function(err, r) {
 //   assert.equal(null, err);
 //   assert.equal(3, r.insertedCount);

    // Update a single document
    col.updateOne({a:1}, {$set: {b: 1}}, function(err, r) {
      assert.equal(null, err);
      assert.equal(1, r.matchedCount);
      assert.equal(1, r.modifiedCount);

      // Update multiple documents
    //  col.updateMany({a:2}, {$set: {b: 1}}, function(err, r) {
   //     assert.equal(null, err);
     //   assert.equal(2, r.matchedCount);
     //   assert.equal(2, r.modifiedCount);

        // Upsert a single document
     //   col.updateOne({a:3}, {$set: {b: 1}}, {
    //      upsert: true
     //   }, function(err, r) {
     //     assert.equal(null, err);
      //    assert.equal(0, r.matchedCount);
      //    assert.equal(1, r.upsertedCount);
          db.close();
     //   });
      });
    });
 // });
//});




var MongoClient = require('mongodb').MongoClient
  , assert = require('assert');
var url = 'mongodb://localhost:27017/test';
MongoClient.connect(url, function(err, db) {
  assert.equal(null, err);
  createValidated(db, function() {
    db.close();
  });
});


var createValidated = function(db, callback) {
  db.createCollection("DAOmembers", 
	   {
	      'validator': { '$or':
	         [
                { 'firstLastName': { '$type': "string" } },
                { 'email':  { '$type': "string" } },
	            { 'phone': { '$type': "string" } },
                { 'address': { '$type': "string" } },
                { 'city': { '$type': "string" } },
                { 'postalCode': { '$type': "string" } },	           
	            { 'country': { '$type': "string" } } 
	         ]
	      }
	   },	   
    function(err, results) {
      console.log("Collection created.");
      callback();
    }
  );
};
  