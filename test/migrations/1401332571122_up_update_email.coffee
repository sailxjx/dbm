print('update email')
db.users.update {email: 'user@gmail.com'}, email: 'new@gmail.com'
