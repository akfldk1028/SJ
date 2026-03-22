/// 천간지지 다국어 매핑
///
/// DB/계산 레이어는 한글 키 유지 (갑, 을, 자, 축 등)
/// UI 표시 시 locale에 따라 변환
///
/// - ko: 한글 그대로 (무)
/// - ja: 일본어 음독 (ぼ)
/// - zh: 중국어 병음 (wù)
/// - en/기타: 로마자 (Mu)
///
/// 한자는 CJK 공통이므로 모든 언어에서 동일

/// 천간 한글 → 로마자/다국어 표시명
const Map<String, Map<String, String>> _cheonganI18n = {
  '갑': {'ko': '갑', 'ja': 'こう',  'zh': 'jiǎ',  'en': 'Gap'},
  '을': {'ko': '을', 'ja': 'おつ',  'zh': 'yǐ',   'en': 'Eul'},
  '병': {'ko': '병', 'ja': 'へい',  'zh': 'bǐng',  'en': 'Byeong'},
  '정': {'ko': '정', 'ja': 'てい',  'zh': 'dīng',  'en': 'Jeong'},
  '무': {'ko': '무', 'ja': 'ぼ',    'zh': 'wù',    'en': 'Mu'},
  '기': {'ko': '기', 'ja': 'き',    'zh': 'jǐ',    'en': 'Gi'},
  '경': {'ko': '경', 'ja': 'こう',  'zh': 'gēng',  'en': 'Gyeong'},
  '신': {'ko': '신', 'ja': 'しん',  'zh': 'xīn',   'en': 'Sin'},
  '임': {'ko': '임', 'ja': 'じん',  'zh': 'rén',   'en': 'Im'},
  '계': {'ko': '계', 'ja': 'き',    'zh': 'guǐ',   'en': 'Gye'},
};

/// 지지 한글 → 로마자/다국어 표시명
const Map<String, Map<String, String>> _jijiI18n = {
  '자': {'ko': '자', 'ja': 'し',    'zh': 'zǐ',    'en': 'Ja'},
  '축': {'ko': '축', 'ja': 'ちゅう','zh': 'chǒu',  'en': 'Chuk'},
  '인': {'ko': '인', 'ja': 'いん',  'zh': 'yín',   'en': 'In'},
  '묘': {'ko': '묘', 'ja': 'ぼう',  'zh': 'mǎo',   'en': 'Myo'},
  '진': {'ko': '진', 'ja': 'しん',  'zh': 'chén',  'en': 'Jin'},
  '사': {'ko': '사', 'ja': 'し',    'zh': 'sì',    'en': 'Sa'},
  '오': {'ko': '오', 'ja': 'ご',    'zh': 'wǔ',    'en': 'O'},
  '미': {'ko': '미', 'ja': 'び',    'zh': 'wèi',   'en': 'Mi'},
  '신': {'ko': '신', 'ja': 'しん',  'zh': 'shēn',  'en': 'Sin'},
  '유': {'ko': '유', 'ja': 'ゆう',  'zh': 'yǒu',   'en': 'Yu'},
  '술': {'ko': '술', 'ja': 'じゅつ','zh': 'xū',    'en': 'Sul'},
  '해': {'ko': '해', 'ja': 'がい',  'zh': 'hài',   'en': 'Hae'},
};

/// 오행 한글 → 다국어 표시명
const Map<String, Map<String, String>> _ohengI18n = {
  '목': {'ko': '목', 'ja': '木',  'zh': '木', 'en': 'Wood'},
  '화': {'ko': '화', 'ja': '火',  'zh': '火', 'en': 'Fire'},
  '토': {'ko': '토', 'ja': '土',  'zh': '土', 'en': 'Earth'},
  '금': {'ko': '금', 'ja': '金',  'zh': '金', 'en': 'Metal'},
  '수': {'ko': '수', 'ja': '水',  'zh': '水', 'en': 'Water'},
};

/// 음양 한글 → 다국어 표시명
const Map<String, Map<String, String>> _eumyangI18n = {
  '양': {'ko': '양', 'ja': '陽',  'zh': '阳', 'en': 'Yang'},
  '음': {'ko': '음', 'ja': '陰',  'zh': '阴', 'en': 'Yin'},
};

/// 띠 동물 한글 → 다국어 표시명
const Map<String, Map<String, String>> _animalI18n = {
  '쥐':     {'ko': '쥐',     'ja': 'ねずみ', 'zh': '鼠', 'en': 'Rat'},
  '소':     {'ko': '소',     'ja': 'うし',   'zh': '牛', 'en': 'Ox'},
  '호랑이': {'ko': '호랑이', 'ja': 'とら',   'zh': '虎', 'en': 'Tiger'},
  '토끼':   {'ko': '토끼',   'ja': 'うさぎ', 'zh': '兔', 'en': 'Rabbit'},
  '용':     {'ko': '용',     'ja': 'たつ',   'zh': '龙', 'en': 'Dragon'},
  '뱀':     {'ko': '뱀',     'ja': 'へび',   'zh': '蛇', 'en': 'Snake'},
  '말':     {'ko': '말',     'ja': 'うま',   'zh': '马', 'en': 'Horse'},
  '양':     {'ko': '양',     'ja': 'ひつじ', 'zh': '羊', 'en': 'Goat'},
  '원숭이': {'ko': '원숭이', 'ja': 'さる',   'zh': '猴', 'en': 'Monkey'},
  '닭':     {'ko': '닭',     'ja': 'とり',   'zh': '鸡', 'en': 'Rooster'},
  '개':     {'ko': '개',     'ja': 'いぬ',   'zh': '狗', 'en': 'Dog'},
  '돼지':   {'ko': '돼지',   'ja': 'いのしし','zh': '猪', 'en': 'Pig'},
};

/// 십성(十神) 한글 → 다국어 (BaZi Ten Gods 국제 표준)
const Map<String, Map<String, String>> _sipsinI18n = {
  '비견': {
    'ko': '비견', 'ja': '比肩', 'zh': '比肩', 'en': 'Companion',
    'vi': 'Tỷ Kiên', 'th': 'เปรียบบ่า', 'id': 'Sahabat', 'ms': 'Sahabat',
    'fr': 'Compagnon', 'de': 'Gefährte', 'es': 'Compañero', 'pt': 'Companheiro',
    'it': 'Compagno', 'hi': 'साथी', 'ar': 'رفيق', 'ru': 'Спутник', 'my': 'အဖော်',
  },
  '겁재': {
    'ko': '겁재', 'ja': '劫財', 'zh': '劫财', 'en': 'Rob Wealth',
    'vi': 'Kiếp Tài', 'th': 'ปล้นทรัพย์', 'id': 'Perampas Kekayaan', 'ms': 'Perampas Kekayaan',
    'fr': 'Vol de Richesse', 'de': 'Raub des Reichtums', 'es': 'Robo de Riqueza', 'pt': 'Roubo de Riqueza',
    'it': 'Furto di Ricchezza', 'hi': 'धन लूट', 'ar': 'سلب الثروة', 'ru': 'Грабёж Богатства', 'my': 'ဥစ္စာလုယက်',
  },
  '식신': {
    'ko': '식신', 'ja': '食神', 'zh': '食神', 'en': 'Eating God',
    'vi': 'Thực Thần', 'th': 'เทพอาหาร', 'id': 'Dewa Makan', 'ms': 'Dewa Makan',
    'fr': 'Dieu Nourricier', 'de': 'Essensgott', 'es': 'Dios Alimentador', 'pt': 'Deus Alimentador',
    'it': 'Dio del Cibo', 'hi': 'भोजन देवता', 'ar': 'إله الطعام', 'ru': 'Бог Пищи', 'my': 'စားသောက်နတ်',
  },
  '상관': {
    'ko': '상관', 'ja': '傷官', 'zh': '伤官', 'en': 'Hurting Officer',
    'vi': 'Thương Quan', 'th': 'ทำร้ายขุนนาง', 'id': 'Pejabat Terluka', 'ms': 'Pegawai Terluka',
    'fr': 'Officier Blessé', 'de': 'Verletzter Beamter', 'es': 'Oficial Herido', 'pt': 'Oficial Ferido',
    'it': 'Ufficiale Ferito', 'hi': 'घायल अधिकारी', 'ar': 'الضابط المجروح', 'ru': 'Раненый Чиновник', 'my': 'ဒဏ်ရာရအရာရှိ',
  },
  '편재': {
    'ko': '편재', 'ja': '偏財', 'zh': '偏财', 'en': 'Indirect Wealth',
    'vi': 'Thiên Tài', 'th': 'ทรัพย์ทางอ้อม', 'id': 'Kekayaan Tidak Langsung', 'ms': 'Kekayaan Tidak Langsung',
    'fr': 'Richesse Indirecte', 'de': 'Indirekter Reichtum', 'es': 'Riqueza Indirecta', 'pt': 'Riqueza Indireta',
    'it': 'Ricchezza Indiretta', 'hi': 'अप्रत्यक्ष धन', 'ar': 'ثروة غير مباشرة', 'ru': 'Косвенное Богатство', 'my': 'သွယ်ဝိုက်ဥစ္စာ',
  },
  '정재': {
    'ko': '정재', 'ja': '正財', 'zh': '正财', 'en': 'Direct Wealth',
    'vi': 'Chính Tài', 'th': 'ทรัพย์โดยตรง', 'id': 'Kekayaan Langsung', 'ms': 'Kekayaan Langsung',
    'fr': 'Richesse Directe', 'de': 'Direkter Reichtum', 'es': 'Riqueza Directa', 'pt': 'Riqueza Direta',
    'it': 'Ricchezza Diretta', 'hi': 'प्रत्यक्ष धन', 'ar': 'ثروة مباشرة', 'ru': 'Прямое Богатство', 'my': 'တိုက်ရိုက်ဥစ္စာ',
  },
  '편관': {
    'ko': '편관', 'ja': '偏官', 'zh': '偏官', 'en': 'Seven Killings',
    'vi': 'Thất Sát', 'th': 'เจ็ดสังหาร', 'id': 'Tujuh Pembunuhan', 'ms': 'Tujuh Pembunuhan',
    'fr': 'Sept Meurtres', 'de': 'Sieben Tötungen', 'es': 'Siete Muertes', 'pt': 'Sete Matanças',
    'it': 'Sette Uccisioni', 'hi': 'सात वध', 'ar': 'سبع ضربات', 'ru': 'Семь Убийств', 'my': 'ခုနစ်ချက်သတ်',
  },
  '정관': {
    'ko': '정관', 'ja': '正官', 'zh': '正官', 'en': 'Direct Officer',
    'vi': 'Chính Quan', 'th': 'ขุนนางโดยตรง', 'id': 'Pejabat Langsung', 'ms': 'Pegawai Langsung',
    'fr': 'Officier Direct', 'de': 'Direkter Beamter', 'es': 'Oficial Directo', 'pt': 'Oficial Direto',
    'it': 'Ufficiale Diretto', 'hi': 'प्रत्यक्ष अधिकारी', 'ar': 'الضابط المباشر', 'ru': 'Прямой Чиновник', 'my': 'တိုက်ရိုက်အရာရှိ',
  },
  '편인': {
    'ko': '편인', 'ja': '偏印', 'zh': '偏印', 'en': 'Indirect Resource',
    'vi': 'Thiên Ấn', 'th': 'ทรัพยากรทางอ้อม', 'id': 'Sumber Tidak Langsung', 'ms': 'Sumber Tidak Langsung',
    'fr': 'Ressource Indirecte', 'de': 'Indirekte Ressource', 'es': 'Recurso Indirecto', 'pt': 'Recurso Indireto',
    'it': 'Risorsa Indiretta', 'hi': 'अप्रत्यक्ष संसाधन', 'ar': 'مورد غير مباشر', 'ru': 'Косвенный Ресурс', 'my': 'သွယ်ဝိုက်အရင်းအမြစ်',
  },
  '정인': {
    'ko': '정인', 'ja': '正印', 'zh': '正印', 'en': 'Direct Resource',
    'vi': 'Chính Ấn', 'th': 'ทรัพยากรโดยตรง', 'id': 'Sumber Langsung', 'ms': 'Sumber Langsung',
    'fr': 'Ressource Directe', 'de': 'Direkte Ressource', 'es': 'Recurso Directo', 'pt': 'Recurso Direto',
    'it': 'Risorsa Diretta', 'hi': 'प्रत्यक्ष संसाधन', 'ar': 'مورد مباشر', 'ru': 'Прямой Ресурс', 'my': 'တိုက်ရိုက်အရင်းအမြစ်',
  },
};

