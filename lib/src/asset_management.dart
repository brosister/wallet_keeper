part of '../main.dart';

enum WalletKeeperAssetType {
  account,
  card,
  securities,
  crypto,
  loan,
  cash;

  String get label {
    switch (this) {
      case WalletKeeperAssetType.account:
        return '계좌';
      case WalletKeeperAssetType.card:
        return '카드';
      case WalletKeeperAssetType.securities:
        return '증권';
      case WalletKeeperAssetType.crypto:
        return '코인';
      case WalletKeeperAssetType.loan:
        return '대출';
      case WalletKeeperAssetType.cash:
        return '현금';
    }
  }

  String get providerLabel {
    switch (this) {
      case WalletKeeperAssetType.account:
        return '은행';
      case WalletKeeperAssetType.card:
        return '카드사';
      case WalletKeeperAssetType.securities:
        return '증권사';
      case WalletKeeperAssetType.crypto:
        return '거래소';
      case WalletKeeperAssetType.loan:
        return '금융사';
      case WalletKeeperAssetType.cash:
        return '관리 방식';
    }
  }

  IconData get icon {
    switch (this) {
      case WalletKeeperAssetType.account:
        return Icons.account_balance_rounded;
      case WalletKeeperAssetType.card:
        return Icons.credit_card_rounded;
      case WalletKeeperAssetType.securities:
        return Icons.candlestick_chart_rounded;
      case WalletKeeperAssetType.crypto:
        return Icons.currency_bitcoin_rounded;
      case WalletKeeperAssetType.loan:
        return Icons.request_quote_rounded;
      case WalletKeeperAssetType.cash:
        return Icons.account_balance_wallet_rounded;
    }
  }

  Color get color {
    switch (this) {
      case WalletKeeperAssetType.account:
        return const Color(0xFF4F8FF7);
      case WalletKeeperAssetType.card:
        return const Color(0xFFFF695D);
      case WalletKeeperAssetType.securities:
        return const Color(0xFF20A879);
      case WalletKeeperAssetType.crypto:
        return const Color(0xFFF3A72F);
      case WalletKeeperAssetType.loan:
        return const Color(0xFF7A6FF0);
      case WalletKeeperAssetType.cash:
        return const Color(0xFF6A7482);
    }
  }

  bool get isLiability =>
      this == WalletKeeperAssetType.card || this == WalletKeeperAssetType.loan;
}

class WalletKeeperAssetBrand {
  const WalletKeeperAssetBrand({
    required this.key,
    required this.name,
    required this.assetPath,
    required this.supportedTypes,
    required this.aliases,
  });

  final String key;
  final String name;
  final String assetPath;
  final List<WalletKeeperAssetType> supportedTypes;
  final List<String> aliases;

  WalletKeeperAssetType get defaultType => supportedTypes.first;
  bool supports(WalletKeeperAssetType type) => supportedTypes.contains(type);
}

