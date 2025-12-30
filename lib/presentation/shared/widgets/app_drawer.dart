import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/session_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../items/screens/items_list_screen.dart';
import '../../customers/screens/customers_list_screen.dart';
import '../../orders/screens/orders_list_screen.dart';
import '../../accounts/receivable/screens/accounts_receivable_screen.dart';
import '../../accounts/payable/screens/accounts_payable_screen.dart';
import '../../admin/screens/admin_screen.dart';

// Cores do sistema para o drawer (cores originais)
class DrawerColors {
  static Color background(BuildContext context) => Theme.of(context).drawerTheme.backgroundColor ?? Colors.white;
  static Color headerBackground(BuildContext context) => Theme.of(context).colorScheme.primary;
}

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  bool _isCollapsed = false;

  bool _isActive(BuildContext context, String routeName) {
    final route = ModalRoute.of(context);
    if (route == null) return false;
    
    final routeSettings = route.settings;
    final routeNameCurrent = routeSettings.name ?? '';
    
    // Detecta pela rota nomeada
    return routeNameCurrent.contains(routeName.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionProvider);

    return Drawer(
      backgroundColor: DrawerColors.background(context),
      width: _isCollapsed ? 80 : 280,
      child: Column(
        children: [
          // Header com Logo
          _DrawerHeader(
            isCollapsed: _isCollapsed,
            onToggleCollapse: () {
              setState(() => _isCollapsed = !_isCollapsed);
            },
            child: sessionAsync.when(
              data: (session) => session != null
                  ? _UserProfileHeader(
                      userName: session.profile.name ?? 'Usuário',
                      isSuperAdmin: session.profile.isSuperAdmin,
                      isCollapsed: _isCollapsed,
                    )
                  : null,
              loading: () => const SizedBox(
                height: 60,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox(),
            ),
          ),
          
          // Menu items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seção Principal
                  if (!_isCollapsed)
                    _SectionLabel(label: 'PRINCIPAL'),
                  _NavigationItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    label: 'Dashboard',
                    isActive: _isActive(context, 'dashboard'),
                    isCollapsed: _isCollapsed,
                    onTap: () => _navigateTo(context, const DashboardScreen(), '/dashboard'),
                  ),
                  _NavigationItem(
                    icon: Icons.inventory_2_outlined,
                    activeIcon: Icons.inventory_2,
                    label: 'Itens',
                    isActive: _isActive(context, 'items'),
                    isCollapsed: _isCollapsed,
                    onTap: () => _navigateTo(context, const ItemsListScreen(), '/items'),
                  ),
                  _NavigationItem(
                    icon: Icons.people_outline,
                    activeIcon: Icons.people,
                    label: 'Clientes',
                    isActive: _isActive(context, 'customers'),
                    isCollapsed: _isCollapsed,
                    onTap: () => _navigateTo(context, const CustomersListScreen(), '/customers'),
                  ),
                  _NavigationItem(
                    icon: Icons.shopping_cart_outlined,
                    activeIcon: Icons.shopping_cart,
                    label: 'Pedidos',
                    isActive: _isActive(context, 'orders'),
                    isCollapsed: _isCollapsed,
                    onTap: () => _navigateTo(context, const OrdersListScreen(), '/orders'),
                  ),
                  
                  if (!_isCollapsed) ...[
                    const SizedBox(height: 24),
                    _SectionLabel(label: 'FINANCEIRO'),
                  ],
                  _NavigationItem(
                    icon: Icons.arrow_downward_outlined,
                    activeIcon: Icons.arrow_downward,
                    label: 'Contas a Receber',
                    isActive: _isActive(context, 'receivable'),
                    isCollapsed: _isCollapsed,
                    iconColor: const Color(0xFF10B981),
                    onTap: () => _navigateTo(context, const AccountsReceivableScreen(), '/receivable'),
                  ),
                  _NavigationItem(
                    icon: Icons.arrow_upward_outlined,
                    activeIcon: Icons.arrow_upward,
                    label: 'Contas a Pagar',
                    isActive: _isActive(context, 'payable'),
                    isCollapsed: _isCollapsed,
                    iconColor: const Color(0xFFEF4444),
                    onTap: () => _navigateTo(context, const AccountsPayableScreen(), '/payable'),
                  ),
                  
                  // Administração (apenas para super admins)
                  sessionAsync.when(
                    data: (session) {
                      if (session != null && session.profile.isSuperAdmin) {
                        return Column(
                          children: [
                            if (!_isCollapsed) ...[
                              const SizedBox(height: 24),
                              _SectionLabel(label: 'ADMINISTRAÇÃO'),
                            ],
                            _NavigationItem(
                              icon: Icons.admin_panel_settings_outlined,
                              activeIcon: Icons.admin_panel_settings,
                              label: 'Administração',
                              subtitle: 'Super Admin',
                              isActive: _isActive(context, 'admin'),
                              isCollapsed: _isCollapsed,
                              iconColor: const Color(0xFF9333EA),
                              onTap: () => _navigateTo(context, const AdminScreen(), '/admin'),
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
          
          // Footer com perfil do usuário e logout
          Container(
            padding: EdgeInsets.all(_isCollapsed ? 8 : 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                sessionAsync.when(
                  data: (session) {
                    if (session == null) return const SizedBox();
                    return _UserProfileFooter(
                      userName: session.profile.name ?? 'Usuário',
                      userEmail: session.profile.id.substring(0, 8) + '...',
                      isCollapsed: _isCollapsed,
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
                const SizedBox(height: 8),
                _NavigationItem(
                  icon: Icons.logout_outlined,
                  activeIcon: Icons.logout,
                  label: 'Sair',
                  isActive: false,
                  isCollapsed: _isCollapsed,
                  iconColor: const Color(0xFFEF4444),
                  onTap: () async {
                    Navigator.pop(context);
                    await ref.read(authProvider.notifier).signOut();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen, String routeName) {
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
        settings: RouteSettings(name: routeName),
      ),
    );
  }
}

// Header do drawer com logo
class _DrawerHeader extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final Widget? child;

  const _DrawerHeader({
    required this.isCollapsed,
    required this.onToggleCollapse,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCollapsed ? 16 : 24),
      decoration: BoxDecoration(
        color: DrawerColors.headerBackground(context),
        border: const Border(
          bottom: BorderSide(color: Colors.white12, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!isCollapsed)
                const Text(
                  'FlexBiz',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                )
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'FB',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              IconButton(
                icon: Icon(
                  isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                  size: 20,
                  color: Colors.white,
                ),
                onPressed: onToggleCollapse,
                tooltip: isCollapsed ? 'Expandir' : 'Recolher',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (child != null && !isCollapsed) ...[
            const SizedBox(height: 16),
            child!,
          ],
        ],
      ),
    );
  }
}

// Header do perfil do usuário
class _UserProfileHeader extends StatelessWidget {
  final String userName;
  final bool isSuperAdmin;
  final bool isCollapsed;

  const _UserProfileHeader({
    required this.userName,
    required this.isSuperAdmin,
    required this.isCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isSuperAdmin) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'SUPER ADMIN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Footer com perfil do usuário
class _UserProfileFooter extends StatelessWidget {
  final String userName;
  final String userEmail;
  final bool isCollapsed;

  const _UserProfileFooter({
    required this.userName,
    required this.userEmail,
    required this.isCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    
    if (isCollapsed) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: primaryColor.withValues(alpha: 0.1),
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: primaryColor.withValues(alpha: 0.1),
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyMedium?.color ?? Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  userEmail,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7) ?? Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Label de seção
class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7) ?? Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// Item de navegação
class _NavigationItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String? subtitle;
  final bool isActive;
  final bool isCollapsed;
  final Color? iconColor;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.subtitle,
    required this.isActive,
    required this.isCollapsed,
    this.iconColor,
    required this.onTap,
  });

  @override
  State<_NavigationItem> createState() => _NavigationItemState();
}

class _NavigationItemState extends State<_NavigationItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final effectiveIconColor = widget.iconColor ??
        (widget.isActive 
            ? primaryColor 
            : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ?? Colors.grey);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCollapsed ? 0 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: widget.isActive
                ? primaryColor.withValues(alpha: 0.1)
                : (_isHovered ? Colors.grey.withValues(alpha: 0.1) : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: widget.isActive
                ? Border(
                    left: BorderSide(
                      color: primaryColor,
                      width: 3,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.isActive ? widget.activeIcon : widget.icon,
                size: 22,
                color: effectiveIconColor,
              ),
              if (!widget.isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                          color: widget.isActive
                              ? primaryColor
                              : theme.textTheme.bodyMedium?.color ?? Colors.black87,
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7) ?? Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