/// 십성 5대 카테고리 한글 → 다국어
const Map<String, Map<String, String>> _sipsinCategoryI18n = {
  '비겁': {
    'ko': '비겁', 'ja': '比劫', 'zh': '比劫', 'en': 'Companions',
    'vi': 'Đồng hành', 'th': 'สหาย', 'id': 'Sahabat', 'ms': 'Sahabat',
    'fr': 'Compagnons', 'de': 'Gefährten', 'es': 'Compañeros', 'pt': 'Companheiros',
    'it': 'Compagni', 'hi': 'साथी', 'ar': 'رفاق', 'ru': 'Спутники', 'my': 'အဖော်များ',
  },
  '식상': {
    'ko': '식상', 'ja': '食傷', 'zh': '食伤', 'en': 'Output',
    'vi': 'Sản xuất', 'th': 'ผลผลิต', 'id': 'Keluaran', 'ms': 'Keluaran',
    'fr': 'Production', 'de': 'Ertrag', 'es': 'Producción', 'pt': 'Produção',
    'it': 'Produzione', 'hi': 'उत्पादन', 'ar': 'إنتاج', 'ru': 'Выход', 'my': 'ထုတ်လုပ်မှု',
  },
  '재성': {
    'ko': '재성', 'ja': '財星', 'zh': '财星', 'en': 'Wealth',
    'vi': 'Tài lộc', 'th': 'ทรัพย์', 'id': 'Kekayaan', 'ms': 'Kekayaan',
    'fr': 'Richesse', 'de': 'Reichtum', 'es': 'Riqueza', 'pt': 'Riqueza',
    'it': 'Ricchezza', 'hi': 'धन', 'ar': 'ثروة', 'ru': 'Богатство', 'my': 'ဥစ္စာ',
  },
  '관성': {
    'ko': '관성', 'ja': '官星', 'zh': '官星', 'en': 'Authority',
    'vi': 'Quyền lực', 'th': 'อำนาจ', 'id': 'Otoritas', 'ms': 'Kuasa',
    'fr': 'Autorité', 'de': 'Autorität', 'es': 'Autoridad', 'pt': 'Autoridade',
    'it': 'Autorità', 'hi': 'अधिकार', 'ar': 'سلطة', 'ru': 'Власть', 'my': 'အာဏာ',
  },
  '인성': {
    'ko': '인성', 'ja': '印星', 'zh': '印星', 'en': 'Resource',
    'vi': 'Tài nguyên', 'th': 'ทรัพยากร', 'id': 'Sumber', 'ms': 'Sumber',
    'fr': 'Ressource', 'de': 'Ressource', 'es': 'Recurso', 'pt': 'Recurso',
    'it': 'Risorsa', 'hi': 'संसाधन', 'ar': 'مورد', 'ru': 'Ресурс', 'my': 'အရင်းအမြစ်',
  },
};

/// 12운성(十二運星) 한글 → 다국어
const Map<String, Map<String, String>> _unsungI18n = {
  '장생': {
    'ko': '장생', 'ja': '長生', 'zh': '长生', 'en': 'Birth',
    'vi': 'Trường Sinh', 'th': 'เกิด', 'id': 'Kelahiran', 'ms': 'Kelahiran',
    'fr': 'Naissance', 'de': 'Geburt', 'es': 'Nacimiento', 'pt': 'Nascimento',
    'it': 'Nascita', 'hi': 'जन्म', 'ar': 'الولادة', 'ru': 'Рождение', 'my': 'မွေးဖွားခြင်း',
  },
  '목욕': {
    'ko': '목욕', 'ja': '沐浴', 'zh': '沐浴', 'en': 'Bath',
    'vi': 'Mộc Dục', 'th': 'อาบน้ำ', 'id': 'Mandi', 'ms': 'Mandi',
    'fr': 'Bain', 'de': 'Bad', 'es': 'Baño', 'pt': 'Banho',
    'it': 'Bagno', 'hi': 'स्नान', 'ar': 'الاستحمام', 'ru': 'Купание', 'my': 'ရေချိုးခြင်း',
  },
  '관대': {
    'ko': '관대', 'ja': '冠帯', 'zh': '冠带', 'en': 'Crown',
    'vi': 'Quan Đới', 'th': 'สวมมงกุฎ', 'id': 'Mahkota', 'ms': 'Mahkota',
    'fr': 'Couronne', 'de': 'Krone', 'es': 'Corona', 'pt': 'Coroa',
    'it': 'Corona', 'hi': 'मुकुट', 'ar': 'التاج', 'ru': 'Корона', 'my': 'သရဖူ',
  },
  '건록': {
    'ko': '건록', 'ja': '建禄', 'zh': '建禄', 'en': 'Officer',
    'vi': 'Lâm Quan', 'th': 'ขุนนาง', 'id': 'Pejabat', 'ms': 'Pegawai',
    'fr': 'Officier', 'de': 'Beamter', 'es': 'Oficial', 'pt': 'Oficial',
    'it': 'Ufficiale', 'hi': 'अधिकारी', 'ar': 'الموظف', 'ru': 'Чиновник', 'my': 'အရာရှိ',
  },
  '제왕': {
    'ko': '제왕', 'ja': '帝旺', 'zh': '帝旺', 'en': 'Emperor',
    'vi': 'Đế Vượng', 'th': 'จักรพรรดิ', 'id': 'Kaisar', 'ms': 'Maharaja',
    'fr': 'Empereur', 'de': 'Kaiser', 'es': 'Emperador', 'pt': 'Imperador',
    'it': 'Imperatore', 'hi': 'सम्राट', 'ar': 'الإمبراطور', 'ru': 'Император', 'my': 'ဧကရာဇ်',
  },
  '쇠': {
    'ko': '쇠', 'ja': '衰', 'zh': '衰', 'en': 'Decline',
    'vi': 'Suy', 'th': 'เสื่อม', 'id': 'Kemunduran', 'ms': 'Kemerosotan',
    'fr': 'Déclin', 'de': 'Niedergang', 'es': 'Declive', 'pt': 'Declínio',
    'it': 'Declino', 'hi': 'पतन', 'ar': 'الانحدار', 'ru': 'Упадок', 'my': 'ကျဆင်းခြင်း',
  },
  '병': {
    'ko': '병', 'ja': '病', 'zh': '病', 'en': 'Sickness',
    'vi': 'Bệnh', 'th': 'เจ็บป่วย', 'id': 'Sakit', 'ms': 'Sakit',
    'fr': 'Maladie', 'de': 'Krankheit', 'es': 'Enfermedad', 'pt': 'Doença',
    'it': 'Malattia', 'hi': 'बीमारी', 'ar': 'المرض', 'ru': 'Болезнь', 'my': 'ရောဂါ',
  },
  '사': {
    'ko': '사', 'ja': '死', 'zh': '死', 'en': 'Death',
    'vi': 'Tử', 'th': 'ตาย', 'id': 'Kematian', 'ms': 'Kematian',
    'fr': 'Mort', 'de': 'Tod', 'es': 'Muerte', 'pt': 'Morte',
    'it': 'Morte', 'hi': 'मृत्यु', 'ar': 'الموت', 'ru': 'Смерть', 'my': 'သေခြင်း',
  },
  '묘': {
    'ko': '묘', 'ja': '墓', 'zh': '墓', 'en': 'Grave',
    'vi': 'Mộ', 'th': 'หลุมฝังศพ', 'id': 'Makam', 'ms': 'Kubur',
    'fr': 'Tombe', 'de': 'Grab', 'es': 'Tumba', 'pt': 'Túmulo',
    'it': 'Tomba', 'hi': 'कब्र', 'ar': 'القبر', 'ru': 'Могила', 'my': 'သင်္ချိုင်း',
  },
  '절': {
    'ko': '절', 'ja': '絶', 'zh': '绝', 'en': 'Extinction',
    'vi': 'Tuyệt', 'th': 'ดับสูญ', 'id': 'Kepunahan', 'ms': 'Kepupusan',
    'fr': 'Extinction', 'de': 'Auslöschung', 'es': 'Extinción', 'pt': 'Extinção',
    'it': 'Estinzione', 'hi': 'विलुप्ति', 'ar': 'الانقراض', 'ru': 'Угасание', 'my': 'ပျောက်ကွယ်ခြင်း',
  },
  '태': {
    'ko': '태', 'ja': '胎', 'zh': '胎', 'en': 'Conception',
    'vi': 'Thai', 'th': 'ปฏิสนธิ', 'id': 'Pembuahan', 'ms': 'Persenyawaan',
    'fr': 'Conception', 'de': 'Empfängnis', 'es': 'Concepción', 'pt': 'Concepção',
    'it': 'Concepimento', 'hi': 'गर्भधारण', 'ar': 'الحمل', 'ru': 'Зачатие', 'my': 'ပဋိသန္ဓေ',
  },
  '양': {
    'ko': '양', 'ja': '養', 'zh': '养', 'en': 'Nurture',
    'vi': 'Dưỡng', 'th': 'เลี้ยงดู', 'id': 'Pengasuhan', 'ms': 'Pemeliharaan',
    'fr': 'Nourriture', 'de': 'Pflege', 'es': 'Crianza', 'pt': 'Nutrição',
    'it': 'Nutrimento', 'hi': 'पालन-पोषण', 'ar': 'الرعاية', 'ru': 'Воспитание', 'my': 'ပြုစုပျိုးထောင်ခြင်း',
  },
};

