-- Campus Lost & Found - database schema + demo data (SQLite, runs in the browser via sql.js)
PRAGMA foreign_keys = ON;

CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'student' CHECK (role IN ('student','admin')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','suspended')),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE student_profiles (
  user_id INTEGER PRIMARY KEY,
  student_id TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  department TEXT,
  year_of_study INTEGER,
  phone TEXT,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, description TEXT);
CREATE TABLE locations (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, description TEXT);
CREATE TABLE items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL CHECK (type IN ('lost','found')),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category_id INTEGER NOT NULL,
  location_id INTEGER NOT NULL,
  event_date TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected','claimed','returned')),
  admin_note TEXT,
  reported_by INTEGER NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT,
  FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE RESTRICT,
  FOREIGN KEY (reported_by) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX idx_items_status_type ON items(status, type);
CREATE INDEX idx_items_category ON items(category_id);
CREATE INDEX idx_items_location ON items(location_id);
CREATE TABLE item_images (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  item_id INTEGER NOT NULL,
  image_url TEXT NOT NULL,
  FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
);
CREATE TABLE claims (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  item_id INTEGER NOT NULL,
  claimant_id INTEGER NOT NULL,
  proof TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
  admin_note TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reviewed_at TEXT,
  UNIQUE (item_id, claimant_id),
  FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE,
  FOREIGN KEY (claimant_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE notifications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  is_read INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX idx_notif_user ON notifications(user_id, is_read);
CREATE TABLE announcements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);
CREATE TABLE activity_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER,
  action TEXT NOT NULL,
  details TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);
CREATE INDEX idx_logs_created ON activity_logs(created_at);

-- View: items joined with category, location and reporter
CREATE VIEW v_item_details AS
SELECT i.id, i.type, i.title, i.status, i.event_date, c.name AS category, l.name AS location, p.full_name AS reporter
FROM items i JOIN categories c ON c.id=i.category_id JOIN locations l ON l.id=i.location_id JOIN student_profiles p ON p.user_id=i.reported_by;

-- Trigger: notify the reporter automatically when an admin approves/rejects a pending report
CREATE TRIGGER trg_item_review AFTER UPDATE OF status ON items
WHEN OLD.status='pending' AND NEW.status IN ('approved','rejected')
BEGIN
  INSERT INTO notifications(user_id,title,message)
  VALUES (NEW.reported_by, 'Report '||NEW.status,
    'Your '||NEW.type||' report "'||NEW.title||'" was '||NEW.status||'.'||COALESCE(' Note: '||NEW.admin_note,''));
END;

-- ---------------- Demo data ----------------
INSERT INTO categories(name,description) VALUES
('Electronics','Phones, laptops, chargers, earbuds'),
('Books & Stationery','Books, notebooks, calculators'),
('Clothing & Accessories','Jackets, caps, scarves, glasses'),
('ID & Cards','Student ID, library and bank cards'),
('Keys','Keys and key chains'),
('Bags & Wallets','Backpacks, purses, wallets'),
('Sports Equipment','Bats, rackets, bottles, shoes'),
('Other','Anything else');

INSERT INTO locations(name,description) VALUES
('Main Library','Reading halls and stacks'),
('Student Cafeteria','Food court and seating'),
('Engineering Block','Lecture halls and labs'),
('Science Block','Physics, chemistry and biology labs'),
('Sports Complex','Courts, gym and ground'),
('Auditorium','Events and seminars'),
('Hostel Gate','Main hostel entrance'),
('Computer Lab','Central computing facility'),
('Admin Building','Offices and reception'),
('Parking Area','Two-wheeler and car parking');

