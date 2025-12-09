import 'package:flutter/material.dart';
import 'package:schedsync_app/Profile/edit_profile_screen.dart'; 
import 'package:schedsync_app/Profile/change_password_screen.dart'; 
import 'package:schedsync_app/model/base_app_user.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage(
    this.switchTheme, {
    super.key,
    required this.currentUser,
    required this.logout,
    required this.goToHome,
  });

  final void Function() switchTheme;
  final VoidCallback goToHome;
  final VoidCallback logout;
  final BaseAppUser currentUser;

  @override
  State<ProfilePage> createState() => _ProfilePageState(); 
}

class _ProfilePageState extends State<ProfilePage> {
  late BaseAppUser _user;

  @override
  void initState() {
    super.initState();
    _user = widget.currentUser;
  }

  void _updateUser(BaseAppUser updatedUser) {
    setState(() {
      _user = updatedUser;
    });
  }

  void _goToEditProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => EditProfileScreen(
          currentUser: _user, 
          onProfileUpdated: _updateUser, 
        ),
      ),
    );
  }

  void _goToChangePassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ChangePasswordScreen(
          currentUser: _user, 
        ),
      ),
    );
  }

  Future _confirmLogout(BuildContext context) async {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(
                'Logout confirmation',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'Are you sure you want to logout?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await Future.delayed(const Duration(milliseconds: 300));
                    widget.logout();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Yes'),
                ),
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              widget.goToHome();
              Navigator.pop(context);
            }),
        actions: [
          IconButton(
            onPressed: widget.switchTheme,
            icon: const Icon(Icons.brightness_6), 
          ),
        ],
      ),
      body: Column(
        children: [

          const CircleAvatar(
            backgroundColor: Colors.black,
            radius: 50,
            child: Icon(
              Icons.person,
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),

          // USER NAME 
          Text(
            '${_user.firstName} ${_user.lastName}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onBackground,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          // EMAIL 
          Text(
            _user.email,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onBackground,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // EDIT 
              OutlinedButton.icon(
                onPressed: _goToEditProfile,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text("Edit Profile"),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              //PASSWORD 
              OutlinedButton.icon(
                onPressed: _goToChangePassword,
                icon: const Icon(Icons.lock, size: 16),
                label: const Text("Change Password"),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          
          const Spacer(),

          // LOGOUT BUTTON 
          Align(
            alignment: Alignment.bottomRight,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout, size: 16),
              label: const Text("Logout"),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}