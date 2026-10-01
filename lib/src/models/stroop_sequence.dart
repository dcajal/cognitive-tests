/// One pair in the ordered sequence shared by all three Stroop pages.
///
/// Both indices use the fixed mapping 0 = red, 1 = green, 2 = blue.
/// Page 0 displays the word in black, page 1 displays the color alone,
/// and page 2 displays the word in the color. Words use the test's language.
/// The entry's position in the list defines presentation order.
typedef StroopSequenceEntry = ({int wordIndex, int colorIndex});
