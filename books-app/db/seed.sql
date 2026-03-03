-- Seed data for Books & Authors

INSERT INTO authors (name, bio, nationality, born_year) VALUES
  ('George Orwell',        'English novelist and essayist, known for dystopian fiction.', 'British',    1903),
  ('J.K. Rowling',         'British author best known for the Harry Potter series.',      'British',    1965),
  ('Frank Herbert',        'American science fiction author of the Dune series.',         'American',   1920),
  ('Gabriel García Márquez','Colombian novelist, one of the pioneers of Magic Realism.',  'Colombian',  1927),
  ('Ursula K. Le Guin',    'American author of speculative fiction and fantasy.',         'American',   1929),
  ('Fyodor Dostoevsky',    'Russian novelist known for psychological depth.',             'Russian',    1821),
  ('Agatha Christie',      'British mystery writer, known as the Queen of Crime.',       'British',    1890),
  ('Isaac Asimov',         'American author and professor of biochemistry, prolific sci-fi writer.', 'American', 1920);

INSERT INTO books (title, author_id, genre, published_year, isbn, description) VALUES
  ('1984',                        1, 'Dystopian Fiction',    1949, '978-0451524935', 'A chilling portrait of a totalitarian society ruled by Big Brother.'),
  ('Animal Farm',                 1, 'Political Satire',     1945, '978-0451526342', 'A satirical allegory of Soviet totalitarianism using farm animals.'),
  ('Harry Potter and the Philosopher''s Stone', 2, 'Fantasy', 1997, '978-0747532699', 'A young boy discovers he is a wizard and attends Hogwarts School.'),
  ('Harry Potter and the Chamber of Secrets',   2, 'Fantasy', 1998, '978-0747538486', 'Harry''s second year at Hogwarts brings a mysterious monster.'),
  ('Dune',                        3, 'Science Fiction',      1965, '978-0441013593', 'Epic tale of politics, religion, and ecology on a desert planet.'),
  ('One Hundred Years of Solitude', 4, 'Magic Realism',      1967, '978-0060883287', 'The Buendía family saga across seven generations in Macondo.'),
  ('The Left Hand of Darkness',   5, 'Science Fiction',      1969, '978-0441478125', 'An envoy explores a planet where inhabitants have no fixed gender.'),
  ('The Dispossessed',            5, 'Science Fiction',      1974, '978-0061054884', 'A physicist from an anarchist moon visits its capitalist twin planet.'),
  ('Crime and Punishment',        6, 'Psychological Fiction', 1866, '978-0486415871', 'A student commits a murder and grapples with guilt and redemption.'),
  ('The Brothers Karamazov',      6, 'Philosophical Fiction', 1880, '978-0374528379', 'A passionate philosophical novel about faith, doubt, and morality.'),
  ('Murder on the Orient Express', 7, 'Mystery',             1934, '978-0062693662', 'Hercule Poirot investigates a murder aboard a snowbound train.'),
  ('And Then There Were None',    7, 'Mystery',              1939, '978-0062073488', 'Ten strangers are lured to an island and killed one by one.'),
  ('Foundation',                  8, 'Science Fiction',      1951, '978-0553293357', 'A mathematician develops a plan to preserve civilization across millennia.'),
  ('I, Robot',                    8, 'Science Fiction',      1950, '978-0553294385', 'Short stories exploring the interactions between humans and robots.');
