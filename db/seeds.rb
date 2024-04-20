
Restaurant.create!([
  {name: "Anderson's", description: "Anderson's Food Hall & Cafe", address1: "4 The Rise", address2: "Glasnevin", state: "Leinster", city: "Dublin", postcode: "D09XW83", country: "AF", image: "www.google.com", status: "active", capacity: 0, user_id: 1}
])
Tax.create!([
  {name: "Local Lax", taxtype: "local", taxpercentage: 12.0, restaurant_id: 1, sequence: 1},
  {name: "state", taxtype: "state", taxpercentage: 10.0, restaurant_id: 1, sequence: 2},
  {name: "Service", taxtype: "service", taxpercentage: 8.0, restaurant_id: 1, sequence: 3}
])
Allergyn.create!([
  {name: "Gluten", description: "wheat (such as spelt and khorasan wheat), rye, barley, oats.", symbol: "G"},
  {name: "Crustaceans", description: "Crabs, prawns, lobsters", symbol: "C"},
  {name: "Eggs", description: "Eggs", symbol: "E"},
  {name: "Fish", description: "Fish", symbol: "F"},
  {name: "Peanuts", description: "Peanuts", symbol: "PN"},
  {name: "Soybeans", description: "Soybeans", symbol: "SB"},
  {name: "Milk", description: "Milk", symbol: "M"},
  {name: "Nuts", description: "Nuts (almonds, hazelnuts, walnuts, cashews, pecan nuts, brazil nuts, pistachio nuts, macadamia/Queensland nut).", symbol: "N"},
  {name: "Celery", description: "Celery", symbol: "C"},
  {name: "Mustard", description: "Mustard", symbol: "MU"},
  {name: "Sesame seeds", description: "Sesame seeds", symbol: "S"},
  {name: "Sulphur", description: "Sulphur dioxide and sulphites (at concentrations of more than 10 mg/kg or 10 mg/L in terms of total sulphur dioxide) – used as a preservative", symbol: "SU"},
  {name: "Lupin", description: "Lupin", symbol: "L"},
  {name: "Molluscs", description: "Mussels, oysters, squid, snails", symbol: "MO"}
])
Tablesetting.create!([
  {name: "T1", description: "Table 1", status: "free", capacity: 2, tabletype: "indoor", restaurant_id: 1},
  {name: "T2", description: "Table 2", status: "free", capacity: 3, tabletype: "outdoor", restaurant_id: 1}
])
Size.create!([
  {size: "xs", name: "Extra Small", description: ""},
  {size: "sm", name: "Small", description: ""}
])

