// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class LZh extends L {
  LZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Norway Explore';

  @override
  String get appTagline => '峡湾、瀑布与城镇 — 无需联网';

  @override
  String get nearbyTitle => '附近有什么';

  @override
  String get nearbySubtitle => '附近地点，含距离和方向';

  @override
  String get browseTitle => '去哪里';

  @override
  String get browseSubtitle => '全国的城镇与景点';

  @override
  String get favoritesTitle => '我的行程';

  @override
  String favoritesSaved(int count) {
    return '已保存 $count 个地点';
  }

  @override
  String get sourcesTitle => '来源与许可';

  @override
  String get sourcesTooltip => '关于来源';

  @override
  String photoBy(String credit) {
    return '图片：$credit';
  }

  @override
  String get nearbyScreenTitle => '我的附近';

  @override
  String nearbyScreenTitleAt(String city) {
    return '$city附近';
  }

  @override
  String get searchTooltip => '搜索';

  @override
  String get setCityTooltip => '选择城市';

  @override
  String get useGpsTooltip => '使用 GPS';

  @override
  String get interestsTooltip => '我的兴趣';

  @override
  String get locationUnknown => '位置未知，点击选择城市';

  @override
  String get nothingInFilters => '没有符合所选筛选条件的结果';

  @override
  String get loadError => '无法加载地点';

  @override
  String get otherLanguageShort => '其他语言';

  @override
  String get descriptionOtherLanguage => '暂无翻译 — 显示原文';

  @override
  String get tabCities => '城镇';

  @override
  String get tabPlaces => '景点';

  @override
  String get noCities => '此数据版本中没有城镇';

  @override
  String get nothingInCategories => '所选分类中没有找到内容';

  @override
  String shownOf(int shown, int total) {
    return '已显示 $shown / $total';
  }

  @override
  String get resetFilter => '重置';

  @override
  String placesCount(int count) {
    return '$count 个地点';
  }

  @override
  String get cityLarge => '大城市';

  @override
  String get cityMedium => '城市';

  @override
  String get citySmall => '小城';

  @override
  String get cityVillage => '村镇';

  @override
  String get cityHamlet => '小村';

  @override
  String get cityTourist => '旅游地';

  @override
  String get cityGeneric => '聚居地';

  @override
  String get noPlacesInCity => '该城镇暂无地点';

  @override
  String get placeNotFound => '未找到该地点';

  @override
  String get noDescription => '暂无介绍。坐标和导航可用 — 可以自己前往查看。';

  @override
  String get noDescriptionShort => '介绍尚未加载';

  @override
  String get routeButton => '导航前往';

  @override
  String get mapsFailed => '无法打开地图，需要联网。';

  @override
  String get addToFavorites => '加入行程';

  @override
  String get removeFromFavorites => '移出行程';

  @override
  String get factOpeningHours => '开放时间';

  @override
  String get factFee => '门票';

  @override
  String get factDifficulty => '难度';

  @override
  String get factDuration => '所需时间';

  @override
  String factMinutes(int count) {
    return '$count 分钟';
  }

  @override
  String get factSeason => '季节';

  @override
  String get factWebsite => '网站';

  @override
  String get searchHint => '地点、城镇、瀑布…';

  @override
  String get searchPrompt => '请至少输入两个字符';

  @override
  String get searchPromptDetail => '同时搜索您的语言、挪威语和英语 — 可以按路牌上的写法输入。';

  @override
  String searchNothing(String query) {
    return '没有找到「$query」';
  }

  @override
  String get searchNothingDetail => '并非所有地点都有介绍。可尝试挪威语写法或词的一部分。';

  @override
  String get searchError => '搜索出错';

  @override
  String get favoritesWant => '想去';

  @override
  String get favoritesVisited => '已去过';

  @override
  String get favoritesEmpty => '这里还是空的';

  @override
  String get favoritesEmptyDetail => '点击地点卡片上的心形即可加入这里。可以标记去过的地方并添加备注。';

  @override
  String get noteTooltip => '备注';

  @override
  String get noteHint => '几点开门、在哪停车、需要带什么…';

  @override
  String get markVisited => '已去过';

  @override
  String get markNotVisited => '还没去';

  @override
  String removedFromTrip(String place) {
    return '已将$place移出行程';
  }

  @override
  String get undo => '撤销';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get emergencyTitle => '紧急求助';

  @override
  String get emergencyTooltip => '紧急求助';

  @override
  String get emergencyOther => '其他服务';

  @override
  String get emergencyKnow => '重要提示';

  @override
  String get emergencyCoordinates => '您的坐标';

  @override
  String get emergencyCopy => '复制';

  @override
  String get emergencyCopied => '坐标已复制';

  @override
  String get emergencyManualPosition => '位置为手动设置，非 GPS 定位';

  @override
  String emergencyDial(String service, String number) {
    return '$service：拨打 $number';
  }

  @override
  String get whereAreYou => '您在哪里？';

  @override
  String get cityHint => '城市：Bergen、Oslo、Tromsø…';

  @override
  String get nothingFound => '没有找到';

  @override
  String get profileQuestion => '您最感兴趣的是什么？';

  @override
  String get profileQuestionDetail => '我们会调整优先显示的内容。不会隐藏任何内容 — 完整目录仍可通过搜索查看。';

  @override
  String get profileWhen => '您计划何时出行？';

  @override
  String get profileWhenDetail => '山路和部分步道冬季关闭 — 不会推荐现在无法抵达的地方。';

  @override
  String get profileNow => '我现在就在挪威';

  @override
  String get profileSoon => '未来几个月';

  @override
  String get profileBrowsing => '只是看看';

  @override
  String get profileSkip => '跳过';

  @override
  String get profileNext => '下一步';

  @override
  String profileDone(int count) {
    return '完成 — 已按 $count 项兴趣调整排序';
  }

  @override
  String get catMuseums => '博物馆';

  @override
  String get catViewpoints => '观景点';

  @override
  String get catFjords => '峡湾';

  @override
  String get catWaterfalls => '瀑布';

  @override
  String get catChurches => '教堂';

  @override
  String get catHikes => '步道';

  @override
  String get catGlaciers => '冰川';

  @override
  String get catBeaches => '海滩';

  @override
  String get catMuseum => '博物馆';

  @override
  String get catViewpoint => '观景点';

  @override
  String get catFjord => '峡湾';

  @override
  String get catWaterfall => '瀑布';

  @override
  String get catChurch => '教堂';

  @override
  String get catHike => '步道';

  @override
  String get catGlacier => '冰川';

  @override
  String get catBeach => '海滩';

  @override
  String get catOther => '地点';

  @override
  String get emgAmbulance => '急救';

  @override
  String get emgAmbulanceSub => 'Ambulanse · 危及生命、重伤';

  @override
  String get emgPolice => '警察';

  @override
  String get emgPoliceSub => 'Politi · 犯罪、事故、人员失踪';

  @override
  String get emgFire => '消防';

  @override
  String get emgFireSub => 'Brann · 火灾、浓烟、燃气泄漏';

  @override
  String get emgDoctor => '值班医生';

  @override
  String get emgDoctorSub => 'Legevakt · 紧急但无生命危险';

  @override
  String get emgSea => '海上救援';

  @override
  String get emgSeaSub => 'Hovedredningssentralen · 海上事故';

  @override
  String get emgPoison => '中毒';

  @override
  String get emgPoisonSub => 'Giftinformasjonen · 24 小时';

  @override
  String get emgRoad => '道路服务';

  @override
  String get emgRoadSub => 'Vegtrafikksentralen · 道路封闭、雪崩';

  @override
  String get emgNoteSimTitle => '无网络、无 SIM 卡也能拨通';

  @override
  String get emgNoteSimBody =>
      '拨打 112 和 113 会经由任何可用信号塔接通，即使您的运营商没有信号、手机里没有 SIM 卡。';

  @override
  String get emgNoteCoordsTitle => '报出坐标';

  @override
  String get emgNoteCoordsBody => '山区和峡湾没有门牌地址。请读出纬度和经度 — 就在本页下方，可以复制。';

  @override
  String get emgNoteEnglishTitle => '可以说英语';

  @override
  String get emgNoteEnglishBody => '挪威紧急服务接线员会说英语。请保持冷静、简短说明：发生了什么、在哪里、有多少人受伤。';

  @override
  String get emgNoteMountainTitle => '山区求助拨 112';

  @override
  String get emgNoteMountainBody => '山区救援由警方负责，没有单独号码。请勿关机：救援人员会通过手机定位您。';

  @override
  String get emgVerified =>
      '号码适用于挪威。已于 2026-09-10 依据 politiet.no、helsenorge.no、hovedredningssentralen.no 核对。';

  @override
  String get onboardingTitle => '您对挪威的什么感兴趣？';

  @override
  String get onboardingSubtitle => '选择所有符合的项目 — 我们会据此调整优先显示的内容。';

  @override
  String get onboardingNothingHidden => '不会隐藏任何内容：完整目录仍可通过搜索和筛选查看。';

  @override
  String get onboardingStart => '开始';

  @override
  String get intNature => '自然与风景';

  @override
  String get intHiking => '徒步与远足';

  @override
  String get intFishing => '钓鱼';

  @override
  String get intHunting => '狩猎';

  @override
  String get intCulture => '博物馆与文化';

  @override
  String get intPhoto => '摄影';

  @override
  String get intKids => '亲子出行';

  @override
  String get intRoadtrip => '自驾游';

  @override
  String get intWinter => '冬季运动';

  @override
  String get intCruise => '邮轮靠岸数小时';

  @override
  String get rulesTitle => '规定与许可';

  @override
  String get rulesWhereToCheck => '在哪里核实';

  @override
  String rulesKommune(String name) {
    return '$name 市镇';
  }

  @override
  String rulesCheckedAt(String date) {
    return '数据获取于 $date';
  }

  @override
  String get rulesCallKommune => '致电市镇';

  @override
  String get rulesOpenSite => '市镇网站';

  @override
  String get rulesDisclaimer =>
      '本应用不发放任何许可，也无法判断此处是否允许垂钓或狩猎。这取决于市镇、土地所有者、季节和物种。出行前请向市镇或土地所有者核实。';

  @override
  String get rulesNational => '全国通用规定';

  @override
  String rulesSource(String authority) {
    return '来源：$authority';
  }

  @override
  String get rulesFishing => '钓鱼';

  @override
  String get rulesHunting => '狩猎';

  @override
  String get rulesNoKommune =>
      '无法确定此处所属市镇。在斯瓦尔巴群岛，规定由总督（Sysselmesteren）制定，而非市镇。';

  @override
  String get promptTitle => '您对什么感兴趣？';

  @override
  String get promptSubtitle => '钓鱼、徒步、博物馆 — 我们据此调整显示内容';

  @override
  String get modeTourist => '全部';

  @override
  String get modeFishing => '钓鱼';

  @override
  String get modeHunting => '狩猎';

  @override
  String get modeSwitch => '模式';

  @override
  String get modeFishingHint => '正在显示钓鱼点。城镇和景点已隐藏 — 可通过模式按钮恢复。';

  @override
  String get modeHuntingHint => '正在显示自然区域。狩猎场未在地图上标注 — 此处关键在于规定和市镇。';

  @override
  String get modeRulesButton => '规定与许可';

  @override
  String get locServiceOff => '手机设置中已关闭定位';

  @override
  String get locDenied => '无法访问位置信息';

  @override
  String get locDeniedForever => '位置权限已被拒绝，可在应用设置中开启';

  @override
  String get locUnavailable => '无法确定您的位置。室内信号较弱';

  @override
  String get locOpenSettings => '设置';

  @override
  String get locSetCity => '选择城市';

  @override
  String get locRetry => '重试';

  @override
  String get nothingNearby => '附近没有地点';

  @override
  String get nothingNearbyHint => '本指南只收录有介绍或照片的地点，您周围目前没有。';

  @override
  String get nothingInFiltersHint => '试着取消一个分类，附近可能还有其他地点。';

  @override
  String get resetFilters => '显示全部分类';

  @override
  String get mostVisitedTitle => '最多人去';

  @override
  String get mostVisitedSubtitle => '人们专程前往挪威的二十五个地点';

  @override
  String get mostVisitedEmpty => '此内容包中没有榜单';

  @override
  String get mostVisitedNote =>
      '排序由人工整理，依据参观人数、联合国教科文组织名录状态和知名度。若显示参观人数，年份与来源见地点详情页。';

  @override
  String get unescoShort => '联合国教科文';

  @override
  String photoCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 张照片',
    );
    return '$_temp0';
  }

  @override
  String visitorsPerYear(int n, String year) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '每年约 $nString 名访客（$year）';
  }

  @override
  String get profileDoneButton => '完成';

  @override
  String get downloadsTitle => '出行前下载';

  @override
  String get downloadsNote => '照片按地区下载，以保持应用轻量。不会自动下载任何内容——本指南绝不会未经您同意消耗流量。';

  @override
  String downloadsBuiltAt(String date) {
    return '内容制作于 $date';
  }

  @override
  String downloadsPhotos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 张照片',
    );
    return '$_temp0';
  }

  @override
  String get downloadsStart => '下载';

  @override
  String get downloadsRemove => '删除';

  @override
  String get downloadsUpdateAvailable => '有更新的版本';

  @override
  String get downloadsFailed => '下载失败';

  @override
  String get downloadsOffline => '无法连接到内容服务器';

  @override
  String get downloadsNothingInstalled => '尚未下载任何内容。地点仍可使用，只是缺少额外照片。';

  @override
  String downloadsInstalledCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '已下载 $n 个地区',
    );
    return '$_temp0';
  }

  @override
  String get routeBannerTitle => '现成的城市漫步路线';

  @override
  String routeTitle(String city) {
    return '$city 漫步路线';
  }

  @override
  String routeAbout(String hours) {
    return '约 $hours 小时';
  }

  @override
  String routeDistance(String km) {
    return '$km 公里';
  }

  @override
  String routeStops(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n 站');
    return '$_temp0';
  }

  @override
  String get routeEmpty => '此路线没有站点';

  @override
  String get routeNote =>
      '顺序与时间均为估算：距离按直线计算并加上街道系数，参观时长按地点类型估计。需要导航请使用地点页面的地图按钮。';

  @override
  String offerTitle(String region) {
    return '您位于$region';
  }

  @override
  String offerSubtitle(int n, String mb) {
    return '该地区 $n 张照片 · $mb MB';
  }

  @override
  String get offerLater => '暂不';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsContent => '内容';

  @override
  String get settingsAutoWifi => '自动下载地区内容';

  @override
  String get settingsAutoWifiDetail => '仅在 Wi-Fi 下。绝不使用移动流量。';

  @override
  String get settingsWifiNow => '已连接 Wi-Fi';

  @override
  String get settingsWifiNo => '当前没有 Wi-Fi';

  @override
  String get settingsProfileSection => '您的兴趣';

  @override
  String get settingsNoInterests => '未设置';

  @override
  String get settingsResetOffers => '重新显示下载建议';

  @override
  String get settingsResetOffersDetail => '您此前忽略的地区将再提示一次';

  @override
  String get settingsResetDone => '建议已恢复';

  @override
  String get settingsAbout => '关于';

  @override
  String distanceMeters(int n) {
    return '$n 米';
  }

  @override
  String distanceKm(String km) {
    return '$km 公里';
  }

  @override
  String get compassN => '北';

  @override
  String get compassNE => '东北';

  @override
  String get compassE => '东';

  @override
  String get compassSE => '东南';

  @override
  String get compassS => '南';

  @override
  String get compassSW => '西南';

  @override
  String get compassW => '西';

  @override
  String get compassNW => '西北';

  @override
  String get gpxExport => '导出为 GPX';

  @override
  String get gpxDescription => '由 Norway Explore 生成。站点顺序与时间均为估算。';

  @override
  String get gpxFailed => '无法分享文件';
}
