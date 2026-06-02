/// modelo de dados que representa o perfil de usuário do sistema
class User {
  final String? id;
  final String name;
  final String email;
  final String password;
  final String? profileImage;

  User({
   this.id,
   required this.name,
   required this.email,
   required this.password,
   this.profileImage,
});

  // mapeia os dados do usuário para o formato de chave e valor armazenável no banco SQLite
  Map<String, dynamic> toMap() { 
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'profile_image': profileImage,
    };
  }

  // cria uma instância de User obtendo as chaves mapeadas do banco de dados local
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toString(),
      name: map['name'],
      email: map['email'],
      password: map['password'],
      profileImage: map['profile_image'],
    );
  }
}