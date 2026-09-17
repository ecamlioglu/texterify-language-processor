# Texterify Renamer — macOS uygulama planı

Tarih: 16 Eylül 2026. Bu belge ilk tasarım planıdır. Aynı gün MVP aynı repo içindeki `macos/` altında uygulandı. Gerçek teslim ve doğrulama durumu için [MAC_APP_VALIDATION.md](MAC_APP_VALIDATION.md) ve [macOS kullanım belgesi](../macos/README.md) esas alınmalıdır.

## 1. Ürün kararı

Menü çubuğunda yaşayan, tamamen yerel çalışan küçük bir macOS aracı. Kullanıcı Texterify'dan indirdiği ZIP'i bırakır, hangi dosyaların yeniden adlandırılacağını görür ve **ZIP’i indir** düğmesiyle çıktıyı kaydeder. İlk sürüm tek ZIP ve tek etkin config üzerinde çalışır.

Önerilen ad: **Texterify Renamer**. Arayüz dili ilk sürümde Türkçe; dosya adları, dil kodları ve config anahtarları olduğu gibi korunur.

Başarı ölçütü: günlük kullanımda **dosyayı bırak → ZIP’i indir**. Config bir kez ayarlandıktan sonra tekrar düzenlemek gerekmez.

## 2. Mevcut projeden doğrulananlar

İncelenen kaynaklar:

- `src/texterify_processor/controllers/processor_controller.py`: doğrulama, çıktı çakışması, geçici klasöre açma, yeniden adlandırma ve paketleme.
- `src/texterify_processor/services/`: config, arşiv, dosya eşleştirme ve çıktı adlandırma.
- `src/texterify_processor/models/config.py` ve `config/language_mappings.json`: mevcut config sözleşmesi.
- `src/Doktar App-16-09-2026-1789557129283.zip` ve `src/lang_files_16_09.zip`: gerçek girdi ve beklenen çıktı.

Gerçek girdi 11 JSON içeriyor: ar, bg, en, fr, el, hu, it, pt, ro, es, tr. Çıktıda bunlar config'teki UUID dosya adlarına dönüşüyor. Dosya kümeleri tam eşleşiyor; her dosyanın açılmış içeriği bayt düzeyinde aynı. ZIP dosyasının sıkıştırılmış baytlarının aynı olması gerekmiyor.

Örnek eşleştirmeler:

| Girdi | Çıktı |
| --- | --- |
| en.json | 24c9b00d-d028-4e04-a1aa-f04d2dcae2c3.json |
| tr.json | 26c7ace9-13fc-43b8-9988-2384fe670d03.json |
| fr.json | 835a7c06-9e18-4ff5-8087-9e41cd2c9e72.json |

Mevcut davranış: dosya uzantısından bağımsız olarak son uzantı öncesindeki ad eşleştirilir; büyük/küçük harf duyarlılığı config'e bağlıdır. Alt klasörlerde de eşleşme aranır. Eşleşmeyen dosyalar yerinde tutulur. Çıktı adı işlem tarihinden üretilir; girdinin dosya adındaki tarih kullanılmaz. Çıktı giriş dosyasının yanına yazılır; çakışma terminalde sorulur.

Doğrulama:

- `python3 tests/run_tests.py`: **18 test geçti**, sıfır hata/başarısızlık/atlama.
- Gerçek girdinin geçici klasörde `src/texterify_processor.py` ile işlenmesi başarılı; üretilen ZIP'in adları ve açılmış içerikleri verilen çıktıyla eşleşti.
- `src/main.py` aynı denemede hata verdi: `module 'texterify_processor' has no attribute 'TexterifyProcessor'`. Geçen testler bu giriş noktasının çalıştığını kanıtlamıyor.

Mac uygulaması tasarımını etkileyen eksikler:

1. Config yüklenemezse yalnızca en/tr içeren varsayılana dönülüyor. Uygulamada hatalı config açıkça gösterilmeli ve işlem durmalı.
2. `preserve_extensions` ve `backup_original` modele okunuyor fakat dönüşümde uygulanmıyor. Çalışan ayarlarmış gibi anahtarlı seçenek olarak sunulmamalı.
3. Dosya yeniden adlandırma hataları tek tek yutulabiliyor; başka dosyalar işlendiğinde genel sonuç başarılı olabiliyor. Yeni uygulamada kısmi işlem sessizce başarılı sayılmamalı.
4. Hedef ad çakışmaları, güvenli dosya adı kuralları ve arşiv kaynak sınırları için açık ön kontrol gerekiyor.
5. Arşivdeki dilleri tanımlayan yardımcı kod etkin config yerine varsayılan config kullanıyor. Önizleme ve gerçek işlem aynı eşleştirme planını kullanmalı.
6. Paket ile eski modülün aynı adı taşıması ve console bağımlılıkları doğrudan GUI sarmalamasını zorlaştırıyor.

## 3. Günlük kullanım

### Boş durum

- Menü çubuğunda tek renkli, sistem temasına uyumlu simge; Dock'ta sürekli simge yok.
- Tıklanınca yaklaşık 380 pt genişliğinde kompakt panel.
- Başlık: Texterify Renamer. Alt satır: etkin config adı, başlangıç için **Doktar**.
- Ana alan: **Texterify ZIP’ini buraya bırak**. Alternatif: **Dosya seç…**.
- Alt bölüm: **Ayarlar…** ve **Çıkış**. Tek config varken profil seçici gösterilmez.

### Dosya bırakıldı

İki giriş de aynı işi başlatır: açık panelin üzerine bırakma veya doğrudan menü çubuğu simgesinin üzerine bırakma. İkincisi ilk prototipin kabul koşuludur; yalnızca panelde çalışan bir demo bu gereksinimi karşılamaz. Tarayıcıdan önce yerel diske indirilmiş ZIP kabul edilir; indirme bağlantısı ayrı bir özellik değildir.

Dosya arka planda incelenir. Panel açılır ve şu bilgiler gösterilir:

- Girdi dosyasının adı.
- **11 dosya yeniden adlandırılacak** özeti.
- Açılabilir **Değişiklikleri göster** listesi: kaynak → hedef. Uzun UUID'ler buradadır.
- Çıktı adı: **lang_files_16_09.zip**.
- Kayıt yeri: **İndirilenler** veya kullanıcının seçtiği klasör.
- Tek ana eylem: **ZIP’i indir**.

Önizlemede etkin config'in anlık kopyası tutulur. Config değiştirilirse plan yeniden hesaplanır; eski önizleme ile yeni config kullanılarak çıktı oluşturulmaz.

### Kaydetme ve tamamlanma

**ZIP’i indir**, dosyayı yerel olarak üretip seçilmiş klasöre kaydeder. İlk kullanımda native klasör seçimiyle İndirilenler önerilir ve yetki alınır; sonraki kullanımlar tek tıklamadır. Küçük ikincil eylem **Farklı kaydet…**, native kayıt penceresini açar. Kayıt penceresini iptal etmek önizlemeye geri döndürür.

Çakışmada varsayılan yeni ad `lang_files_16_09_1.zip`, ardından `_2` olur. Var olan çıktı otomatik ezilmez. Kaynak ZIP hiçbir durumda hedef dosya olamaz. Seçilen nihai ad kaydetmeden önce görünür.

Tamamlanınca **Kaydedildi**, dosya adı, **Finder’da göster** ve **Yeni dosya** eylemleri görünür. Popover kapansa da devam eden iş sürer; tekrar açıldığında durum korunur. İşlem sürerken ikinci girdi kabul edilmez; kullanıcıya mevcut işlemi bitirmesi veya iptal etmesi söylenir.

### Hata ve uyarı davranışı

| Durum | Uygulama davranışı |
| --- | --- |
| ZIP değil / bozuk veya şifreli ZIP | Anlaşılır hata; çıktı üretme |
| Hiçbir dosya eşleşmedi | İndirmeyi kapat; config'e gitme eylemi sun |
| Bazı dosyalar eşleşmedi | Adlarını göster; değişmeden korunacaklarını belirt |
| Config'teki bazı diller arşivde yok | Bilgilendir; bunu zorunlu dil eksikliği sayma |
| Aynı hedefe giden dosyalar veya mevcut hedefle çakışma | İşlemi durdur; çakışan adları göster |
| Hatalı config | Önceki geçerli config'i koru; kaydetme/uygulama başarısızlığını göster |
| Klasöre erişim kayboldu | **Klasör seç…** ile erişimi yenile |
| Disk dolu / iptal / yazma hatası | Eksik çıktıyı temizle; tamamlandı deme |

