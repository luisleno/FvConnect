import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/desktop/pages/desktop_tab_page.dart';
import 'package:flutter_hbb/models/peer_tab_model.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class FvColors {
  static bool _dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color page(BuildContext context) =>
      _dark(context) ? const Color(0xFF16191E) : const Color(0xFFF4F7FB);
  static Color card(BuildContext context) =>
      _dark(context) ? const Color(0xFF1E2228) : Colors.white;
  static Color border(BuildContext context) =>
      _dark(context) ? const Color(0xFF2A3038) : const Color(0xFFE3E8EF);
  static Color sidebar(BuildContext context) =>
      _dark(context) ? const Color(0xFF1E2228) : Colors.white;
  static Color muted(BuildContext context) =>
      _dark(context) ? const Color(0xFF9AA3AD) : const Color(0xFF7F8184);
  static Color selectedBg(BuildContext context) =>
      _dark(context) ? const Color(0x331170CA) : const Color(0xFFE3EEF9);
  static Color accentText(BuildContext context) =>
      _dark(context) ? const Color(0xFF5AB0FF) : MyTheme.accent;
}

class FvCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const FvCard(
      {Key? key,
      required this.child,
      this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 14)})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: FvColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FvColors.border(context)),
      ),
      child: child,
    );
  }
}

class _FvNavItem {
  final IconData icon;
  final String label;
  final PeerTabIndex tab;
  const _FvNavItem(this.icon, this.label, this.tab);
}

/// Main window sidebar. Icons only in light mode, icons + labels in dark mode.
class FvSidebar extends StatelessWidget {
  const FvSidebar({Key? key}) : super(key: key);

  static const _items = [
    _FvNavItem(Icons.home_outlined, 'Recent sessions', PeerTabIndex.recent),
    _FvNavItem(Icons.star_outline_rounded, 'Favorites', PeerTabIndex.fav),
    _FvNavItem(Icons.lan_outlined, 'Discovered', PeerTabIndex.lan),
  ];

  @override
  Widget build(BuildContext context) {
    final expanded = Theme.of(context).brightness == Brightness.dark;
    return ChangeNotifierProvider.value(
      value: gFFI.peerTabModel,
      child: Consumer<PeerTabModel>(builder: (context, model, _) {
        final visible = model.visibleEnabledOrderedIndexs;
        return Container(
          width: expanded ? 172 : 64,
          decoration: BoxDecoration(
            color: FvColors.sidebar(context),
            border: Border(right: BorderSide(color: FvColors.border(context))),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            crossAxisAlignment:
                expanded ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
            children: [
              _brand(context, expanded).marginOnly(bottom: 18),
              ..._items
                  .where((e) => visible.contains(e.tab.index))
                  .map((e) => _navButton(
                        context,
                        expanded: expanded,
                        icon: e.icon,
                        label: translate(e.label),
                        selected: model.currentTab == e.tab.index,
                        onTap: () => model.setCurrentTab(e.tab.index),
                      ).marginOnly(bottom: 6)),
              const Spacer(),
              if (!bind.isDisableSettings())
                _navButton(
                  context,
                  expanded: expanded,
                  icon: Icons.settings_outlined,
                  label: translate('Settings'),
                  selected: false,
                  onTap: DesktopTabPage.onAddSetting,
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _brand(BuildContext context, bool expanded) {
    final icon = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: loadIcon(34),
    );
    if (!expanded) return icon;
    return Row(
      children: [
        icon,
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            bind.mainGetAppNameSync(),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _navButton(BuildContext context,
      {required bool expanded,
      required IconData icon,
      required String label,
      required bool selected,
      required VoidCallback onTap}) {
    final color = selected ? FvColors.accentText(context) : FvColors.muted(context);
    final content = expanded
        ? Row(children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: color)),
            ),
          ])
        : Icon(icon, size: 22, color: color);
    final button = Material(
      color: selected ? FvColors.selectedBg(context) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: expanded ? 10 : 9, vertical: 9),
          child: content,
        ),
      ),
    );
    return expanded ? button : Tooltip(message: label, child: button);
  }
}