/// 12운성 의미(meaning) 한글 → 다국어
const Map<String, Map<String, String>> _unsungMeaningI18n = {
  '탄생, 시작의 기운': {
    'ko': '탄생, 시작의 기운',
    'en': 'Birth, energy of new beginnings',
    'ja': '誕生、始まりのエネルギー',
    'zh': '诞生，新开始的能量',
    'vi': 'Sinh ra, năng lượng khởi đầu mới',
    'th': 'การเกิด พลังแห่งการเริ่มต้นใหม่',
    'id': 'Kelahiran, energi awal yang baru',
    'ms': 'Kelahiran, tenaga permulaan baharu',
    'fr': 'Naissance, énergie des nouveaux départs',
    'de': 'Geburt, Energie des Neuanfangs',
    'es': 'Nacimiento, energía de nuevos comienzos',
    'pt': 'Nascimento, energia de novos começos',
    'it': 'Nascita, energia di nuovi inizi',
    'hi': 'जन्म, नई शुरुआत की ऊर्जा',
    'ar': 'الولادة، طاقة البدايات الجديدة',
    'ru': 'Рождение, энергия новых начинаний',
    'my': 'မွေးဖွား, အသစ်စတင်ခြင်း စွမ်းအင်',
  },
  '씻음, 정화의 단계': {
    'ko': '씻음, 정화의 단계',
    'en': 'Cleansing, stage of purification',
    'ja': '洗浄、浄化の段階',
    'zh': '洗涤，净化的阶段',
    'vi': 'Tẩy rửa, giai đoạn thanh lọc',
    'th': 'การชำระล้าง ขั้นตอนแห่งการบริสุทธิ์',
    'id': 'Pembersihan, tahap pemurnian',
    'ms': 'Pembersihan, tahap penyucian',
    'fr': 'Purification, étape de nettoyage',
    'de': 'Reinigung, Phase der Läuterung',
    'es': 'Limpieza, etapa de purificación',
    'pt': 'Limpeza, fase de purificação',
    'it': 'Purificazione, fase di pulizia',
    'hi': 'शुद्धि, सफाई का चरण',
    'ar': 'التطهير، مرحلة التنقية',
    'ru': 'Очищение, стадия очистки',
    'my': 'သန့်စင်ခြင်း, စင်ကြယ်ခြင်း အဆင့်',
  },
  '성장, 관을 쓰는 시기': {
    'ko': '성장, 관을 쓰는 시기',
    'en': 'Growth, coming of age',
    'ja': '成長、成人を迎える時期',
    'zh': '成长，成年加冠的时期',
    'vi': 'Trưởng thành, thời kỳ đến tuổi trưởng thành',
    'th': 'การเติบโต ช่วงเวลาแห่งวัยผู้ใหญ่',
    'id': 'Pertumbuhan, masa kedewasaan',
    'ms': 'Pertumbuhan, masa mendewasa',
    'fr': 'Croissance, passage à l\'âge adulte',
    'de': 'Wachstum, Erwachsenwerden',
    'es': 'Crecimiento, llegada a la madurez',
    'pt': 'Crescimento, chegada à maturidade',
    'it': 'Crescita, raggiungimento della maturità',
    'hi': 'विकास, वयस्क होने का समय',
    'ar': 'النمو، مرحلة البلوغ',
    'ru': 'Рост, достижение зрелости',
    'my': 'ကြီးထွားခြင်း, အရွယ်ရောက်ချိန်',
  },
  '녹을 세움, 왕성한 활동': {
    'ko': '녹을 세움, 왕성한 활동',
    'en': 'Establishing fortune, vigorous activity',
    'ja': '運を築く、旺盛な活動',
    'zh': '建立福禄，活动旺盛',
    'vi': 'Xây dựng vận may, hoạt động mạnh mẽ',
    'th': 'สร้างโชคลาภ กิจกรรมที่แข็งแกร่ง',
    'id': 'Membangun keberuntungan, aktivitas yang giat',
    'ms': 'Membina nasib baik, aktiviti yang cergas',
    'fr': 'Établir la fortune, activité vigoureuse',
    'de': 'Glück aufbauen, rege Tätigkeit',
    'es': 'Establecer la fortuna, actividad vigorosa',
    'pt': 'Estabelecer a fortuna, atividade vigorosa',
    'it': 'Stabilire la fortuna, attività vigorosa',
    'hi': 'भाग्य की स्थापना, जोरदार गतिविधि',
    'ar': 'تأسيس الحظ، نشاط قوي',
    'ru': 'Утверждение удачи, активная деятельность',
    'my': 'ကံကောင်းခြင်း တည်ဆောက်ခြင်း, တက်ကြွသော လှုပ်ရှားမှု',
  },
  '최고 전성기': {
    'ko': '최고 전성기',
    'en': 'Peak of prosperity',
    'ja': '繁栄の絶頂',
    'zh': '繁荣的巅峰',
    'vi': 'Đỉnh cao thịnh vượng',
    'th': 'จุดสูงสุดแห่งความรุ่งเรือง',
    'id': 'Puncak kemakmuran',
    'ms': 'Kemuncak kemakmuran',
    'fr': 'Apogée de la prospérité',
    'de': 'Höhepunkt des Wohlstands',
    'es': 'Cumbre de la prosperidad',
    'pt': 'Auge da prosperidade',
    'it': 'Apice della prosperità',
    'hi': 'समृद्धि का चरम',
    'ar': 'ذروة الازدهار',
    'ru': 'Пик процветания',
    'my': 'ကြီးပွားမှု အထွဋ်အထိပ်',
  },
  '쇠퇴의 시작': {
    'ko': '쇠퇴의 시작',
    'en': 'Beginning of decline',
    'ja': '衰退の始まり',
    'zh': '衰退的开始',
    'vi': 'Bắt đầu suy thoái',
    'th': 'จุดเริ่มต้นของความเสื่อม',
    'id': 'Awal kemunduran',
    'ms': 'Permulaan kemerosotan',
    'fr': 'Début du déclin',
    'de': 'Beginn des Niedergangs',
    'es': 'Inicio del declive',
    'pt': 'Início do declínio',
    'it': 'Inizio del declino',
    'hi': 'पतन की शुरुआत',
    'ar': 'بداية الانحدار',
    'ru': 'Начало упадка',
    'my': 'ကျဆင်းမှု အစ',
  },
  '병듦, 약해짐': {
    'ko': '병듦, 약해짐',
    'en': 'Weakening, falling ill',
    'ja': '衰弱、病に倒れる',
    'zh': '衰弱，患病',
    'vi': 'Yếu đi, đổ bệnh',
    'th': 'อ่อนแอ เจ็บป่วย',
    'id': 'Melemah, jatuh sakit',
    'ms': 'Melemah, jatuh sakit',
    'fr': 'Affaiblissement, tomber malade',
    'de': 'Schwächung, Erkrankung',
    'es': 'Debilitamiento, caer enfermo',
    'pt': 'Enfraquecimento, adoecer',
    'it': 'Indebolimento, ammalarsi',
    'hi': 'कमज़ोर होना, बीमार पड़ना',
    'ar': 'الضعف، الإصابة بالمرض',
    'ru': 'Ослабление, болезнь',
    'my': 'အားနည်းလာခြင်း, ဖျားနာခြင်း',
  },
  '기운의 죽음': {
    'ko': '기운의 죽음',
    'en': 'Death of energy',
    'ja': '気の死',
    'zh': '气运的死亡',
    'vi': 'Cái chết của năng lượng',
    'th': 'การตายของพลังงาน',
    'id': 'Kematian energi',
    'ms': 'Kematian tenaga',
    'fr': 'Mort de l\'énergie',
    'de': 'Tod der Energie',
    'es': 'Muerte de la energía',
    'pt': 'Morte da energia',
    'it': 'Morte dell\'energia',
    'hi': 'ऊर्जा की मृत्यु',
    'ar': 'موت الطاقة',
    'ru': 'Смерть энергии',
    'my': 'စွမ်းအင် ပျက်သုဉ်းခြင်း',
  },
  '묻힘, 창고': {
    'ko': '묻힘, 창고',
    'en': 'Buried, storage',
    'ja': '埋葬、貯蔵',
    'zh': '埋藏，入库',
    'vi': 'Chôn vùi, cất giữ',
    'th': 'ถูกฝัง การเก็บรักษา',
    'id': 'Terkubur, penyimpanan',
    'ms': 'Terkubur, penyimpanan',
    'fr': 'Enterré, mise en réserve',
    'de': 'Begraben, Aufbewahrung',
    'es': 'Enterrado, almacenamiento',
    'pt': 'Enterrado, armazenamento',
    'it': 'Sepolto, conservazione',
    'hi': 'दफ़न, भंडारण',
    'ar': 'مدفون، تخزين',
    'ru': 'Погребение, хранение',
    'my': 'မြှုပ်နှံခြင်း, သိုလှောင်ခြင်း',
  },
  '끊어짐, 절멸': {
    'ko': '끊어짐, 절멸',
    'en': 'Severed, extinction',
    'ja': '断絶、絶滅',
    'zh': '断绝，灭绝',
    'vi': 'Đứt đoạn, tuyệt diệt',
    'th': 'ขาดสะบั้น การสูญสิ้น',
    'id': 'Terputus, kepunahan',
    'ms': 'Terputus, kepupusan',
    'fr': 'Rupture, extinction',
    'de': 'Abgetrennt, Auslöschung',
    'es': 'Cortado, extinción',
    'pt': 'Cortado, extinção',
    'it': 'Reciso, estinzione',
    'hi': 'विच्छेद, विलुप्ति',
    'ar': 'الانقطاع، الانقراض',
    'ru': 'Разрыв, угасание',
    'my': 'ပြတ်တောက်ခြင်း, ချုပ်ငြိမ်းခြင်း',
  },
  '잉태, 새 생명의 시작': {
    'ko': '잉태, 새 생명의 시작',
    'en': 'Conceived, new life begins',
    'ja': '懐胎、新たな命の始まり',
    'zh': '怀胎，新生命的开始',
    'vi': 'Thụ thai, khởi đầu sự sống mới',
    'th': 'การปฏิสนธิ จุดเริ่มต้นของชีวิตใหม่',
    'id': 'Dikandung, awal kehidupan baru',
    'ms': 'Mengandung, permulaan kehidupan baharu',
    'fr': 'Conception, début d\'une nouvelle vie',
    'de': 'Empfängnis, Beginn neuen Lebens',
    'es': 'Concepción, inicio de una nueva vida',
    'pt': 'Concepção, início de uma nova vida',
    'it': 'Concepimento, inizio di una nuova vita',
    'hi': 'गर्भधारण, नए जीवन की शुरुआत',
    'ar': 'الحمل، بداية حياة جديدة',
    'ru': 'Зачатие, начало новой жизни',
    'my': 'ပဋိသန္ဓေ, ဘဝသစ် အစ',
  },
  '기름, 양육': {
    'ko': '기름, 양육',
    'en': 'Nourishing, nurturing',
    'ja': '養育、育み',
    'zh': '滋养，养育',
    'vi': 'Nuôi dưỡng, chăm sóc',
    'th': 'การบำรุงเลี้ยง การเลี้ยงดู',
    'id': 'Menyuburkan, mengasuh',
    'ms': 'Menyuburkan, memelihara',
    'fr': 'Nourrissant, bienveillant',
    'de': 'Nährend, Fürsorge',
    'es': 'Nutrir, criar',
    'pt': 'Nutrir, cuidar',
    'it': 'Nutrire, allevare',
    'hi': 'पोषण, पालन-पोषण',
    'ar': 'التغذية، الرعاية',
    'ru': 'Питание, воспитание',
    'my': 'ပြုစုပျိုးထောင်ခြင်း, မွေးမြူခြင်း',
  },
};