## 4. Ayarlar: küçük, ayrı bir pencere

Yaklaşık 660 × 520 pt, yeniden boyutlandırılabilir native pencere. İki bölüm yeterli: **Eşleştirmeler** ve **Çıktı**. Ayarlar panel açık kalmadan da düzenlenebilir.

**Eşleştirmeler**

- Dil kodu ve hedef dosya adı sütunları; satır ekleme/silme/düzenleme.
- **Config içe aktar…**, **Config dışa aktar…**, **JSON’u göster**.
- Kaydet/iptal ile taslak düzenleme; geçersiz değişiklik etkin config'i bozmaz.
- Boş değer, yinelenen/harf duyarsız eşdeğer kaynak, yinelenen hedef ve yol içeren hedef adlarına satır içinde hata.
- Hedef adın UUID olması zorunlu değil; mevcut config gibi özel dosya adları da desteklenir.
- Kaynak eşleştirme mevcut son uzantı öncesi ada göre yapılır; `.json` zorunluluğu sessizce eklenmez.

**Çıktı**

- Dosya adı ön eki: `lang_files`.
- Tarih biçimi: okunabilir seçenekler **16_09**, **20260916**, **2026-09-16**; yanında canlı çıktı adı örneği.
- Kayıt klasörü ve **Her seferinde sor** seçeneği.
- Çakışma davranışı: **Numara ekle** (varsayılan) veya **Bana sor**.
- Gelişmiş bölümde büyük/küçük harf duyarlılığı.
- Görünüm: Sistem / Açık / Koyu. Başlangıç tercihi Sistem.

Config sözleşmesi: mevcut `language_mappings` ve `settings.output_format` içe aktarılabilir. İlk sürümde `%d_%m`, `%Y%m%d`, `%Y-%m-%d`, `%Y-%m-%d_%H%M` biçimleri açıkça desteklenir; başka bir biçim varsa anlaşılır doğrulama hatasıyla kullanıcıdan seçim istenir. Python tarih biçimi metni doğrudan Swift DateFormatter'a verilmez.

`preserve_extensions=false` ve `backup_original=false` uyumluluk için korunabilir. Bunlar `true` ise özellik destekleniyormuş gibi işlem yapılmaz; içe aktarma açıklama ile durur. Kaynağı korumak zaten yeni uygulamanın değişmez kuralıdır. Çıktı uzantısı ilk sürümde `.zip` olmalıdır. `_metadata` ve diğer açıklama alanları içe/dışa aktarımda korunur. Bilinmeyen işlem ayarları açıkça bildirilir.

Uygulamaya özgü tercihler (tema, klasör yetkisi, çakışma tercihi) dönüştürme config'inden ayrı saklanır. Böylece dışa aktarılan işlem config'i CLI ile paylaşılabilir. Birden fazla config/profil yönetimi ikinci sürümdedir.

## 5. Görsel yaklaşım

Sistem fontu, SF Symbols, sistemle uyumlu açık/koyu yüzeyler, tek vurgu rengi. Teknik değerlerde eş aralıklı font. Geniş pazarlama başlıkları yerine dosya ve işlem odaklı kısa metinler. Normal kullanımda terminal çıktısı gösterilmez; hata ayrıntısı gerektiğinde açılır ve kopyalanabilir.

Ana panelde yalnızca o anki dosya ve işlem bulunur. Dosya listesi gerektiğinde açılır. Başarı ve hata yalnızca renkle anlatılmaz; metin ve simge birlikte kullanılır. Klavye erişimi, VoiceOver etiketleri ve büyük metinde taşmama kabul testine dahildir.

## 6. Teknik tercih

**Öneri: SwiftUI arayüz + ince AppKit menü çubuğu katmanı + Swift işlem çekirdeği.** İlk plan macOS 13 varsayımıyla hazırlanmıştı. Kullanıcının en yeni Liquid Glass talebiyle uygulanan hedef macOS 27 / Xcode 27 / Swift 6.4 olarak güncellendi; güncel ekran akışı için `macos/README.md` geçerlidir.

