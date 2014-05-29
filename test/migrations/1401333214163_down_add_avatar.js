print('remove avatar');
db.users.update({}, {avatar: null})
