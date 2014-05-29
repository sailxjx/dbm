print('rollback email')
db.users.update {email: 'new@gmail.com'}, email: 'user@gmail.com'
