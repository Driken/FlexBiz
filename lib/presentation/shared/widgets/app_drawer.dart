import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/session_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../items/screens/items_list_screen.dart';
import '../../customers/screens/customers_list_screen.dart';
import '../../orders/screens/orders_list_screen.dart';
import '../../accounts/receivable/screens/accounts_receivable_screen.dart';
import '../../accounts/payable/screens/accounts_payable_screen.dart';
import '../../admin/screens/admin_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionProvider);
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    return Drawer(
      backgroundColor: AppColors.cardBackground,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          sessionAsync.when(
            data: (session) {
              if (session == null) {
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'FlexBiz',
                        style: AppTypography.title.copyWith(
                          color: AppColors.textInverse,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'FlexBiz',
                      style: AppTypography.title.copyWith(
                        color: AppColors.textInverse,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      session.profile.name ?? 'Usuário',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textInverse,
                      ),
                    ),
                    if (session.profile.isSuperAdmin)
                      Container(
                        margin: const EdgeInsets.only(top: AppSpacing.xs),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'SUPER ADMIN',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textInverse,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          'Empresa: ${session.companyId.substring(0, 8)}...',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textInverse.withOpacity(0.8),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
            loading: () => Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(color: AppColors.primary),
              child: const CircularProgressIndicator(color: AppColors.textInverse),
            ),
            error: (error, stack) => Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Text(
                'Erro',
                style: AppTypography.body.copyWith(color: AppColors.textInverse),
              ),
            ),
          ),
          _DrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            isActive: currentRoute.contains('dashboard'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
              );
            },
          ),
          _DrawerItem(
            icon: Icons.inventory_2,
            title: 'Itens',
            isActive: currentRoute.contains('items'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ItemsListScreen(),
                ),
              );
            },
          ),
          _DrawerItem(
            icon: Icons.people,
            title: 'Clientes',
            isActive: currentRoute.contains('customers'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomersListScreen(),
                ),
              );
            },
          ),
          _DrawerItem(
            icon: Icons.shopping_cart,
            title: 'Pedidos',
            isActive: currentRoute.contains('orders'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrdersListScreen(),
                ),
              );
            },
          ),
          const Divider(),
          _DrawerItem(
            icon: Icons.arrow_downward,
            title: 'Contas a Receber',
            isActive: currentRoute.contains('receivable'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountsReceivableScreen(),
                ),
              );
            },
          ),
          _DrawerItem(
            icon: Icons.arrow_upward,
            title: 'Contas a Pagar',
            isActive: currentRoute.contains('payable'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountsPayableScreen(),
                ),
              );
            },
          ),
          sessionAsync.when(
            data: (session) {
              if (session != null && session.profile.isSuperAdmin) {
                return Column(
                  children: [
                    const Divider(),
                    _DrawerItem(
                      icon: Icons.admin_panel_settings,
                      title: 'Administração',
                      isActive: currentRoute.contains('admin'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const Divider(),
          _DrawerItem(
            icon: Icons.logout,
            title: 'Sair',
            isActive: false,
            onTap: () async {
              Navigator.pop(context);
              try {
                // Fazer logout - o authProvider já invalida o sessionProvider
                await ref.read(authProvider.notifier).signOut();
                
                // O MaterialApp em main.dart vai reagir automaticamente
                // às mudanças no sessionProvider e redirecionar para LoginScreen
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao fazer logout: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(
          title,
          style: AppTypography.body.copyWith(
            color: isActive ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }
}