/// 12신살(十二神煞) 한글 → 다국어
const Map<String, Map<String, String>> _sinsalI18n = {
  '겁살': {
    'ko': '겁살', 'ja': '劫煞', 'zh': '劫煞', 'en': 'Robbery Star',
    'vi': 'Sao Cướp', 'th': 'ดาวโจร', 'id': 'Bintang Perampokan', 'ms': 'Bintang Rompakan',
    'fr': 'Étoile du Vol', 'de': 'Raubstern', 'es': 'Estrella del Robo', 'pt': 'Estrela do Roubo',
    'it': 'Stella del Furto', 'hi': 'डकैती तारा', 'ar': 'نجم السرقة', 'ru': 'Звезда Грабежа', 'my': 'ဓားပြကြယ်',
  },
  '재살': {
    'ko': '재살', 'ja': '災煞', 'zh': '灾煞', 'en': 'Calamity Star',
    'vi': 'Sao Tai Họa', 'th': 'ดาวภัยพิบัติ', 'id': 'Bintang Bencana', 'ms': 'Bintang Bencana',
    'fr': 'Étoile de Calamité', 'de': 'Unheilsstern', 'es': 'Estrella de Calamidad', 'pt': 'Estrela de Calamidade',
    'it': 'Stella della Calamità', 'hi': 'आपदा तारा', 'ar': 'نجم الكارثة', 'ru': 'Звезда Бедствия', 'my': 'ဘေးဒုက္ခကြယ်',
  },
  '천살': {
    'ko': '천살', 'ja': '天煞', 'zh': '天煞', 'en': 'Heaven Star',
    'vi': 'Sao Trời', 'th': 'ดาวสวรรค์', 'id': 'Bintang Langit', 'ms': 'Bintang Langit',
    'fr': 'Étoile Céleste', 'de': 'Himmelsstern', 'es': 'Estrella Celestial', 'pt': 'Estrela Celestial',
    'it': 'Stella Celeste', 'hi': 'स्वर्ग तारा', 'ar': 'نجم السماء', 'ru': 'Звезда Небес', 'my': 'ကောင်းကင်ကြယ်',
  },
  '지살': {
    'ko': '지살', 'ja': '地煞', 'zh': '地煞', 'en': 'Earth Star',
    'vi': 'Sao Đất', 'th': 'ดาวดิน', 'id': 'Bintang Bumi', 'ms': 'Bintang Bumi',
    'fr': 'Étoile Terrestre', 'de': 'Erdstern', 'es': 'Estrella Terrenal', 'pt': 'Estrela Terrestre',
    'it': 'Stella Terrestre', 'hi': 'पृथ्वी तारा', 'ar': 'نجم الأرض', 'ru': 'Звезда Земли', 'my': 'မြေကြီးကြယ်',
  },
  '연살': {
    'ko': '연살', 'ja': '年煞', 'zh': '年煞', 'en': 'Year Sha',
    'vi': 'Niên Sát', 'th': 'ปีศาจ', 'id': 'Sha Tahunan', 'ms': 'Sha Tahunan',
    'fr': 'Sha Annuel', 'de': 'Jahres-Sha', 'es': 'Sha Anual', 'pt': 'Sha Anual',
    'it': 'Sha Annuale', 'hi': 'वार्षिक शा', 'ar': 'شا السنوي', 'ru': 'Годовой Ша', 'my': 'နှစ်စဉ်ရှာ',
  },
  '월살': {
    'ko': '월살', 'ja': '月煞', 'zh': '月煞', 'en': 'Solitary Star',
    'vi': 'Sao Cô Đơn', 'th': 'ดาวโดดเดี่ยว', 'id': 'Bintang Kesepian', 'ms': 'Bintang Kesendirian',
    'fr': 'Étoile Solitaire', 'de': 'Einsamer Stern', 'es': 'Estrella Solitaria', 'pt': 'Estrela Solitária',
    'it': 'Stella Solitaria', 'hi': 'एकांत तारा', 'ar': 'النجم الوحيد', 'ru': 'Одинокая Звезда', 'my': 'အထီးကျန်ကြယ်',
  },
  '망신': {
    'ko': '망신', 'ja': '亡身', 'zh': '亡身', 'en': 'Body Loss',
    'vi': 'Vong Thân', 'th': 'สูญเสียกาย', 'id': 'Kehilangan Diri', 'ms': 'Kehilangan Diri',
    'fr': 'Perte du Corps', 'de': 'Körperverlust', 'es': 'Pérdida del Cuerpo', 'pt': 'Perda do Corpo',
    'it': 'Perdita del Corpo', 'hi': 'शरीर हानि', 'ar': 'فقدان الجسد', 'ru': 'Потеря Тела', 'my': 'ခန္ဓာဆုံးရှုံးခြင်း',
  },
  '장성': {
    'ko': '장성', 'ja': '將星', 'zh': '将星', 'en': 'General Star',
    'vi': 'Sao Tướng', 'th': 'ดาวแม่ทัพ', 'id': 'Bintang Jenderal', 'ms': 'Bintang Jeneral',
    'fr': 'Étoile du Général', 'de': 'Generalstern', 'es': 'Estrella del General', 'pt': 'Estrela do General',
    'it': 'Stella del Generale', 'hi': 'सेनापति तारा', 'ar': 'نجم القائد', 'ru': 'Звезда Генерала', 'my': 'ဗိုလ်ချုပ်ကြယ်',
  },
  '반안': {
    'ko': '반안', 'ja': '攀鞍', 'zh': '攀鞍', 'en': 'Saddle Star',
    'vi': 'Sao Yên Ngựa', 'th': 'ดาวอานม้า', 'id': 'Bintang Pelana', 'ms': 'Bintang Pelana',
    'fr': 'Étoile de la Selle', 'de': 'Sattelstern', 'es': 'Estrella de la Silla', 'pt': 'Estrela da Sela',
    'it': 'Stella della Sella', 'hi': 'काठी तारा', 'ar': 'نجم السرج', 'ru': 'Звезда Седла', 'my': 'ကုန်းနှီးကြယ်',
  },
  '역마': {
    'ko': '역마', 'ja': '駅馬', 'zh': '驿马', 'en': 'Post Horse',
    'vi': 'Dịch Mã', 'th': 'ม้าเร็ว', 'id': 'Kuda Pos', 'ms': 'Kuda Pos',
    'fr': 'Cheval de Poste', 'de': 'Postpferd', 'es': 'Caballo Postal', 'pt': 'Cavalo Postal',
    'it': 'Cavallo Postale', 'hi': 'डाक घोड़ा', 'ar': 'حصان البريد', 'ru': 'Почтовая Лошадь', 'my': 'စာပို့မြင်း',
  },
  '육해': {
    'ko': '육해', 'ja': '六害', 'zh': '六害', 'en': 'Six Harm',
    'vi': 'Lục Hại', 'th': 'หกอันตราย', 'id': 'Enam Bahaya', 'ms': 'Enam Bahaya',
    'fr': 'Six Nuisances', 'de': 'Sechs Schäden', 'es': 'Seis Daños', 'pt': 'Seis Danos',
    'it': 'Sei Danni', 'hi': 'छह हानि', 'ar': 'الأضرار الستة', 'ru': 'Шесть Вредов', 'my': 'ခြောက်ပါးအန္တရာယ်',
  },
  '화개': {
    'ko': '화개', 'ja': '華蓋', 'zh': '华盖', 'en': 'Canopy Star',
    'vi': 'Sao Hoa Cái', 'th': 'ดาวร่ม', 'id': 'Bintang Kanopi', 'ms': 'Bintang Kanopi',
    'fr': 'Étoile du Dais', 'de': 'Baldachinstern', 'es': 'Estrella del Dosel', 'pt': 'Estrela do Dossel',
    'it': 'Stella del Baldacchino', 'hi': 'छत्र तारा', 'ar': 'نجم المظلة', 'ru': 'Звезда Балдахина', 'my': 'ထီးဖြူကြယ်',
  },
};

