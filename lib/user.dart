class ClubUser {
  final String name;
  final String surname;
  final String email;
  final String password;
  final String birthdate;
  final String role;
  final String club_class;
  final String soccer_class;
  final String status;
  final DateTime created_time;

  ClubUser({required this.name, 
        required this.surname, 
        required this.birthdate, 
        required this.email, 
        required this.password, 
        required this.role,
        required this.club_class,
        required this.soccer_class,
        required this.status,
        required this.created_time});
}
