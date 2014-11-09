exports.up = function(next) {
  mongo(function() {
    db.users.create({
      name: 'mms',
      email: "mms@gmail.com"
    });
  });
};

exports.down = function(next) {
  mongo(function() {
    db.users.remove({
      name: 'mms'
    });
  });
};
