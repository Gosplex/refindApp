import '../../core/model/app_user_model.dart';
import 'service/admin_user_service.dart';

class AdminUserController {
  final AdminUserService _service = AdminUserService();

  Stream<List<AppUser>> getUsers() {
    return _service.fetchUsers();
  }
}