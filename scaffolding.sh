rails d scaffold Restaurant --force
rails d scaffold Menu --force
rails d scaffold Menusection --force
rails d scaffold Menuitem --force
rails d scaffold Allergyn --force
rails d scaffold Tag --force
rails d scaffold Employee --force
rails d scaffold Tablesetting --force
rails d scaffold Ordr --force
rails d scaffold Ordritem --force
rails d scaffold Ordritemnote --force
rails d scaffold Taxes --force

rails g scaffold Restaurant     name:string description:text address1:string address2:string state:string city:string postcode:string country:string image:string status:integer capacity:integer user:references --force
rails g scaffold Menu           name:string description:text image:string status:integer sequence:integer restaurant:references --force
rails g scaffold Menusection    name:string description:text image:string status:integer sequence:integer menu:references --force
rails g scaffold Menuitem       name:string description:text image:string status:integer sequence:integer calories:integer price:float menusection:references --force
rails g scaffold Allergyn       name:string description:text symbol:string menuitem:references --force
rails g scaffold Tag            name:string description:text menuitem:references --force
rails g scaffold Employee       name:string eid:string image:string status:integer restaurant:references --force
rails g scaffold Tablesetting   name:string description:text status:integer capacity:integer restaurant:references --force
rails g scaffold Ordr           orderedAt:timestamp deliveredAt:timestamp paidAt:timestamp nett:float tip:float service:float tax:float gross:float employee:references tablesetting:references menu:references restaurant:references --force
rails g scaffold Ordritem       ordr:references menuitem:references --force
rails g scaffold Ordritemnote   note:string ordritem:references --force
rails g scaffold Taxes          name:string taxtype:integer taxpercentage:float restaurant:references --force
rails g scaffold Smartmenu      slug:string:index restaurant:references menu:references tablesetting:references
