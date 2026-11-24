import '../models/newspaper.dart';

/// Default newspaper catalog. It is written to Firestore the first time the app
/// runs; after that the admin manages newspapers from the Catalog tab.
final List<Newspaper> kNewspapers = [
  const Newspaper(id: 'nyt', name: 'The New York Times', pricePerCopy: 3.00),
  const Newspaper(id: 'wsj', name: 'The Wall Street Journal', pricePerCopy: 3.50),
  const Newspaper(id: 'wapo', name: 'The Washington Post', pricePerCopy: 2.75),
  const Newspaper(id: 'guardian', name: 'The Guardian', pricePerCopy: 2.50),
  const Newspaper(id: 'times_uk', name: 'The Times (UK)', pricePerCopy: 2.90),
  const Newspaper(id: 'telegraph', name: 'The Daily Telegraph', pricePerCopy: 2.60),
  const Newspaper(id: 'usa_today', name: 'USA Today', pricePerCopy: 2.25),
  const Newspaper(id: 'ft', name: 'Financial Times', pricePerCopy: 4.00),
  const Newspaper(id: 'toi', name: 'The Times of India', pricePerCopy: 1.50),
  const Newspaper(id: 'hindu', name: 'The Hindu', pricePerCopy: 1.40),
];