/// 12신살 의미(meaning) 한글 → 다국어
const Map<String, Map<String, String>> _sinsalMeaningI18n = {
  '재물 손실, 도난 주의': {
    'ko': '재물 손실, 도난 주의',
    'en': 'Financial loss, beware of theft',
    'ja': '財物の損失、盗難に注意',
    'zh': '财物损失，注意盗窃',
    'vi': 'Tổn thất tài chính, cẩn thận trộm cắp',
    'th': 'สูญเสียทางการเงิน ระวังการโจรกรรม',
    'id': 'Kerugian finansial, waspada pencurian',
    'ms': 'Kerugian kewangan, berwaspada terhadap kecurian',
    'fr': 'Perte financière, attention au vol',
    'de': 'Finanzieller Verlust, Vorsicht vor Diebstahl',
    'es': 'Pérdida financiera, cuidado con el robo',
    'pt': 'Perda financeira, cuidado com roubo',
    'it': 'Perdita finanziaria, attenzione ai furti',
    'hi': 'वित्तीय हानि, चोरी से सावधान',
    'ar': 'خسارة مالية، احذر السرقة',
    'ru': 'Финансовые потери, остерегайтесь кражи',
    'my': 'ငွေကြေးဆုံးရှုံးခြင်း, ခိုးမှုကို သတိထား',
  },
  '재앙, 사고 주의': {
    'ko': '재앙, 사고 주의',
    'en': 'Disaster, beware of accidents',
    'ja': '災害、事故に注意',
    'zh': '灾难，注意事故',
    'vi': 'Tai họa, cẩn thận tai nạn',
    'th': 'ภัยพิบัติ ระวังอุบัติเหตุ',
    'id': 'Bencana, waspada kecelakaan',
    'ms': 'Bencana, berwaspada terhadap kemalangan',
    'fr': 'Catastrophe, attention aux accidents',
    'de': 'Katastrophe, Vorsicht vor Unfällen',
    'es': 'Desastre, cuidado con los accidentes',
    'pt': 'Desastre, cuidado com acidentes',
    'it': 'Disastro, attenzione agli incidenti',
    'hi': 'आपदा, दुर्घटनाओं से सावधान',
    'ar': 'كارثة، احذر الحوادث',
    'ru': 'Бедствие, остерегайтесь несчастных случаев',
    'my': 'ဘေးအန္တရာယ်, မတော်တဆမှုကို သတိထား',
  },
  '하늘의 재앙, 예기치 못한 일': {
    'ko': '하늘의 재앙, 예기치 못한 일',
    'en': 'Heavenly disaster, unexpected events',
    'ja': '天災、予期せぬ出来事',
    'zh': '天灾，意想不到的事件',
    'vi': 'Thiên tai, sự kiện bất ngờ',
    'th': 'ภัยจากฟ้า เหตุการณ์ที่ไม่คาดคิด',
    'id': 'Bencana langit, kejadian tak terduga',
    'ms': 'Bencana langit, kejadian tidak dijangka',
    'fr': 'Catastrophe céleste, événements inattendus',
    'de': 'Himmlische Katastrophe, unerwartete Ereignisse',
    'es': 'Desastre celestial, eventos inesperados',
    'pt': 'Desastre celeste, eventos inesperados',
    'it': 'Disastro celeste, eventi inaspettati',
    'hi': 'दैवी आपदा, अप्रत्याशित घटनाएँ',
    'ar': 'كارثة سماوية، أحداث غير متوقعة',
    'ru': 'Небесное бедствие, неожиданные события',
    'my': 'မိုးကောင်းကင် ဘေးအန္တရာယ်, မမျှော်လင့်သော အဖြစ်အပျက်',
  },
  '땅의 재앙, 이사/이동 관련': {
    'ko': '땅의 재앙, 이사/이동 관련',
    'en': 'Earthly disaster, moving/relocation',
    'ja': '地災、引越し・移動に関連',
    'zh': '地灾，搬迁/移动相关',
    'vi': 'Thiên tai từ đất, di chuyển/chuyển chỗ ở',
    'th': 'ภัยจากดิน การย้ายถิ่น/โยกย้าย',
    'id': 'Bencana bumi, pindah/relokasi',
    'ms': 'Bencana bumi, perpindahan/penempatan semula',
    'fr': 'Catastrophe terrestre, déménagement/relocalisation',
    'de': 'Irdische Katastrophe, Umzug/Umsiedlung',
    'es': 'Desastre terrenal, mudanza/reubicación',
    'pt': 'Desastre terrestre, mudança/realocação',
    'it': 'Disastro terrestre, trasloco/trasferimento',
    'hi': 'पृथ्वी की आपदा, स्थानांतरण/पुनर्वास',
    'ar': 'كارثة أرضية، انتقال/نقل',
    'ru': 'Земное бедствие, переезд/перемещение',
    'my': 'မြေကြီး ဘေးအန္တရာယ်, ပြောင်းရွှေ့ခြင်း',
  },
  '도화살, 이성 인연, 매력': {
    'ko': '도화살, 이성 인연, 매력',
    'en': 'Romance, attraction, charisma',
    'ja': 'ロマンス、魅力、カリスマ',
    'zh': '桃花运，异性缘，魅力',
    'vi': 'Tình duyên, sức hấp dẫn, sự quyến rũ',
    'th': 'ความรัก เสน่ห์ดึงดูด บารมี',
    'id': 'Romansa, daya tarik, karisma',
    'ms': 'Percintaan, daya tarikan, karisma',
    'fr': 'Romance, attraction, charisme',
    'de': 'Romantik, Anziehung, Charisma',
    'es': 'Romance, atracción, carisma',
    'pt': 'Romance, atração, carisma',
    'it': 'Romanticismo, attrazione, carisma',
    'hi': 'प्रेम, आकर्षण, करिश्मा',
    'ar': 'رومانسية، جاذبية، كاريزما',
    'ru': 'Романтика, привлекательность, харизма',
    'my': 'အချစ်ရေး, ဆွဲဆောင်မှု, ကာရစ်မာ',
  },
  '고독, 외로움, 독립심': {
    'ko': '고독, 외로움, 독립심',
    'en': 'Solitude, loneliness, independence',
    'ja': '孤独、寂しさ、独立心',
    'zh': '孤独，寂寞，独立性',
    'vi': 'Cô đơn, lẻ loi, tính độc lập',
    'th': 'ความโดดเดี่ยว ความเหงา ความเป็นอิสระ',
    'id': 'Kesendirian, kesepian, kemandirian',
    'ms': 'Kesendirian, kesepian, kebebasan',
    'fr': 'Solitude, isolement, indépendance',
    'de': 'Einsamkeit, Alleinsein, Unabhängigkeit',
    'es': 'Soledad, aislamiento, independencia',
    'pt': 'Solidão, isolamento, independência',
    'it': 'Solitudine, isolamento, indipendenza',
    'hi': 'एकांत, अकेलापन, स्वतंत्रता',
    'ar': 'العزلة، الوحدة، الاستقلالية',
    'ru': 'Одиночество, уединение, независимость',
    'my': 'တစ်ကိုယ်တည်း, အထီးကျန်, လွတ်လပ်မှု',
  },
  '체면 손상, 창피': {
    'ko': '체면 손상, 창피',
    'en': 'Loss of face, embarrassment',
    'ja': '面目を失う、恥をかく',
    'zh': '丢面子，尴尬',
    'vi': 'Mất mặt, xấu hổ',
    'th': 'เสียหน้า ความอับอาย',
    'id': 'Kehilangan muka, rasa malu',
    'ms': 'Hilang muka, rasa malu',
    'fr': 'Perte de prestige, embarras',
    'de': 'Gesichtsverlust, Peinlichkeit',
    'es': 'Pérdida de prestigio, vergüenza',
    'pt': 'Perda de prestígio, constrangimento',
    'it': 'Perdita di prestigio, imbarazzo',
    'hi': 'प्रतिष्ठा की हानि, शर्मिंदगी',
    'ar': 'فقدان الوجه، إحراج',
    'ru': 'Потеря лица, смущение',
    'my': 'မျက်နှာပျက်ခြင်း, ရှက်ကြောက်ခြင်း',
  },
  '권위, 리더십, 지휘력': {
    'ko': '권위, 리더십, 지휘력',
    'en': 'Authority, leadership, command',
    'ja': '権威、リーダーシップ、指揮力',
    'zh': '权威，领导力，指挥力',
    'vi': 'Quyền lực, khả năng lãnh đạo, chỉ huy',
    'th': 'อำนาจ ความเป็นผู้นำ การบัญชาการ',
    'id': 'Otoritas, kepemimpinan, komando',
    'ms': 'Kuasa, kepimpinan, pemerintahan',
    'fr': 'Autorité, leadership, commandement',
    'de': 'Autorität, Führung, Befehlsgewalt',
    'es': 'Autoridad, liderazgo, mando',
    'pt': 'Autoridade, liderança, comando',
    'it': 'Autorità, leadership, comando',
    'hi': 'अधिकार, नेतृत्व, कमान',
    'ar': 'السلطة، القيادة، القيادة',
    'ru': 'Авторитет, лидерство, командование',
    'my': 'အာဏာ, ခေါင်းဆောင်မှု, ကွပ်ကဲမှု',
  },
  '안정, 승진, 출세': {
    'ko': '안정, 승진, 출세',
    'en': 'Stability, promotion, success',
    'ja': '安定、昇進、出世',
    'zh': '稳定，升职，成功',
    'vi': 'Ổn định, thăng tiến, thành công',
    'th': 'ความมั่นคง การเลื่อนตำแหน่ง ความสำเร็จ',
    'id': 'Stabilitas, promosi, kesuksesan',
    'ms': 'Kestabilan, kenaikan pangkat, kejayaan',
    'fr': 'Stabilité, promotion, réussite',
    'de': 'Stabilität, Beförderung, Erfolg',
    'es': 'Estabilidad, ascenso, éxito',
    'pt': 'Estabilidade, promoção, sucesso',
    'it': 'Stabilità, promozione, successo',
    'hi': 'स्थिरता, पदोन्नति, सफलता',
    'ar': 'الاستقرار، الترقية، النجاح',
    'ru': 'Стабильность, повышение, успех',
    'my': 'တည်ငြိမ်မှု, ရာထူးတိုး, အောင်မြင်မှု',
  },
  '이동, 변동, 여행': {
    'ko': '이동, 변동, 여행',
    'en': 'Travel, change, movement',
    'ja': '移動、変動、旅行',
    'zh': '移动，变动，旅行',
    'vi': 'Di chuyển, thay đổi, du lịch',
    'th': 'การเดินทาง การเปลี่ยนแปลง การเคลื่อนไหว',
    'id': 'Perjalanan, perubahan, perpindahan',
    'ms': 'Perjalanan, perubahan, pergerakan',
    'fr': 'Voyage, changement, mouvement',
    'de': 'Reise, Veränderung, Bewegung',
    'es': 'Viaje, cambio, movimiento',
    'pt': 'Viagem, mudança, movimento',
    'it': 'Viaggio, cambiamento, movimento',
    'hi': 'यात्रा, परिवर्तन, गतिविधि',
    'ar': 'السفر، التغيير، الحركة',
    'ru': 'Путешествие, перемены, движение',
    'my': 'ခရီးသွား, ပြောင်းလဲခြင်း, ရွေ့လျားခြင်း',
  },
  '육친 갈등, 가족 문제': {
    'ko': '육친 갈등, 가족 문제',
    'en': 'Family conflict, relationship issues',
    'ja': '家族の衝突、人間関係の問題',
    'zh': '家庭冲突，关系问题',
    'vi': 'Mâu thuẫn gia đình, vấn đề quan hệ',
    'th': 'ความขัดแย้งในครอบครัว ปัญหาความสัมพันธ์',
    'id': 'Konflik keluarga, masalah hubungan',
    'ms': 'Konflik keluarga, masalah hubungan',
    'fr': 'Conflit familial, problèmes relationnels',
    'de': 'Familienkonflikt, Beziehungsprobleme',
    'es': 'Conflicto familiar, problemas de relación',
    'pt': 'Conflito familiar, problemas de relacionamento',
    'it': 'Conflitto familiare, problemi relazionali',
    'hi': 'पारिवारिक संघर्ष, रिश्तों की समस्याएँ',
    'ar': 'صراع عائلي، مشاكل في العلاقات',
    'ru': 'Семейный конфликт, проблемы в отношениях',
    'my': 'မိသားစု ပဋိပက္ခ, ဆက်ဆံရေး ပြဿနာ',
  },
  '예술, 종교, 학문': {
    'ko': '예술, 종교, 학문',
    'en': 'Arts, spirituality, academics',
    'ja': '芸術、宗教、学問',
    'zh': '艺术，宗教，学术',
    'vi': 'Nghệ thuật, tâm linh, học thuật',
    'th': 'ศิลปะ จิตวิญญาณ วิชาการ',
    'id': 'Seni, spiritualitas, akademis',
    'ms': 'Seni, kerohanian, akademik',
    'fr': 'Arts, spiritualité, études',
    'de': 'Kunst, Spiritualität, Wissenschaft',
    'es': 'Arte, espiritualidad, estudios',
    'pt': 'Arte, espiritualidade, estudos',
    'it': 'Arte, spiritualità, studi',
    'hi': 'कला, आध्यात्मिकता, शिक्षा',
    'ar': 'الفنون، الروحانية، الأكاديميات',
    'ru': 'Искусство, духовность, наука',
    'my': 'အနုပညာ, ဝိညာဉ်ရေး, ပညာရေး',
  },
};