INSERT INTO users(email,password_hash,role,status,created_at) VALUES
('sunita.rao@campus.edu','668c94bf7d60bc30:f81bdc01a3752145e6dce409b04c2c7943253fca2acb417ec33f07925bb59a2b','admin','active','2026-08-01 09:00:00'),
('anil.kumar@campus.edu','0491c7d4a82e805d:2071a1f12abf17bdedc19853dbb5ca043d9d78877b0460df770fe8cf2d8dd641','admin','active','2026-08-01 09:00:00'),
('jiya.gupta@campus.edu','f8aa25c0438867b2:435fe043b4ee7329c76e6630a6be129d1067727596fdd022d8b874e86ddcc2d9','student','active','2026-08-03 10:00:00'),
('ananya.iyer@campus.edu','991d509b353d640e:70477514fee5bdafc9e48b01605e0f38599f0dcad7ddd7bc892cb58a47bfbe47','student','active','2026-08-04 10:00:00'),
('kabir.malhotra@campus.edu','7df5336b48090d3d:bca7181d10822bf782e073af6e539772a17997824a7a2b1de811cb2694c30b1e','student','active','2026-08-05 10:00:00'),
('priya.nair@campus.edu','1e2d2b005c13cf3b:3fa86112bb4cbbd74664dca738225e7b4429ee8290cc6a3bc2a0e855c7fea4fc','student','active','2026-08-06 10:00:00'),
('vikram.singh@campus.edu','b91cf1825cc4aa2a:8a5f12a2f89aeba5513df58f8d680a9a63bc15bb45c717378ae7b6475d104992','student','active','2026-08-07 10:00:00'),
('sneha.kulkarni@campus.edu','9850ac6b78e7f314:4c63d6b03b4dad265bf11f33b7865b5dce39dc2e53ade3109ad13ad13ace1737','student','active','2026-08-08 10:00:00'),
('aditya.verma@campus.edu','1d38e553f116a850:00ef302b0a8bbe320df18da78be482b76843a39b26a63871571fda116bc5ca86','student','active','2026-08-09 10:00:00'),
('neha.gupta@campus.edu','1b293764238268ad:543f233b9d5d081bc3b5f74d6ecbfa774373f22d7aa2aa8cb8e94ab8ade1c7e3','student','active','2026-08-10 10:00:00'),
('rahul.mehta@campus.edu','3c7699e75673568a:ac0c086622f2ac46173e754b68f63b9e1ac8fab172337d4f06eee8a8b769af5b','student','active','2026-08-11 10:00:00'),
('pooja.reddy@campus.edu','1b6b823ffedb57d8:030a8bfb22a3407e9b7bb36c1670a30b42e38cb1769d123aaa2cfec2c775d436','student','active','2026-08-12 10:00:00'),
('karan.kapoor@campus.edu','7fefa6c6c2d72012:041a82659415ac31b6c951211954eb08e741d2daf92ceadf168eea82271155fa','student','active','2026-08-13 10:00:00'),
('divya.menon@campus.edu','0607d2d31c6c9f2b:55a8f52730375637e2da37b8d7d87151c38cf73c681777f9190bc8bf71f469ab','student','active','2026-08-14 10:00:00'),
('siddharth.joshi@campus.edu','f94cf2e090add2c0:c29a410cd2581b5b6584dfbd59962c07aa16c50b26e2007e00903b51587d1a19','student','active','2026-08-15 10:00:00'),
('meera.pillai@campus.edu','e665d43c371ca323:fd04149b015c1a3f6a8af98173118ae9cf988161cff7c38ccecaf11b8e8187d3','student','active','2026-08-16 10:00:00'),
('harsh.agarwal@campus.edu','16982f8b00cb23e2:fbd302c09112e90dcf292f59d39be8a8fdcbb90a7ffa0f2f74a576b566130712','student','active','2026-08-17 10:00:00'),
('tanvi.deshmukh@campus.edu','95a45162b9efcd9c:d294d6f3268b3abd194828c0348bdc2e68cd3815b2f0acf5da32a0c86fb4389f','student','active','2026-08-18 10:00:00'),
('nikhil.bansal@campus.edu','dafab3907cda728e:7d8df0e8da538e4265345dff309c6bfac16f76e6ac39de76f6d9cd074727c632','student','active','2026-08-19 10:00:00'),
('ishita.chatterjee@campus.edu','d4df9e8ff88584dc:0913805b01f89ffa3096fa5e4bc48a2769b5cba4666a90b7ca13965a8736e8fe','student','active','2026-08-20 10:00:00'),
('manish.yadav@campus.edu','0c89c4ee6efb0a7f:52f50b9f50459f32ea74466c58f93dea77d6021037c3fbf27f1514739358d34e','student','active','2026-08-21 10:00:00'),
('simran.kaur@campus.edu','0ceaa45702fe3894:6fb3601808a280c0cda1e5560a74b440399f91a80273b2acaee545935b954887','student','active','2026-08-22 10:00:00'),
('varun.choudhary@campus.edu','51b6b7f4ecf9c731:ae6418c64e56b62e75b22f5896c83de5ba49bab28733e5bec800b994d5522e18','student','active','2026-08-23 10:00:00'),
('riya.banerjee@campus.edu','91cc693990a0bba5:f255f4097cfaa93de59dfea0c2791f705e9a9f64c802fd16077c7e2f0bb4fe76','student','active','2026-08-24 10:00:00'),
('yash.patel@campus.edu','f24b6d44ef9b8877:719712c14e6bdcf520d7dd25871570e81345c7ef64300b144ac77a22db46fdc9','student','active','2026-08-25 10:00:00'),
('aisha.khan@campus.edu','05f8bd8e684ed3c0:5d4ed00bf65d6b4572ec656145b33179dcb427f82b8ab870694e1ee1a982338a','student','suspended','2026-08-26 10:00:00');

