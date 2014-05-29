print('add avatar');
db.users.update({}, {avatar: 'avatarurl'});
