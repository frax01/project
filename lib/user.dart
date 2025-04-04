class ClubUser {
  final String name;
  final String surname;
  final String email;
  final String password;
  final String birthdate;
  final String club;
  final String role;
  final String club_class;
  final String soccer_class;
  final String status;
  final String token;
  final DateTime created_time;
  final String version;
  final bool privacy;

  ClubUser(
      {required this.name,
      required this.surname,
      required this.birthdate,
      required this.email,
      required this.password,
      required this.club,
      required this.role,
      required this.club_class,
      required this.soccer_class,
      required this.status,
      required this.token,
      required this.created_time,
      required this.version,
      required this.privacy});
}