INSERT INTO student_profiles(user_id,student_id,full_name,department,year_of_study,phone) VALUES
('1','ADM-01','Sunita Rao','Administration',NULL,'9000000000'),
('2','ADM-02','Anil Kumar','Administration',NULL,'9000000000'),
('3','CS2601','Jiya Gupta','Mechanical Engineering','2','9800000001'),
('4','CS2602','Ananya Iyer','Electronics','3','9800000002'),
('5','CS2603','Kabir Malhotra','Civil Engineering','4','9800000003'),
('6','CS2604','Priya Nair','Business Administration','1','9800000004'),
('7','CS2605','Vikram Singh','Physics','2','9800000005'),
('8','CS2606','Sneha Kulkarni','Computer Science','3','9800000006'),
('9','CS2607','Aditya Verma','Mechanical Engineering','4','9800000007'),
('10','CS2608','Neha Gupta','Electronics','1','9800000008'),
('11','CS2609','Rahul Mehta','Civil Engineering','2','9800000009'),
('12','CS2610','Pooja Reddy','Business Administration','3','9800000010'),
('13','CS2611','Karan Kapoor','Physics','4','9800000011'),
('14','CS2612','Divya Menon','Computer Science','1','9800000012'),
('15','CS2613','Siddharth Joshi','Mechanical Engineering','2','9800000013'),
('16','CS2614','Meera Pillai','Electronics','3','9800000014'),
('17','CS2615','Harsh Agarwal','Civil Engineering','4','9800000015'),
('18','CS2616','Tanvi Deshmukh','Business Administration','1','9800000016'),
('19','CS2617','Nikhil Bansal','Physics','2','9800000017'),
('20','CS2618','Ishita Chatterjee','Computer Science','3','9800000018'),
('21','CS2619','Manish Yadav','Mechanical Engineering','4','9800000019'),
('22','CS2620','Simran Kaur','Electronics','1','9800000020'),
('23','CS2621','Varun Choudhary','Civil Engineering','2','9800000021'),
('24','CS2622','Riya Banerjee','Business Administration','3','9800000022'),
('25','CS2623','Yash Patel','Physics','4','9800000023'),
('26','CS2624','Aisha Khan','Computer Science','1','9800000024');

