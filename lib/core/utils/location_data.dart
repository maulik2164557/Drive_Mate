class LocationData {
  static const Map<String, List<String>> gujaratDistricts = {
    'Ahmedabad': ['Sabarmati Ashram', 'Kankaria Lake', 'Adalaj Stepwell', 'Science City', 'Akshardham Temple'],
    'Surat': ['Dumas Beach', 'Dutch Garden', 'Sarthana Nature Park', 'Science Centre', 'Ambika Niketan Temple'],
    'Vadodara': ['Laxmi Vilas Palace', 'Sayaji Baug', 'Champaner-Pavagadh', 'EME Temple', 'Kirti Mandir'],
    'Rajkot': ['Watson Museum', 'Rotary Dolls Museum', 'Nyari Dam', 'Ishwariya Park'],
    'Bhavnagar': ['Nilambag Palace', 'Takhteshwar Temple', 'Victoria Park', 'Velavadar National Park'],
    'Jamnagar': ['Lakhota Lake', 'Khijadiya Bird Sanctuary', 'Bala Hanuman Temple', 'Marine National Park'],
    'Junagadh': ['Girnar Hill', 'Uparkot Fort', 'Mahabat Maqbara', 'Sakkarbaug Zoo'],
    'Gandhinagar': ['Akshardham', 'Indroda Nature Park', 'Sarita Udyan', 'Adalaj Stepwell'],
    'Anand': ['Amul Dairy', 'Flo Art Gallery', 'Swaminarayan Mandir'],
    'Kutch': ['Rann of Kutch', 'Bhujia Hill', 'Vijay Vilas Palace', 'Aina Mahal'],
    'Mehsana': ['Sun Temple Modhera', 'Thol Lake', 'Shankus Water Park'],
    'Patan': ['Rani ki Vav', 'Sahastralinga Talav', 'Hemachandracharya Library'],
    'Amreli': ['Ambardi Safari Park', 'Dhari Dam', 'Khodiyar Mandir'],
    'Banaskantha': ['Ambaji Temple', 'Balaram Ambaji Sanctuary', 'Jessore Sloth Bear Sanctuary'],
    'Bharuch': ['Golden Bridge', 'Shravan Tirth', 'Kabirvad'],
    'Dahod': ['Ratanmahal Sanctuary', 'Bawka Shiv Temple'],
    'Dang': ['Saputara', 'Gira Waterfalls', 'Purna Sanctuary'],
    'Gir Somnath': ['Somnath Temple', 'Gir National Park', 'Triveni Sangam'],
    'Kheda': ['Dakore Temple', 'Vadtal Swaminarayan Mandir'],
    'Morbi': ['Mani Mandir', 'Jhulto Pul', 'Wankaner Palace'],
    'Narmada': ['Statue of Unity', 'Sardar Sarovar Dam', 'Valley of Flowers'],
    'Navsari': ['Dandi Memorial', 'Udvada Atash Behram'],
    'Panchmahal': ['Pavagadh Hill', 'Champaner Archeological Park'],
    'Porbandar': ['Kirti Mandir', 'Sudama Mandir', 'Chowpati'],
    'Tapi': ['Ukai Dam', 'Doswada Dam'],
    'Valsad': ['Tithal Beach', 'Parnera Hill', 'Wilson Hills'],
    'Aravalli': ['Shamlaji Temple', 'Meshwo Reservoir'],
    'Botad': ['Salangpur Hanumanji Temple', 'Gadhada Swaminarayan Temple'],
    'Chhota Udaipur': ['Kusum Vilas Palace', 'Rathwa Tribal Museum'],
    'Devbhoomi Dwarka': ['Dwarkadhish Temple', 'Bet Dwarka', 'Shivrajpur Beach'],
    'Mahisagar': ['Kaleshwari Historical Complex', 'Kadana Dam'],
    'Sabarkantha': ['Polo Forest', 'Idar Fort', 'Saputara'],
    'Surendranagar': ['Tarnetar', 'Zalawad', 'Vadhwan Stepwell'],
  };

  static List<String> getAllDistricts() {
    final list = gujaratDistricts.keys.toList();
    list.sort();
    return list;
  }

  static List<String> getAllPlaces() {
    List<String> places = [];
    gujaratDistricts.forEach((city, sites) {
      places.add(city);
      places.addAll(sites.map((site) => '$site, $city'));
    });
    return places;
  }
}
