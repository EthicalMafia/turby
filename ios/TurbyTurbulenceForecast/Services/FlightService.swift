import Foundation

nonisolated struct FlightSuggestion: Sendable, Identifiable {
    let flight: String
    let dep: String
    let arr: String
    let airline: String
    let depCity: String
    let arrCity: String
    let depTimeLocal: String?
    let arrTimeLocal: String?
    let status: String?
    let flightIndex: Int
    var id: String { "\(flight)_\(flightIndex)" }
}

@Observable
@MainActor
class FlightService {
    var isLoading = false
    var errorMessage: String?
    var autocompleteSuggestions: [FlightSuggestion] = []
    var autocompleteFlights: [ADBFlightResponse] = []
    var isLoadingAutocomplete = false

    private var autocompleteTask: Task<Void, Never>?
    private var lastAutocompleteQuery = ""

    private let weatherService = AviationWeatherService()
    private let meteoService = OpenMeteoService()
    private let turbulenceEngine = TurbulenceEngine()
    private let geoResolver = GeoRegionResolver()

    private var aeroDataBox: AeroDataBoxService? {
        let key = APIKeyStore.aeroDataBoxKey
        guard !key.isEmpty else { return nil }
        return AeroDataBoxService(apiKey: key)
    }

    private let airportDatabase: [String: (name: String, city: String, lat: Double, lon: Double)] = [
        // North America - USA Major
        "JFK": ("John F. Kennedy International", "New York", 40.6413, -73.7781),
        "LAX": ("Los Angeles International", "Los Angeles", 33.9425, -118.4081),
        "ORD": ("O'Hare International", "Chicago", 41.9742, -87.9073),
        "ATL": ("Hartsfield-Jackson International", "Atlanta", 33.6407, -84.4277),
        "DFW": ("Dallas/Fort Worth International", "Dallas", 32.8998, -97.0403),
        "SFO": ("San Francisco International", "San Francisco", 37.6213, -122.3790),
        "MIA": ("Miami International", "Miami", 25.7959, -80.2870),
        "DEN": ("Denver International", "Denver", 39.8561, -104.6737),
        "SEA": ("Seattle-Tacoma International", "Seattle", 47.4502, -122.3088),
        "IAH": ("George Bush Intercontinental", "Houston", 29.9902, -95.3368),
        "EWR": ("Newark Liberty International", "Newark", 40.6895, -74.1745),
        "BOS": ("Boston Logan International", "Boston", 42.3656, -71.0096),
        "DTW": ("Detroit Metropolitan", "Detroit", 42.2124, -83.3534),
        "MSP": ("Minneapolis-St. Paul International", "Minneapolis", 44.8848, -93.2223),
        "FLL": ("Fort Lauderdale-Hollywood International", "Fort Lauderdale", 26.0726, -80.1527),
        "MCO": ("Orlando International", "Orlando", 28.4312, -81.3081),
        "CLT": ("Charlotte Douglas International", "Charlotte", 35.2140, -80.9431),
        "PHX": ("Phoenix Sky Harbor International", "Phoenix", 33.4373, -112.0078),
        "IAD": ("Washington Dulles International", "Washington D.C.", 38.9531, -77.4565),
        "DCA": ("Ronald Reagan Washington National", "Washington D.C.", 38.8512, -77.0402),
        "SAN": ("San Diego International", "San Diego", 32.7336, -117.1897),
        "MDW": ("Chicago Midway International", "Chicago", 41.7868, -87.7522),
        "DAL": ("Dallas Love Field", "Dallas", 32.8481, -96.8512),
        "HOU": ("William P. Hobby", "Houston", 29.6454, -95.2789),
        "BWI": ("Baltimore/Washington International", "Baltimore", 39.1774, -76.6684),
        "ANC": ("Ted Stevens Anchorage International", "Anchorage", 61.1743, -149.9983),
        "LAS": ("Harry Reid International", "Las Vegas", 36.0840, -115.1537),
        "SLC": ("Salt Lake City International", "Salt Lake City", 40.7884, -111.9778),
        "PHL": ("Philadelphia International", "Philadelphia", 39.8721, -75.2411),
        "LGA": ("LaGuardia", "New York", 40.7769, -73.8740),
        "BNA": ("Nashville International", "Nashville", 36.1263, -86.6774),
        "AUS": ("Austin-Bergstrom International", "Austin", 30.1975, -97.6664),
        "RDU": ("Raleigh-Durham International", "Raleigh", 35.8776, -78.7875),
        "MCI": ("Kansas City International", "Kansas City", 39.2976, -94.7139),
        "SJC": ("San Jose International", "San Jose", 37.3626, -121.9290),
        "OAK": ("Oakland International", "Oakland", 37.7213, -122.2208),
        "SMF": ("Sacramento International", "Sacramento", 38.6954, -121.5908),
        "TPA": ("Tampa International", "Tampa", 27.9755, -82.5332),
        "PDX": ("Portland International", "Portland", 45.5898, -122.5951),
        "STL": ("St. Louis Lambert International", "St. Louis", 38.7487, -90.3700),
        "IND": ("Indianapolis International", "Indianapolis", 39.7173, -86.2944),
        "CLE": ("Cleveland Hopkins International", "Cleveland", 41.4117, -81.8498),
        "PIT": ("Pittsburgh International", "Pittsburgh", 40.4915, -80.2329),
        "CMH": ("John Glenn Columbus International", "Columbus", 39.9980, -82.8919),
        "MKE": ("General Mitchell International", "Milwaukee", 42.9472, -87.8966),
        "MSY": ("Louis Armstrong New Orleans International", "New Orleans", 29.9934, -90.2580),
        "CVG": ("Cincinnati/Northern Kentucky International", "Cincinnati", 39.0488, -84.6678),
        "HNL": ("Daniel K. Inouye International", "Honolulu", 21.3187, -157.9225),
        "OGG": ("Kahului", "Maui", 20.8986, -156.4305),
        "SJU": ("Luis Munoz Marin International", "San Juan", 18.4394, -66.0018),
        // Canada
        "YYZ": ("Toronto Pearson International", "Toronto", 43.6777, -79.6248),
        "YVR": ("Vancouver International", "Vancouver", 49.1967, -123.1815),
        "YUL": ("Montréal-Trudeau International", "Montréal", 45.4706, -73.7408),
        "YYC": ("Calgary International", "Calgary", 51.1215, -114.0076),
        "YEG": ("Edmonton International", "Edmonton", 53.3097, -113.5800),
        "YOW": ("Ottawa Macdonald-Cartier International", "Ottawa", 45.3225, -75.6692),
        "YHZ": ("Halifax Stanfield International", "Halifax", 44.8808, -63.5086),
        "YWG": ("Winnipeg James Armstrong Richardson International", "Winnipeg", 49.9100, -97.2399),
        // Mexico & Caribbean
        "MEX": ("Mexico City International", "Mexico City", 19.4363, -99.0721),
        "CUN": ("Cancun International", "Cancun", 21.0365, -86.8771),
        "GDL": ("Guadalajara International", "Guadalajara", 20.5218, -103.3111),
        "SJD": ("San Jose del Cabo International", "Los Cabos", 23.1518, -109.7215),
        "PVR": ("Puerto Vallarta International", "Puerto Vallarta", 20.6801, -105.2544),
        "MTY": ("Monterrey International", "Monterrey", 25.7785, -100.1069),
        "SDQ": ("Las Americas International", "Santo Domingo", 18.4297, -69.6688),
        "PUJ": ("Punta Cana International", "Punta Cana", 18.5674, -68.3634),
        "NAS": ("Lynden Pindling International", "Nassau", 25.0390, -77.4662),
        "MBJ": ("Sangster International", "Montego Bay", 18.5037, -77.9134),
        "KIN": ("Norman Manley International", "Kingston", 17.9357, -76.7875),
        "HAV": ("Jose Marti International", "Havana", 22.9892, -82.4091),
        "AUA": ("Queen Beatrix International", "Oranjestad", 12.5014, -70.0152),
        "SXM": ("Princess Juliana International", "Philipsburg", 18.0410, -63.1089),
        // UK & Ireland
        "LHR": ("London Heathrow", "London", 51.4700, -0.4543),
        "LGW": ("London Gatwick", "London", 51.1537, -0.1821),
        "STN": ("London Stansted", "London", 51.8860, 0.2389),
        "LTN": ("London Luton", "London", 51.8747, -0.3684),
        "MAN": ("Manchester Airport", "Manchester", 53.3537, -2.2750),
        "EDI": ("Edinburgh Airport", "Edinburgh", 55.9500, -3.3725),
        "BHX": ("Birmingham Airport", "Birmingham", 52.4539, -1.7480),
        "GLA": ("Glasgow Airport", "Glasgow", 55.8642, -4.4331),
        "BRS": ("Bristol Airport", "Bristol", 51.3827, -2.7191),
        "LCY": ("London City Airport", "London", 51.5053, 0.0553),
        "DUB": ("Dublin Airport", "Dublin", 53.4264, -6.2499),
        "SNN": ("Shannon Airport", "Shannon", 52.7020, -8.9248),
        "ORK": ("Cork Airport", "Cork", 51.8413, -8.4911),
        // France
        "CDG": ("Charles de Gaulle", "Paris", 49.0097, 2.5479),
        "ORY": ("Paris Orly", "Paris", 48.7233, 2.3794),
        "NCE": ("Nice Côte d'Azur", "Nice", 43.6584, 7.2159),
        "LYS": ("Lyon-Saint Exupéry", "Lyon", 45.7256, 5.0811),
        "MRS": ("Marseille Provence", "Marseille", 43.4393, 5.2214),
        // Germany
        "FRA": ("Frankfurt Airport", "Frankfurt", 50.0379, 8.5622),
        "MUC": ("Munich Airport", "Munich", 48.3537, 11.7750),
        "BER": ("Berlin Brandenburg", "Berlin", 52.3667, 13.5033),
        "DUS": ("Düsseldorf Airport", "Düsseldorf", 51.2895, 6.7668),
        "HAM": ("Hamburg Airport", "Hamburg", 53.6304, 9.9882),
        "CGN": ("Cologne Bonn", "Cologne", 50.8659, 7.1427),
        "STR": ("Stuttgart Airport", "Stuttgart", 48.6899, 9.2220),
        // Netherlands, Belgium, Switzerland, Austria
        "AMS": ("Amsterdam Schiphol", "Amsterdam", 52.3105, 4.7683),
        "BRU": ("Brussels Airport", "Brussels", 50.9010, 4.4844),
        "ZRH": ("Zurich Airport", "Zurich", 47.4647, 8.5492),
        "GVA": ("Geneva Airport", "Geneva", 46.2381, 6.1090),
        "VIE": ("Vienna International", "Vienna", 48.1103, 16.5697),
        // Italy
        "FCO": ("Leonardo da Vinci International", "Rome", 41.8003, 12.2389),
        "MXP": ("Milan Malpensa", "Milan", 45.6306, 8.7281),
        "LIN": ("Milan Linate", "Milan", 45.4491, 9.2783),
        "VCE": ("Venice Marco Polo", "Venice", 45.5053, 12.3519),
        "NAP": ("Naples International", "Naples", 40.8860, 14.2908),
        "BLQ": ("Bologna Guglielmo Marconi", "Bologna", 44.5354, 11.2887),
        "FLR": ("Florence Amerigo Vespucci", "Florence", 43.8100, 11.2051),
        "CTA": ("Catania-Fontanarossa", "Catania", 37.4668, 15.0664),
        // Spain & Portugal
        "MAD": ("Adolfo Suarez Madrid-Barajas", "Madrid", 40.4936, -3.5668),
        "BCN": ("Barcelona El Prat", "Barcelona", 41.2974, 2.0833),
        "PMI": ("Palma de Mallorca", "Palma", 39.5517, 2.7388),
        "AGP": ("Málaga-Costa del Sol", "Málaga", 36.6749, -4.4991),
        "ALC": ("Alicante-Elche", "Alicante", 38.2822, -0.5582),
        "LIS": ("Lisbon Humberto Delgado", "Lisbon", 38.7813, -9.1359),
        "OPO": ("Porto Francisco Sá Carneiro", "Porto", 41.2481, -8.6814),
        "FAO": ("Faro Airport", "Faro", 37.0144, -7.9659),
        // Scandinavia
        "CPH": ("Copenhagen Kastrup", "Copenhagen", 55.6181, 12.6560),
        "OSL": ("Oslo Gardermoen", "Oslo", 60.1939, 11.1004),
        "ARN": ("Stockholm Arlanda", "Stockholm", 59.6519, 17.9186),
        "HEL": ("Helsinki-Vantaa", "Helsinki", 60.3172, 24.9633),
        "KEF": ("Keflavik International", "Reykjavik", 63.9850, -22.6056),
        // Eastern Europe
        "WAW": ("Warsaw Chopin", "Warsaw", 52.1657, 20.9671),
        "PRG": ("Václav Havel Prague", "Prague", 50.1008, 14.2600),
        "BUD": ("Budapest Ferenc Liszt", "Budapest", 47.4399, 19.2556),
        "OTP": ("Henri Coandă International", "Bucharest", 44.5711, 26.0850),
        "SOF": ("Sofia Airport", "Sofia", 42.6967, 23.4114),
        "BEG": ("Belgrade Nikola Tesla", "Belgrade", 44.8184, 20.3091),
        "ZAG": ("Zagreb Franjo Tuđman", "Zagreb", 45.7430, 16.0688),
        "ATH": ("Athens Eleftherios Venizelos", "Athens", 37.9364, 23.9445),
        "SKG": ("Thessaloniki Macedonia", "Thessaloniki", 40.5197, 22.9709),
        "HER": ("Heraklion International", "Heraklion", 35.3397, 25.1803),
        "TLL": ("Tallinn Lennart Meri", "Tallinn", 59.4133, 24.8328),
        "RIX": ("Riga International", "Riga", 56.9236, 23.9711),
        "VNO": ("Vilnius International", "Vilnius", 54.6341, 25.2858),
        // Turkey
        "IST": ("Istanbul Airport", "Istanbul", 41.2619, 28.7419),
        "SAW": ("Sabiha Gökçen International", "Istanbul", 40.8986, 29.3092),
        "AYT": ("Antalya Airport", "Antalya", 36.8987, 30.8005),
        "ESB": ("Esenboğa International", "Ankara", 40.1281, 32.9951),
        "ADB": ("Adnan Menderes", "Izmir", 38.2924, 27.1570),
        // Middle East
        "DXB": ("Dubai International", "Dubai", 25.2532, 55.3657),
        "AUH": ("Abu Dhabi International", "Abu Dhabi", 24.4330, 54.6511),
        "DOH": ("Hamad International", "Doha", 25.2609, 51.6138),
        "RUH": ("King Khalid International", "Riyadh", 24.9576, 46.6988),
        "JED": ("King Abdulaziz International", "Jeddah", 21.6796, 39.1565),
        "DMM": ("King Fahd International", "Dammam", 26.4712, 49.7979),
        "MED": ("Prince Mohammad bin Abdulaziz International", "Medina", 24.5534, 39.7051),
        "BAH": ("Bahrain International", "Manama", 26.2708, 50.6336),
        "KWI": ("Kuwait International", "Kuwait City", 29.2266, 47.9689),
        "MCT": ("Muscat International", "Muscat", 23.5933, 58.2844),
        "TLV": ("Ben Gurion International", "Tel Aviv", 32.0114, 34.8867),
        "AMM": ("Queen Alia International", "Amman", 31.7226, 35.9932),
        "BEY": ("Rafic Hariri International", "Beirut", 33.8209, 35.4884),
        "IKA": ("Imam Khomeini International", "Tehran", 35.4161, 51.1522),
        "BGW": ("Baghdad International", "Baghdad", 33.2625, 44.2346),
        // Egypt
        "CAI": ("Cairo International", "Cairo", 30.1219, 31.4056),
        "HRG": ("Hurghada International", "Hurghada", 27.1783, 33.7994),
        "SSH": ("Sharm el-Sheikh International", "Sharm el-Sheikh", 27.9773, 34.3950),
        "LXR": ("Luxor International", "Luxor", 25.6741, 32.7066),
        "HBE": ("Borg El Arab International", "Alexandria", 30.9177, 29.6964),
        // North Africa
        "CMN": ("Mohammed V International", "Casablanca", 33.3675, -7.5898),
        "RAK": ("Marrakech Menara", "Marrakech", 31.6069, -8.0363),
        "TNG": ("Tangier Ibn Battouta", "Tangier", 35.7269, -5.9169),
        "TUN": ("Tunis-Carthage International", "Tunis", 36.8510, 10.2272),
        "ALG": ("Houari Boumediene", "Algiers", 36.6910, 3.2154),
        // Sub-Saharan Africa
        "JNB": ("O.R. Tambo International", "Johannesburg", -26.1392, 28.2460),
        "CPT": ("Cape Town International", "Cape Town", -33.9649, 18.6017),
        "DUR": ("King Shaka International", "Durban", -29.6144, 31.1197),
        "NBO": ("Jomo Kenyatta International", "Nairobi", -1.3192, 36.9278),
        "ADD": ("Addis Ababa Bole International", "Addis Ababa", 8.9779, 38.7993),
        "LOS": ("Murtala Muhammed International", "Lagos", 6.5774, 3.3211),
        "ABV": ("Nnamdi Azikiwe International", "Abuja", 9.0065, 7.2632),
        "ACC": ("Kotoka International", "Accra", 5.6052, -0.1668),
        "DSS": ("Blaise Diagne International", "Dakar", 14.6700, -17.0733),
        "DAR": ("Julius Nyerere International", "Dar es Salaam", -6.8781, 39.2026),
        "EBB": ("Entebbe International", "Entebbe", 0.0424, 32.4435),
        "KGL": ("Kigali International", "Kigali", -1.9686, 30.1395),
        "MRU": ("Sir Seewoosagur Ramgoolam International", "Mauritius", -20.4302, 57.6836),
        "SEZ": ("Seychelles International", "Mahé", -4.6743, 55.5218),
        // East Asia
        "NRT": ("Narita International", "Tokyo", 35.7720, 140.3929),
        "HND": ("Haneda Airport", "Tokyo", 35.5494, 139.7798),
        "KIX": ("Kansai International", "Osaka", 34.4347, 135.2441),
        "NGO": ("Chubu Centrair International", "Nagoya", 34.8584, 136.8125),
        "FUK": ("Fukuoka Airport", "Fukuoka", 33.5859, 130.4511),
        "CTS": ("New Chitose Airport", "Sapporo", 42.7752, 141.6925),
        "ICN": ("Incheon International", "Seoul", 37.4602, 126.4407),
        "GMP": ("Gimpo International", "Seoul", 37.5586, 126.7906),
        "PUS": ("Gimhae International", "Busan", 35.1795, 128.9382),
        "HKG": ("Hong Kong International", "Hong Kong", 22.3080, 113.9185),
        "PVG": ("Shanghai Pudong International", "Shanghai", 31.1443, 121.8083),
        "SHA": ("Shanghai Hongqiao International", "Shanghai", 31.1979, 121.3363),
        "PEK": ("Beijing Capital International", "Beijing", 40.0799, 116.6031),
        "PKX": ("Beijing Daxing International", "Beijing", 39.5098, 116.4105),
        "CAN": ("Guangzhou Baiyun International", "Guangzhou", 23.3924, 113.2988),
        "SZX": ("Shenzhen Bao'an International", "Shenzhen", 22.6393, 113.8107),
        "CTU": ("Chengdu Shuangliu International", "Chengdu", 30.5728, 103.9472),
        "CKG": ("Chongqing Jiangbei International", "Chongqing", 29.7192, 106.6417),
        "XIY": ("Xi'an Xianyang International", "Xi'an", 34.4471, 108.7516),
        "HGH": ("Hangzhou Xiaoshan International", "Hangzhou", 30.2295, 120.4344),
        "NKG": ("Nanjing Lukou International", "Nanjing", 31.7420, 118.8620),
        "WUH": ("Wuhan Tianhe International", "Wuhan", 30.7838, 114.2081),
        "TPE": ("Taiwan Taoyuan International", "Taipei", 25.0797, 121.2342),
        // Southeast Asia
        "SIN": ("Singapore Changi", "Singapore", 1.3644, 103.9915),
        "BKK": ("Suvarnabhumi Airport", "Bangkok", 13.6900, 100.7501),
        "DMK": ("Don Mueang International", "Bangkok", 13.9126, 100.6068),
        "KUL": ("Kuala Lumpur International", "Kuala Lumpur", 2.7456, 101.7099),
        "CGK": ("Soekarno-Hatta International", "Jakarta", -6.1256, 106.6558),
        "DPS": ("Ngurah Rai International", "Bali", -8.7482, 115.1672),
        "MNL": ("Ninoy Aquino International", "Manila", 14.5086, 121.0198),
        "CEB": ("Mactan-Cebu International", "Cebu", 10.3075, 123.9794),
        "SGN": ("Tan Son Nhat International", "Ho Chi Minh City", 10.8188, 106.6520),
        "HAN": ("Noi Bai International", "Hanoi", 21.2212, 105.8070),
        "DAD": ("Da Nang International", "Da Nang", 16.0439, 108.1992),
        "REP": ("Siem Reap International", "Siem Reap", 13.4107, 103.8126),
        "PNH": ("Phnom Penh International", "Phnom Penh", 11.5466, 104.8442),
        "RGN": ("Yangon International", "Yangon", 16.9074, 96.1332),
        "HKT": ("Phuket International", "Phuket", 8.1132, 98.3169),
        "CNX": ("Chiang Mai International", "Chiang Mai", 18.7668, 98.9625),
        // South Asia
        "DEL": ("Indira Gandhi International", "New Delhi", 28.5562, 77.1000),
        "BOM": ("Chhatrapati Shivaji International", "Mumbai", 19.0896, 72.8656),
        "BLR": ("Kempegowda International", "Bengaluru", 13.1979, 77.7063),
        "MAA": ("Chennai International", "Chennai", 12.9941, 80.1709),
        "HYD": ("Rajiv Gandhi International", "Hyderabad", 17.2403, 78.4294),
        "CCU": ("Netaji Subhas Chandra Bose International", "Kolkata", 22.6547, 88.4467),
        "COK": ("Cochin International", "Kochi", 10.1520, 76.4019),
        "GOI": ("Goa International", "Goa", 15.3809, 73.8314),
        "ISB": ("Islamabad International", "Islamabad", 33.5605, 72.8526),
        "KHI": ("Jinnah International", "Karachi", 24.9065, 67.1610),
        "LHE": ("Allama Iqbal International", "Lahore", 31.5216, 74.4036),
        "DAC": ("Hazrat Shahjalal International", "Dhaka", 23.8432, 90.3978),
        "CMB": ("Bandaranaike International", "Colombo", 7.1808, 79.8841),
        "MLE": ("Velana International", "Malé", 4.1918, 73.5290),
        "KTM": ("Tribhuvan International", "Kathmandu", 27.6966, 85.3591),
        // Oceania
        "SYD": ("Sydney Kingsford Smith", "Sydney", -33.9461, 151.1772),
        "MEL": ("Melbourne Airport", "Melbourne", -37.6690, 144.8410),
        "BNE": ("Brisbane Airport", "Brisbane", -27.3842, 153.1175),
        "PER": ("Perth Airport", "Perth", -31.9403, 115.9672),
        "ADL": ("Adelaide Airport", "Adelaide", -34.9461, 138.5310),
        "AKL": ("Auckland Airport", "Auckland", -37.0082, 174.7850),
        "CHC": ("Christchurch International", "Christchurch", -43.4894, 172.5322),
        "WLG": ("Wellington International", "Wellington", -41.3272, 174.8053),
        "NAN": ("Nadi International", "Nadi", -17.7554, 177.4436),
        "PPT": ("Faa'a International", "Papeete", -17.5537, -149.6073),
        // South America
        "GRU": ("Sao Paulo-Guarulhos International", "Sao Paulo", -23.4356, -46.4731),
        "GIG": ("Rio de Janeiro-Galeão International", "Rio de Janeiro", -22.8100, -43.2506),
        "EZE": ("Ministro Pistarini International", "Buenos Aires", -34.8222, -58.5358),
        "SCL": ("Santiago International", "Santiago", -33.3930, -70.7858),
        "LIM": ("Jorge Chavez International", "Lima", -12.0219, -77.1143),
        "BOG": ("El Dorado International", "Bogota", 4.7016, -74.1469),
        "MDE": ("José María Córdova International", "Medellín", 6.1645, -75.4231),
        "UIO": ("Mariscal Sucre International", "Quito", -0.1292, -78.3575),
        "GYE": ("José Joaquín de Olmedo International", "Guayaquil", -2.1574, -79.8837),
        "CCS": ("Simón Bolívar International", "Caracas", 10.6012, -66.9912),
        "MVD": ("Carrasco International", "Montevideo", -34.8384, -56.0308),
        // Central America
        "PTY": ("Tocumen International", "Panama City", 9.0714, -79.3835),
        "SJO": ("Juan Santamaría International", "San José", 9.9939, -84.2088),
        "GUA": ("La Aurora International", "Guatemala City", 14.5833, -90.5275),
        "SAL": ("Monseñor Óscar Arnulfo Romero International", "San Salvador", 13.4409, -89.0557),
        // Russia & Central Asia
        "SVO": ("Sheremetyevo International", "Moscow", 55.9726, 37.4146),
        "DME": ("Domodedovo International", "Moscow", 55.4088, 37.9063),
        "LED": ("Pulkovo", "St. Petersburg", 59.8003, 30.2625),
        "ALA": ("Almaty International", "Almaty", 43.3521, 77.0405),
        "NQZ": ("Nursultan Nazarbayev International", "Astana", 51.0222, 71.4669),
        "TAS": ("Islam Karimov Tashkent International", "Tashkent", 41.2579, 69.2812),
        "GYD": ("Heydar Aliyev International", "Baku", 40.4675, 50.0467),
        "TBS": ("Tbilisi International", "Tbilisi", 41.6692, 44.9547),
        "EVN": ("Zvartnots International", "Yerevan", 40.1473, 44.3959),
    ]