INSERT INTO items(type,title,description,category_id,location_id,event_date,status,admin_note,reported_by,created_at) VALUES
('lost','Black wireless earbuds case','Black charging case with a small scratch on the lid.','1','3','2026-10-01','approved',NULL,'3','2026-10-01 12:00:00'),
('found','Blue water bottle','Blue steel bottle with a sticker on the side.','7','5','2026-10-02','approved',NULL,'8','2026-10-02 12:00:00'),
('lost','Student ID card','University student ID card in a clear holder.','4','1','2026-10-03','pending',NULL,'13','2026-10-03 12:00:00'),
('found','Set of keys','Three keys on a red key ring with a small tag.','5','7','2026-10-04','approved',NULL,'18','2026-10-04 12:00:00'),
('lost','Scientific calculator','Grey scientific calculator with a cracked cover.','2','4','2026-10-05','claimed',NULL,'23','2026-10-05 12:00:00'),
('found','Grey hoodie','Medium grey hoodie with a zipper.','3','2','2026-10-06','rejected','Insufficient details provided','4','2026-10-06 12:00:00'),
('lost','Laptop charger','65W charger with a white cable.','1','8','2026-10-07','approved',NULL,'9','2026-10-07 12:00:00'),
('found','Brown leather wallet','Brown wallet containing a few cards and papers.','6','2','2026-10-08','returned',NULL,'14','2026-10-08 12:00:00'),
('lost','Data Structures textbook','Hardcover textbook with handwritten notes.','2','1','2026-10-09','approved',NULL,'19','2026-10-09 12:00:00'),
('found','Black backpack','Black backpack with a blue zipper pull.','6','10','2026-10-10','approved',NULL,'24','2026-10-10 12:00:00'),
('lost','Prescription glasses','Round black-framed glasses in a soft case.','3','6','2026-10-11','pending',NULL,'5','2026-10-11 12:00:00'),
('found','USB flash drive 64GB','Silver USB drive with a lanyard.','1','8','2026-10-12','approved',NULL,'10','2026-10-12 12:00:00'),
('lost','Badminton racket','Red racket with a black grip.','7','5','2026-10-13','claimed',NULL,'15','2026-10-13 12:00:00'),
('found','Library card','Library membership card, slightly bent.','4','1','2026-10-14','rejected','Insufficient details provided','20','2026-10-14 12:00:00'),
('lost','Bike key','Single bike key with a rubber cover.','5','10','2026-10-15','approved',NULL,'25','2026-10-15 12:00:00'),
('found','Smartwatch','Black smartwatch with a fitness band.','1','3','2026-10-16','returned',NULL,'6','2026-10-16 12:00:00'),
('lost','Umbrella','Dark green foldable umbrella.','8','9','2026-10-17','approved',NULL,'11','2026-10-17 12:00:00'),
('found','Notebook (Physics)','Spiral notebook with a blue cover.','2','4','2026-10-18','approved',NULL,'16','2026-10-18 12:00:00'),
('lost','Wristwatch','Analog watch with a brown strap.','3','6','2026-10-19','pending',NULL,'21','2026-10-19 12:00:00'),
('found','Power bank','10000mAh white power bank.','1','2','2026-10-20','approved',NULL,'26','2026-10-20 12:00:00'),
('lost','Black wireless earbuds case','Black charging case with a small scratch on the lid.','1','3','2026-10-21','claimed',NULL,'7','2026-10-21 12:00:00'),
('found','Blue water bottle','Blue steel bottle with a sticker on the side.','7','5','2026-10-22','rejected','Insufficient details provided','12','2026-10-22 12:00:00'),
('lost','Student ID card','University student ID card in a clear holder.','4','1','2026-10-23','approved',NULL,'17','2026-10-23 12:00:00'),
('found','Set of keys','Three keys on a red key ring with a small tag.','5','7','2026-10-24','returned',NULL,'22','2026-10-24 12:00:00'),
('lost','Scientific calculator','Grey scientific calculator with a cracked cover.','2','4','2026-10-25','approved',NULL,'3','2026-10-25 12:00:00'),
('found','Grey hoodie','Medium grey hoodie with a zipper.','3','2','2026-10-26','approved',NULL,'8','2026-10-26 12:00:00'),
('lost','Laptop charger','65W charger with a white cable.','1','8','2026-10-27','pending',NULL,'13','2026-10-27 12:00:00'),
('found','Brown leather wallet','Brown wallet containing a few cards and papers.','6','2','2026-10-28','approved',NULL,'18','2026-10-28 12:00:00'),
('lost','Data Structures textbook','Hardcover textbook with handwritten notes.','2','1','2026-10-29','claimed',NULL,'23','2026-10-29 12:00:00'),
('found','Black backpack','Black backpack with a blue zipper pull.','6','10','2026-10-30','rejected','Insufficient details provided','4','2026-10-30 12:00:00'),
('lost','Prescription glasses','Round black-framed glasses in a soft case.','3','6','2026-10-31','approved',NULL,'9','2026-10-31 12:00:00'),
('found','USB flash drive 64GB','Silver USB drive with a lanyard.','1','8','2026-11-01','returned',NULL,'14','2026-11-01 12:00:00'),
('lost','Badminton racket','Red racket with a black grip.','7','5','2026-11-02','approved',NULL,'19','2026-11-02 12:00:00'),
('found','Library card','Library membership card, slightly bent.','4','1','2026-11-03','approved',NULL,'24','2026-11-03 12:00:00'),
('lost','Bike key','Single bike key with a rubber cover.','5','10','2026-11-04','pending',NULL,'5','2026-11-04 12:00:00'),
('found','Smartwatch','Black smartwatch with a fitness band.','1','3','2026-11-05','approved',NULL,'10','2026-11-05 12:00:00'),
('lost','Umbrella','Dark green foldable umbrella.','8','9','2026-11-06','claimed',NULL,'15','2026-11-06 12:00:00'),
('found','Notebook (Physics)','Spiral notebook with a blue cover.','2','4','2026-11-07','rejected','Insufficient details provided','20','2026-11-07 12:00:00'),
('lost','Wristwatch','Analog watch with a brown strap.','3','6','2026-11-08','approved',NULL,'25','2026-11-08 12:00:00'),
('found','Power bank','10000mAh white power bank.','1','2','2026-11-09','returned',NULL,'6','2026-11-09 12:00:00');