const List<WalletKeeperAssetBrand> walletKeeperAssetBrands = [
  WalletKeeperAssetBrand(
    key: 'kb_bank',
    name: 'KB국민은행',
    assetPath: 'assets/icons/asset_kb_bank.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['KB국민은행', '국민은행', 'KB스타뱅킹', 'com.kbstar.kbbank'],
  ),
  WalletKeeperAssetBrand(
    key: 'shinhan',
    name: '신한은행',
    assetPath: 'assets/icons/asset_shinhan.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['신한은행', '신한SOL뱅크', 'com.shinhan.sbanking'],
  ),
  WalletKeeperAssetBrand(
    key: 'woori',
    name: '우리은행',
    assetPath: 'assets/icons/asset_woori.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['우리은행', '우리WON뱅킹', 'com.wooribank'],
  ),
  WalletKeeperAssetBrand(
    key: 'hana',
    name: '하나은행',
    assetPath: 'assets/icons/asset_hana.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['하나은행', '하나원큐', 'com.hanabank.oqf', 'com.kebhana'],
  ),
  WalletKeeperAssetBrand(
    key: 'nh',
    name: 'NH농협은행',
    assetPath: 'assets/icons/asset_nh.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['NH농협은행', '농협은행', 'NH스마트뱅킹', 'nh.smart.banking'],
  ),
  WalletKeeperAssetBrand(
    key: 'ibk_bank',
    name: 'IBK기업은행',
    assetPath: 'assets/icons/asset_ibk_bank.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['IBK기업은행', '기업은행', 'i-ONE Bank', 'com.ibk.android.ionebank'],
  ),
  WalletKeeperAssetBrand(
    key: 'kbank',
    name: '케이뱅크',
    assetPath: 'assets/icons/asset_kbank.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['케이뱅크', 'K뱅크', 'com.kbankwith.smartbank'],
  ),
  WalletKeeperAssetBrand(
    key: 'kakaobank',
    name: '카카오뱅크',
    assetPath: 'assets/icons/asset_kakaobank.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['카카오뱅크', '카뱅', 'com.kakaobank'],
  ),
  WalletKeeperAssetBrand(
    key: 'toss',
    name: '토스',
    assetPath: 'assets/icons/asset_toss.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.securities,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['토스', '토스뱅크', '토스증권', 'viva.republica.toss'],
  ),
  WalletKeeperAssetBrand(
    key: 'sc_bank',
    name: 'SC제일은행',
    assetPath: 'assets/icons/asset_sc_bank.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['SC제일은행', 'SC은행', 'com.scbank.ma30'],
  ),
  WalletKeeperAssetBrand(
    key: 'citi_bank',
    name: '한국씨티은행',
    assetPath: 'assets/icons/asset_citi_bank.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['한국씨티은행', '씨티은행', '씨티모바일', 'kr.co.citibank'],
  ),
  WalletKeeperAssetBrand(
    key: 'post_bank',
    name: '우체국',
    assetPath: 'assets/icons/asset_post_bank.png',
    supportedTypes: [WalletKeeperAssetType.account],
    aliases: ['우체국', '우체국예금', '우체국뱅킹', 'com.epost.psf.sdsi'],
  ),
  WalletKeeperAssetBrand(
    key: 'mg_bank',
    name: '새마을금고',
    assetPath: 'assets/icons/asset_mg_bank.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['새마을금고', 'MG더뱅킹', 'com.smg.spbs'],
  ),
  WalletKeeperAssetBrand(
    key: 'shinhyup',
    name: '신협',
    assetPath: 'assets/icons/asset_shinhyup.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['신협', '신협온뱅크', 'kr.co.cu.onbank'],
  ),
  WalletKeeperAssetBrand(
    key: 'suhyup',
    name: '수협은행',
    assetPath: 'assets/icons/asset_suhyup.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['수협은행', '수협', '파트너뱅크', 'com.suhyup.psmb'],
  ),
  WalletKeeperAssetBrand(
    key: 'busan_bank',
    name: '부산은행',
    assetPath: 'assets/icons/asset_busan_bank.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['BNK부산은행', '부산은행', 'kr.co.busanbank.mbp'],
  ),
  WalletKeeperAssetBrand(
    key: 'kyongnam_bank',
    name: '경남은행',
    assetPath: 'assets/icons/asset_kyongnam_bank.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['BNK경남은행', '경남은행', 'com.knb.psb'],
  ),
  WalletKeeperAssetBrand(
    key: 'im_bank',
    name: 'iM뱅크',
    assetPath: 'assets/icons/asset_im_bank.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['iM뱅크', '아이엠뱅크', '대구은행', 'DGB', 'kr.co.dgb.dgbm'],
  ),
  WalletKeeperAssetBrand(
    key: 'gwangju_bank',
    name: '광주은행',
    assetPath: 'assets/icons/asset_gwangju_bank.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['광주은행', '광주와뱅크', 'com.kjbank.asb.pbanking'],
  ),
  WalletKeeperAssetBrand(
    key: 'jeonbuk_bank',
    name: '전북은행',
    assetPath: 'assets/icons/asset_jeonbuk_bank.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['전북은행', '쏙뱅크', 'kr.co.jbbank.privatebank'],
  ),
  WalletKeeperAssetBrand(
    key: 'jeju_bank',
    name: '제주은행',
    assetPath: 'assets/icons/asset_jeju_bank.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['제주은행', 'J BANK', 'com.jejubank.smartnew'],
  ),
  WalletKeeperAssetBrand(
    key: 'kdb_bank',
    name: 'KDB산업은행',
    assetPath: 'assets/icons/asset_kdb_bank.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['KDB산업은행', '산업은행', '스마트KDB', 'co.kr.kdb.android.smartkdb'],
  ),
  WalletKeeperAssetBrand(
    key: 'forestry_bank',
    name: '산림조합',
    assetPath: 'assets/icons/asset_forestry_bank.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['산림조합', 'SJ산림조합', '산림조합 스마트뱅킹', 'kr.or.nfcf.NFCFSmart'],
  ),
  WalletKeeperAssetBrand(
    key: 'sb_plus',
    name: '저축은행 통합',
    assetPath: 'assets/icons/asset_sb_plus.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['저축은행 통합', 'SB톡톡플러스', 'SB톡톡+', 'kr.or.sbbank.plus'],
  ),
  WalletKeeperAssetBrand(
    key: 'kb_card',
    name: 'KB국민카드',
    assetPath: 'assets/icons/asset_kb_card.png',
    supportedTypes: [WalletKeeperAssetType.card],
    aliases: ['KB국민카드', '국민카드', 'KB Pay', 'com.kbcard'],
  ),
  WalletKeeperAssetBrand(
    key: 'shinhan_card',
    name: '신한카드',
    assetPath: 'assets/icons/asset_shinhan_card.png',
    supportedTypes: [WalletKeeperAssetType.card],
    aliases: ['신한카드', '신한SOL페이', 'com.shcard.smartpay'],
  ),
  WalletKeeperAssetBrand(
    key: 'samsung_card',
    name: '삼성카드',
    assetPath: 'assets/icons/asset_samsung_card.png',
    supportedTypes: [WalletKeeperAssetType.card],
    aliases: ['삼성카드', '모니모', 'samsungcard', 'net.ib.android.smcard'],
  ),
  WalletKeeperAssetBrand(
    key: 'hyundai_card',
    name: '현대카드',
    assetPath: 'assets/icons/asset_hyundai_card.png',
    supportedTypes: [WalletKeeperAssetType.card],
    aliases: ['현대카드', 'hyundaicard', 'com.hyundaicard'],
  ),
  WalletKeeperAssetBrand(
    key: 'lotte_card',
    name: '롯데카드',
    assetPath: 'assets/icons/asset_lotte_card.png',
    supportedTypes: [WalletKeeperAssetType.card],
    aliases: ['롯데카드', '디지로카', 'com.lcacApp'],
  ),
  WalletKeeperAssetBrand(
    key: 'woori_card',
    name: '우리카드',
    assetPath: 'assets/icons/asset_woori_card.png',
    supportedTypes: [WalletKeeperAssetType.card],
    aliases: ['우리카드', '우리WON카드', 'com.wooricard.smartapp'],
  ),
  WalletKeeperAssetBrand(
    key: 'hana_card',
    name: '하나카드',
    assetPath: 'assets/icons/asset_hana_card.png',
    supportedTypes: [WalletKeeperAssetType.card],
    aliases: ['하나카드', '하나Pay', 'com.hanaskcard.paycla'],
  ),
  WalletKeeperAssetBrand(
    key: 'nh_card',
    name: 'NH농협카드',
    assetPath: 'assets/icons/asset_nh_card.png',
    supportedTypes: [WalletKeeperAssetType.card],
    aliases: ['NH농협카드', '농협카드', 'NH pay', 'nh.smart.nhallonepay'],
  ),
  WalletKeeperAssetBrand(
    key: 'bc_card',
    name: 'BC카드',
    assetPath: 'assets/icons/asset_bc_card.png',
    supportedTypes: [WalletKeeperAssetType.card],
    aliases: ['BC카드', '비씨카드', '페이북', 'kvp.jjy.MispAndroid320'],
  ),
  WalletKeeperAssetBrand(
    key: 'ibk_card',
    name: 'IBK카드',
    assetPath: 'assets/icons/asset_ibk_bank.png',
    supportedTypes: [WalletKeeperAssetType.card],
    aliases: ['IBK카드', '기업은행카드', '기업카드'],
  ),
  WalletKeeperAssetBrand(
    key: 'kbank_card',
    name: '케이뱅크 카드',
    assetPath: 'assets/icons/asset_kbank.png',
    supportedTypes: [WalletKeeperAssetType.card],
    aliases: ['케이뱅크 카드', '케이뱅크 체크카드', 'K뱅크 카드'],
  ),
  WalletKeeperAssetBrand(
    key: 'kakaobank_card',
    name: '카카오뱅크 카드',
    assetPath: 'assets/icons/asset_kakaobank.png',
    supportedTypes: [WalletKeeperAssetType.card],
    aliases: ['카카오뱅크 카드', '카카오뱅크 체크카드', '카뱅 카드'],
  ),
  WalletKeeperAssetBrand(
    key: 'toss_card',
    name: '토스뱅크 카드',
    assetPath: 'assets/icons/asset_toss.png',
    supportedTypes: [WalletKeeperAssetType.card],
    aliases: ['토스뱅크 카드', '토스뱅크 체크카드', '토스 카드'],
  ),
  WalletKeeperAssetBrand(
    key: 'citi_card',
    name: '씨티카드',
    assetPath: 'assets/icons/asset_citi_bank.png',
    supportedTypes: [WalletKeeperAssetType.card],
    aliases: ['씨티카드', '한국씨티카드'],
  ),
  WalletKeeperAssetBrand(
    key: 'sc_card',
    name: 'SC제일은행 카드',
    assetPath: 'assets/icons/asset_sc_bank.png',
    supportedTypes: [WalletKeeperAssetType.card],
    aliases: ['SC제일은행 카드', 'SC제일카드', 'SC카드'],
  ),
  WalletKeeperAssetBrand(
    key: 'mg_card',
    name: '새마을금고 카드',
    assetPath: 'assets/icons/asset_mg_bank.png',
    supportedTypes: [WalletKeeperAssetType.card],
    aliases: ['새마을금고 카드', 'MG체크카드', 'MG카드'],
  ),
  WalletKeeperAssetBrand(
    key: 'shinhyup_card',
    name: '신협 카드',
    assetPath: 'assets/icons/asset_shinhyup.png',
    supportedTypes: [WalletKeeperAssetType.card],
    aliases: ['신협 카드', '신협체크카드'],
  ),
  WalletKeeperAssetBrand(
    key: 'suhyup_card',
    name: '수협카드',
    assetPath: 'assets/icons/asset_suhyup.png',
    supportedTypes: [WalletKeeperAssetType.card],
    aliases: ['수협카드', '수협 체크카드'],
  ),
  WalletKeeperAssetBrand(
    key: 'post_card',
    name: '우체국 카드',
    assetPath: 'assets/icons/asset_post_bank.png',
    supportedTypes: [WalletKeeperAssetType.card],
    aliases: ['우체국 카드', '우체국 체크카드'],
  ),
  WalletKeeperAssetBrand(
    key: 'busan_card',
    name: '부산은행 카드',
    assetPath: 'assets/icons/asset_busan_bank.png',
    supportedTypes: [WalletKeeperAssetType.card],
    aliases: ['부산은행 카드', 'BNK부산은행 카드'],
  ),
  WalletKeeperAssetBrand(
    key: 'kyongnam_card',
    name: '경남은행 카드',
    assetPath: 'assets/icons/asset_kyongnam_bank.png',
    supportedTypes: [WalletKeeperAssetType.card],
    aliases: ['경남은행 카드', 'BNK경남은행 카드'],
  ),
  WalletKeeperAssetBrand(
    key: 'im_card',
    name: 'iM뱅크 카드',
    assetPath: 'assets/icons/asset_im_bank.png',
    supportedTypes: [WalletKeeperAssetType.card],
    aliases: ['iM뱅크 카드', '대구은행 카드', 'DGB카드'],
  ),
  WalletKeeperAssetBrand(
    key: 'gwangju_card',
    name: '광주은행 카드',
    assetPath: 'assets/icons/asset_gwangju_bank.png',
    supportedTypes: [WalletKeeperAssetType.card],
    aliases: ['광주은행 카드', 'KJ카드'],
  ),
  WalletKeeperAssetBrand(
    key: 'jeonbuk_card',
    name: '전북은행 카드',
    assetPath: 'assets/icons/asset_jeonbuk_bank.png',
    supportedTypes: [WalletKeeperAssetType.card],
    aliases: ['전북은행 카드', 'JB카드'],
  ),
  WalletKeeperAssetBrand(
    key: 'jeju_card',
    name: '제주은행 카드',
    assetPath: 'assets/icons/asset_jeju_bank.png',
    supportedTypes: [WalletKeeperAssetType.card],
    aliases: ['제주은행 카드', 'J BANK 카드'],
  ),
  WalletKeeperAssetBrand(
    key: 'mirae',
    name: '미래에셋증권',
    assetPath: 'assets/icons/asset_mirae.png',
    supportedTypes: [WalletKeeperAssetType.securities],
    aliases: ['미래에셋', '미래에셋증권', 'M-STOCK', 'com.miraeasset'],
  ),
  WalletKeeperAssetBrand(
    key: 'kiwoom',
    name: '키움증권',
    assetPath: 'assets/icons/asset_kiwoom.png',
    supportedTypes: [WalletKeeperAssetType.securities],
    aliases: ['키움증권', '영웅문', 'com.kiwoom.heromts'],
  ),
  WalletKeeperAssetBrand(
    key: 'samsung_sec',
    name: '삼성증권',
    assetPath: 'assets/icons/asset_samsung_sec.png',
    supportedTypes: [WalletKeeperAssetType.securities],
    aliases: ['삼성증권', 'mPOP', 'com.samsungpop.android.mpop'],
  ),
  WalletKeeperAssetBrand(
    key: 'nh_sec',
    name: 'NH투자증권',
    assetPath: 'assets/icons/asset_nh_sec.png',
    supportedTypes: [WalletKeeperAssetType.securities],
    aliases: ['NH투자증권', '나무증권', 'com.wooriwm.txsmart'],
  ),
  WalletKeeperAssetBrand(
    key: 'kb_sec',
    name: 'KB증권',
    assetPath: 'assets/icons/asset_kb_sec.png',
    supportedTypes: [WalletKeeperAssetType.securities],
    aliases: ['KB증권', 'M-able', '마블', 'com.kbsec'],
  ),
  WalletKeeperAssetBrand(
    key: 'korea_invest',
    name: '한국투자증권',
    assetPath: 'assets/icons/asset_korea_invest.png',
    supportedTypes: [WalletKeeperAssetType.securities],
    aliases: ['한국투자증권', '한투', 'com.truefriend'],
  ),
  WalletKeeperAssetBrand(
    key: 'shinhan_sec',
    name: '신한투자증권',
    assetPath: 'assets/icons/asset_shinhan_sec.png',
    supportedTypes: [WalletKeeperAssetType.securities],
    aliases: ['신한투자증권', '신한SOL증권', 'com.shinhaninvest'],
  ),
  WalletKeeperAssetBrand(
    key: 'hana_sec',
    name: '하나증권',
    assetPath: 'assets/icons/asset_hana_sec.png',
    supportedTypes: [WalletKeeperAssetType.securities],
    aliases: ['하나증권', '원큐프로', 'com.hanasec.stock'],
  ),
  WalletKeeperAssetBrand(
    key: 'meritz_sec',
    name: '메리츠증권',
    assetPath: 'assets/icons/asset_meritz_sec.png',
    supportedTypes: [WalletKeeperAssetType.securities],
    aliases: ['메리츠증권', '메리츠SMART', 'com.imeritz.smartmeritz'],
  ),
  WalletKeeperAssetBrand(
    key: 'daishin_sec',
    name: '대신증권',
    assetPath: 'assets/icons/asset_daishin_sec.png',
    supportedTypes: [WalletKeeperAssetType.securities],
    aliases: ['대신증권', 'CYBOS Touch', '사이보스', 'com.daishin'],
  ),
  WalletKeeperAssetBrand(
    key: 'yuanta_sec',
    name: '유안타증권',
    assetPath: 'assets/icons/asset_yuanta_sec.png',
    supportedTypes: [WalletKeeperAssetType.securities],
    aliases: ['유안타증권', '티레이더M', 'tRadar', 'com.yuanta.tradars'],
  ),
  WalletKeeperAssetBrand(
    key: 'kyobo_sec',
    name: '교보증권',
    assetPath: 'assets/icons/asset_kyobo_sec.png',
    supportedTypes: [WalletKeeperAssetType.securities],
    aliases: ['교보증권', 'Win.K', '윈케이', 'kr.com.wink'],
  ),
  WalletKeeperAssetBrand(
    key: 'ls_sec',
    name: 'LS증권',
    assetPath: 'assets/icons/asset_ls_sec.png',
    supportedTypes: [WalletKeeperAssetType.securities],
    aliases: ['LS증권', '이베스트투자증권', '투혼', 'com.ebest.mobile'],
  ),
  WalletKeeperAssetBrand(
    key: 'db_sec',
    name: 'DB증권',
    assetPath: 'assets/icons/asset_db_sec.png',
    supportedTypes: [WalletKeeperAssetType.securities],
    aliases: ['DB증권', 'DB금융투자', '알파증권', 'com.dbfi.xts'],
  ),
  WalletKeeperAssetBrand(
    key: 'hanwha_sec',
    name: '한화투자증권',
    assetPath: 'assets/icons/asset_hanwha_sec.png',
    supportedTypes: [WalletKeeperAssetType.securities],
    aliases: ['한화투자증권', '한화증권', 'STEPS', 'plus.steps.sapp'],
  ),
  WalletKeeperAssetBrand(
    key: 'hyundai_sec',
    name: '현대차증권',
    assetPath: 'assets/icons/asset_hyundai_sec.png',
    supportedTypes: [WalletKeeperAssetType.securities],
    aliases: ['현대차증권', '현대증권', '현대차증권 내일', 'com.hmsec.mts'],
  ),
  WalletKeeperAssetBrand(
    key: 'shinyoung_sec',
    name: '신영증권',
    assetPath: 'assets/icons/asset_shinyoung_sec.png',
    supportedTypes: [WalletKeeperAssetType.securities],
    aliases: ['신영증권', '신영증권 그린', 'com.shinyoung.mts'],
  ),
  WalletKeeperAssetBrand(
    key: 'eugene_sec',
    name: '유진투자증권',
    assetPath: 'assets/icons/asset_eugene_sec.png',
    supportedTypes: [WalletKeeperAssetType.securities],
    aliases: ['유진투자증권', '유진증권', '스마트챔피언', 'com.eugenefn.smartchampion2'],
  ),
  WalletKeeperAssetBrand(
    key: 'im_sec',
    name: 'iM증권',
    assetPath: 'assets/icons/asset_im_sec.png',
    supportedTypes: [WalletKeeperAssetType.securities],
    aliases: ['iM증권', '하이투자증권', 'com.hiib.android.imhim'],
  ),
  WalletKeeperAssetBrand(
    key: 'bnk_sec',
    name: 'BNK투자증권',
    assetPath: 'assets/icons/asset_bnk_sec.png',
    supportedTypes: [WalletKeeperAssetType.securities],
    aliases: ['BNK투자증권', 'BNK증권', 'com.bnkfn.mtsplus'],
  ),
  WalletKeeperAssetBrand(
    key: 'sk_sec',
    name: 'SK증권',
    assetPath: 'assets/icons/asset_sk_sec.png',
    supportedTypes: [WalletKeeperAssetType.securities],
    aliases: ['SK증권', '주파수3', 'com.sks.android.neojoopasoo'],
  ),
  WalletKeeperAssetBrand(
    key: 'ibk_sec',
    name: 'IBK투자증권',
    assetPath: 'assets/icons/asset_ibk_sec.png',
    supportedTypes: [WalletKeeperAssetType.securities],
    aliases: ['IBK투자증권', 'IBK증권', 'Wings', 'com.ibks.ione.mts'],
  ),
  WalletKeeperAssetBrand(
    key: 'kakaopay_sec',
    name: '카카오페이증권',
    assetPath: 'assets/icons/asset_kakaopay_sec.png',
    supportedTypes: [WalletKeeperAssetType.securities],
    aliases: ['카카오페이증권', '카카오 주식', 'com.kakaopay.app'],
  ),
  WalletKeeperAssetBrand(
    key: 'daol_sec',
    name: '다올투자증권',
    assetPath: 'assets/icons/asset_daol_sec.png',
    supportedTypes: [WalletKeeperAssetType.securities],
    aliases: ['다올투자증권', '다올증권', 'KTB투자증권', 'com.ktb.android.mobiletrading'],
  ),
  WalletKeeperAssetBrand(
    key: 'upbit',
    name: '업비트',
    assetPath: 'assets/icons/asset_upbit.png',
    supportedTypes: [WalletKeeperAssetType.crypto],
    aliases: ['업비트', 'UPBIT', 'com.dunamu.exchange'],
  ),
  WalletKeeperAssetBrand(
    key: 'bithumb',
    name: '빗썸',
    assetPath: 'assets/icons/asset_bithumb.png',
    supportedTypes: [WalletKeeperAssetType.crypto],
    aliases: ['빗썸', 'BITHUMB', 'com.btckorea.bithumb'],
  ),
  WalletKeeperAssetBrand(
    key: 'coinone',
    name: '코인원',
    assetPath: 'assets/icons/asset_coinone.png',
    supportedTypes: [WalletKeeperAssetType.crypto],
    aliases: ['코인원', 'COINONE', 'coinone.co.kr.official'],
  ),
  WalletKeeperAssetBrand(
    key: 'korbit',
    name: '코빗',
    assetPath: 'assets/icons/asset_korbit.png',
    supportedTypes: [WalletKeeperAssetType.crypto],
    aliases: ['코빗', 'KORBIT', 'com.korbit.exchange'],
  ),
  WalletKeeperAssetBrand(
    key: 'gopax',
    name: '고팍스',
    assetPath: 'assets/icons/asset_gopax.png',
    supportedTypes: [WalletKeeperAssetType.crypto],
    aliases: ['고팍스', 'GOPAX', 'kr.co.gopax'],
  ),
  WalletKeeperAssetBrand(
    key: 'binance',
    name: '바이낸스',
    assetPath: 'assets/icons/asset_binance.png',
    supportedTypes: [WalletKeeperAssetType.crypto],
    aliases: ['바이낸스', 'BINANCE', 'com.binance.dev'],
  ),
  WalletKeeperAssetBrand(
    key: 'coinbase',
    name: '코인베이스',
    assetPath: 'assets/icons/asset_coinbase.png',
    supportedTypes: [WalletKeeperAssetType.crypto],
    aliases: ['코인베이스', 'COINBASE', 'com.coinbase.android'],
  ),
  WalletKeeperAssetBrand(
    key: 'bybit',
    name: '바이비트',
    assetPath: 'assets/icons/asset_bybit.png',
    supportedTypes: [WalletKeeperAssetType.crypto],
    aliases: ['바이비트', 'BYBIT', 'com.bybit.app'],
  ),
  WalletKeeperAssetBrand(
    key: 'okx',
    name: 'OKX',
    assetPath: 'assets/icons/asset_okx.png',
    supportedTypes: [WalletKeeperAssetType.crypto],
    aliases: ['OKX', '오케이엑스', 'com.okinc.okex.gp'],
  ),
  WalletKeeperAssetBrand(
    key: 'cryptocom',
    name: 'Crypto.com',
    assetPath: 'assets/icons/asset_cryptocom.png',
    supportedTypes: [WalletKeeperAssetType.crypto],
    aliases: ['Crypto.com', '크립토닷컴', 'co.mona.android'],
  ),
  WalletKeeperAssetBrand(
    key: 'kraken',
    name: '크라켄',
    assetPath: 'assets/icons/asset_kraken.png',
    supportedTypes: [WalletKeeperAssetType.crypto],
    aliases: ['크라켄', 'KRAKEN', 'com.kraken.invest.app'],
  ),
  WalletKeeperAssetBrand(
    key: 'kucoin',
    name: '쿠코인',
    assetPath: 'assets/icons/asset_kucoin.png',
    supportedTypes: [WalletKeeperAssetType.crypto],
    aliases: ['쿠코인', 'KUCOIN', 'com.kubi.kucoin'],
  ),
  WalletKeeperAssetBrand(
    key: 'gateio',
    name: 'Gate.io',
    assetPath: 'assets/icons/asset_gateio.png',
    supportedTypes: [WalletKeeperAssetType.crypto],
    aliases: ['Gate.io', '게이트아이오', 'GATEIO', 'com.gateio.gateio'],
  ),
  WalletKeeperAssetBrand(
    key: 'bitget',
    name: '비트겟',
    assetPath: 'assets/icons/asset_bitget.png',
    supportedTypes: [WalletKeeperAssetType.crypto],
    aliases: ['비트겟', 'BITGET', 'com.bitget.exchange'],
  ),
  WalletKeeperAssetBrand(
    key: 'mexc',
    name: 'MEXC',
    assetPath: 'assets/icons/asset_mexc.png',
    supportedTypes: [WalletKeeperAssetType.crypto],
    aliases: ['MEXC', '멕시', 'com.mexcpro.client'],
  ),
  WalletKeeperAssetBrand(
    key: 'htx',
    name: 'HTX',
    assetPath: 'assets/icons/asset_htx.png',
    supportedTypes: [WalletKeeperAssetType.crypto],
    aliases: ['HTX', '후오비', 'HUOBI', 'pro.huobi'],
  ),
  WalletKeeperAssetBrand(
    key: 'gemini_exchange',
    name: 'Gemini',
    assetPath: 'assets/icons/asset_gemini_exchange.png',
    supportedTypes: [WalletKeeperAssetType.crypto],
    aliases: ['Gemini Exchange', '제미니 거래소', 'com.gemini.android.app'],
  ),
  WalletKeeperAssetBrand(
    key: 'bitmart',
    name: 'BitMart',
    assetPath: 'assets/icons/asset_bitmart.png',
    supportedTypes: [WalletKeeperAssetType.crypto],
    aliases: ['BitMart', '비트마트', 'com.bitmart.bitmarket'],
  ),
  WalletKeeperAssetBrand(
    key: 'bingx',
    name: 'BingX',
    assetPath: 'assets/icons/asset_bingx.png',
    supportedTypes: [WalletKeeperAssetType.crypto],
    aliases: ['BingX', '빙엑스', 'pro.bingbon.app'],
  ),
  WalletKeeperAssetBrand(
    key: 'phemex',
    name: 'Phemex',
    assetPath: 'assets/icons/asset_phemex.png',
    supportedTypes: [WalletKeeperAssetType.crypto],
    aliases: ['Phemex', '페멕스', 'com.phemex.app'],
  ),
  WalletKeeperAssetBrand(
    key: 'lbank',
    name: 'LBank',
    assetPath: 'assets/icons/asset_lbank.png',
    supportedTypes: [WalletKeeperAssetType.crypto],
    aliases: ['LBank', '엘뱅크', 'com.superchain.lbankgoogle'],
  ),
  WalletKeeperAssetBrand(
    key: 'coinex',
    name: 'CoinEx',
    assetPath: 'assets/icons/asset_coinex.png',
    supportedTypes: [WalletKeeperAssetType.crypto],
    aliases: ['CoinEx', '코인엑스', 'com.coinex.trade.play'],
  ),
  WalletKeeperAssetBrand(
    key: 'bitfinex',
    name: 'Bitfinex',
    assetPath: 'assets/icons/asset_bitfinex.png',
    supportedTypes: [WalletKeeperAssetType.crypto],
    aliases: ['Bitfinex', '비트파이넥스', 'com.bitfinex.mobileapp'],
  ),
  WalletKeeperAssetBrand(
    key: 'sbi_savings',
    name: 'SBI저축은행',
    assetPath: 'assets/icons/asset_sbi_savings.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['SBI저축은행', '사이다뱅크', 'com.sbi.saidabank'],
  ),
  WalletKeeperAssetBrand(
    key: 'ok_savings',
    name: 'OK저축은행',
    assetPath: 'assets/icons/asset_ok_savings.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['OK저축은행', '오케이저축은행', 'com.cabsoft.oksavingbank'],
  ),
  WalletKeeperAssetBrand(
    key: 'welcome_savings',
    name: '웰컴저축은행',
    assetPath: 'assets/icons/asset_welcome_savings.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['웰컴저축은행', '웰뱅', 'kr.co.welcomebank.omb'],
  ),
  WalletKeeperAssetBrand(
    key: 'pepper_savings',
    name: '페퍼저축은행',
    assetPath: 'assets/icons/asset_pepper_savings.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['페퍼저축은행', '페퍼루', 'kr.pepperbank.digital'],
  ),
  WalletKeeperAssetBrand(
    key: 'kb_savings',
    name: 'KB저축은행',
    assetPath: 'assets/icons/asset_kb_savings.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['KB저축은행', '키위뱅크', 'com.kbsavings.android'],
  ),
  WalletKeeperAssetBrand(
    key: 'hana_savings',
    name: '하나저축은행',
    assetPath: 'assets/icons/asset_hana_savings.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['하나저축은행', '하나원큐저축은행', 'com.hanasv.smartbanknew'],
  ),
  WalletKeeperAssetBrand(
    key: 'shinhan_savings',
    name: '신한저축은행',
    assetPath: 'assets/icons/asset_shinhan_savings.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['신한저축은행', '신한 SOL저축은행', 'com.shinhan.spbs'],
  ),
  WalletKeeperAssetBrand(
    key: 'woori_savings',
    name: '우리금융저축은행',
    assetPath: 'assets/icons/asset_woori_savings.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['우리금융저축은행', '우리WON저축은행', 'com.woorifsb.woorifsbapp'],
  ),
  WalletKeeperAssetBrand(
    key: 'nh_savings',
    name: 'NH저축은행',
    assetPath: 'assets/icons/asset_nh_savings.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['NH저축은행', 'NH FIC Bank', 'kr.co.nhsavingsbank.m'],
  ),
  WalletKeeperAssetBrand(
    key: 'ibk_savings',
    name: 'IBK저축은행',
    assetPath: 'assets/icons/asset_ibk_savings.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['IBK저축은행', 'IBK i-Bank', 'kr.co.ibksb.ibank'],
  ),
  WalletKeeperAssetBrand(
    key: 'bnk_savings',
    name: 'BNK저축은행',
    assetPath: 'assets/icons/asset_bnk_savings.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['BNK저축은행', 'com.bnksb.sb'],
  ),
  WalletKeeperAssetBrand(
    key: 'korea_invest_savings',
    name: '한국투자저축은행',
    assetPath: 'assets/icons/asset_korea_invest_savings.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: [
      '한국투자저축은행',
      'KEY뱅크',
      'com.koreainvestment.android.keybank',
    ],
  ),
  WalletKeeperAssetBrand(
    key: 'acuon_savings',
    name: '애큐온저축은행',
    assetPath: 'assets/icons/asset_acuon_savings.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['애큐온저축은행', '애큐온스마트뱅킹', 'com.acuonsavingsbank.acuonsb'],
  ),
  WalletKeeperAssetBrand(
    key: 'daol_savings',
    name: '다올저축은행',
    assetPath: 'assets/icons/asset_daol_savings.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['다올저축은행', '다올디지털뱅크 Fi', 'com.eugene.eugenebank'],
  ),
  WalletKeeperAssetBrand(
    key: 'moa_savings',
    name: '모아저축은행',
    assetPath: 'assets/icons/asset_moa_savings.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['모아저축은행', '모아디지털뱅크', 'kr.co.moasb.moaapp'],
  ),
  WalletKeeperAssetBrand(
    key: 'sangsangin_savings',
    name: '상상인저축은행',
    assetPath: 'assets/icons/asset_sangsangin_savings.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['상상인저축은행', '뱅뱅뱅', 'com.ssi.sdfp'],
  ),
  WalletKeeperAssetBrand(
    key: 'jtchinae_savings',
    name: 'JT친애저축은행',
    assetPath: 'assets/icons/asset_jtchinae_savings.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['JT친애저축은행', 'JT친애 모바일뱅킹', 'kr.co.jtchinaebank.app.ft'],
  ),
  WalletKeeperAssetBrand(
    key: 'osb_savings',
    name: 'OSB저축은행',
    assetPath: 'assets/icons/asset_osb_savings.png',
    supportedTypes: [
      WalletKeeperAssetType.account,
      WalletKeeperAssetType.loan,
    ],
    aliases: ['OSB저축은행', 'OSB스마트뱅킹', 'co.osb.banking'],
  ),
  WalletKeeperAssetBrand(
    key: 'hyundai_capital',
    name: '현대캐피탈',
    assetPath: 'assets/icons/asset_hyundai_capital.png',
    supportedTypes: [WalletKeeperAssetType.loan],
    aliases: ['현대캐피탈', 'hyundaicapital', 'com.hyundai.capital'],
  ),
  WalletKeeperAssetBrand(
    key: 'kb_capital',
    name: 'KB캐피탈',
    assetPath: 'assets/icons/asset_kb_capital.png',
    supportedTypes: [WalletKeeperAssetType.loan],
    aliases: ['KB캐피탈', 'KB차차차', 'kr.co.kbc.cha.android'],
  ),
  WalletKeeperAssetBrand(
    key: 'hana_capital',
    name: '하나캐피탈',
    assetPath: 'assets/icons/asset_hana_capital.png',
    supportedTypes: [WalletKeeperAssetType.loan],
    aliases: ['하나캐피탈', '원큐캐피탈', 'com.hanacapital.unc.phone'],
  ),
  WalletKeeperAssetBrand(
    key: 'woori_capital',
    name: '우리금융캐피탈',
    assetPath: 'assets/icons/asset_woori_capital.png',
    supportedTypes: [WalletKeeperAssetType.loan],
    aliases: ['우리금융캐피탈', '우리WON캐피탈', 'com.woorifcapital.m.cus'],
  ),
  WalletKeeperAssetBrand(
    key: 'lotte_capital',
    name: '롯데캐피탈',
    assetPath: 'assets/icons/asset_lotte_capital.png',
    supportedTypes: [WalletKeeperAssetType.loan],
    aliases: ['롯데캐피탈', '롯데캐피탈 모바일뱅킹', 'com.lottecap.finance'],
  ),
  WalletKeeperAssetBrand(
    key: 'nh_capital',
    name: 'NH농협캐피탈',
    assetPath: 'assets/icons/asset_nh_capital.png',
    supportedTypes: [WalletKeeperAssetType.loan],
    aliases: ['NH농협캐피탈', '농협캐피탈', 'kr.co.nhcapital'],
  ),
  WalletKeeperAssetBrand(
    key: 'bnk_capital',
    name: 'BNK캐피탈',
    assetPath: 'assets/icons/asset_bnk_capital.png',
    supportedTypes: [WalletKeeperAssetType.loan],
    aliases: ['BNK캐피탈', 'com.bnkfg.bnkcapital'],
  ),
  WalletKeeperAssetBrand(
    key: 'jb_capital',
    name: 'JB우리캐피탈',
    assetPath: 'assets/icons/asset_jb_capital.png',
    supportedTypes: [WalletKeeperAssetType.loan],
    aliases: ['JB우리캐피탈', 'JB캐피탈', 'com.wooricap.jbmobilesupport'],
  ),
  WalletKeeperAssetBrand(
    key: 'korea_capital',
    name: '한국캐피탈',
    assetPath: 'assets/icons/asset_korea_capital.png',
    supportedTypes: [WalletKeeperAssetType.loan],
    aliases: ['한국캐피탈', 'kr.co.hankookcapital.m'],
  ),
  WalletKeeperAssetBrand(
    key: 'mg_capital',
    name: 'MG캐피탈',
    assetPath: 'assets/icons/asset_mg_capital.png',
    supportedTypes: [WalletKeeperAssetType.loan],
    aliases: ['MG캐피탈', 'M캐피탈', 'kr.co.mcapital.mapp'],
  ),
  WalletKeeperAssetBrand(
    key: 'acuon_capital',
    name: '애큐온캐피탈',
    assetPath: 'assets/icons/asset_acuon_capital.png',
    supportedTypes: [WalletKeeperAssetType.loan],
    aliases: ['애큐온캐피탈', '스마트애큐온', 'mobile.acuon.co.smartacuon'],
  ),
  WalletKeeperAssetBrand(
    key: 'ibk_capital',
    name: 'IBK캐피탈',
    assetPath: 'assets/icons/asset_ibk_capital.png',
    supportedTypes: [WalletKeeperAssetType.loan],
    aliases: ['IBK캐피탈', 'com.ibkc.mobile'],
  ),
  WalletKeeperAssetBrand(
    key: 'cash',
    name: '직접 관리',
    assetPath: '',
    supportedTypes: [WalletKeeperAssetType.cash],
    aliases: ['현금', '지갑', '비상금'],
  ),
];