    private var knownAirlineCodes: Set<String> {
        Set(AirlineDatabase.allAirlines.map { $0.iata })
    }

    func updateAutocomplete(for input: String, date: Date) {
        let cleaned = input.uppercased().trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "")

        guard cleaned.count >= 2 else {
            autocompleteTask?.cancel()
            autocompleteSuggestions = []
            isLoadingAutocomplete = false
            lastAutocompleteQuery = ""
            return
        }

        let parsed = parseAirlineAndNumber(cleaned)
        guard !parsed.airline.isEmpty else {
            autocompleteSuggestions = []
            return
        }

        let airlineCode = parsed.airline.count == 3 ? String(parsed.airline.prefix(2)) : parsed.airline
        let airlineName = AirlineDatabase.allAirlines.first(where: { $0.iata == airlineCode })?.name ?? ""

        if !airlineName.isEmpty && parsed.number.isEmpty {
            autocompleteSuggestions = [
                FlightSuggestion(flight: airlineCode, dep: "", arr: "", airline: "\(airlineName) — type flight number", depCity: "", arrCity: "", depTimeLocal: nil, arrTimeLocal: nil, status: nil, flightIndex: 0)
            ]
            return
        }

        guard !parsed.number.isEmpty, !airlineName.isEmpty else {
            autocompleteSuggestions = []
            return
        }