/// 길흉 타입 한글 → 다국어
const Map<String, Map<String, String>> _fortuneTypeI18n = {
  '길': {
    'ko': '길', 'ja': '吉', 'zh': '吉', 'en': 'Auspicious',
    'vi': 'Tốt lành', 'th': 'มงคล', 'id': 'Beruntung', 'ms': 'Bertuah',
    'fr': 'Propice', 'de': 'Glückverheißend', 'es': 'Auspicioso', 'pt': 'Auspicioso',
    'it': 'Propizio', 'hi': 'शुभ', 'ar': 'ميمون', 'ru': 'Благоприятный', 'my': 'မင်္ဂလာ',
  },
  '흉': {
    'ko': '흉', 'ja': '凶', 'zh': '凶', 'en': 'Inauspicious',
    'vi': 'Xấu', 'th': 'อัปมงคล', 'id': 'Sial', 'ms': 'Malang',
    'fr': 'Néfaste', 'de': 'Unheilvoll', 'es': 'Desfavorable', 'pt': 'Desfavorável',
    'it': 'Infausto', 'hi': 'अशुभ', 'ar': 'نحس', 'ru': 'Неблагоприятный', 'my': 'အကြံအဖန်',
  },
  '평': {
    'ko': '평', 'ja': '平', 'zh': '平', 'en': 'Neutral',
    'vi': 'Bình thường', 'th': 'เป็นกลาง', 'id': 'Netral', 'ms': 'Neutral',
    'fr': 'Neutre', 'de': 'Neutral', 'es': 'Neutro', 'pt': 'Neutro',
    'it': 'Neutro', 'hi': 'तटस्थ', 'ar': 'محايد', 'ru': 'Нейтральный', 'my': 'ကြားနေ',
  },
  '길흉혼합': {
    'ko': '길흉혼합', 'ja': '吉凶混合', 'zh': '吉凶混合', 'en': 'Mixed',
    'vi': 'Hỗn hợp', 'th': 'ผสม', 'id': 'Campuran', 'ms': 'Campuran',
    'fr': 'Mixte', 'de': 'Gemischt', 'es': 'Mixto', 'pt': 'Misto',
    'it': 'Misto', 'hi': 'मिश्रित', 'ar': 'مختلط', 'ru': 'Смешанный', 'my': 'ရောစပ်',
  },
  '혼합': {
    'ko': '혼합', 'ja': '混合', 'zh': '混合', 'en': 'Mixed',
    'vi': 'Hỗn hợp', 'th': 'ผสม', 'id': 'Campuran', 'ms': 'Campuran',
    'fr': 'Mixte', 'de': 'Gemischt', 'es': 'Mixto', 'pt': 'Misto',
    'it': 'Misto', 'hi': 'मिश्रित', 'ar': 'مختلط', 'ru': 'Смешанный', 'my': 'ရောစပ်',
  },
};

/// 지장간 타입 한글 → 다국어
const Map<String, Map<String, String>> _jijangganTypeI18n = {
  '여기': {
    'ko': '여기', 'ja': '余気', 'zh': '余气', 'en': 'Residual',
    'vi': 'Dư khí', 'th': 'พลังคงเหลือ', 'id': 'Sisa', 'ms': 'Baki',
    'fr': 'Résiduel', 'de': 'Restlich', 'es': 'Residual', 'pt': 'Residual',
    'it': 'Residuo', 'hi': 'अवशिष्ट', 'ar': 'متبقي', 'ru': 'Остаточный', 'my': 'ကျန်ရှိ',
  },
  '중기': {
    'ko': '중기', 'ja': '中気', 'zh': '中气', 'en': 'Middle',
    'vi': 'Trung khí', 'th': 'พลังกลาง', 'id': 'Tengah', 'ms': 'Tengah',
    'fr': 'Médian', 'de': 'Mittel', 'es': 'Medio', 'pt': 'Médio',
    'it': 'Medio', 'hi': 'मध्य', 'ar': 'أوسط', 'ru': 'Средний', 'my': 'အလယ်',
  },
  '정기': {
    'ko': '정기', 'ja': '正気', 'zh': '正气', 'en': 'Main',
    'vi': 'Chính khí', 'th': 'พลังหลัก', 'id': 'Utama', 'ms': 'Utama',
    'fr': 'Principal', 'de': 'Haupt', 'es': 'Principal', 'pt': 'Principal',
    'it': 'Principale', 'hi': 'मुख्य', 'ar': 'رئيسي', 'ru': 'Основной', 'my': 'အဓိက',
  },
};

/// 신강/신약 레벨 한글 → 다국어
const Map<String, Map<String, String>> _singangLevelI18n = {
  '극신약': {
    'ko': '극신약', 'ja': '極身弱', 'zh': '极身弱', 'en': 'Extremely Weak',
    'vi': 'Cực yếu', 'th': 'อ่อนแอมาก', 'id': 'Sangat Lemah Sekali', 'ms': 'Amat Lemah',
    'fr': 'Extrêmement Faible', 'de': 'Äußerst Schwach', 'es': 'Extremadamente Débil', 'pt': 'Extremamente Fraco',
    'it': 'Estremamente Debole', 'hi': 'अत्यंत कमज़ोर', 'ar': 'ضعيف للغاية', 'ru': 'Крайне Слабый', 'my': 'အလွန်အားနည်း',
  },
  '대신약': {
    'ko': '대신약', 'ja': '大身弱', 'zh': '大身弱', 'en': 'Very Weak',
    'vi': 'Rất yếu', 'th': 'อ่อนแอมาก', 'id': 'Sangat Lemah', 'ms': 'Sangat Lemah',
    'fr': 'Très Faible', 'de': 'Sehr Schwach', 'es': 'Muy Débil', 'pt': 'Muito Fraco',
    'it': 'Molto Debole', 'hi': 'बहुत कमज़ोर', 'ar': 'ضعيف جداً', 'ru': 'Очень Слабый', 'my': 'အလွန်အားနည်း',
  },
  '신약': {
    'ko': '신약', 'ja': '身弱', 'zh': '身弱', 'en': 'Weak',
    'vi': 'Yếu', 'th': 'อ่อนแอ', 'id': 'Lemah', 'ms': 'Lemah',
    'fr': 'Faible', 'de': 'Schwach', 'es': 'Débil', 'pt': 'Fraco',
    'it': 'Debole', 'hi': 'कमज़ोर', 'ar': 'ضعيف', 'ru': 'Слабый', 'my': 'အားနည်း',
  },
  '중신약': {
    'ko': '중신약', 'ja': '中身弱', 'zh': '中身弱', 'en': 'Neutral Weak',
    'vi': 'Trung bình yếu', 'th': 'ค่อนข้างอ่อน', 'id': 'Agak Lemah', 'ms': 'Agak Lemah',
    'fr': 'Neutre Faible', 'de': 'Neutral Schwach', 'es': 'Neutro Débil', 'pt': 'Neutro Fraco',
    'it': 'Neutro Debole', 'hi': 'तटस्थ कमज़ोर', 'ar': 'محايد ضعيف', 'ru': 'Нейтрально Слабый', 'my': 'အလယ်အလတ် အားနည်း',
  },
  '중신강': {
    'ko': '중신강', 'ja': '中身強', 'zh': '中身强', 'en': 'Neutral Strong',
    'vi': 'Trung bình mạnh', 'th': 'ค่อนข้างแข็ง', 'id': 'Agak Kuat', 'ms': 'Agak Kuat',
    'fr': 'Neutre Fort', 'de': 'Neutral Stark', 'es': 'Neutro Fuerte', 'pt': 'Neutro Forte',
    'it': 'Neutro Forte', 'hi': 'तटस्थ मज़बूत', 'ar': 'محايد قوي', 'ru': 'Нейтрально Сильный', 'my': 'အလယ်အလတ် အားကောင်း',
  },
  '신강': {
    'ko': '신강', 'ja': '身強', 'zh': '身强', 'en': 'Strong',
    'vi': 'Mạnh', 'th': 'แข็งแกร่ง', 'id': 'Kuat', 'ms': 'Kuat',
    'fr': 'Fort', 'de': 'Stark', 'es': 'Fuerte', 'pt': 'Forte',
    'it': 'Forte', 'hi': 'मज़बूत', 'ar': 'قوي', 'ru': 'Сильный', 'my': 'အားကောင်း',
  },
  '대신강': {
    'ko': '대신강', 'ja': '大身強', 'zh': '大身强', 'en': 'Very Strong',
    'vi': 'Rất mạnh', 'th': 'แข็งแกร่งมาก', 'id': 'Sangat Kuat', 'ms': 'Sangat Kuat',
    'fr': 'Très Fort', 'de': 'Sehr Stark', 'es': 'Muy Fuerte', 'pt': 'Muito Forte',
    'it': 'Molto Forte', 'hi': 'बहुत मज़बूत', 'ar': 'قوي جداً', 'ru': 'Очень Сильный', 'my': 'အလွန်အားကောင်း',
  },
  '극신강': {
    'ko': '극신강', 'ja': '極身強', 'zh': '极身强', 'en': 'Extremely Strong',
    'vi': 'Cực mạnh', 'th': 'แข็งแกร่งที่สุด', 'id': 'Sangat Kuat Sekali', 'ms': 'Amat Kuat',
    'fr': 'Extrêmement Fort', 'de': 'Äußerst Stark', 'es': 'Extremadamente Fuerte', 'pt': 'Extremamente Forte',
    'it': 'Estremamente Forte', 'hi': 'अत्यंत मज़बूत', 'ar': 'قوي للغاية', 'ru': 'Крайне Сильный', 'my': 'အလွန်ဆုံးအားကောင်း',
  },
};

