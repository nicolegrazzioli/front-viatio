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

  //chave, valor - chama user.toMap
  //transforma em string e guarda no banco
  Map<String, dynamic> toMap() { //dynamic = recebe string ou  int
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'profile_image': profileImage,
    };
  }

  //receb do banco
  factory /*metodo de criaçao de objetos*/ User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toString(),
      name: map['name'],
      email: map['email'],
      password: map['password'],
      profileImage: map['profile_image'],
    );
  }


}