- `NSStatusItem` ve `NSPopover`: menü çubuğu simgesi, doğrudan simgeye bırakma, açılma/kapanma ve odak yönetimi. SwiftUI ekranları `NSHostingView` / `NSHostingController` ile barındırılır.
- Sadece simgeye tıklayıp panelde dosya bırakmak hedeflenseydi `MenuBarExtra(.window)` daha kısa bir seçenek olurdu. Buradaki doğrudan simgeye bırakma hedefi nedeniyle AppKit davranışı ilk prototipte test edilir.
- `RenamerCore`: arşiv ön kontrolü, eşleştirme planı, çıktı adlandırma ve yazma. Console veya UI bağımlılığı yoktur.
- ZIP okuma/yazma için Swift Package Manager üzerinden sürümü sabitlenmiş ZIPFoundation; JSON config için Codable.
- Büyük işlemler ana UI iş parçacığından ayrılır; ilerleme ve iptal desteklenir. Küçük dosyalarda yapay yüzde veya bekleme eklenmez.
- Etkin config Application Support altında, ufak tercihler UserDefaults'ta saklanır. Tek config için veritabanı gerekmez.
- Kullanıcının seçtiği klasör için sandbox kapsamlı erişim/bookmark yaşam döngüsü uygulanır. Yetki kalıcılığı yeniden açılışta test edilir.

Python çekirdeği küçük olduğu için Swift'e taşımak bu ürün için makul bir maliyettir. Alternatif olan Python runtime'ını paketleyip subprocess ile çağırmak ilk prototipi hızlandırabilir; ancak dağıtım, console prompt'ları, süreç haberleşmesi ve runtime bakımını beraberinde getirir. Web tabanlı masaüstü kabuğunun platformlar arası faydası ise yalnızca macOS hedeflenen bu kapsamda öncelik değildir.

Mevcut CLI yerinde tutulur. Swift çekirdeği, iki uygulamanın paylaştığı fixture/manifest testleriyle doğrulanır; farklı dillerde iki implementasyonun zamanla ayrışması bu sözleşmeyle kontrol edilir.

Önerilen yeni yapı:

```text
macos/TexterifyRenamer/
  App/                  # yaşam döngüsü, status item, popover
  Features/Import/      # bırakma, önizleme, sonuç
  Features/Settings/    # eşleştirmeler, çıktı tercihleri
  Core/                 # planlama, config, arşiv ve yazma
  Tests/                # çekirdek ve macOS akış testleri
tests/fixtures/         # Python/Swift için ortak davranış örnekleri
```

İşleme modeli iki aşamalı olur: `inspect(input, config) → plan` ve `export(plan, destination) → result`. Plan kaynak/hedef göreli yollarını, değişmeden korunacak dosyaları, uyarıları ve config anlık kopyasını taşır. Önizleme sonrası girdi değiştirilmişse plan geçersizleşir ve yeniden incelenir.

Ön kontrolde güvenli göreli arşiv yolları, yinelenen girişler, hedef çakışmaları, symlink girdileri ve açılmış toplam boyut/dosya sayısı sınırları kontrol edilir. İlk sürüm için 100 MB kaynak ZIP, 500 MB açılmış içerik ve 10.000 giriş önerilir; gerçek örneğin yaklaşık 3,6 MB açılmış boyutuna göre geniş pay vardır. Şifreli arşivler ve symlink girdileri ilk sürümde reddedilir. Çıktı doğrudan hedefin üstüne yazılmaz: aynı hedef klasörde geçici dosya üretilir, başarıyla kapanıp doğrulandıktan sonra nihai ada atomik olarak alınır. Eşleşmeyen dosyaların içerikleri ve klasör konumları korunur.

## 7. Uygulama aşamaları