INSERT INTO claims(item_id,claimant_id,proof,status,admin_note,created_at,reviewed_at) VALUES
('1','7','It has my initials scratched inside; I lost it on the same day.','pending',NULL,'2026-10-01 17:00:00',NULL),
('5','3','I can describe unique marks and the exact contents of this item.','approved','Ownership verified at Admin Building','2026-10-05 15:00:00','2026-11-05 11:00:00'),
('5','8','I think this belongs to me, it looks like mine.','rejected','Could not verify ownership','2026-10-05 16:00:00','2026-11-05 11:30:00'),
('8','18','I can describe unique marks and the exact contents of this item.','approved','Ownership verified at Admin Building','2026-10-08 15:00:00','2026-11-08 11:00:00'),
('8','23','I think this belongs to me, it looks like mine.','rejected','Could not verify ownership','2026-10-08 16:00:00','2026-11-08 11:30:00'),
('9','23','It has my initials scratched inside; I lost it on the same day.','pending',NULL,'2026-10-09 17:00:00',NULL),
('13','19','I can describe unique marks and the exact contents of this item.','approved','Ownership verified at Admin Building','2026-10-13 15:00:00','2026-11-05 11:00:00'),
('13','24','I think this belongs to me, it looks like mine.','rejected','Could not verify ownership','2026-10-13 16:00:00','2026-11-05 11:30:00'),
('16','10','I can describe unique marks and the exact contents of this item.','approved','Ownership verified at Admin Building','2026-10-16 15:00:00','2026-11-08 11:00:00'),
('16','15','I think this belongs to me, it looks like mine.','rejected','Could not verify ownership','2026-10-16 16:00:00','2026-11-08 11:30:00'),
('17','15','It has my initials scratched inside; I lost it on the same day.','pending',NULL,'2026-10-17 17:00:00',NULL),
('21','11','I can describe unique marks and the exact contents of this item.','approved','Ownership verified at Admin Building','2026-10-21 15:00:00','2026-11-05 11:00:00'),
('21','16','I think this belongs to me, it looks like mine.','rejected','Could not verify ownership','2026-10-21 16:00:00','2026-11-05 11:30:00'),
('24','26','I can describe unique marks and the exact contents of this item.','approved','Ownership verified at Admin Building','2026-10-24 15:00:00','2026-11-08 11:00:00'),
('24','7','I think this belongs to me, it looks like mine.','rejected','Could not verify ownership','2026-10-24 16:00:00','2026-11-08 11:30:00'),
('25','7','It has my initials scratched inside; I lost it on the same day.','pending',NULL,'2026-10-25 17:00:00',NULL),
('29','3','I can describe unique marks and the exact contents of this item.','approved','Ownership verified at Admin Building','2026-10-29 15:00:00','2026-11-05 11:00:00'),
('29','8','I think this belongs to me, it looks like mine.','rejected','Could not verify ownership','2026-10-29 16:00:00','2026-11-05 11:30:00'),
('32','18','I can describe unique marks and the exact contents of this item.','approved','Ownership verified at Admin Building','2026-11-01 15:00:00','2026-11-08 11:00:00'),
('32','23','I think this belongs to me, it looks like mine.','rejected','Could not verify ownership','2026-11-01 16:00:00','2026-11-08 11:30:00'),
('33','23','It has my initials scratched inside; I lost it on the same day.','pending',NULL,'2026-11-02 17:00:00',NULL),
('37','19','I can describe unique marks and the exact contents of this item.','approved','Ownership verified at Admin Building','2026-11-06 15:00:00','2026-11-05 11:00:00'),
('37','24','I think this belongs to me, it looks like mine.','rejected','Could not verify ownership','2026-11-06 16:00:00','2026-11-05 11:30:00'),
('40','10','I can describe unique marks and the exact contents of this item.','approved','Ownership verified at Admin Building','2026-11-09 15:00:00','2026-11-08 11:00:00'),
('40','15','I think this belongs to me, it looks like mine.','rejected','Could not verify ownership','2026-11-09 16:00:00','2026-11-08 11:30:00');

