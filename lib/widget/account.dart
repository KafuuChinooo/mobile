import 'package:flutter/material.dart';
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF673AB7);
    const secondaryColor = Colors.white; // Màu nền nhẹ (hoặc Colors.white)

    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: secondaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 30, color: Colors.black),
          onPressed: () {
            // Xử lý sự kiện quay lại
          },
        ),
        title: const Text(
          'Account',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          children: <Widget>[
            // --- Ảnh đại diện ---
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.black,
                  width: 1.0,
                ),
              ),
              child: const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('images/avatar.jpg'),
              ),
            ),
            const SizedBox(height: 15),

            // --- Tên người dùng ---
            const Text(
              'Kafuu Chino',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 50),

            // --- Nút Setting (Cài đặt) ---
            _buildOptionButton(
              icon: Icons.settings,
              text: 'Setting',
              onTap: () {},
            ),
            const SizedBox(height: 30),

            // --- Nút Activities (Hoạt động) ---
            _buildOptionButton(
              icon: Icons.notifications_none,
              text: 'Activities',
              onTap: () {},
            ),
            const SizedBox(height: 50),

            // --- Nút Log out (Đăng xuất) ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor.withOpacity(0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Log out',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // --- Thanh điều hướng dưới cùng ---
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // Widget riêng để tạo các nút tùy chọn
  Widget _buildOptionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: Colors.black, size: 28),
            const SizedBox(width: 15),
            Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget riêng để tạo thanh điều hướng dưới cùng
  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.home_outlined, size: 40, color: Colors.grey),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 40, color: Colors.grey),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.folder_open_outlined, size: 40, color: Colors.grey),
              onPressed: () {},
            ),
            // Icon đang hoạt động (Account)
            IconButton(
              icon: const Icon(Icons.person, size: 40, color: Colors.black),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
