typedef FindShortcutUnbinder = void Function();

FindShortcutUnbinder bindFindShortcut({
  required bool Function() isEnabled,
  required void Function() onTrigger,
}) {
  return () {};
}
