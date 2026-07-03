// 认证模块领域实体：`UserEntity`。用于在业务层和展示层之间传递稳定语义，避免直接耦合接口原始结构。

class UserEntity {
  final String id;
  final String username;

  UserEntity({required this.id, required this.username});
}