| Aşama | İş | Bitti sayılması için |
| --- | --- | --- |
| 1 — Davranış sözleşmesi | Gerçek örneklerden ad/içerik manifesti, ek sentetik fixture'lar, config kuralları | Girdi/çıktı eşleşmesi ve bütün hata politikaları yazılı; CLI referansı sabit |
| 2 — macOS etkileşim prototipi | Menü simgesi, SwiftUI panel, simgeye/panele bırakma, dosya seçme, kayıt penceresi | Finder'dan iki hedefe de ZIP bırakılabiliyor; popover odak ve pencere iptalleri doğru |
| 3 — Swift çekirdeği | Config okuma, önizleme planı, ZIP yazma, numaralı ad, iptal | Gerçek 11 dil örneği ve sentetik kenar durum testleri geçiyor; içerik kaybı yok |
| 4 — Kullanılabilir MVP | Gerçek önizleme/indirme, ayarlar, JSON içe/dışa aktarım, klasör yetkisi | Yeni kurulumdan itibaren terminal gerektirmeden tam akış; yeniden başlatmada tercihler korunuyor |
| 5 — Dağıtım | Uygulama simgesi, release build, kurulum paketi, hedef cihaz testi | Kopyalanıp açılabilen `.app`; paylaşılacak sürümde imza/notarization ve temiz Mac kontrolü |

Planlama tahmini: bir geliştirici için yaklaşık **6–9 iş günü**; 1 gün sözleşme/prototip, 2–3 gün çekirdek, 2–3 gün UI/ayarlar, 1–2 gün doğrulama/paketleme. Bu bir taahhüt değil; simgeye bırakma, hedef macOS ve imzalama ortamı aşama 2 sonunda tahmini netleştirir. Apple hesap/sertifika beklemeleri dahil değildir.

## 8. Kabul testleri

- Gerçek örneğin 11 dosyası doğru hedef adları ve aynı açılmış dosya baytlarıyla üretilmeli; orijinal girdinin hash'i değişmemeli.
- Alt klasörler, eşleşmeyen metadata, Türkçe/Unicode adlar, harf duyarlılığı ve özel hedef adları korunmalı.
- Yeniden adlandırma zinciri, aynı klasörde hedef çakışması ve harf duyarsız eşdeğer hedefler kontrollü ele alınmalı; veri kaybı olmamalı.
- Hatalı JSON/config, hiç eşleşme olmaması, bozuk/şifreli ZIP, aşırı büyük arşiv, yinelenen giriş ve yol ihlalleri denenmeli.
- Aynı gün tekrar indirme, mevcut dosya çakışması, kaynak üstüne yazma girişimi, kayıt iptali, disk/yazma hatası ve kaybolan klasör yetkisi denenmeli.
- Önizleme sonrası config/girdi değişimi eski planı kullanmamalı.
- Simgeye ve açık panele Finder'dan bırakma; indirilen dosyayı tarayıcıdan sürükleme; çoklu monitör, tam ekran uygulama ve popover yeniden açma gerçek macOS oturumunda test edilmeli. Dosya URL'si göndermeyen tarayıcı sürüklemelerinde Finder/Dosya seç akışı kullanılmalı.
- Açık/koyu tema, klavye, VoiceOver ve ayarlardaki uzun dosya adları kontrol edilmeli.
- Apple Silicon hedefte release testi zorunlu; Intel desteklenecekse ayrıca build ve cihaz testi yapılmalı. Universal binary üretmek tek başına Intel çalışma kanıtı sayılmaz.

İlk sürüm sonrasına bırakılanlar: çoklu profil, toplu ZIP kuyruğu, işlem geçmişi, klasör izleme, Texterify API bağlantısı, otomatik güncelleme ve oturum açılışında başlatma. İlk sürüm tamamen çevrimdışı işler.

## 9. Teknik kaynaklar ve mevcut teslim durumu

- [Apple — MenuBarExtra](https://developer.apple.com/documentation/swiftui/menubarextra)
- [Apple — Menü çubuğu pencereleri, WWDC22](https://developer.apple.com/videos/play/wwdc2022/10061/)
- [Apple — NSStatusItem](https://developer.apple.com/documentation/appkit/nsstatusitem)
- [Apple — NSDraggingDestination](https://developer.apple.com/documentation/appkit/nsdraggingdestination)
- [ZIPFoundation — kaynak ve kullanım](https://github.com/weichsel/ZIPFoundation)
- [Apple — macOS notarization](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)

Bu çalışmada kaynak uygulama kodu/config değişmedi; plan ve ayrı bir etkileşimli arayüz taslağı hazırlandı. Swift build, gerçek menü çubuğu davranışı, sandbox yetkileri ve imzalı dağıtım henüz uygulanmadı/test edilmedi. Başlangıçtaki eski ZIP silinmeleri ve yeni ZIP dosyaları kullanıcı değişikliği olarak korundu.