INSERT INTO notifications(user_id,title,message,is_read,created_at) VALUES
('3','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('3','Claim update','One of your claims has been reviewed. Check My Claims.','0','2026-11-05 10:00:00'),
('4','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('4','Report approved','Your report was approved and is now visible to everyone.','0','2026-11-06 10:00:00'),
('5','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('6','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('6','Claim update','One of your claims has been reviewed. Check My Claims.','0','2026-11-05 10:00:00'),
('7','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('8','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('8','Report approved','Your report was approved and is now visible to everyone.','0','2026-11-06 10:00:00'),
('9','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('9','Claim update','One of your claims has been reviewed. Check My Claims.','0','2026-11-05 10:00:00'),
('10','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('11','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('12','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('12','Claim update','One of your claims has been reviewed. Check My Claims.','0','2026-11-05 10:00:00'),
('12','Report approved','Your report was approved and is now visible to everyone.','0','2026-11-06 10:00:00'),
('13','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('14','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('15','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('15','Claim update','One of your claims has been reviewed. Check My Claims.','0','2026-11-05 10:00:00'),
('16','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('16','Report approved','Your report was approved and is now visible to everyone.','0','2026-11-06 10:00:00'),
('17','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('18','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('18','Claim update','One of your claims has been reviewed. Check My Claims.','0','2026-11-05 10:00:00'),
('19','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('20','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('20','Report approved','Your report was approved and is now visible to everyone.','0','2026-11-06 10:00:00'),
('21','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('21','Claim update','One of your claims has been reviewed. Check My Claims.','0','2026-11-05 10:00:00'),
('22','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('23','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('24','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('24','Claim update','One of your claims has been reviewed. Check My Claims.','0','2026-11-05 10:00:00'),
('24','Report approved','Your report was approved and is now visible to everyone.','0','2026-11-06 10:00:00'),
('25','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00'),
('26','Welcome','Welcome to Campus Lost & Found!','1','2026-10-01 09:00:00');

INSERT INTO announcements(title,body,created_by,created_at) VALUES
('Lost & Found desk timings','The physical desk in the Admin Building is open 9 AM to 5 PM on working days.','1','2026-10-02 09:00:00'),
('Always carry your ID','Please keep your student ID with you. Report lost cards immediately.','1','2026-10-15 09:00:00'),
('Unclaimed items policy','Items unclaimed for 60 days are handed over to the campus security office.','2','2026-11-01 09:00:00'),
('Exam week reminder','Do not leave electronics unattended in the library during exam week.','1','2026-11-10 09:00:00');

INSERT INTO activity_logs(user_id,action,details,created_at) VALUES
('3','LOGIN','Signed in','2026-11-01 8:15:00'),
('4','REPORT_ITEM','Submitted a report','2026-11-02 9:15:00'),
('5','CLAIM_SUBMIT','Submitted a claim','2026-11-03 10:15:00'),
('2','ITEM_REVIEW','Reviewed an item report','2026-11-04 11:15:00'),
('1','CLAIM_REVIEW','Reviewed an ownership claim','2026-11-05 12:15:00'),
('8','LOGIN','Signed in','2026-11-06 13:15:00'),
('9','REPORT_ITEM','Submitted a report','2026-11-07 14:15:00'),
('10','CLAIM_SUBMIT','Submitted a claim','2026-11-08 15:15:00'),
('1','ITEM_REVIEW','Reviewed an item report','2026-11-09 16:15:00'),
('2','CLAIM_REVIEW','Reviewed an ownership claim','2026-11-10 17:15:00'),
('13','LOGIN','Signed in','2026-11-11 8:15:00'),
('14','REPORT_ITEM','Submitted a report','2026-11-12 9:15:00'),
('15','CLAIM_SUBMIT','Submitted a claim','2026-11-13 10:15:00'),
('2','ITEM_REVIEW','Reviewed an item report','2026-11-14 11:15:00'),
('1','CLAIM_REVIEW','Reviewed an ownership claim','2026-11-15 12:15:00'),
('18','LOGIN','Signed in','2026-11-16 13:15:00'),
('19','REPORT_ITEM','Submitted a report','2026-11-17 14:15:00'),
('20','CLAIM_SUBMIT','Submitted a claim','2026-11-18 15:15:00'),
('1','ITEM_REVIEW','Reviewed an item report','2026-11-01 16:15:00'),
('2','CLAIM_REVIEW','Reviewed an ownership claim','2026-11-02 17:15:00'),
('23','LOGIN','Signed in','2026-11-03 8:15:00'),
('24','REPORT_ITEM','Submitted a report','2026-11-04 9:15:00'),
('25','CLAIM_SUBMIT','Submitted a claim','2026-11-05 10:15:00'),
('2','ITEM_REVIEW','Reviewed an item report','2026-11-06 11:15:00'),
('1','CLAIM_REVIEW','Reviewed an ownership claim','2026-11-07 12:15:00'),
('4','LOGIN','Signed in','2026-11-08 13:15:00'),
('5','REPORT_ITEM','Submitted a report','2026-11-09 14:15:00'),
('6','CLAIM_SUBMIT','Submitted a claim','2026-11-10 15:15:00'),
('1','ITEM_REVIEW','Reviewed an item report','2026-11-11 16:15:00'),
('2','CLAIM_REVIEW','Reviewed an ownership claim','2026-11-12 17:15:00');
