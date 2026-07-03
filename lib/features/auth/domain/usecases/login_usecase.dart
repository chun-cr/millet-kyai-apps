// 认证模块用例入口：`LoginUsecase`。把单个业务动作收敛成明确调用点，减少页面直接拼装仓储逻辑。

import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<void> execute() async {
    // login logic
  }
}
