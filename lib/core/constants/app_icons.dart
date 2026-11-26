import 'package:flutter/material.dart';

/// Rounded Material icons used across the app.
///
/// The mockups mix Material Symbols Outlined and Rounded; ClientHunt standardizes
/// on Flutter's built-in rounded set. Centralizing the set here keeps an outline
/// icon from slipping in and guarantees no icon is ever rendered as text.
abstract final class AppIcons {
  // Brand / navigation.
  static const IconData logo = Icons.filter_center_focus_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData searchOutline = Icons.search_rounded;
  static const IconData saved = Icons.bookmark_rounded;
  static const IconData savedOutline = Icons.bookmark_border_rounded;
  static const IconData settings = Icons.settings_rounded;
  static const IconData history = Icons.history_rounded;
  static const IconData back = Icons.arrow_back_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData chevronRight = Icons.chevron_right_rounded;
  static const IconData chevronDown = Icons.expand_more_rounded;
  static const IconData more = Icons.more_vert_rounded;
  static const IconData share = Icons.share_rounded;
  static const IconData arrowForward = Icons.arrow_forward_rounded;
  static const IconData externalLink = Icons.open_in_new_rounded;
  static const IconData check = Icons.check_rounded;
  static const IconData checkCircle = Icons.check_circle_rounded;
  static const IconData add = Icons.add_rounded;
  static const IconData checkbox = Icons.check_box_rounded;
  static const IconData checkboxBlank = Icons.check_box_outline_blank_rounded;
  static const IconData lock = Icons.lock_rounded;
  static const IconData info = Icons.info_outline_rounded;
  static const IconData pro = Icons.workspace_premium_rounded;

  // Search form.
  static const IconData niche = Icons.business_center_rounded;
  static const IconData location = Icons.location_on_rounded;
  static const IconData myLocation = Icons.my_location_rounded;
  static const IconData bolt = Icons.bolt_rounded;
  static const IconData filters = Icons.tune_rounded;
  static const IconData sort = Icons.swap_vert_rounded;
  static const IconData listView = Icons.view_list_rounded;

  // Sources.
  static const IconData maps = Icons.map_rounded;
  static const IconData instagram = Icons.photo_camera_rounded;
  static const IconData linkedin = Icons.badge_rounded;
  static const IconData facebook = Icons.groups_rounded;
  static const IconData x = Icons.tag_rounded;
  static const IconData public = Icons.public_rounded;
  static const IconData work = Icons.work_rounded;

  // Contact / lead fields.
  static const IconData phone = Icons.call_rounded;
  static const IconData mobile = Icons.smartphone_rounded;
  static const IconData email = Icons.mail_rounded;
  static const IconData website = Icons.language_rounded;
  static const IconData whatsapp = Icons.chat_rounded;
  static const IconData directions = Icons.directions_rounded;
  static const IconData saveContact = Icons.contact_phone_rounded;
  static const IconData copy = Icons.content_copy_rounded;
  static const IconData delete = Icons.delete_outline_rounded;
  static const IconData download = Icons.file_download_rounded;
  static const IconData addToList = Icons.playlist_add_rounded;
  static const IconData tag = Icons.sell_rounded;
  static const IconData notes = Icons.notes_rounded;
  static const IconData alarm = Icons.alarm_rounded;
  static const IconData star = Icons.star_rounded;
  static const IconData starHalf = Icons.star_half_rounded;
  static const IconData reviews = Icons.reviews_rounded;
  static const IconData schedule = Icons.schedule_rounded;
  static const IconData storefront = Icons.storefront_rounded;
  static const IconData group = Icons.group_rounded;

  // Settings.
  static const IconData palette = Icons.palette_rounded;
  static const IconData globe = Icons.public_rounded;
  static const IconData layers = Icons.layers_rounded;
  static const IconData numbers = Icons.format_list_numbered_rounded;
  static const IconData copyStack = Icons.copy_all_rounded;
  static const IconData database = Icons.storage_rounded;
  static const IconData exportAll = Icons.file_download_rounded;
  static const IconData clearHistory = Icons.restore_rounded;
  static const IconData clearAll = Icons.delete_outline_rounded;
  static const IconData ad = Icons.campaign_rounded;
  static const IconData refresh = Icons.refresh_rounded;
  static const IconData shield = Icons.shield_rounded;
  static const IconData rate = Icons.star_border_rounded;
  static const IconData feedback = Icons.chat_bubble_outline_rounded;
  static const IconData support = Icons.mail_outline_rounded;
  static const IconData help = Icons.help_outline_rounded;
  static const IconData document = Icons.description_rounded;
  static const IconData external = Icons.open_in_new_rounded;
  static const IconData code = Icons.code_rounded;
  static const IconData version = Icons.info_outline_rounded;

  // Filters / export.
  static const IconData keywords = Icons.tag_rounded;
  static const IconData results = Icons.assignment_rounded;
  static const IconData clearance = Icons.delete_outline_rounded;
  static const IconData table = Icons.table_chart_rounded;
  static const IconData pdf = Icons.picture_as_pdf_rounded;
  static const IconData contactFile = Icons.contact_page_rounded;
  static const IconData file = Icons.description_rounded;
  static const IconData balance = Icons.balance_rounded;
  static const IconData reviewsList = Icons.forum_rounded;
}