        let queryKey = "\(airlineCode)\(parsed.number)"
        guard queryKey != lastAutocompleteQuery else { return }
        lastAutocompleteQuery = queryKey

        autocompleteTask?.cancel()
        autocompleteTask = Task {
            isLoadingAutocomplete = true
            defer { isLoadingAutocomplete = false }

            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }

            guard let service = aeroDataBox else { return }

            do {
                let flightNumber = "\(airlineCode)\(parsed.number)"
                let flights = try await service.fetchFlightStatus(flightNumber: flightNumber, date: date)
                guard !Task.isCancelled else { return }

                let sorted = flights.sorted { a, b in
                    let aTime = self.parseADBTime(a.departure?.scheduledTime?.utc ?? a.departure?.scheduledTime?.local)
                    let bTime = self.parseADBTime(b.departure?.scheduledTime?.utc ?? b.departure?.scheduledTime?.local)
                    let now = Date()
                    let aUpcoming = aTime.map { $0 > now } ?? false
                    let bUpcoming = bTime.map { $0 > now } ?? false
                    if aUpcoming != bUpcoming { return aUpcoming }
                    guard let at = aTime, let bt = bTime else { return false }
                    return at < bt
                }
                autocompleteSuggestions = sorted.prefix(8).enumerated().compactMap { index, flight in
                    guard let depIata = flight.departure?.airport?.iata,
                          let arrIata = flight.arrival?.airport?.iata else { return nil }
                    return FlightSuggestion(
                        flight: flight.number ?? flightNumber,
                        dep: depIata,
                        arr: arrIata,
                        airline: flight.airline?.name ?? airlineName,
                        depCity: flight.departure?.airport?.municipalityName ?? "",
                        arrCity: flight.arrival?.airport?.municipalityName ?? "",
                        depTimeLocal: flight.departure?.scheduledTime?.local ?? flight.departure?.scheduledTime?.utc,
                        arrTimeLocal: flight.arrival?.scheduledTime?.local ?? flight.arrival?.scheduledTime?.utc,
                        status: flight.status,
                        flightIndex: index
                    )
                }
                autocompleteFlights = Array(sorted.prefix(8))
            } catch {
                guard !Task.isCancelled else { return }
                autocompleteSuggestions = []
            }
        }
    }

    func clearAutocomplete() {
        autocompleteTask?.cancel()
        autocompleteSuggestions = []
        autocompleteFlights = []
        isLoadingAutocomplete = false
        lastAutocompleteQuery = ""
    }

    func validateFlightNumber(_ input: String) -> String? {
        let cleaned = input.uppercased().trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "")
        guard !cleaned.isEmpty else { return "Please enter a flight number." }

        let parsed = parseAirlineAndNumber(cleaned)
        guard !parsed.airline.isEmpty else { return "Flight number must start with an airline code (e.g. AA, UA, DL)." }
        guard parsed.airline.count >= 2, parsed.airline.count <= 3 else { return "Invalid airline code. Use 2-3 letters (e.g. AA, UAL)." }
        guard !parsed.number.isEmpty else { return "Flight number must include a number (e.g. AA1234)." }
        guard parsed.number.count <= 4 else { return "Flight number too long. Use 1-4 digits (e.g. AA1234)." }

        let airlineCode = parsed.airline.count == 3 ? String(parsed.airline.prefix(2)) : parsed.airline
        guard knownAirlineCodes.contains(airlineCode) else {
            return "\"\(airlineCode)\" is not a recognized airline code."
        }

        return nil
    }

    func fetchForecast(query: FlightSearchQuery, selectedFlight: ADBFlightResponse? = nil) async -> FlightForecast? {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        if query.searchByFlightNumber {
            if let validationError = validateFlightNumber(query.flightNumber) {
                errorMessage = validationError
                return nil
            }
        }

        let depCode: String
        let arrCode: String
        var depLat: Double?
        var depLon: Double?
        var arrLat: Double?
        var arrLon: Double?
        var depName: String?
        var arrName: String?
        var depCity: String?
        var arrCity: String?
        var scheduledDep: Date?
        var scheduledArr: Date?
        var flightStatus: String?
        var depGate: String?
        var depTerminal: String?
        var arrGate: String?
        var arrTerminal: String?
        var aircraftModel: String?
        var aircraftReg: String?

        if query.searchByFlightNumber {
            let flightData = selectedFlight

            if let flight = flightData {
                depCode = flight.departure?.airport?.iata ?? query.departureAirport.uppercased().trimmingCharacters(in: .whitespaces)
                arrCode = flight.arrival?.airport?.iata ?? query.arrivalAirport.uppercased().trimmingCharacters(in: .whitespaces)
                depLat = flight.departure?.airport?.location?.lat
                depLon = flight.departure?.airport?.location?.lon
                arrLat = flight.arrival?.airport?.location?.lat
                arrLon = flight.arrival?.airport?.location?.lon
                depName = flight.departure?.airport?.name
                arrName = flight.arrival?.airport?.name
                depCity = flight.departure?.airport?.municipalityName
                arrCity = flight.arrival?.airport?.municipalityName
                flightStatus = flight.status
                depGate = flight.departure?.gate
                depTerminal = flight.departure?.terminal
                arrGate = flight.arrival?.gate
                arrTerminal = flight.arrival?.terminal
                aircraftModel = flight.aircraft?.model
                aircraftReg = flight.aircraft?.reg
                scheduledDep = parseADBTime(flight.departure?.scheduledTime?.utc ?? flight.departure?.scheduledTime?.local)
                scheduledArr = parseADBTime(flight.arrival?.scheduledTime?.utc ?? flight.arrival?.scheduledTime?.local)
            } else {
                if aeroDataBox != nil {
                    errorMessage = "No flight found for that number on \(formattedDate(query.date)). Check the flight number and date."
                    return nil
                } else {
                    errorMessage = "Flight data API not configured. Add your AeroDataBox API key in Settings."
                    return nil
                }
            }
        } else {
            depCode = query.departureAirport.uppercased().trimmingCharacters(in: .whitespaces)
            arrCode = query.arrivalAirport.uppercased().trimmingCharacters(in: .whitespaces)
            guard !depCode.isEmpty, !arrCode.isEmpty else {
                errorMessage = "Please enter both departure and arrival airports."
                return nil
            }
        }

        let departure = buildAirport(
            code: depCode,
            name: depName,
            city: depCity,
            lat: depLat,
            lon: depLon
        )
        let arrival = buildAirport(
            code: arrCode,
            name: arrName,
            city: arrCity,
            lat: arrLat,
            lon: arrLon
        )

        let depTime = scheduledDep ?? query.date
        let arrTime = scheduledArr ?? query.date.addingTimeInterval(estimateFlightDuration(from: departure, to: arrival))

        let routeLatLons = generateRouteLatLons(from: departure, to: arrival, count: 12)

        async let depMetarTask = weatherService.fetchMetar(station: depCode)
        async let arrMetarTask = weatherService.fetchMetar(station: arrCode)
        async let depTafTask = weatherService.fetchTaf(station: depCode)
        async let sigmetsTask = weatherService.fetchSigmets()
        async let pirepsTask = weatherService.fetchPireps(hours: 6)
        async let gairmetsTask = weatherService.fetchGairmets()
        async let routeWindTask = meteoService.fetchWindAlongRoute(points: routeLatLons)

        let depMetar = await depMetarTask
        let arrMetar = await arrMetarTask
        let depTaf = await depTafTask
        let sigmets = await sigmetsTask
        let pireps = await pirepsTask
        let gairmets = await gairmetsTask
        let routeWind = await routeWindTask

        let analysis = turbulenceEngine.analyze(
            departureMetar: depMetar,
            arrivalMetar: arrMetar,
            sigmets: sigmets,
            pireps: pireps,
            gairmets: gairmets,
            routeWind: routeWind,
            routePoints: routeLatLons
        )

        let routePoints = buildRoutePoints(latLons: routeLatLons, scores: analysis.routePointScores)

        let regionalInsights = geoResolver.resolveRegions(
            routePoints: routeLatLons,
            scores: analysis.routePointScores,
            departure: (lat: departure.latitude, lon: departure.longitude),
            arrival: (lat: arrival.latitude, lon: arrival.longitude)
        )

        let flightNum = query.searchByFlightNumber
            ? query.flightNumber.uppercased().trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "")
            : "\(depCode)-\(arrCode)"

        let displayScore = min(10, max(0, (analysis.overallScore + 5) / 10))

        let forecast = FlightForecast(
            id: UUID().uuidString,
            flightNumber: flightNum,
            departureAirport: departure,
            arrivalAirport: arrival,
            departureTime: depTime,
            arrivalTime: arrTime,
            overallScore: displayScore,
            takeoffCondition: turbulenceForScore(analysis.takeoffScore),
            cruiseCondition: turbulenceForScore(analysis.cruiseScore),
            landingCondition: turbulenceForScore(analysis.landingScore),
            takeoffWeather: metarToWeather(depMetar, fallbackCode: depCode),
            landingWeather: metarToWeather(arrMetar, fallbackCode: arrCode),
            routePoints: routePoints,
            metar: depMetar?.rawOb,
            taf: depTaf?.rawTAF,
            climbCondition: turbulenceForScore(analysis.climbScore),
            descentCondition: turbulenceForScore(analysis.descentScore),
            departureGate: depGate,
            departureTerminal: depTerminal,
            arrivalGate: arrGate,
            arrivalTerminal: arrTerminal,
            flightStatus: flightStatus,
            aircraftModel: aircraftModel,
            aircraftReg: aircraftReg,
            regionalInsights: regionalInsights
        )

        return forecast
    }

    func fetchAllFlightsFromAPI(flightNumber: String, date: Date) async -> [ADBFlightResponse] {
        guard let service = aeroDataBox else { return [] }

        do {
            let flights = try await service.fetchFlightStatus(flightNumber: flightNumber, date: date)
            return flights
        } catch {
            if let adbError = error as? ADBError {
                errorMessage = adbError.errorDescription
            } else {
                print("[FlightService] Flight number search error: \(error)")
                errorMessage = "Could not search flights. Please try again."
            }
            return []
        }
    }

    func fetchFlightsByRoute(departureIata: String, arrivalIata: String, date: Date) async -> [ADBFlightResponse] {
        guard let service = aeroDataBox else {
            errorMessage = "Flight data API not configured. Add your AeroDataBox API key in Settings."
            return []
        }

        var calendar = Calendar.current
        calendar.timeZone = .current
        let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
        let year = calendar.component(.year, from: noon)
        let month = calendar.component(.month, from: noon)
        let day = calendar.component(.day, from: noon)

        do {
            let departures = try await service.fetchDepartures(airportIata: departureIata, dateComponents: (year: year, month: month, day: day))
            let filtered = departures.filter { flight in
                guard let arrIata = flight.arrival?.airport?.iata else { return false }
                return arrIata.uppercased() == arrivalIata.uppercased()
            }
            return filtered
        } catch {
            if let adbError = error as? ADBError {
                errorMessage = adbError.errorDescription
            } else {
                print("[FlightService] Route search error: \(error)")
                errorMessage = "Could not search flights. Please try again."
            }
            return []
        }
    }

    private func buildAirport(code: String, name: String?, city: String?, lat: Double?, lon: Double?) -> Airport {
        let fallback = airportDatabase[code]
        let resolvedLat = lat ?? fallback?.lat
        let resolvedLon = lon ?? fallback?.lon

        if resolvedLat == nil || resolvedLon == nil {
            print("[FlightService] WARNING: No coordinates found for airport \(code). Route map will be inaccurate.")
        }

        return Airport(
            id: code,
            code: code,
            name: name ?? fallback?.name ?? "\(code) Airport",
            city: city ?? fallback?.city ?? code,
            latitude: resolvedLat ?? 0,
            longitude: resolvedLon ?? 0
        )
    }

    private func generateRouteLatLons(from departure: Airport, to arrival: Airport, count: Int) -> [(lat: Double, lon: Double)] {
        let lat1 = departure.latitude * .pi / 180
        let lon1 = departure.longitude * .pi / 180
        let lat2 = arrival.latitude * .pi / 180
        let lon2 = arrival.longitude * .pi / 180

        let dLon = lon2 - lon1
        let cosLat2 = cos(lat2)
        let sinLat2 = sin(lat2)
        let cosLat1 = cos(lat1)
        let sinLat1 = sin(lat1)

        let d = 2 * asin(sqrt(
            pow(sin((lat2 - lat1) / 2), 2) + cosLat1 * cosLat2 * pow(sin(dLon / 2), 2)
        ))

        guard d > 0.001 else {
            return (0..<count).map { _ in (lat: departure.latitude, lon: departure.longitude) }
        }

        var points: [(lat: Double, lon: Double)] = []
        for i in 0..<count {
            let f = Double(i) / Double(count - 1)
            let a = sin((1 - f) * d) / sin(d)
            let b = sin(f * d) / sin(d)
            let x = a * cosLat1 * cos(lon1) + b * cosLat2 * cos(lon2)
            let y = a * cosLat1 * sin(lon1) + b * cosLat2 * sin(lon2)
            let z = a * sinLat1 + b * sinLat2
            let lat = atan2(z, sqrt(x * x + y * y)) * 180 / .pi
            let lon = atan2(y, x) * 180 / .pi
            points.append((lat: lat, lon: lon))
        }
        return points
    }

    private func buildRoutePoints(latLons: [(lat: Double, lon: Double)], scores: [Int]) -> [RoutePoint] {
        var points: [RoutePoint] = []
        for (i, ll) in latLons.enumerated() {
            let score = scores[safe: i] ?? 10
            points.append(RoutePoint(
                id: UUID().uuidString,
                latitude: ll.lat,
                longitude: ll.lon,
                turbulenceLevel: turbulenceForScore(score),
                altitude: 35000
            ))
        }
        return points
    }

    private func metarToWeather(_ metar: NOAAMetar?, fallbackCode: String) -> WeatherCondition {
        guard let m = metar else {
            return WeatherCondition(
                id: UUID().uuidString,
                temperature: 20,
                windSpeed: 5,
                windDirection: 0,
                visibility: 10,
                cloudCover: "CLR",
                precipitation: nil,
                pressure: 1013,
                humidity: 50
            )
        }

        let cloudCover: String
        if let clouds = m.clouds, let first = clouds.first, let cover = first.cover {
            cloudCover = cover
        } else {
            cloudCover = "CLR"
        }

        return WeatherCondition(
            id: UUID().uuidString,
            temperature: m.temp ?? 20,
            windSpeed: Double(m.wspd ?? 5),
            windDirection: m.wdir ?? 0,
            visibility: m.visib ?? 10,
            cloudCover: cloudCover,
            precipitation: m.wxString,
            pressure: m.slp ?? m.altim ?? 1013,
            humidity: Int(m.humid ?? 50)
        )
    }

    private func turbulenceForScore(_ score: Int) -> TurbulenceLevel {
        switch score {
        case 0...20: return .smooth
        case 21...45: return .light
        case 46...70: return .moderate
        default: return .severe
        }
    }

    private func displayTurbulenceForScore(_ score: Int) -> TurbulenceLevel {
        switch score {
        case 0...2: return .smooth
        case 3...4: return .light
        case 5...7: return .moderate
        default: return .severe
        }
    }

    private func estimateFlightDuration(from dep: Airport, to arr: Airport) -> TimeInterval {
        let r = 6371.0
        let dLat = (arr.latitude - dep.latitude) * .pi / 180
        let dLon = (arr.longitude - dep.longitude) * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2) + cos(dep.latitude * .pi / 180) * cos(arr.latitude * .pi / 180) * sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        let distKm = r * c
        let speedKmh = 850.0
        let hours = distKm / speedKmh
        return max(hours * 3600 + 1800, 3600)
    }

    private func parseAirlineAndNumber(_ input: String) -> (airline: String, number: String) {
        let cleaned = input.uppercased().trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "")
        var airline = ""
        var number = ""
        for char in cleaned {
            if char.isLetter {
                if number.isEmpty {
                    airline.append(char)
                }
            } else if char.isNumber {
                number.append(char)
            }
        }
        return (airline, number)
    }

    private func parseADBTime(_ timeStr: String?) -> Date? {
        guard let timeStr else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = formatter.date(from: timeStr) { return d }
        formatter.formatOptions = [.withInternetDateTime]
        if let d = formatter.date(from: timeStr) { return d }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mmZ"
        return df.date(from: timeStr)
    }

    func fetchTimeShiftedScore(forecast: FlightForecast, hourOffset: Int) async -> Int {
        let routeLatLons = generateRouteLatLons(from: forecast.departureAirport, to: forecast.arrivalAirport, count: 8)
        let routeWind = await meteoService.fetchWindAlongRoute(points: routeLatLons, hourOffset: hourOffset)

        let analysis = turbulenceEngine.analyze(
            departureMetar: nil,
            arrivalMetar: nil,
            sigmets: [],
            pireps: [],
            gairmets: [],
            routeWind: routeWind,
            routePoints: routeLatLons
        )

        return min(10, max(0, (analysis.overallScore + 5) / 10))
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}