/// 특수 신살 한글 → 다국어
const Map<String, Map<String, String>> _specialSinsalI18n = {
  '천을귀인': {'ko': '천을귀인', 'ja': '天乙貴人', 'zh': '天乙贵人', 'en': 'Heavenly Noble'},
  '문창귀인': {'ko': '문창귀인', 'ja': '文昌貴人', 'zh': '文昌贵人', 'en': 'Academic Star'},
  '괴강살':   {'ko': '괴강살',   'ja': '魁罡殺',   'zh': '魁罡杀',   'en': 'Power Star'},
  '양인살':   {'ko': '양인살',   'ja': '羊刃殺',   'zh': '羊刃杀',   'en': 'Goat Blade'},
  '도화살':   {'ko': '도화살',   'ja': '桃花殺',   'zh': '桃花杀',   'en': 'Peach Blossom'},
  '천라지망': {'ko': '천라지망', 'ja': '天羅地網', 'zh': '天罗地网', 'en': 'Heaven Net Earth Snare'},
  '원진살':   {'ko': '원진살',   'ja': '怨嗔殺',   'zh': '怨嗔杀',   'en': 'Grudge Spirit'},
  '효신살':   {'ko': '효신살',   'ja': '梟神殺',   'zh': '枭神杀',   'en': 'Filial Spirit'},
  '고신살':   {'ko': '고신살',   'ja': '孤辰殺',   'zh': '孤辰杀',   'en': 'Solitary Spirit'},
  '과숙살':   {'ko': '과숙살',   'ja': '寡宿殺',   'zh': '寡宿杀',   'en': 'Overripe Spirit'},
  '백호살':   {'ko': '백호살',   'ja': '白虎殺',   'zh': '白虎杀',   'en': 'White Tiger'},
  '공망':     {'ko': '공망',     'ja': '空亡',     'zh': '空亡',     'en': 'Void'},
  '정상':     {'ko': '정상',     'ja': '正常',     'zh': '正常',     'en': 'Normal'},
};

/// 월령 상태 한글 → 다국어
const Map<String, Map<String, String>> _monthStatusI18n = {
  '득령': {
    'ko': '득령', 'ja': '得令', 'zh': '得令', 'en': 'In Season',
    'vi': 'Đắc lệnh', 'th': 'ตรงฤดู', 'id': 'Dalam Musim', 'ms': 'Dalam Musim',
    'fr': 'En Saison', 'de': 'In der Saison', 'es': 'En Temporada', 'pt': 'Na Estação',
    'it': 'In Stagione', 'hi': 'मौसम में', 'ar': 'في الموسم', 'ru': 'В Сезоне', 'my': 'ရာသီတွင်း',
  },
  '실령': {
    'ko': '실령', 'ja': '失令', 'zh': '失令', 'en': 'Out of Season',
    'vi': 'Thất lệnh', 'th': 'นอกฤดู', 'id': 'Di Luar Musim', 'ms': 'Di Luar Musim',
    'fr': 'Hors Saison', 'de': 'Außerhalb der Saison', 'es': 'Fuera de Temporada', 'pt': 'Fora de Estação',
    'it': 'Fuori Stagione', 'hi': 'मौसम के बाहर', 'ar': 'خارج الموسم', 'ru': 'Вне Сезона', 'my': 'ရာသီပြင်ပ',
  },
};

/// 합충 설명 한글 → 다국어
/// 천간합, 지지육합, 삼합, 방합, 형 등의 description 문자열 번역
const Map<String, Map<String, String>> _hapchungDescI18n = {
  // === 천간합 (5) ===
  '갑기합화토(甲己合化土) - 중정지합': {
    'ko': '갑기합화토(甲己合化土) - 중정지합',
    'en': 'Gap-Gi Harmony → Earth (甲己合化土) - Harmony of Balance',
    'ja': '甲己合化土 - 中正の合',
    'zh': '甲己合化土 - 中正之合',
  },
  '을경합화금(乙庚合化金) - 인의지합': {
    'ko': '을경합화금(乙庚合化金) - 인의지합',
    'en': 'Eul-Gyeong Harmony → Metal (乙庚合化金) - Harmony of Virtue',
    'ja': '乙庚合化金 - 仁義の合',
    'zh': '乙庚合化金 - 仁义之合',
  },
  '병신합화수(丙辛合化水) - 위엄지합': {
    'ko': '병신합화수(丙辛合化水) - 위엄지합',
    'en': 'Byeong-Sin Harmony → Water (丙辛合化水) - Harmony of Authority',
    'ja': '丙辛合化水 - 威厳の合',
    'zh': '丙辛合化水 - 威严之合',
  },
  '정임합화목(丁壬合化木) - 인수지합': {
    'ko': '정임합화목(丁壬合化木) - 인수지합',
    'en': 'Jeong-Im Harmony → Wood (丁壬合化木) - Harmony of Wisdom',
    'ja': '丁壬合化木 - 淫邪の合',
    'zh': '丁壬合化木 - 淫邪之合',
  },
  '무계합화화(戊癸合化火) - 무정지합': {
    'ko': '무계합화화(戊癸合化火) - 무정지합',
    'en': 'Mu-Gye Harmony → Fire (戊癸合化火) - Harmony of Passion',
    'ja': '戊癸合化火 - 無情の合',
    'zh': '戊癸合化火 - 无情之合',
  },

  // === 지지 육합 (6) ===
  '자축합토(子丑合土)': {
    'ko': '자축합토(子丑合土)',
    'en': 'Ja-Chuk Harmony → Earth (子丑合土)',
    'ja': '子丑合土',
    'zh': '子丑合土',
  },
  '인해합목(寅亥合木)': {
    'ko': '인해합목(寅亥合木)',
    'en': 'In-Hae Harmony → Wood (寅亥合木)',
    'ja': '寅亥合木',
    'zh': '寅亥合木',
  },
  '묘술합화(卯戌合火)': {
    'ko': '묘술합화(卯戌合火)',
    'en': 'Myo-Sul Harmony → Fire (卯戌合火)',
    'ja': '卯戌合火',
    'zh': '卯戌合火',
  },
  '진유합금(辰酉合金)': {
    'ko': '진유합금(辰酉合金)',
    'en': 'Jin-Yu Harmony → Metal (辰酉合金)',
    'ja': '辰酉合金',
    'zh': '辰酉合金',
  },
  '사신합수(巳申合水)': {
    'ko': '사신합수(巳申合水)',
    'en': 'Sa-Sin Harmony → Water (巳申合水)',
    'ja': '巳申合水',
    'zh': '巳申合水',
  },
  '오미합토(午未合土)': {
    'ko': '오미합토(午未合土)',
    'en': 'O-Mi Harmony → Earth (午未合土)',
    'ja': '午未合土',
    'zh': '午未合土',
  },

  // === 지지 삼합 (4) ===
  '인오술 화국(寅午戌 火局)': {
    'ko': '인오술 화국(寅午戌 火局)',
    'en': 'In-O-Sul Fire Formation (寅午戌 火局)',
    'ja': '寅午戌 火局',
    'zh': '寅午戌 火局',
  },
  '사유축 금국(巳酉丑 金局)': {
    'ko': '사유축 금국(巳酉丑 金局)',
    'en': 'Sa-Yu-Chuk Metal Formation (巳酉丑 金局)',
    'ja': '巳酉丑 金局',
    'zh': '巳酉丑 金局',
  },
  '신자진 수국(申子辰 水局)': {
    'ko': '신자진 수국(申子辰 水局)',
    'en': 'Sin-Ja-Jin Water Formation (申子辰 水局)',
    'ja': '申子辰 水局',
    'zh': '申子辰 水局',
  },
  '해묘미 목국(亥卯未 木局)': {
    'ko': '해묘미 목국(亥卯未 木局)',
    'en': 'Hae-Myo-Mi Wood Formation (亥卯未 木局)',
    'ja': '亥卯未 木局',
    'zh': '亥卯未 木局',
  },

  // === 지지 방합 (4) ===
  '인묘진 동방목(寅卯辰 東方木)': {
    'ko': '인묘진 동방목(寅卯辰 東方木)',
    'en': 'In-Myo-Jin Eastern Wood (寅卯辰 東方木)',
    'ja': '寅卯辰 東方木',
    'zh': '寅卯辰 东方木',
  },
  '사오미 남방화(巳午未 南方火)': {
    'ko': '사오미 남방화(巳午未 南方火)',
    'en': 'Sa-O-Mi Southern Fire (巳午未 南方火)',
    'ja': '巳午未 南方火',
    'zh': '巳午未 南方火',
  },
  '신유술 서방금(申酉戌 西方金)': {
    'ko': '신유술 서방금(申酉戌 西方金)',
    'en': 'Sin-Yu-Sul Western Metal (申酉戌 西方金)',
    'ja': '申酉戌 西方金',
    'zh': '申酉戌 西方金',
  },
  '해자축 북방수(亥子丑 北方水)': {
    'ko': '해자축 북방수(亥子丑 北方水)',
    'en': 'Hae-Ja-Chuk Northern Water (亥子丑 北方水)',
    'ja': '亥子丑 北方水',
    'zh': '亥子丑 北方水',
  },

  // === 지지 형 (11) ===
  '인사형(寅巳刑) - 무은지형': {
    'ko': '인사형(寅巳刑) - 무은지형',
    'en': 'In-Sa Punishment (寅巳刑) - Ungrateful',
    'ja': '寅巳刑 - 無恩之刑',
    'zh': '寅巳刑 - 无恩之刑',
  },
  '사신형(巳申刑) - 무은지형': {
    'ko': '사신형(巳申刑) - 무은지형',
    'en': 'Sa-Sin Punishment (巳申刑) - Ungrateful',
    'ja': '巳申刑 - 無恩之刑',
    'zh': '巳申刑 - 无恩之刑',
  },
  '신인형(申寅刑) - 무은지형': {
    'ko': '신인형(申寅刑) - 무은지형',
    'en': 'Sin-In Punishment (申寅刑) - Ungrateful',
    'ja': '申寅刑 - 無恩之刑',
    'zh': '申寅刑 - 无恩之刑',
  },
  '축술형(丑戌刑) - 지세지형': {
    'ko': '축술형(丑戌刑) - 지세지형',
    'en': 'Chuk-Sul Punishment (丑戌刑) - Bullying',
    'ja': '丑戌刑 - 持勢之刑',
    'zh': '丑戌刑 - 持势之刑',
  },
  '술미형(戌未刑) - 지세지형': {
    'ko': '술미형(戌未刑) - 지세지형',
    'en': 'Sul-Mi Punishment (戌未刑) - Bullying',
    'ja': '戌未刑 - 持勢之刑',
    'zh': '戌未刑 - 持势之刑',
  },
  '미축형(未丑刑) - 지세지형': {
    'ko': '미축형(未丑刑) - 지세지형',
    'en': 'Mi-Chuk Punishment (未丑刑) - Bullying',
    'ja': '未丑刑 - 持勢之刑',
    'zh': '未丑刑 - 持势之刑',
  },
  '자묘형(子卯刑) - 무례지형': {
    'ko': '자묘형(子卯刑) - 무례지형',
    'en': 'Ja-Myo Punishment (子卯刑) - Discourteous',
    'ja': '子卯刑 - 無禮之刑',
    'zh': '子卯刑 - 无礼之刑',
  },
  '진진자형(辰辰自刑)': {
    'ko': '진진자형(辰辰自刑)',
    'en': 'Jin Self-Punishment (辰辰自刑)',
    'ja': '辰辰自刑',
    'zh': '辰辰自刑',
  },
  '오오자형(午午自刑)': {
    'ko': '오오자형(午午自刑)',
    'en': 'O Self-Punishment (午午自刑)',
    'ja': '午午自刑',
    'zh': '午午自刑',
  },
  '유유자형(酉酉自刑)': {
    'ko': '유유자형(酉酉自刑)',
    'en': 'Yu Self-Punishment (酉酉自刑)',
    'ja': '酉酉自刑',
    'zh': '酉酉自刑',
  },
  '해해자형(亥亥自刑)': {
    'ko': '해해자형(亥亥自刑)',
    'en': 'Hae Self-Punishment (亥亥自刑)',
    'ja': '亥亥自刑',
    'zh': '亥亥自刑',
  },
};

