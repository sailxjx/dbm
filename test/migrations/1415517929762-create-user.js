exports.up = function() {
  mongo(function() {
    db.users.create({
      name: 'mms',
      email: "mms@gmail.com"
    });
  });
};

exports.down = function() {
  mongo(function() {
    db.users.remove({
      name: 'mms'
    });
  });
};
