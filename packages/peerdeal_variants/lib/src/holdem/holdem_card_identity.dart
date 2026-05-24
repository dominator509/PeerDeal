bool isHoldemCardIdentity(String card) {
  if (card.length != 2) {
    return false;
  }

  const ranks = <String>{
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'T',
    'J',
    'Q',
    'K',
    'A',
  };
  const suits = <String>{'c', 'd', 'h', 's'};
  return ranks.contains(card[0]) && suits.contains(card[1]);
}