class WalletKeeperAsset {
  const WalletKeeperAsset({
    required this.id,
    required this.name,
    required this.institution,
    required this.type,
    required this.openingBalance,
    required this.lastFour,
    required this.memo,
    required this.brandKey,
    required this.iconBase64,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String institution;
  final WalletKeeperAssetType type;
  final double openingBalance;
  final String lastFour;
  final String memo;
  final String brandKey;
  final String iconBase64;
  final DateTime createdAt;

  WalletKeeperAsset copyWith({
    String? id,
    String? name,
    String? institution,
    WalletKeeperAssetType? type,
    double? openingBalance,
    String? lastFour,
    String? memo,
    String? brandKey,
    String? iconBase64,
    DateTime? createdAt,
  }) {
    return WalletKeeperAsset(
      id: id ?? this.id,
      name: name ?? this.name,
      institution: institution ?? this.institution,
      type: type ?? this.type,
      openingBalance: openingBalance ?? this.openingBalance,
      lastFour: lastFour ?? this.lastFour,
      memo: memo ?? this.memo,
      brandKey: brandKey ?? this.brandKey,
      iconBase64: iconBase64 ?? this.iconBase64,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'institution': institution,
    'type': type.name,
    'openingBalance': openingBalance,
    'lastFour': lastFour,
    'memo': memo,
    'brandKey': brandKey,
    'iconBase64': iconBase64,
    'createdAt': createdAt.toIso8601String(),
  };

  factory WalletKeeperAsset.fromJson(Map<String, dynamic> json) {
    final typeName = json['type']?.toString() ?? '';
    final type = WalletKeeperAssetType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => WalletKeeperAssetType.account,
    );
    final brandKey = _migrateWalletKeeperAssetBrandKey(
      type,
      json['brandKey']?.toString() ?? '',
    );
    return WalletKeeperAsset(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      institution: json['institution']?.toString() ?? '',
      type: type,
      openingBalance: (json['openingBalance'] as num?)?.toDouble() ?? 0,
      lastFour: json['lastFour']?.toString() ?? '',
      memo: json['memo']?.toString() ?? '',
      brandKey: brandKey,
      iconBase64: json['iconBase64']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

String _migrateWalletKeeperAssetBrandKey(
  WalletKeeperAssetType type,
  String brandKey,
) {
  if (type != WalletKeeperAssetType.card) return brandKey;
  return switch (brandKey) {
    'shinhan' => 'shinhan_card',
    'woori' => 'woori_card',
    'hana' => 'hana_card',
    'nh' => 'nh_card',
    _ => brandKey,
  };
}

class WalletKeeperAssetRepository {
  Future<List<WalletKeeperAsset>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_assetStorageKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = (jsonDecode(raw) as List)
        .cast<Map<String, dynamic>>()
        .map(WalletKeeperAsset.fromJson)
        .where((asset) => asset.id.isNotEmpty)
        .toList();
    decoded.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return decoded;
  }

  Future<void> save(List<WalletKeeperAsset> assets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _assetStorageKey,
      jsonEncode(assets.map((asset) => asset.toJson()).toList()),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_assetStorageKey);
  }
}

class WalletKeeperAssetSuggestion {
  const WalletKeeperAssetSuggestion({
    required this.name,
    required this.institution,
    required this.type,
    required this.brandKey,
    required this.iconBase64,
  });

  final String name;
  final String institution;
  final WalletKeeperAssetType type;
  final String brandKey;
  final String iconBase64;
}

String _normalizeAssetMatchText(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^0-9a-z가-힣]'), '');

WalletKeeperAssetBrand? walletKeeperAssetBrandByKey(String key) {
  for (final brand in walletKeeperAssetBrands) {
    if (brand.key == key) return brand;
  }
  return null;
}

bool walletKeeperIsGeneratedAssetName({
  required String name,
  required String institution,
  required WalletKeeperAssetType type,
  WalletKeeperAssetBrand? brand,
}) {
  final trimmedName = name.trim();
  final trimmedInstitution = institution.trim();
  return trimmedName.isEmpty ||
      trimmedName == trimmedInstitution ||
      (brand != null && trimmedName == '${brand.name} ${type.label}');
}

WalletKeeperAssetBrand? walletKeeperAssetBrandFromText(String value) {
  final normalized = _normalizeAssetMatchText(value);
  if (normalized.isEmpty) return null;
  WalletKeeperAssetBrand? bestMatch;
  var bestScore = -1;
  for (final brand in walletKeeperAssetBrands) {
    for (final alias in brand.aliases) {
      final normalizedAlias = _normalizeAssetMatchText(alias);
      if (normalizedAlias.isNotEmpty && normalized.contains(normalizedAlias)) {
        final isPackageName = alias.contains('.');
        final score = normalizedAlias.length + (isPackageName ? 0 : 1000);
        if (score > bestScore) {
          bestMatch = brand;
          bestScore = score;
        }
      }
    }
  }
  return bestMatch;
}

WalletKeeperAssetType _assetTypeFromDraft(
  WalletKeeperSmsDraft draft, {
  WalletKeeperAssetBrand? brand,
}) {
  final text = '${draft.institution} ${draft.title} ${draft.rawBody}'
      .toLowerCase();
  if (text.contains('대출') || text.contains('상환')) {
    return WalletKeeperAssetType.loan;
  }
  if (text.contains('증권') ||
      text.contains('주식') ||
      text.contains('매수') ||
      text.contains('매도')) {
    return WalletKeeperAssetType.securities;
  }
  if (text.contains('코인') ||
      text.contains('비트코인') ||
      text.contains('업비트') ||
      text.contains('빗썸')) {
    return WalletKeeperAssetType.crypto;
  }
  if (text.contains('카드') || text.contains('일시불')) {
    return WalletKeeperAssetType.card;
  }
  return brand?.defaultType ?? WalletKeeperAssetType.account;
}

WalletKeeperAssetSuggestion? inferWalletKeeperAssetSuggestion(
  WalletKeeperSmsDraft? draft,
) {
  if (draft == null) return null;
  final source =
      '${draft.institution} ${draft.sourceAddress} ${draft.title} ${draft.rawBody}';
  final brand = walletKeeperAssetBrandFromText(source);
  final rawInstitution = draft.institution.trim();
  final packageLooksLikeName =
      rawInstitution.contains('.') && !rawInstitution.contains(' ');
  final institution = brand?.name ?? (packageLooksLikeName ? '' : rawInstitution);
  if (institution.isEmpty && brand == null) return null;
  final type = _assetTypeFromDraft(draft, brand: brand);
  return WalletKeeperAssetSuggestion(
    name: institution.isEmpty ? type.label : '$institution ${type.label}',
    institution: institution,
    type: type,
    brandKey: brand?.key ?? '',
    iconBase64: draft.sourceAppIconBase64,
  );
}

WalletKeeperAssetSuggestion? inferWalletKeeperAssetSuggestionFromEntry(
  LedgerEntry entry,
) {
  final source = '${entry.title} ${entry.category} ${entry.note}';
  final brand = walletKeeperAssetBrandFromText(source);
  if (brand == null) return null;
  return WalletKeeperAssetSuggestion(
    name: '${brand.name} ${brand.defaultType.label}',
    institution: brand.name,
    type: brand.defaultType,
    brandKey: brand.key,
    iconBase64: '',
  );
}

List<LedgerEntry> walletKeeperUnlinkedAssetEntries(
  List<LedgerEntry> entries,
  List<WalletKeeperAsset> assets,
) {
  final validAssetIds = assets.map((asset) => asset.id).toSet();
  final result =
      entries.where((entry) {
        if (entry.type == EntryType.transfer) return false;
        final assetId = entry.assetId?.trim() ?? '';
        return assetId.isEmpty || !validAssetIds.contains(assetId);
      }).toList()..sort((a, b) {
        final dateOrder = b.date.compareTo(a.date);
        return dateOrder != 0 ? dateOrder : b.createdAt.compareTo(a.createdAt);
      });
  return result;
}

WalletKeeperAsset? detectWalletKeeperAsset(
  WalletKeeperSmsDraft? draft,
  List<WalletKeeperAsset> assets,
) {
  if (draft == null || assets.isEmpty) return null;
  final source =
      '${draft.institution} ${draft.sourceAddress} ${draft.title} ${draft.rawBody}';
  final normalizedSource = _normalizeAssetMatchText(source);
  final suggestedBrand = walletKeeperAssetBrandFromText(source);
  WalletKeeperAsset? best;
  var bestScore = 0;
  for (final asset in assets) {
    var score = 0;
    final brand = walletKeeperAssetBrandByKey(asset.brandKey);
    if (suggestedBrand != null && suggestedBrand.key == asset.brandKey) {
      score += 80;
    }
    final institution = _normalizeAssetMatchText(asset.institution);
    if (institution.isNotEmpty && normalizedSource.contains(institution)) {
      score += 55;
    }
    final name = _normalizeAssetMatchText(asset.name);
    if (name.isNotEmpty && normalizedSource.contains(name)) {
      score += 40;
    }
    if (brand != null &&
        brand.aliases.any(
          (alias) => normalizedSource.contains(_normalizeAssetMatchText(alias)),
        )) {
      score += 45;
    }
    final lastFour = asset.lastFour.replaceAll(RegExp(r'\D'), '');
    if (lastFour.length == 4 && normalizedSource.contains(lastFour)) {
      score += 100;
    }
    final inferredType = _assetTypeFromDraft(draft, brand: suggestedBrand);
    if (asset.type == inferredType) score += 10;
    if (score > bestScore) {
      best = asset;
      bestScore = score;
    }
  }
  return bestScore >= 45 ? best : null;
}

double walletKeeperAssetCurrentBalance(
  WalletKeeperAsset asset,
  List<LedgerEntry> entries, {
  DateTime? asOf,
}) {
  return asset.openingBalance +
      walletKeeperAssetLinkedBalanceDelta(
        assetId: asset.id,
        type: asset.type,
        entries: entries,
        asOf: asOf,
      );
}

double walletKeeperAssetLinkedBalanceDelta({
  required String assetId,
  required WalletKeeperAssetType type,
  required List<LedgerEntry> entries,
  DateTime? asOf,
}) {
  var delta = 0.0;
  final now = asOf ?? DateTime.now();
  for (final entry in entries.where((entry) => entry.assetId == assetId)) {
    if (entry.isFixedEntry) {
      final occurrence = walletKeeperMaterializeFixedEntryForMonth(entry, now);
      if (occurrence.date.isAfter(now)) continue;
    }
    final amount = entry.amount.abs();
    if (type.isLiability) {
      delta += entry.type == EntryType.expense ? amount : -amount;
    } else {
      delta += entry.type == EntryType.income ? amount : -amount;
    }
  }
  return delta;
}

class WalletKeeperAssetIcon extends StatelessWidget {
  const WalletKeeperAssetIcon({
    super.key,
    required this.type,
    this.brandKey = '',
    this.iconBase64 = '',
    this.size = 42,
  });

  final WalletKeeperAssetType type;
  final String brandKey;
  final String iconBase64;
  final double size;

  @override
  Widget build(BuildContext context) {
    final brand = walletKeeperAssetBrandByKey(brandKey);
    Widget content;
    if (brand != null && brand.assetPath.isNotEmpty) {
      content = Image.asset(
        brand.assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackIcon(),
      );
    } else if (iconBase64.trim().isNotEmpty) {
      try {
        content = Image.memory(
          base64Decode(iconBase64),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallbackIcon(),
        );
      } catch (_) {
        content = _fallbackIcon();
      }
    } else {
      content = _fallbackIcon();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.3),
      child: SizedBox(width: size, height: size, child: content),
    );
  }

  Widget _fallbackIcon() {
    return ColoredBox(
      color: type.color.withValues(alpha: 0.12),
      child: Icon(type.icon, size: size * 0.48, color: type.color),
    );
  }
}

class WalletKeeperAssetEditorResult {
  const WalletKeeperAssetEditorResult.save(this.asset) : deletedAssetId = null;
  const WalletKeeperAssetEditorResult.delete(this.deletedAssetId) : asset = null;

  final WalletKeeperAsset? asset;
  final String? deletedAssetId;
}

Future<WalletKeeperAssetEditorResult?> showWalletKeeperAssetEditorSheet(
  BuildContext context, {
  WalletKeeperAsset? existing,
  WalletKeeperAssetSuggestion? suggestion,
  List<LedgerEntry> entries = const [],
}) {
  return showModalBottomSheet<WalletKeeperAssetEditorResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final keyboardInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      final screenHeight = MediaQuery.sizeOf(sheetContext).height;
      return AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.94),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Material(
              color: const Color(0xFFF7F8FA),
              child: _WalletKeeperAssetEditor(
                existing: existing,
                suggestion: suggestion,
                entries: entries,
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _WalletKeeperAssetEditor extends StatefulWidget {
  const _WalletKeeperAssetEditor({
    this.existing,
    this.suggestion,
    required this.entries,
  });

  final WalletKeeperAsset? existing;
  final WalletKeeperAssetSuggestion? suggestion;
  final List<LedgerEntry> entries;

  @override
  State<_WalletKeeperAssetEditor> createState() =>
      _WalletKeeperAssetEditorState();
}

class _WalletKeeperAssetEditorState extends State<_WalletKeeperAssetEditor> {
  late final TextEditingController _nameController;
  late final TextEditingController _institutionController;
  late final TextEditingController _balanceController;
  late final TextEditingController _lastFourController;
  late final TextEditingController _memoController;
  late final FocusNode _institutionFocusNode;
  late WalletKeeperAssetType _type;
  String _brandKey = '';
  String _iconBase64 = '';
  bool _customBrandSelected = false;

  @override
  void initState() {
    super.initState();
    final source = widget.existing;
    final suggestion = widget.suggestion;
    _nameController = TextEditingController(
      text: source?.name ?? suggestion?.name ?? '',
    );
    _institutionController = TextEditingController(
      text: source?.institution ?? suggestion?.institution ?? '',
    );
    final currentBalance = source == null
        ? 0.0
        : walletKeeperAssetCurrentBalance(source, widget.entries);
    _balanceController = TextEditingController(
      text: currentBalance == 0
          ? ''
          : NumberFormat.decimalPattern('ko_KR').format(currentBalance),
    );
    _lastFourController = TextEditingController(text: source?.lastFour ?? '');
    _memoController = TextEditingController(text: source?.memo ?? '');
    _institutionFocusNode = FocusNode();
    _type =
        source?.type ?? suggestion?.type ?? WalletKeeperAssetType.account;
    _brandKey = source?.brandKey ?? suggestion?.brandKey ?? '';
    _iconBase64 = source?.iconBase64 ?? suggestion?.iconBase64 ?? '';
    _customBrandSelected =
        _brandKey.isEmpty && _institutionController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _institutionController.dispose();
    _balanceController.dispose();
    _lastFourController.dispose();
    _memoController.dispose();
    _institutionFocusNode.dispose();
    super.dispose();
  }

  void _selectBrand(WalletKeeperAssetBrand brand) {
    final previousBrand = walletKeeperAssetBrandByKey(_brandKey);
    final previousInstitution = _institutionController.text.trim();
    final previousName = _nameController.text.trim();
    final shouldReplaceName = walletKeeperIsGeneratedAssetName(
      name: previousName,
      institution: previousInstitution,
      type: _type,
      brand: previousBrand,
    );
    setState(() {
      _brandKey = brand.key;
      _iconBase64 = '';
      _customBrandSelected = false;
      _institutionController.text = brand.name;
      if (shouldReplaceName) {
        _nameController.text = '${brand.name} ${_type.label}';
      }
    });
  }

  void _selectCustomBrand() {
    final selectedBrand = walletKeeperAssetBrandByKey(_brandKey);
    final previousInstitution = _institutionController.text.trim();
    final previousName = _nameController.text.trim();
    setState(() {
      if (selectedBrand != null &&
          previousInstitution == selectedBrand.name) {
        _institutionController.clear();
      }
      if (selectedBrand != null &&
          previousName == '${selectedBrand.name} ${_type.label}') {
        _nameController.clear();
      }
      _brandKey = '';
      _iconBase64 = '';
      _customBrandSelected = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _institutionFocusNode.requestFocus();
    });
  }

  List<WalletKeeperAssetBrand> get _availableBrands => walletKeeperAssetBrands
      .where((brand) => brand.supports(_type))
      .toList(growable: false);

  void _selectType(WalletKeeperAssetType type) {
    if (_type == type) return;
    final previousType = _type;
    final selectedBrand = walletKeeperAssetBrandByKey(_brandKey);
    final wasCustomBrandSelected = _customBrandSelected;
    final previousInstitution = _institutionController.text.trim();
    final previousName = _nameController.text.trim();
    final shouldReplaceName = walletKeeperIsGeneratedAssetName(
      name: previousName,
      institution: previousInstitution,
      type: previousType,
      brand: selectedBrand,
    );
    setState(() {
      _type = type;
      if (selectedBrand == null || !selectedBrand.supports(type)) {
        if (previousInstitution == selectedBrand?.name) {
          _institutionController.clear();
        }
        if (shouldReplaceName) {
          _nameController.clear();
        }
        _brandKey = '';
        _iconBase64 = '';
        _customBrandSelected =
            selectedBrand == null && wasCustomBrandSelected;
        return;
      }
      if (shouldReplaceName) {
        _nameController.text = '${selectedBrand.name} ${type.label}';
      }
    });
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('자산 삭제'),
        content: const Text('연결된 거래 기록은 유지되고 자산 연결만 해제됩니다. 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF695D),
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    Navigator.of(
      context,
    ).pop(WalletKeeperAssetEditorResult.delete(existing.id));
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showAppToast('자산 이름을 입력해주세요.');
      return;
    }
    final amount =
        double.tryParse(_balanceController.text.replaceAll(',', '').trim()) ??
        0;
    final assetId =
        widget.existing?.id ??
        'asset_${DateTime.now().microsecondsSinceEpoch}';
    final openingBalance = widget.existing == null
        ? amount
        : amount -
              walletKeeperAssetLinkedBalanceDelta(
                assetId: assetId,
                type: _type,
                entries: widget.entries,
              );
    final asset = WalletKeeperAsset(
      id: assetId,
      name: name,
      institution: _institutionController.text.trim(),
      type: _type,
      openingBalance: openingBalance,
      lastFour: _lastFourController.text
          .replaceAll(RegExp(r'\D'), '')
          .trim(),
      memo: _memoController.text.trim(),
      brandKey: _brandKey,
      iconBase64: _iconBase64,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    Navigator.of(context).pop(WalletKeeperAssetEditorResult.save(asset));
  }

  @override
  Widget build(BuildContext context) {
    final availableBrands = _availableBrands;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 14, 12),
          child: Row(
            children: [
              Text(
                widget.existing == null ? '자산 추가' : '자산 수정',
                style: const TextStyle(
                  color: Color(0xFF15181D),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Flexible(
          fit: FlexFit.loose,
          child: ListView(
            shrinkWrap: true,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
            children: [
              const _AssetEditorSectionTitle(
                title: '자산 종류',
                subtitle: '종류를 먼저 선택해주세요',
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: WalletKeeperAssetType.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final type = WalletKeeperAssetType.values[index];
                    final selected = _type == type;
                    return ChoiceChip(
                      selected: selected,
                      showCheckmark: false,
                      onSelected: (_) => _selectType(type),
                      avatar: Icon(
                        type.icon,
                        size: 17,
                        color: selected ? Colors.white : type.color,
                      ),
                      label: Text(type.label),
                      labelStyle: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color(0xFF4C5562),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                      selectedColor: type.color,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: selected
                            ? type.color
                            : const Color(0xFFE2E7ED),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              _AssetEditorSectionTitle(
                title: _type.providerLabel,
                subtitle: _type == WalletKeeperAssetType.cash
                    ? '현금은 직접 잔액을 관리해요'
                    : '${_type.label}에 해당하는 ${_type.providerLabel}만 표시됩니다',
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  key: ValueKey(_type),
                  scrollDirection: Axis.horizontal,
                  itemCount: availableBrands.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == availableBrands.length) {
                      return GestureDetector(
                        onTap: _selectCustomBrand,
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          constraints: const BoxConstraints(minWidth: 68),
                          padding: const EdgeInsets.fromLTRB(8, 7, 8, 5),
                          decoration: BoxDecoration(
                            color: _customBrandSelected
                                ? const Color(0xFFFFE9E7)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.edit_note_rounded,
                                size: 39,
                                color: _customBrandSelected
                                    ? const Color(0xFFE76158)
                                    : const Color(0xFF7C8591),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '직접 설정',
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(
                                  color: _customBrandSelected
                                      ? const Color(0xFFE76158)
                                      : const Color(0xFF59616D),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final brand = availableBrands[index];
                    final selected = _brandKey == brand.key;
                    return GestureDetector(
                      onTap: () => _selectBrand(brand),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        constraints: const BoxConstraints(minWidth: 68),
                        padding: const EdgeInsets.fromLTRB(8, 7, 8, 5),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFFFE9E7)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            AnimatedScale(
                              scale: selected ? 1.06 : 1,
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              child: WalletKeeperAssetIcon(
                                type: _type,
                                brandKey: brand.key,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              brand.name,
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                color: selected
                                    ? const Color(0xFFE76158)
                                    : const Color(0xFF59616D),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              _AssetEditorFields(
                nameController: _nameController,
                institutionController: _institutionController,
                institutionFocusNode: _institutionFocusNode,
                balanceController: _balanceController,
                lastFourController: _lastFourController,
                memoController: _memoController,
                type: _type,
              ),
              if (widget.existing != null) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 19),
                  label: const Text('자산 삭제'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFE35249),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE76158),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '저장하기',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AssetEditorSectionTitle extends StatelessWidget {
  const _AssetEditorSectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1D2229),
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF9AA2AD),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _AssetEditorFields extends StatelessWidget {
  const _AssetEditorFields({
    required this.nameController,
    required this.institutionController,
    required this.institutionFocusNode,
    required this.balanceController,
    required this.lastFourController,
    required this.memoController,
    required this.type,
  });

  final TextEditingController nameController;
  final TextEditingController institutionController;
  final FocusNode institutionFocusNode;
  final TextEditingController balanceController;
  final TextEditingController lastFourController;
  final TextEditingController memoController;
  final WalletKeeperAssetType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _AssetEditorTextField(
            label: '자산 이름',
            hint: '예: 월급 통장',
            controller: nameController,
          ),
          const Divider(height: 1, color: Color(0xFFEEF1F5)),
          _AssetEditorTextField(
            label: type.providerLabel,
            hint: type == WalletKeeperAssetType.cash
                ? '예: 지갑, 비상금'
                : '직접 입력 가능',
            controller: institutionController,
            focusNode: institutionFocusNode,
          ),
          const Divider(height: 1, color: Color(0xFFEEF1F5)),
          _AssetEditorTextField(
            label: type.isLiability ? '현재 사용액' : '현재 잔액',
            hint: '0',
            controller: balanceController,
            keyboardType: TextInputType.number,
            inputFormatters: const [_ThousandsSeparatorInputFormatter()],
            suffix: '원',
          ),
          const Divider(height: 1, color: Color(0xFFEEF1F5)),
          _AssetEditorTextField(
            label: '끝 4자리',
            hint: '선택 입력',
            controller: lastFourController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 4,
          ),
          const Divider(height: 1, color: Color(0xFFEEF1F5)),
          _AssetEditorTextField(
            label: '메모',
            hint: '선택 입력',
            controller: memoController,
          ),
        ],
      ),
    );
  }
}

class _AssetEditorTextField extends StatelessWidget {
  const _AssetEditorTextField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.suffix,
    this.maxLength,
    this.focusNode,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? suffix;
  final int? maxLength;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF616A76),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              maxLength: maxLength,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF1D2229),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                counterText: '',
                suffixText: suffix,
                suffixStyle: const TextStyle(
                  color: Color(0xFF747D89),
                  fontWeight: FontWeight.w700,
                ),
                hintStyle: const TextStyle(
                  color: Color(0xFFB3BAC3),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const String _assetSelectorNone = '__asset_none__';
const String _assetSelectorCreate = '__asset_create__';

Future<String?> showWalletKeeperAssetSelectorSheet(
  BuildContext context, {
  required List<WalletKeeperAsset> assets,
  required List<LedgerEntry> entries,
  String? selectedAssetId,
  WalletKeeperAssetSuggestion? suggestion,
}) {
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '연결할 자산',
                style: TextStyle(
                  color: Color(0xFF171A1F),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                '이 기록이 저장되면 선택한 자산 금액도 함께 반영됩니다.',
                style: TextStyle(
                  color: Color(0xFF8B94A0),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _AssetSelectorTile(
                      icon: const _NoAssetIcon(),
                      title: '연결 안 함',
                      subtitle: '거래 기록만 저장',
                      selected: selectedAssetId == null,
                      onTap: () =>
                          Navigator.of(context).pop(_assetSelectorNone),
                    ),
                    ...assets.map(
                      (asset) => _AssetSelectorTile(
                        icon: WalletKeeperAssetIcon(
                          type: asset.type,
                          brandKey: asset.brandKey,
                          iconBase64: asset.iconBase64,
                          size: 40,
                        ),
                        title: asset.name,
                        subtitle:
                            '${asset.type.label} · ${formatCurrency(walletKeeperAssetCurrentBalance(asset, entries))}',
                        selected: selectedAssetId == asset.id,
                        onTap: () => Navigator.of(context).pop(asset.id),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(_assetSelectorCreate),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    suggestion == null
                        ? '새 자산 추가'
                        : '${suggestion.institution} 자산 추가',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE35249),
                    side: const BorderSide(color: Color(0xFFFFB7B0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AssetSelectorTile extends StatelessWidget {
  const _AssetSelectorTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final Widget icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF24282E),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9AA2AD),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 22,
              color: selected
                  ? const Color(0xFFFF695D)
                  : const Color(0xFFD5DAE1),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoAssetIcon extends StatelessWidget {
  const _NoAssetIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.link_off_rounded,
        size: 20,
        color: Color(0xFF8A939F),
      ),
    );
  }
}

class WalletKeeperAssetConnectionResult {
  const WalletKeeperAssetConnectionResult({
    required this.entry,
    required this.asset,
  });

  final LedgerEntry entry;
  final WalletKeeperAsset? asset;
}

Future<void> showWalletKeeperUnlinkedAssetEntriesSheet(
  BuildContext context, {
  required List<LedgerEntry> entries,
  required List<WalletKeeperAsset> assets,
  required Future<WalletKeeperAssetConnectionResult?> Function(
    LedgerEntry entry,
  )
  onSelectAsset,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.86,
      child: Material(
        color: const Color(0xFFF7F8FA),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: _UnlinkedAssetEntriesSheet(
          initialEntries: entries,
          initialAssets: assets,
          onSelectAsset: onSelectAsset,
        ),
      ),
    ),
  );
}

class _UnlinkedAssetEntriesSheet extends StatefulWidget {
  const _UnlinkedAssetEntriesSheet({
    required this.initialEntries,
    required this.initialAssets,
    required this.onSelectAsset,
  });

  final List<LedgerEntry> initialEntries;
  final List<WalletKeeperAsset> initialAssets;
  final Future<WalletKeeperAssetConnectionResult?> Function(LedgerEntry entry)
  onSelectAsset;

  @override
  State<_UnlinkedAssetEntriesSheet> createState() =>
      _UnlinkedAssetEntriesSheetState();
}

class _UnlinkedAssetEntriesSheetState
    extends State<_UnlinkedAssetEntriesSheet> {
  late final List<LedgerEntry> _entries = [...widget.initialEntries];
  late final Map<String, WalletKeeperAsset> _assetsById = {
    for (final asset in widget.initialAssets) asset.id: asset,
  };
  String? _busyEntryId;

  Future<void> _selectAsset(LedgerEntry entry) async {
    if (_busyEntryId != null) return;
    setState(() => _busyEntryId = entry.id);
    final result = await widget.onSelectAsset(entry);
    if (!mounted) return;
    if (result != null) {
      final index = _entries.indexWhere((item) => item.id == entry.id);
      if (index >= 0) {
        _entries[index] = result.entry;
      }
      final asset = result.asset;
      if (asset != null) {
        _assetsById[asset.id] = asset;
      }
    }
    setState(() => _busyEntryId = null);
  }

  @override
  Widget build(BuildContext context) {
    final connectedCount = _entries
        .where(
          (entry) =>
              entry.assetId != null &&
              _assetsById.containsKey(entry.assetId),
        )
        .length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 12, 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '자산 연결',
                      style: TextStyle(
                        color: Color(0xFF171A1F),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '연결하면 수입과 지출이 자산 금액에 자동 반영됩니다.',
                      style: const TextStyle(
                        color: Color(0xFF858E9A),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE9E7),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '$connectedCount/${_entries.length}',
                  style: const TextStyle(
                    color: Color(0xFFE76158),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
            itemCount: _entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final entry = _entries[index];
              final asset = _assetsById[entry.assetId];
              return _UnlinkedAssetEntryCard(
                entry: entry,
                asset: asset,
                busy: _busyEntryId == entry.id,
                onTap: () => _selectAsset(entry),
              );
            },
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE8EBF0))),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE76158),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  '완료',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UnlinkedAssetEntryCard extends StatelessWidget {
  const _UnlinkedAssetEntryCard({
    required this.entry,
    required this.asset,
    required this.busy,
    required this.onTap,
  });

  final LedgerEntry entry;
  final WalletKeeperAsset? asset;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isIncome = entry.type == EntryType.income;
    final accent = isIncome
        ? const Color(0xFF4F8FF7)
        : const Color(0xFFFF695D);
    final sign = isIncome ? '+' : '-';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(19),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 13, 13),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 39,
                    height: 39,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(entry.type.icon, size: 19, color: accent),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title.trim().isEmpty ? entry.category : entry.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF20242A),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('yyyy.MM.dd').format(entry.date)} · ${entry.category}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF969FAA),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$sign${formatCurrencyValue(entry.amount)}',
                    style: TextStyle(
                      color: accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: busy
                    ? const SizedBox(
                        key: ValueKey('busy'),
                        height: 38,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Color(0xFFE76158),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        key: ValueKey(asset?.id ?? 'unlinked'),
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: asset == null
                              ? const Color(0xFFF5F6F8)
                              : const Color(0xFFFFF1EF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            if (asset == null)
                              const Icon(
                                Icons.add_link_rounded,
                                size: 18,
                                color: Color(0xFFE76158),
                              )
                            else
                              WalletKeeperAssetIcon(
                                type: asset!.type,
                                brandKey: asset!.brandKey,
                                iconBase64: asset!.iconBase64,
                                size: 25,
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                asset?.name ?? '연결할 자산 선택',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: asset == null
                                      ? const Color(0xFFE76158)
                                      : const Color(0xFF343941),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              asset == null ? '연결하기' : '변경',
                              style: const TextStyle(
                                color: Color(0xFFE76158),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 17,
                              color: Color(0xFFE76158),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WalletKeeperAssetSummaryItem {
  const WalletKeeperAssetSummaryItem({
    required this.label,
    required this.amount,
    this.type,
  });

  final String label;
  final double amount;
  final WalletKeeperAssetType? type;
}

String _walletKeeperAssetSummaryLabel(WalletKeeperAssetType type) {
  return switch (type) {
    WalletKeeperAssetType.account => '계좌 잔액',
    WalletKeeperAssetType.card => '카드 사용액',
    WalletKeeperAssetType.securities => '증권 자산',
    WalletKeeperAssetType.crypto => '코인 자산',
    WalletKeeperAssetType.loan => '대출 잔액',
    WalletKeeperAssetType.cash => '현금',
  };
}

List<WalletKeeperAssetSummaryItem> walletKeeperTopAssetSummaryItems(
  List<WalletKeeperAsset> assets,
  List<LedgerEntry> entries,
) {
  final totals = <WalletKeeperAssetType, double>{};
  var totalAssets = 0.0;
  var totalLiabilities = 0.0;
  for (final asset in assets) {
    final amount = math.max(
      0.0,
      walletKeeperAssetCurrentBalance(asset, entries),
    );
    totals.update(
      asset.type,
      (value) => value + amount,
      ifAbsent: () => amount,
    );
    if (asset.type.isLiability) {
      totalLiabilities += amount;
    } else {
      totalAssets += amount;
    }
  }
  final populated =
      totals.entries
          .where((entry) => entry.value > 0)
          .map(
            (entry) => WalletKeeperAssetSummaryItem(
              label: _walletKeeperAssetSummaryLabel(entry.key),
              amount: entry.value,
              type: entry.key,
            ),
          )
          .toList()
        ..sort((a, b) {
          final amountOrder = b.amount.compareTo(a.amount);
          if (amountOrder != 0) return amountOrder;
          return a.type!.index.compareTo(b.type!.index);
        });
  if (populated.isNotEmpty) {
    return populated.take(2).toList(growable: false);
  }
  return [
    WalletKeeperAssetSummaryItem(label: '보유 자산', amount: totalAssets),
    WalletKeeperAssetSummaryItem(
      label: '대출·카드 사용액',
      amount: totalLiabilities,
    ),
  ];
}

List<LedgerEntry> walletKeeperAssetEntries(
  String assetId,
  List<LedgerEntry> entries,
) {
  final linked =
      entries
          .where(
            (entry) =>
                entry.assetId == assetId &&
                entry.type != EntryType.transfer,
          )
          .toList()
        ..sort((a, b) {
          final dateOrder = b.date.compareTo(a.date);
          if (dateOrder != 0) return dateOrder;
          return b.createdAt.compareTo(a.createdAt);
        });
  return linked;
}

List<LedgerEntry> walletKeeperAllAssetEntries(
  List<WalletKeeperAsset> assets,
  List<LedgerEntry> entries,
) {
  final assetIds = assets.map((asset) => asset.id).toSet();
  final linked =
      entries
          .where(
            (entry) =>
                entry.assetId != null &&
                assetIds.contains(entry.assetId) &&
                entry.type != EntryType.transfer,
          )
          .toList()
        ..sort((a, b) {
          final dateOrder = b.date.compareTo(a.date);
          if (dateOrder != 0) return dateOrder;
          return b.createdAt.compareTo(a.createdAt);
        });
  return linked;
}

class WalletKeeperAssetPortfolioSection extends StatelessWidget {
  const WalletKeeperAssetPortfolioSection({
    super.key,
    required this.assets,
    required this.entries,
    required this.onAdd,
    required this.onEdit,
    required this.onOpenHistory,
    required this.onOpenAllHistory,
  });

  final List<WalletKeeperAsset> assets;
  final List<LedgerEntry> entries;
  final VoidCallback onAdd;
  final ValueChanged<WalletKeeperAsset> onEdit;
  final ValueChanged<WalletKeeperAsset> onOpenHistory;
  final VoidCallback onOpenAllHistory;

  @override
  Widget build(BuildContext context) {
    final balances = {
      for (final asset in assets)
        asset.id: walletKeeperAssetCurrentBalance(asset, entries),
    };
    final totalAssets = assets
        .where((asset) => !asset.type.isLiability)
        .fold<double>(
          0,
          (sum, asset) => sum + math.max(0, balances[asset.id] ?? 0),
        );
    final totalLiabilities = assets
        .where((asset) => asset.type.isLiability)
        .fold<double>(
          0,
          (sum, asset) => sum + math.max(0, balances[asset.id] ?? 0),
        );
    final netWorth = totalAssets - totalLiabilities;
    final summaryItems = walletKeeperTopAssetSummaryItems(assets, entries);

    return Column(
      children: [
        GestureDetector(
          onTap: onOpenAllHistory,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 17, 18, 17),
            decoration: BoxDecoration(
              color: const Color(0xFFE76158),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE76158)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0814171C),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Text(
                      '내 순자산',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        '${assets.length}개 자산',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  formatCurrency(netWorth),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: List.generate(summaryItems.length * 2 - 1, (index) {
                    if (index.isOdd) {
                      return Container(
                        width: 1,
                        height: 34,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        color: Colors.white.withValues(alpha: 0.26),
                      );
                    }
                    final item = summaryItems[index ~/ 2];
                    return Expanded(
                      child: _AssetSummaryMetric(
                        label: item.label,
                        amount: item.amount,
                        color: Colors.white,
                        onDark: true,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    '내 자산',
                    style: TextStyle(
                      color: Color(0xFF14171C),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onAdd,
                    behavior: HitTestBehavior.opaque,
                    child: const Row(
                      children: [
                        Icon(
                          Icons.add_circle_rounded,
                          color: Color(0xFFE76158),
                          size: 19,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '자산 추가',
                          style: TextStyle(
                            color: Color(0xFFE76158),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (assets.isEmpty)
                GestureDetector(
                  onTap: onAdd,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FB),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.add_card_rounded,
                          color: Color(0xFFFF8A80),
                          size: 30,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '계좌나 카드를 등록해보세요',
                          style: TextStyle(
                            color: Color(0xFF3F4650),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          '금융 문자 기록과 자동으로 연결할 수 있어요',
                          style: TextStyle(
                            color: Color(0xFF9AA2AD),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...List.generate(assets.length, (index) {
                  final asset = assets[index];
                  final recentEntries = walletKeeperAssetEntries(
                    asset.id,
                    entries,
                  ).take(3).toList(growable: false);
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => onOpenHistory(asset),
                              borderRadius: BorderRadius.circular(15),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                child: Row(
                                  children: [
                                    WalletKeeperAssetIcon(
                                      type: asset.type,
                                      brandKey: asset.brandKey,
                                      iconBase64: asset.iconBase64,
                                      size: 43,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  asset.name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Color(0xFF20242A),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: asset.type.color
                                                      .withValues(alpha: 0.11),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  asset.type.label,
                                                  style: TextStyle(
                                                    color: asset.type.color,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            [
                                              if (asset.institution.isNotEmpty)
                                                asset.institution,
                                              if (asset.lastFour.isNotEmpty)
                                                '•••• ${asset.lastFour}',
                                            ].join(' · '),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFF9AA2AD),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      formatCurrency(
                                        balances[asset.id] ?? 0,
                                      ),
                                      style: TextStyle(
                                        color: asset.type.isLiability
                                            ? const Color(0xFFFF695D)
                                            : const Color(0xFF1B2027),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 19,
                                      color: Color(0xFFBEC4CC),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            height: 40,
                            child: IconButton(
                              onPressed: () => onEdit(asset),
                              padding: EdgeInsets.zero,
                              tooltip: '자산 수정',
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 17,
                                color: Color(0xFF9AA2AD),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (recentEntries.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 55, bottom: 10),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => onOpenHistory(asset),
                              borderRadius: BorderRadius.circular(13),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                child: Column(
                                  children: List.generate(recentEntries.length, (
                                    entryIndex,
                                  ) {
                                    return _AssetRecentEntryLine(
                                      entry: recentEntries[entryIndex],
                                      showTopSpacing: entryIndex > 0,
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (index != assets.length - 1)
                        const Divider(
                          height: 1,
                          indent: 55,
                          color: Color(0xFFEEF1F4),
                        ),
                    ],
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

class _AssetRecentEntryLine extends StatelessWidget {
  const _AssetRecentEntryLine({
    required this.entry,
    required this.showTopSpacing,
  });

  final LedgerEntry entry;
  final bool showTopSpacing;

  @override
  Widget build(BuildContext context) {
    final isIncome = entry.type == EntryType.income;
    final color = isIncome
        ? const Color(0xFF4F8FF7)
        : const Color(0xFFFF695D);
    final title = entry.title.trim().isEmpty ? entry.category : entry.title.trim();
    return Padding(
      padding: EdgeInsets.only(top: showTopSpacing ? 7 : 0),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          SizedBox(
            width: 30,
            child: Text(
              DateFormat('M.d').format(entry.date),
              style: const TextStyle(
                color: Color(0xFF9AA2AD),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF505762),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isIncome ? '+' : '-'}${formatCurrencyValue(entry.amount)}',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetSummaryMetric extends StatelessWidget {
  const _AssetSummaryMetric({
    required this.label,
    required this.amount,
    required this.color,
    this.onDark = false,
  });

  final String label;
  final double amount;
  final Color color;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: onDark
                      ? Colors.white.withValues(alpha: 0.76)
                      : const Color(0xFF8A929D),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            formatCurrency(amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: onDark ? Colors.white : const Color(0xFF30353C),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