Menu.create!([
  {name: "Breakfast", description: "Lunch", image: "", status: "active", sequence: 1, restaurant_id: 1},
])
Menusection.create!([
  {name: "Breakfast", description: "Breakfast", image: "http://via.placeholder.com/1280x180", status: "active", sequence: 1, menu_id: 1},
  {name: "Pancakes", description: "Pancakes", image: "http://via.placeholder.com/1280x180", status: "active", sequence: 2, menu_id: 1},
  {name: "Additional Items", description: "Additional Items", image: "http://via.placeholder.com/1280x180", status: "active", sequence: 3, menu_id: 1},
  {name: "Pastries", description: "Pastries", image: "http://via.placeholder.com/1280x180", status: "active", sequence: 4, menu_id: 1},
  {name: "Juices", description: "Juices", image: "http://via.placeholder.com/1280x180", status: "active", sequence: 5, menu_id: 1},
  {name: "Coffees & Teas", description: "Juices", image: "http://via.placeholder.com/1280x180", status: "active", sequence: 6, menu_id: 1}
])
Menuitem.create!([
  {name: "Toast", description: "Sourdough or Multigrain Toast served with Butter & Preserve Homemade Granola", image: "http://via.placeholder.com/300x300", status: "active", sequence: 1, calories: 290, price: 3.50, menusection_id: 1},
  {name: "Fruit of the Forestt", description: "Fruit of the Forest Compote and Greek Yoghurt", image: "http://via.placeholder.com/300x300", status: "active", sequence: 2, calories: 200, price: 7.95, menusection_id: 1},
  {name: "Porridge Oats", description: "Porridge Oats cooked in Milk served with Fresh Cream and Honey - (add Blueberries, Banana, or Fruit of the Forest Compote)", image: "http://via.placeholder.com/300x300", status: "active", sequence: 3, calories: 600, price: 6.95, menusection_id: 1},
  {name: "Multigrain Toast with Smashed Avocado", description: "Multigrain Toast with Smashed Avocado, Smoked Salmon, Feta Cheese, Cucumber & Mixed Seeds ", image: "http://via.placeholder.com/300x300", status: "active", sequence: 4, calories: 1200, price: 9.95, menusection_id: 1},
  {name: "Free Range Scrambled Eggs or Poached Eggs", description: "Free Range Scrambled Eggs or Poached Eggs v with Sourdough / Multigrain Toast ", image: "http://via.placeholder.com/300x300", status: "active", sequence: 5, calories: 1200, price: 8.95, menusection_id: 1},
  {name: "Free Range Scrambled or Poached Eggs & Bacon", description: "Free Range Scrambled or Poached Eggs & Bacon with Sourdough / Multigrain Toast", image: "http://via.placeholder.com/300x300", status: "active", sequence: 6, calories: 1200, price: 10.95, menusection_id: 1},
  {name: "Eggs Benedict", description: "Eggs Benedict - Free Range Poached Eggs & Bacon topped with Hollandaise Sauce & Chives on a Toasted Bagel ", image: "http://via.placeholder.com/300x300", status: "active", sequence: 7, calories: 1200, price: 11.95, menusection_id: 1},
  {name: "Eggs Royale", description: "Eggs Royale - Free Range Poached Eggs, Smoked Salmon & Spinach topped with Hollandaise Sauce & Chives on a Toasted Bagel ", image: "http://via.placeholder.com/300x300", status: "active", sequence: 8, calories: 1200, price: 12.95, menusection_id: 1},
  {name: "Breakfast Sandwich", description: "Breakfast Sandwich - Gourmet Pork Sausage, Bacon, Scrambled Eggs, Smoked Applewood Cheddar and Sweet Pepper Relish on Toasted Ciabatta Bread served with Patatas Bravos ", image: "http://via.placeholder.com/300x300", status: "active", sequence: 9, calories: 1200, price: 13.95, menusection_id: 1},
  {name: "The Full Andersons Breakfast", description: "The Full Andersons Breakfast -Gourmet Pork Sausage, Free Range Poached Eggs, Bacon, Grilled Tomato, Black & White Pudding served with Toast ", image: "http://via.placeholder.com/300x300", status: "active", sequence: 10, calories: 1200, price: 13.95, menusection_id: 1},
  {name: "Breakfast Burrito", description: "Breakfast Burrito - Scrambled Eggs, Chorizo, Bacon, Cherry Tomatoes, Avocado, Mature Irish Cheddar Cheese on a Toasted Tortilla Wrap served with Patatas Bravas", image: "http://via.placeholder.com/300x300", status: "active", sequence: 11, calories: 1200, price: 9.95, menusection_id: 1},
  {name: "American Style Pancakes", description: "American Style Pancakes served with Fresh Strawberries, Blueberries & Maple Flavour Syrup", image: "http://via.placeholder.com/300x300", status: "active", sequence: 12, calories: 1200, price: 10.95, menusection_id: 2},
  {name: "American Style Pancakes & Bacon", description: "served with Bacon, Fresh Strawberries, Blueberries & Maple Flavour Syrup", image: "http://via.placeholder.com/300x300", status: "active", sequence: 12, calories: 1200, price: 12.95, menusection_id: 2},

  {name: "Gourmet Pork Sausage Bacon", description: "Gourmet Pork Sausage (2) Bacon (2 Slices)", image: "http://via.placeholder.com/300x300", status: "active", sequence: 13, calories: 1200, price: 3.0, menusection_id: 3},
  {name: "Poached Egg", description: "Poached Egg", image: "http://via.placeholder.com/300x300", status: "active", sequence: 14, calories: 1200, price: 3.0, menusection_id: 2},
  {name: "Pudding", description: "Black Pudding", image: "http://via.placeholder.com/300x300", status: "active", sequence: 15, calories: 1200, price: 1.75, menusection_id: 2},
  {name: "Grilled Tomato", description: "Grilled Tomato Portion", image: "http://via.placeholder.com/300x300", status: "active", sequence: 16, calories: 1200, price: 1.50, menusection_id: 2},

  {name: "Croissant", description: "Croissant served with Butter & Preserve", image: "http://via.placeholder.com/300x300", status: "active", sequence: 17, calories: 1200, price: 3.25, menusection_id: 3},
  {name: "Almond Croissant", description: "Almond Croissant served with Butter & Preserve", image: "http://via.placeholder.com/300x300", status: "active", sequence: 18, calories: 1200, price: 3.75, menusection_id: 3},
  {name: "Fruit Scone", description: "Fruit Scone served with Butter & Preserve", image: "http://via.placeholder.com/300x300", status: "active", sequence: 19, calories: 1200, price: 3.75, menusection_id: 3},
  {name: "Mixed Berry Scone", description: "Mixed Berry Scone served with Butter & Preserve", image: "http://via.placeholder.com/300x300", status: "active", sequence: 20, calories: 1200, price: 3.75, menusection_id: 3},
  {name: "Pain au Chocolat", description: "Pain au Chocolat", image: "http://via.placeholder.com/300x300", status: "active", sequence: 21, calories: 1200, price: 3.25, menusection_id: 3},
  {name: "Pain au Raisin", description: "Pain au Raisin", image: "http://via.placeholder.com/300x300", status: "active", sequence: 22, calories: 1200, price: 3.25, menusection_id: 3},
  {name: "Cinnamon Swirl", description: "Cinnamon Swirl", image: "http://via.placeholder.com/300x300", status: "active", sequence: 23, calories: 1200, price: 3.25, menusection_id: 3},
  {name: "Pastries of the Day", description: "Pastries of the Day", image: "http://via.placeholder.com/300x300", status: "active", sequence: 24, calories: 1200, price: 3.25, menusection_id: 3},

  {name: "Fresh Orange Juice", description: "Fresh Orange Juice", image: "http://via.placeholder.com/300x300", status: "active", sequence: 25, calories: 1200, price: 3.95, menusection_id: 4},
  {name: "Fresh Apple Juice", description: "Fresh Apple Juice", image: "http://via.placeholder.com/300x300", status: "active", sequence: 26, calories: 1200, price: 3.95, menusection_id: 4},
  {name: "Ballycross Farm Juices Apple", description: "Ballycross Farm Juices Apple {75c1}", image: "http://via.placeholder.com/300x300", status: "active", sequence: 27, calories: 1200, price: 6.95, menusection_id: 4},
  {name: "Apple/Blackcurrant", description: "Apple/Blackcurrant {75c1}", image: "http://via.placeholder.com/300x300", status: "active", sequence: 28, calories: 1200, price: 6.95, menusection_id: 4},
  {name: "Apple/Carrot", description: "Apple/Carrot {75c1}", image: "http://via.placeholder.com/300x300", status: "active", sequence: 28, calories: 1200, price: 6.95, menusection_id: 4},

  {name: "Espresso", description: "Espresso", image: "http://via.placeholder.com/300x300", status: "active", sequence: 29, calories: 1200, price: 3.00, menusection_id: 5},
  {name: "Double Espresso", description: "Double Espresso", image: "http://via.placeholder.com/300x300", status: "active", sequence: 30, calories: 1200, price: 3.75, menusection_id: 5},
  {name: "Macchiato", description: "Macchiato", image: "http://via.placeholder.com/300x300", status: "active", sequence: 31, calories: 1200, price: 3.75, menusection_id: 5},
  {name: "Americano/Regular/White Coffee", description: "Americano/Regular/White Coffee", image: "http://via.placeholder.com/300x300", status: "active", sequence: 32, calories: 1200, price: 3.25, menusection_id: 5},
  {name: "Cappuccino", description: "Cappuccino", image: "http://via.placeholder.com/300x300", status: "active", sequence: 33, calories: 1200, price: 3.75, menusection_id: 5},
  {name: "Latte", description: "Latte", image: "http://via.placeholder.com/300x300", status: "active", sequence: 34, calories: 1200, price: 3.75, menusection_id: 5},
  {name: "Mocha", description: "Mocha", image: "http://via.placeholder.com/300x300", status: "active", sequence: 35, calories: 1200, price: 4.00, menusection_id: 5},
  {name: "Vanilla Latte", description: "Vanilla Latte", image: "http://via.placeholder.com/300x300", status: "active", sequence: 36, calories: 1200, price: 4.00, menusection_id: 5},
  {name: "Flat White", description: "Flat White", image: "http://via.placeholder.com/300x300", status: "active", sequence: 37, calories: 1200, price: 4.25, menusection_id: 5},
  {name: "Hot Chocolate", description: "Hot Chocolate", image: "http://via.placeholder.com/300x300", status: "active", sequence: 38, calories: 1200, price: 3.75, menusection_id: 5},
  {name: "Tea", description: "Tea", image: "http://via.placeholder.com/300x300", status: "active", sequence: 39, calories: 1200, price: 3.25, menusection_id: 5},

  {name: "Roibosh Orange", description: "Roibosh Orange", image: "http://via.placeholder.com/300x300", status: "active", sequence: 40, calories: 1200, price: 3.25, menusection_id: 6},
  {name: "Camomile", description: "Camomile", image: "http://via.placeholder.com/300x300", status: "active", sequence: 41, calories: 1200, price: 4.25, menusection_id: 6},
  {name: "Green", description: "Green", image: "http://via.placeholder.com/300x300", status: "active", sequence: 42, calories: 1200, price: 4.25, menusection_id: 6},
  {name: "Nana {Mint}", description: "Nana {Mint}", image: "http://via.placeholder.com/300x300", status: "active", sequence: 43, calories: 1200, price: 4.25, menusection_id: 6},
  {name: "English Breakfast", description: "English Breakfast", image: "http://via.placeholder.com/300x300", status: "active", sequence: 44, calories: 1200, price: 4.25, menusection_id: 6},
  {name: "Special Earl Grey", description: "Special Earl Grey", image: "http://via.placeholder.com/300x300", status: "active", sequence: 45, calories: 1200, price: 4.25, menusection_id: 6}

])
Employee.create!([
  {name: "Fergus Kelledy", eid: "FK1", image: "Fake Image", status: "active", restaurant_id: 1, role: "manager", email: 'fkelledy@gmail.com', user_id: 1}
])
