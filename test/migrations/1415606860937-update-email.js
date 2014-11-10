// Async
exports.up = function(next) {
  mongo(function() {
    db.users.update({name: 'mms'}, {$set: {email: 'mms@icloud.com'}});
  });
  setTimeout(next, 100);
};

// Async
exports.down = function(next) {
  mongo(function() {
    db.users.update({name: 'mms'}, {$set: {email: 'mms@gmail.com'}});
  });
  setTimeout(next, 100);
};