/// 형(刑) 유형 이름 한글 → 다국어
const Map<String, Map<String, String>> _hyungTypeI18n = {
  '무은지형': {'ko': '무은지형', 'en': 'Ungrateful', 'ja': '無恩之刑', 'zh': '无恩之刑'},
  '지세지형': {'ko': '지세지형', 'en': 'Bullying', 'ja': '持勢之刑', 'zh': '持势之刑'},
  '무례지형': {'ko': '무례지형', 'en': 'Discourteous', 'ja': '無禮之刑', 'zh': '无礼之刑'},
  '자형': {'ko': '자형', 'en': 'Self-Punishment', 'ja': '自刑', 'zh': '自刑'},
};

/// 관계 타입 한글 → 다국어
const Map<String, Map<String, String>> _relationTypeI18n = {
  '육합': {'ko': '육합', 'en': 'Six Harmony', 'ja': '六合', 'zh': '六合'},
  '삼합': {'ko': '삼합', 'en': 'Three Harmony', 'ja': '三合', 'zh': '三合'},
  '반합': {'ko': '반합', 'en': 'Half Harmony', 'ja': '半合', 'zh': '半合'},
  '반합(왕지)': {'ko': '반합(왕지)', 'en': 'Half Harmony', 'ja': '半合(旺支)', 'zh': '半合(旺支)'},
  '방합': {'ko': '방합', 'en': 'Directional Combination', 'ja': '方合', 'zh': '方合'},
  '반방합': {'ko': '반방합', 'en': 'Half Directional', 'ja': '半方合', 'zh': '半方合'},
  '충': {'ko': '충', 'en': 'Clash', 'ja': '沖', 'zh': '冲'},
  '형': {'ko': '형', 'en': 'Punishment', 'ja': '刑', 'zh': '刑'},
  '파': {'ko': '파', 'en': 'Destruction', 'ja': '破', 'zh': '破'},
  '해': {'ko': '해', 'en': 'Harm', 'ja': '害', 'zh': '害'},
  '원진': {'ko': '원진', 'en': 'Grudge', 'ja': '怨嗔', 'zh': '怨嗔'},
  '합': {'ko': '합', 'en': 'Harmony', 'ja': '合', 'zh': '合'},
};

// ============================================================================
// 공개 API
// ============================================================================

/// 사주 용어 다국어 변환 유틸리티
class SajuI18n {
  SajuI18n._();

  /// 천간 한글 → locale별 표시명
  /// 예: ('무', 'en') → 'Mu', ('무', 'ko') → '무'
  static String cheongan(String hangul, String locale) {
    return _lookup(_cheonganI18n, hangul, locale);
  }

  /// 지지 한글 → locale별 표시명
  static String jiji(String hangul, String locale) {
    return _lookup(_jijiI18n, hangul, locale);
  }

  /// 오행 한글 → locale별 표시명
  static String oheng(String hangul, String locale) {
    return _lookup(_ohengI18n, hangul, locale);
  }

  /// 음양 한글 → locale별 표시명
  static String eumyang(String hangul, String locale) {
    return _lookup(_eumyangI18n, hangul, locale);
  }

  /// 띠 동물 한글 → locale별 표시명
  static String animal(String hangul, String locale) {
    return _lookup(_animalI18n, hangul, locale);
  }

  /// 천간 표시 형식: "무(戊)" 또는 "Mu(戊)" 등
  /// [hanja]는 cheongan_jiji.dart에서 가져옴
  static String cheonganWithHanja(String hangul, String hanja, String locale) {
    if (locale == 'ko') return '$hangul($hanja)';
    final localized = cheongan(hangul, locale);
    return '$localized($hanja)';
  }

  /// 지지 표시 형식
  static String jijiWithHanja(String hangul, String hanja, String locale) {
    if (locale == 'ko') return '$hangul($hanja)';
    final localized = jiji(hangul, locale);
    return '$localized($hanja)';
  }

  /// 십성(十神) 한글 → locale별 표시명
  /// 예: ('비견', 'en') → 'Companion'
  static String sipsin(String korean, String locale) {
    return _lookup(_sipsinI18n, korean, locale);
  }

  /// 십성 카테고리 한글 → locale별 표시명
  /// 예: ('비겁', 'en') → 'Companions'
  static String sipsinCategory(String korean, String locale) {
    return _lookup(_sipsinCategoryI18n, korean, locale);
  }

  /// 12운성 한글 → locale별 표시명
  /// 예: ('제왕', 'en') → 'Emperor'
  static String unsung(String korean, String locale) {
    return _lookup(_unsungI18n, korean, locale);
  }

  /// 12운성 의미 한글 → locale별 표시명
  static String unsungMeaning(String korean, String locale) {
    return _lookup(_unsungMeaningI18n, korean, locale);
  }

  /// 12신살 한글 → locale별 표시명
  /// 예: ('역마', 'en') → 'Post Horse'
  static String sinsal(String korean, String locale) {
    return _lookup(_sinsalI18n, korean, locale);
  }

  /// 12신살 의미 한글 → locale별 표시명
  static String sinsalMeaning(String korean, String locale) {
    return _lookup(_sinsalMeaningI18n, korean, locale);
  }

  /// 길흉 타입 한글 → locale별 표시명
  /// 예: ('길', 'en') → 'Auspicious'
  static String fortuneType(String korean, String locale) {
    return _lookup(_fortuneTypeI18n, korean, locale);
  }

  /// 지장간 타입 한글 → locale별 표시명
  static String jijangganType(String korean, String locale) {
    return _lookup(_jijangganTypeI18n, korean, locale);
  }

  /// 신강/신약 레벨 한글 → locale별 표시명
  static String singangLevel(String korean, String locale) {
    return _lookup(_singangLevelI18n, korean, locale);
  }

  /// 특수 신살 한글 → locale별 표시명 (범용)
  /// 12신살에 없는 특수 신살도 처리
  static String specialSinsal(String korean, String locale) {
    // 먼저 12신살 테이블에서 찾기
    final fromTwelve = _sinsalI18n[korean];
    if (fromTwelve != null) {
      return fromTwelve[locale] ?? fromTwelve['en'] ?? korean;
    }
    // 특수 신살 테이블에서 찾기
    return _lookup(_specialSinsalI18n, korean, locale);
  }

  /// 월령 상태 한글 → locale별 표시명
  static String monthStatus(String korean, String locale) {
    return _lookup(_monthStatusI18n, korean, locale);
  }

  /// 합충 설명 한글 → locale별 표시명
  /// 예: ('갑기합화토(甲己合化土) - 중정지합', 'en') → 'Gap-Gi Harmony → Earth ...'
  static String hapchungDesc(String korean, String locale) {
    return _lookup(_hapchungDescI18n, korean, locale);
  }

  /// 형(刑) 유형 한글 → locale별 표시명
  /// 예: ('무은지형', 'en') → 'Ungrateful'
  static String hyungType(String korean, String locale) {
    return _lookup(_hyungTypeI18n, korean, locale);
  }

  /// 관계 타입 한글 → locale별 표시명
  /// 예: ('충', 'en') → 'Clash'
  static String relationType(String korean, String locale) {
    return _lookup(_relationTypeI18n, korean, locale);
  }

  // 내부 조회 헬퍼
  static String _lookup(
    Map<String, Map<String, String>> table,
    String key,
    String locale,
  ) {
    final entry = table[key];
    if (entry == null) return key; // fallback: 원본 반환
    // ko, ja, zh는 전용 값, 나머지는 en 사용
    return entry[locale] ?? entry['en'] ?? key;
  }
}
